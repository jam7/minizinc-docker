# minizinc-docker

A docker container to run minizinc as a host user.

## Prerequisite

Need to install docker.

## Size

A image contains minizinc, gecode, chuffed, cbc, and built-in support for
gecode.  The image has 115MB.

```
$ docker images
REPOSITORY                                          TAG           IMAGE ID       CREATED             SIZE
jam7/minizinc                                       v1.1          1bddf286a408   3 minutes ago       115MB
```

## Solvers

```
$ docker run --rm jam7/minizinc minizinc --solvers
MiniZinc driver.
Available solver configurations:
  Chuffed 0.10.4 (org.chuffed.chuffed, cp, lcg, int)
  COIN-BC 2.10.7/1.17.7 (org.minizinc.mip.coin-bc, mip, float, api, osicbc, coinbc, cbc)
  CPLEX <unknown version> (org.minizinc.mip.cplex, mip, float, api)
  Gecode 6.3.0 (org.gecode.gecode, default solver, cp, int, float, set, restart)
  Gurobi <unknown version> (org.minizinc.mip.gurobi, mip, float, api)
  OR Tools 9.3.10497 (com.google.or-tools, ortools, cp, lcg, float, int)
  SCIP <unknown version> (org.minizinc.mip.scip, mip, float, api)
  Xpress <unknown version> (org.minizinc.mip.xpress, mip, float, api)
Search path for solver configurations:
  /usr/local/share/minizinc/solvers
  /usr/share/minizinc/solvers
```

## Install

Download container and run it to generate kindlegen script.

```
$ docker pull jam7/minizinc
$ docker run --rm jam7/minizinc > minizinc
$ chmod a+x minizinc
```

Don't add `-it` to `docker run`.  Otherwise, your minizinc script may
contain crlf.

## How to use it

Use a generated minizinc script as a regular minizinc.

```
$ ./minizinc tspmip.mzn eil51.dzn
```

## Build

In order to build image by yourself, perform `make`

```
$ make
```

## License

@ 2022 Kazushi (Jam) Marukawa, All rights reserved.

Distributed under the Mozilla Public License Version 2.0. See
`LICENSE` for more information.

## Related projects

Minizinc is in https://github.com/MiniZinc/libminizinc.
