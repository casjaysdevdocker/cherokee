FROM casjaysdevdocker/python2:latest AS build

ARG ALPINE_VERSION="v3.16"

ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data" \
  DEFAULT_CONF_DIR="/usr/local/share/template-files/config" \
  DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG PACK_LIST="bash alpine-sdk autoconf musl-dev automake gettext git libtool \
  openssl openssl-dev linux-headers rrdtool ffmpeg-dev geoip-dev php8-cgi"

ENV LANG=en_US.utf8 \
  ENV=ENV=~/.bashrc \
  TZ="America/New_York" \
  SHELL="/bin/sh" \
  TERM="xterm-256color" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-cherokee" \
  CFLAGS="-static"

RUN set -ex; \
  rm -Rf "/etc/apk/repositories"; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main" >>"/etc/apk/repositories"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/community" >>"/etc/apk/repositories"; \
  if [ "${ALPINE_VERSION}" = "edge" ]; then echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/testing" >>"/etc/apk/repositories" ; fi ; \
  apk update --update-cache && apk add --no-cache ${PACK_LIST} && \
  echo

WORKDIR /tmp/build
RUN mkdir -p "/usr/local/share/template-files/config/defaults/cherokee" "/buildroot" && \
  cd /tmp/build && \
  git clone https://github.com/cherokee/webserver.git . && \
  /usr/bin/libtoolize && \
  aclocal && autoheader && touch ./ChangeLog ./README && autoconf && \
  ./autogen.sh --prefix=/usr/local/share/cherokee --sysconfdir=/etc/cherokee --localstatedir=/tmp/cherokee --enable-static-module=all --enable-static --enable-shared=no && \
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
  openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=CA/L=CA/O=Cherokee/OU=Cherokee/CN=localhost" -keyout /etc/ssl/server.key -out /etc/ssl/server.key && \
  ln -sf /usr/local/share/cherokee/bin/* /usr/local/bin/ && \
  ln -sf /usr/local/share/cherokee/sbin/* /usr/local/bin/ && \
  cp -Rf "/etc/cherokee/." "/usr/local/share/template-files/config/defaults/cherokee/" && \
  cp -Rf "/usr/local/." "/buildroot/"


FROM casjaysdevdocker/php:latest AS php

RUN apk add --no-cache geoip rrdtool openssl

COPY ./rootfs/. /
COPY --from=build /buildroot/. /usr/local/

RUN echo 'Running cleanup' ; \
  rm -Rf /usr/share/doc/* /usr/share/info/* /tmp/* /var/tmp/* ; \
  rm -Rf /usr/local/bin/.gitkeep /usr/local/bin/.gitkeep /config /data /var/cache/apk/* ; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* ; \
  rm -rf /etc/systemd/system/*.wants/* ; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* ; \
  rm -rf /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* ; \
  rm -rf /lib/systemd/system/systemd-update-utmp* ; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ]; then cd "/lib/systemd/system/sysinit.target.wants" && rm $(ls | grep -v systemd-tmpfiles-setup) ; fi

FROM scratch

ARG \
  SERVICE_PORT="80" \
  EXPOSE_PORTS="80 9090" \
  PHP_SERVER="cherokee" \
  NODE_VERSION="system" \
  NODE_MANAGER="system" \
  BUILD_VERSION="latest" \
  LICENSE="MIT" \
  IMAGE_NAME="cherokee" \
  BUILD_DATE="Thu Oct 20 04:49:27 PM EDT 2022" \
  TIMEZONE="America/New_York"

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.com>" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.name="${IMAGE_NAME}" \
  org.opencontainers.image.base.name="${IMAGE_NAME}" \
  org.opencontainers.image.license="${LICENSE}" \
  org.opencontainers.image.vcs-ref="${BUILD_VERSION}" \
  org.opencontainers.image.build-date="${BUILD_DATE}" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.schema-version="${BUILD_VERSION}" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}"

ENV LANG=en_US.utf8 \
  ENV=~/.bashrc \
  SHELL="/bin/bash" \
  PORT="${SERVICE_PORT}" \
  TERM="xterm-256color" \
  PHP_SERVER="${PHP_SERVER}" \
  CONTAINER_NAME="${IMAGE_NAME}" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-${IMAGE_NAME}"

COPY --from=php /. /

USER root
WORKDIR /data/htdocs/www

VOLUME [ "/config","/data" ]

EXPOSE $EXPOSE_PORTS

#CMD [ "" ]
ENTRYPOINT [ "tini", "-p", "SIGTERM", "--", "/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
