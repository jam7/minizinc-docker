# minizinc-docker

A docker container to run minizinc as a host user.

## Prerequisite

Need to install docker.

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
