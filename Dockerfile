FROM casjaysdevdocker/python2:latest AS build

ARG PORTS="80 443 9090"

ENV CFLAGS="-static"

WORKDIR /tmp/build

RUN apk -U upgrade && \
  apk add --no-cache \
  alpine-sdk \
  autoconf \
  musl-dev \
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

RUN cd /tmp/build && \
  git clone https://github.com/cherokee/webserver.git . && \
  /usr/bin/libtoolize && \
  aclocal && autoheader && touch ./ChangeLog ./README && autoconf && \
  ./autogen.sh --prefix=/usr/local/share/cherokee --sysconfdir=/usr/local/share/cherokee/etc --localstatedir=/usr/local/share/cherokee/var --enable-static-module=all && \
  autoreconf -iv && \
  make && make install && \
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
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=CA/L=CA/O=Cherokee/OU=Cherokee/CN=localhost" -keyout /etc/ssl/key.pem -out /etc/ssl/crt.pem && \
  ln -sf /usr/local/share/cherokee/bin/* /usr/local/bin/ && \
  mkdir -p /buildroot && \
  cp -Rf "/usr/local/." "/buildroot/" && \
  rm -Rf /var/cache/apk/* /tmp/* /var/tmp/* /tmp/build /usr/src/*

FROM casjaysdevdocker/php:latest AS source

COPY --from=build /buildroot/. /usr/local/
COPY ./bin/. /usr/local/bin/
COPY ./data/. /usr/local/share/template-files/data/
COPY ./config/. /usr/local/share/template-files/config/

FROM scratch
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

COPY --from=source /. /

ENV PHP_SERVER=cherokee

WORKDIR /data/htdocs/www

EXPOSE $PORTS

VOLUME [ "/data", "/config" ]

ENTRYPOINT [ "tini", "--" ]
HEALTHCHECK --interval=15s --timeout=3s CMD [ "/usr/local/bin/entrypoint-cherokee.sh" "healthcheck" ]
CMD ["/usr/local/bin/entrypoint-cherokee.sh"]

