FROM golang:alpine as golang
WORKDIR /go/src/github.com/beevee/konturtransferbot
COPY . .
RUN go get github.com/kardianos/govendor
RUN govendor sync
# Static build required so that we can safely copy the binary over.
WORKDIR cmd/konturtransferbot
RUN CGO_ENABLED=0 go-wrapper install -ldflags '-extldflags "-static"'

FROM alpine:latest as alpine
RUN apk --no-cache add tzdata zip ca-certificates
WORKDIR /usr/share/zoneinfo
# -0 means no compression.  Needed because go's
# tz loader doesn't handle compressed data.
RUN zip -r -0 /zoneinfo.zip .

FROM scratch
# the program:
COPY cmd/konturtransferbot/schedule.yml /schedule.yml
COPY --from=golang /go/bin/konturtransferbot /konturtransferbot
# the timezone data:
ENV ZONEINFO /zoneinfo.zip
COPY --from=alpine /zoneinfo.zip /
# the tls certificates:
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/konturtransferbot"]
