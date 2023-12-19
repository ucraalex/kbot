APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=ucraalex
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=$(word 2,$(MAKECMDGOALS)) # 1st argument from command line 
TARGETARCH=$(word 3,$(MAKECMDGOALS)) # 2nd argument from command line

format:
	gofmt -s -w ./

lint:
	golint

test:
	go test -v

get:
	go get	

# for building kbot use make build <arg1> <arg2>, where arg1 - OS type (linux, windows, darwin )
# and arg2 - type of architecture (amd64, arm64)

build: format get 
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X="github.com/ucraalex/kbot/cmd.appVersion=${VERSION}

image:
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	rm -rf kbot
        docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}
