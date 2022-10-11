FROM casjaysdevdocker/python2:latest AS build

ARG PORTS="80 443"

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
  rrdtool \
  ffmpeg-dev \
  geoip-dev \
  php8-cgi

RUN git clone https://github.com/cherokee/webserver.git . && \
  libtoolize --force && \
  ./autogen.sh --prefix=/usr/local/share/cherokee && \
  ./configure CFLAGS="-static" --prefix=/usr/local/share/cherokee && \
  make LDFLAGS="-all-static" && make install && \
  echo "<p style='text-align:center'>Built from $(git rev-parse --short HEAD) on $(date)</p>" > ./version.txt && \
  apk del --no-cache \
  alpine-sdk \
  autoconf \
  automake \
  gettext \
  openssl-dev \
  linux-headers \
  ffmpeg-dev \
  geoip-dev \
  libtool && \
  rm -Rf /var/cache/apk/* /tmp/* /var/tmp/* /usr/src/*

FROM casjaysdevdocker/php:latest
ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')"

LABEL \
  org.label-schema.name="cherokee" \
  description="Alpine based image with cherokee and php8." \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/cherokee" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/cherokee" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="WTFPL" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

COPY --from=build /usr/local/share/cherokee/. /usr/local/share/cherokee/
COPY ./bin/. /usr/local/bin/
COPY ./data/. /usr/local/share/template-files/data/
COPY ./config/. /usr/local/share/template-files/config/

ENV PHP_SERVER=cherokee

WORKDIR /data/htdocs/www

EXPOSE $PORTS

VOLUME [ "/data", "/config" ]

ENTRYPOINT [ "tini", "--" ]
HEALTHCHECK --interval=15s --timeout=3s CMD [ "/usr/local/bin/entrypoint-cherokee.sh" "healthcheck" ]
CMD ["/usr/local/bin/entrypoint-cherokee.sh"]

