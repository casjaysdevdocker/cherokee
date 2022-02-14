#!/usr/bin/env bash

export TZ="${TZ:-America/New_York}"
export HOSTNAME="${HOSTNAME:-casjaysdev-cherokee}"

[ -n "${TZ}" ] && echo "${TZ}" >/etc/timezone
[ -n "${HOSTNAME}" ] && echo "${HOSTNAME}" >/etc/hostname
[ -n "${HOSTNAME}" ] && echo "127.0.0.1 $HOSTNAME localhost" >/etc/hosts
[ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"

if [[ ! -f "/config/ssl/key.pem" ]] || [[ ! -f "/etc/ssl/crt.pem" ]]; then
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=CA/L=Manhattan\ Beach/O=Managed\ Kaos/OU=Cherokee\ SSL/CN=localhost" \
    -keyout /etc/ssl/server.pem \
    -out /etc/ssl/server.pem
fi

case "$1" in

healthcheck)
  CH_PORT="$(netstat -lnt | grep -q "80" && echo "OK" || false)"
  [ -n "$CH_PORT" ] && exit 0 || exit 1
  ;;

bash)
  shift 1
  exec /bin/bash "$@"
  exit
  ;;

*)
  /usr/sbin/cherokee-admin -b -p 19070 -c /config/cherokee.conf &
  exec /usr/sbin/cherokee -c /config/cherokee.conf
  ;;

esac
