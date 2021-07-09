FROM golang:latest
LABEL maintainer="Eric Newbury"

WORKDIR /root

RUN git clone https://github.com/enewbury/hydroxide.git
WORKDIR /root/hydroxide
RUN GO111MODULE=on go build ./cmd/hydroxide

FROM alpine
COPY --from=0 /root/hydroxide/hydroxide /usr/bin

# Use musl library to run go binaries compiled for glibc
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

RUN apk add libsecret-dev

WORKDIR /root

COPY login.sh .

EXPOSE 1025