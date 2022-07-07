FROM alpine:3.14 AS build

WORKDIR /tmp/build

RUN apk -U upgrade && \
  apk add --no-cache \
  alpine-sdk \
  autoconf \
  automake \
  gettext \
  git \
  libtool \
  openssl \
  openssl-dev \
  linux-headers \
  python2 \
  rrdtool

RUN git clone https://github.com/cherokee/webserver.git . && \
  libtoolize --force && \
  ./autogen.sh --prefix=/usr/local/share/cherokee && \
  ./configure CFLAGS="-static" --prefix=/usr/local/share/cherokee && \
  make LDFLAGS="-all-static" && make install && \
  echo "<p style='text-align:center'>Built from $(git rev-parse --short HEAD) on $(date)</p>" > ./version.txt && \
  apk del \
  alpine-sdk \
  autoconf \
  automake \
  gettext \
  git \
  libtool \
  openssl

FROM casjaysdev/php:latest
ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')"

LABEL \
  org.label-schema.name="cherokee" \
  description="Alpine based image with cherokee and php8." \
  org.label-schema.url="https://github.com/casjaysdev/cherokee" \
  org.label-schema.vcs-url="https://github.com/casjaysdev/cherokee" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="MIT" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

COPY --from=build /usr/local/share/cherokee/. /usr/local/share/cherokee/
COPY ./config/. /config/
COPY ./data/. /data/
COPY ./bin/. /usr/local/bin/


ENV PHP_SERVER=cherokee

WORKDIR /data/htdocs

EXPOSE 80 19070

VOLUME [ "/data", "/config", "/etc/ssl" ]

HEALTHCHECK CMD [ "/usr/local/bin/entrypoint-cherokee.sh" "healthcheck" ]
CMD ["/usr/local/bin/entrypoint-cherokee.sh"]
