FROM golang:1.25 AS build

WORKDIR /go/src/app

COPY *.go .
RUN go mod init dispatch && go get

RUN go install

FROM debian:12-slim

WORKDIR /app

COPY --from=build /go/bin/dispatch /app/dispatch

EXPOSE 2112

CMD ["./dispatch"]