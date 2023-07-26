# build
FROM golang:latest AS builder
ENV GOPROXY https://goproxy.cn,direct
# RUN apk update && apk add make git tzdata
WORKDIR /build
ADD go.mod .
ADD go.sum .
RUN go mod download
COPY . .
WORKDIR /build/cmd/grafana-reporter
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /app/grafana-repoter

# create image
FROM alpine:latest
COPY util/texlive.profile /
# RUN echo -e 'https://mirrors.aliyun.com/alpine/v3.18/main/\nhttps://mirrors.aliyun.com/alpine/v3.18/community/' > /etc/apk/repositories 
RUN PACKAGES="wget perl-switch" \
  && apk update \
  && apk add $PACKAGES \
  && apk add ca-certificates \
  && wget -qO- \
    "https://raw.githubusercontent.com/yihui/tinytex/main/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr path add \
  && chown -R root:adm /opt/TinyTeX \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && tlmgr install epstopdf-pkg \
  # Cleanup
  && apk del --purge -qq $PACKAGES \
  && apk del --purge -qq \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/grafana-repoter /app/grafana-repoter
ENTRYPOINT [ "/app/grafana-repoter" ]
