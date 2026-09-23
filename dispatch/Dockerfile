FROM golang:1.25.0-bookworm AS build

WORKDIR /go/src/app

COPY *.go .
RUN go mod init dispatch && go get

RUN go install

FROM debian:12.8-slim

WORKDIR /app

RUN useradd --system --create-home --shell /usr/sbin/nologin appuser
COPY --from=build /go/bin/dispatch /app/dispatch
RUN chown appuser:appuser /app/dispatch

USER appuser

EXPOSE 2112

CMD ["./dispatch"]