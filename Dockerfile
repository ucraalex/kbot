FROM quay.io/projectquay/golang:1.21 as builder
ARG OS=linux
ARG ARCH=amd64
ARG NAME=kbot
ARG EXT=""
ARG VERSION=$VERSION
WORKDIR /go/src/app
COPY . .
RUN make build OS=${OS} ARCH=${ARCH} NAME=${NAME} EXT=${EXT} VERSION=${VERSION}

FROM scratch as linux
WORKDIR /
COPY --from=builder /go/src/app/bin/* .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT [ "./kbot" ]
