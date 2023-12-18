ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := windows
	detected_arch := amd64
else
    detected_OS := $(shell uname | tr '[:upper:]' '[:lower:]' 2> /dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
	detected_arch := $(shell dpkg --print-architecture 2>/dev/null || amd64)
endif

APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=Ucra7588
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

get:
	go get

format: 
	gofmt -s -w ./

lint:
	golint

test:
	go test -v

build: format get
	@printf "Detected OS/ARCH: $(detected_OS)/$(detected_arch)\n"
	CGO_ENABLED=0 GOOS=$(detected_OS) GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/Ucra7588/kbot/cmd.appVersion=${VERSION}

linux: format get
	@printf "Target OS/ARCH: linux/$(detected_arch)\n"
	CGO_ENABLED=0 GOOS=linux GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/Ucra7588/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=linux -t ${REGISTRY}/${APP}:${VERSION}-linux-$(detected_arch) .

windows: format get
	@printf "Target OS/ARCH: windows/$(detected_arch)\n"
	CGO_ENABLED=0 GOOS=windows GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/Ucra7588/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=windows -t ${REGISTRY}/${APP}:${VERSION}-windows-$(detected_arch) .

darwin: format get
	@printf "Target OS/ARCH: darwin/$(detected_arch)\n"
	CGO_ENABLED=0 GOOS=darwin GOARCH=$(detected_arch) go build -v -o kbot -ldflags "-X="github.com/Ucra7588/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=darwin -t ${REGISTRY}/${APP}:${VERSION}-darwin-$(detected_arch) .

arm: format get
	@printf "Target OS/ARCH: $(detected_OS)/arm\n"
	CGO_ENABLED=0 GOOS=$(detected_OS) GOARCH=arm go build -v -o kbot -ldflags "-X="github.com/Ucra7588/kbot/cmd.appVersion=${VERSION}
	docker build --build-arg name=arm -t ${REGISTRY}/${APP}:${VERSION}-$(detected_OS)-arm .

image: build
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-$(detected_arch)

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-$(detected_arch)

dive: image
	IMG1=$$(docker images -q | head -n 1); \
	CI=true docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive --ci --lowestEfficiency=0.99 $${IMG1}; \
	IMG2=$$(docker images -q | sed -n 2p); \
	docker rmi $${IMG1}; \
	docker rmi $${IMG2}

clean:
	@rm -rf kbot; \
	IMG1=$$(docker images -q | head -n 1); \
	docker rmi -f $${IMG1}
