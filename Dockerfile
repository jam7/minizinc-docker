FROM alpine AS build-gmp
LABEL maintainer "Kazushi (Jam) Marukawa <jam@pobox.com>"

# GNU Multiple Precision Arithmetic Library
ENV GMP https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz

RUN apk add --no-cache ca-certificates curl tar xz make gcc g++ pkgconfig m4
WORKDIR /work
RUN curl -L ${GMP} -o gmp.tar.xz && \
    tar xf gmp.tar.xz && \
    cd gmp-*/ && \
    ./configure && \
    make install-strip -j

FROM alpine AS build-mpfr

# GNU Multiple-precision floating-point computations with correct rounding
ENV MPFR https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.xz
ENV PATCHES https://www.mpfr.org/mpfr-4.1.0/allpatches

RUN apk add --no-cache ca-certificates curl tar xz make gcc g++ pkgconfig patch
COPY --from=build-gmp /usr/local /usr/local
WORKDIR /work
RUN curl -L ${MPFR} -o mpfr.tar.xz && \
    tar xf mpfr.tar.xz && \
    cd mpfr-*/ && \
    curl -L ${PATCHES} | patch -N -Z -p1 && \
    ./configure && \
    make install-strip -j

FROM alpine AS build-glpk

# GNU Linear Programming Kit
ENV GLPK https://ftp.gnu.org/gnu/glpk/glpk-5.0.tar.gz

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig
COPY --from=build-gmp /usr/local /usr/local
WORKDIR /work
RUN curl -L ${GLPK} -o glpk.tar.gz && \
    tar xf glpk.tar.gz && \
    cd glpk*/ && \
    ./configure --with-gmp && \
    make install-strip -j

FROM alpine AS build-gsl

# GNU Scientific Library
ENV GSL https://ftp.jaist.ac.jp/pub/GNU/gsl/gsl-2.7.1.tar.gz

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig
WORKDIR /work
RUN curl -L ${GSL} -o gsl.tar.gz && \
    tar xf gsl.tar.gz && \
    cd gsl*/ && \
    ./configure && \
    make -j && \
    make install-strip

FROM alpine AS build-gecode

# Generic Constraint Development Environment
ENV GECODE https://github.com/Gecode/gecode.git
ENV BRANCH release/6.3.0
# My develop environment doesn't have enough memory for large size compilation
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig git perl
COPY --from=build-gmp /usr/local /usr/local
COPY --from=build-mpfr /usr/local /usr/local
WORKDIR /work
RUN git clone ${GECODE} -b ${BRANCH} && \
    cd gecode && \
    ./configure && \
    make install -j ${JOBS}

FROM alpine AS build-cbc

# Computational Infrastructure for Operations Research
ENV COINBREW https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew
ENV BRANCH releases/2.10.7
# My develop environment doesn't have enough memory for large size compilation
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig bash git patch file
WORKDIR /work
# On alpine ldconfig returns errors without any arguments.
RUN curl -L ${COINBREW} -o coinbrew && \
    chmod a+x coinbrew && \
    ./coinbrew build Cbc@${BRANCH} -j ${JOBS} --enable-cbc-parallel --prefix=/usr/local || true

FROM alpine AS build-minizinc

# MiniZinc
ENV MINIZINC https://github.com/MiniZinc/libminizinc.git
ENV BRANCH 2.6.2
# My develop environment doesn't have enough memory for large size compilation
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig git cmake zlib-dev
COPY --from=build-gecode /usr/local /usr/local
COPY --from=build-cbc /usr/local /usr/local
WORKDIR /work
RUN git clone ${MINIZINC} -b ${BRANCH} && \
    cd libminizinc && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DUSE_PROPRIETARY=on .. && \
    make install -j ${JOBS}

#COPY --from=build-gmp /usr/local /usr/local
#COPY --from=build-mpfr /usr/local /usr/local
#COPY --from=build-glpk /usr/local /usr/local
#COPY --from=build-gsl /usr/local /usr/local
#COPY --from=build-gecode /usr/local /usr/local

FROM alpine AS runner

RUN apk add --no-cache ca-certificates curl su-exec tar pkgconfig libstdc++

COPY --from=build-minizinc /usr/local /usr/local
COPY entrypoint.sh /minizinc/entrypoint.sh
COPY minizinc.sh /minizinc/minizinc.sh
WORKDIR /work

ENTRYPOINT ["/minizinc/entrypoint.sh"]
