FROM alpine AS build-gmp
LABEL maintainer "Kazushi (Jam) Marukawa <jam@pobox.com>"

# GNU Multiple Precision Arithmetic Library
ENV GMP https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz

RUN apk add --no-cache ca-certificates curl tar xz make gcc g++ pkgconfig m4
WORKDIR /work/gmp
RUN curl -L ${GMP} -o gmp.tar.xz && \
    tar --strip-components 1 -xf gmp.tar.xz && \
    rm gmp.tar.xz
RUN ./configure --enable-static && \
    make install-strip -j

FROM alpine AS build-mpfr

# GNU Multiple-precision floating-point computations with correct rounding
ENV MPFR https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.xz
ENV PATCHES https://www.mpfr.org/mpfr-4.1.0/allpatches

RUN apk add --no-cache ca-certificates curl tar xz make gcc g++ pkgconfig patch
COPY --from=build-gmp /usr/local /usr/local
WORKDIR /work/mpfr
RUN curl -L ${MPFR} -o mpfr.tar.xz && \
    tar --strip-components 1 -xf mpfr.tar.xz && \
    rm mpfr.tar.xz
RUN curl -L ${PATCHES} | patch -N -Z -p1 && \
    ./configure --enable-static && \
    make install-strip -j

FROM alpine AS build-glpk

# GNU Linear Programming Kit
ENV GLPK https://ftp.gnu.org/gnu/glpk/glpk-5.0.tar.gz

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig
COPY --from=build-gmp /usr/local /usr/local
WORKDIR /work/glpk
RUN curl -L ${GLPK} -o glpk.tar.gz && \
    tar --strip-components 1 -xf glpk.tar.gz && \
    rm glpk.tar.gz
RUN ./configure --with-gmp --enable-static && \
    make install-strip -j

FROM alpine AS build-gsl

# GNU Scientific Library
ENV GSL https://ftp.jaist.ac.jp/pub/GNU/gsl/gsl-2.7.1.tar.gz

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig
WORKDIR /work/gsl
RUN curl -L ${GSL} -o gsl.tar.gz && \
    tar --strip-components 1 -xf gsl.tar.gz && \
    rm gsl.tar.gz
RUN ./configure --enable-static && \
    make -j && \
    make install-strip

FROM alpine AS build-gecode

# Generic Constraint Development Environment
ENV GECODE https://github.com/Gecode/gecode.git
ENV BRANCH release/6.3.0
# My develop environment doesn't have enough memory for large size compilation.
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig git perl
COPY --from=build-gmp /usr/local /usr/local
COPY --from=build-mpfr /usr/local /usr/local
WORKDIR /work/gecode
RUN git clone ${GECODE} -b ${BRANCH} .
RUN ./configure --disable-examples --prefix=/opt/gecode && \
    make install -j ${JOBS} && \
    strip --strip-unneeded /opt/gecode/bin/fzn-gecode && \
    strip --strip-unneeded /opt/gecode/lib/*.so*

# Copy bin, lib, and share/minizinc into /usr/local.
WORKDIR /usr/local
RUN tar cf - -C /opt/gecode/ bin lib share/minizinc | tar xpf -

FROM alpine AS build-cbc

# Computational Infrastructure for Operations Research
ENV COINBREW https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew
ENV BRANCH releases/2.10.7
# My develop environment doesn't have enough memory for large size compilation.
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig bash git patch file
WORKDIR /work/cbc
# On alpine ldconfig returns errors without any arguments.
RUN curl -L ${COINBREW} -o coinbrew && \
    chmod a+x coinbrew && \
    ./coinbrew fetch Cbc@${BRANCH}
RUN ./coinbrew build Cbc@${BRANCH} -j ${JOBS} --static --enable-cbc-parallel --prefix=/opt/cbc || true

FROM alpine AS build-chuffed

# Chuffed CP solver
ENV CHUFFED https://github.com/chuffed/chuffed.git
ENV BRANCH Update_mznlib
# My develop environment doesn't have enough memory for large size compilation.
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig git cmake bison flex zlib-dev
WORKDIR /work/chuffed
RUN git clone ${CHUFFED} -b ${BRANCH} .
WORKDIR /work/chuffed/build
# Need to handle generated parser.tab.h correctly.  So, add -I to compiler,
# and remove original parser.tab.h.
# See https://github.com/chuffed/chuffed/issues/75 for detail.
RUN CXXFLAGS=-I`pwd`/chuffed/flatzinc cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/chuffed .. && \
    rm ../chuffed/flatzinc/parser.tab.h && \
    make install/strip -j ${JOBS}
# Create msc file for Chuffed.
WORKDIR /usr/local/share/minizinc/solvers
RUN sed -e '/mznlib/s:share/chuffed/mznlib:../chuffed:' -e '/executable/s:bin/fzn-chuffed:../../../bin/fzn-chuffed:' -e '/stdFlags/s:"-v":"-t","-v","--cp-profiler":' /opt/chuffed/chuffed.msc > chuffed.msc
WORKDIR /usr/local/share/minizinc/chuffed
RUN tar cf - -C /opt/chuffed/share/chuffed/mznlib . | tar xpf -
WORKDIR /usr/local/bin
RUN tar cf - -C /opt/chuffed/bin . | tar xpf -

FROM alpine AS build-minizinc

# MiniZinc
ENV MINIZINC https://github.com/MiniZinc/libminizinc.git
ENV BRANCH 2.6.2
# My develop environment doesn't have enough memory for large size compilation.
ENV JOBS 4

RUN apk add --no-cache ca-certificates curl tar make gcc g++ pkgconfig git cmake zlib-dev
COPY --from=build-gmp /usr/local /usr/local
COPY --from=build-mpfr /usr/local /usr/local
COPY --from=build-gecode /opt/gecode /opt/gecode
COPY --from=build-gecode /usr/local /usr/local
COPY --from=build-cbc /opt/cbc /opt/cbc
WORKDIR /work
RUN git clone ${MINIZINC} -b ${BRANCH} libminizinc
WORKDIR /work/libminizinc
RUN mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DUSE_PROPRIETARY=on -DGecode_ROOT=/opt/gecode -DOsiCBC_ROOT=/opt/cbc .. && \
    make install/strip -j ${JOBS}

#COPY --from=build-gmp /usr/local /usr/local
#COPY --from=build-mpfr /usr/local /usr/local
#COPY --from=build-glpk /usr/local /usr/local
#COPY --from=build-gsl /usr/local /usr/local
#COPY --from=build-gecode /usr/local /usr/local

FROM alpine AS build-ortools

# Google OR-Tools
ENV ORTOOLS https://github.com/google/or-tools/releases/download/v9.3/or-tools_amd64_flatzinc_alpine-edge_v9.3.10497.tar.gz

RUN apk add --no-cache curl tar
WORKDIR /opt/ortools
RUN curl -L ${ORTOOLS} -o ortools.tar.gz && \
    tar --strip-components 1 -xf ortools.tar.gz && \
    rm ortools.tar.gz
# Copy only share/minizinc/ortools mznlib files.
WORKDIR /usr/local
RUN tar cf - -C /opt/ortools/ share/minizinc/ortools | tar xpf -
# Prepare fzn-or-tools script to call fzn-or-tools in another docker container.
COPY fzn-or-tools.sh /usr/local/bin/fzn-or-tools
# Create msc file for OR-Tools.
WORKDIR /usr/local/share/minizinc/solvers
RUN sed -e '/executable/s:fz:fzn-or-tools:' /opt/ortools/share/minizinc/solvers/ortools.msc > ortools.msc

FROM alpine AS runner

RUN apk add --no-cache ca-certificates curl su-exec tar pkgconfig libstdc++ docker-cli

#COPY --from=build-cbc /opt/cbc /opt/cbc
COPY --from=build-minizinc /usr/local /usr/local
COPY --from=build-chuffed /usr/local /usr/local
COPY --from=build-ortools /usr/local /usr/local
#COPY --from=build-gecode /work /work
#COPY --from=build-cbc /work /work
#COPY --from=build-minizinc /work /work

COPY entrypoint.sh /minizinc/entrypoint.sh
COPY minizinc.sh /minizinc/minizinc.sh
WORKDIR /work

ENTRYPOINT ["/minizinc/entrypoint.sh"]
