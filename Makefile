RELEASE_VERSION = v1.0
VERSION = latest

OPTIONS = \
	--build-arg http_proxy=${http_proxy} \
	--build-arg https_proxy=${https_proxy} \
	--build-arg ftp_proxy=${ftp_proxy} \
	--build-arg no_proxy=${no_proxy}

build: FORCE
	docker build -t jam7/minizinc:${VERSION} ${OPTIONS} .

release: FORCE
	docker build -t jam7/minizinc:${RELEASE_VERSION} ${OPTIONS} .

push: FORCE
	docker push jam7/minizinc:${RELEASE_VERSION}
	docker push jam7/minizinc:${VERSION}

run: FORCE
	docker run --init -it --rm -v /var/run/docker.sock:/var/run/docker.sock jam7/minizinc sh

FORCE:

