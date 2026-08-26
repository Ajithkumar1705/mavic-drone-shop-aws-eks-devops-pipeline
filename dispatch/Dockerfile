FROM golang:1.24 AS build

WORKDIR /go/src/app

COPY *.go .
RUN go mod init dispatch && go get

RUN go install

FROM debian:12-slim

WORKDIR /app

COPY --from=build /go/bin/dispatch /app/dispatch

CMD ["./dispatch"]