#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202210102226-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  entrypoint-cherokee.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, Oct 10, 2022 22:26 EDT
# @@File             :  entrypoint-cherokee.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/docker-entrypoint
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
[ -n "$DEBUG" ] && set -x
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202210102226-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__version() { echo -e ${GREEN:-}"$VERSION"${NC:-}; }
__find() { ls -A "$*" 2>/dev/null; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# colorization
[ -n "$SHOW_RAW" ] || printf_color() { echo -e '\t\t'${2:-}"${1:-}${NC}"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_command() {
  local cmd="${*:-/bin/bash -l}"
  local exitCode=0
  echo "Executing command: $cmd"
  eval "$cmd" || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Functions
__heath_check() {
  local status=0
  #curl -q -LSsf -o /dev/null -s -w "200" "http://localhost/server-health" || status=$(($status + 1))
  return ${status:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define default variables - don not change these
TZ="${TZ:-America/New_York}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
HOSTNAME="${HOSTNAME:-casjaysdev-bin}"
TEMPLATE_DATA_DIR="$(__find /usr/local/share/template-files/data/ 2>/dev/null | grep '^' || echo '')"
TEMPLATE_CONFIG_DIR="$(__find /usr/local/share/template-files/config/ 2>/dev/null | grep '^' || echo '')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables and variable overrides
SSL="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables from file
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set timezone
[ -n "${TZ}" ] && echo "${TZ}" >"/etc/timezone"
[ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set hostname
if [ -n "${HOSTNAME}" ]; then
  echo "${HOSTNAME}" >"/etc/hostname"
  echo "127.0.0.1 ${HOSTNAME} localhost ${HOSTNAME}.local" >"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete any gitkeep files
if [ "$SSL" = "true" ] || [ "$SSL" = "yes" ]; then
  if [ -f "/config/ssl/server.crt" ] && [ -f "/config/ssl/server.key" ]; then
    SSL="on"
    SSL_CERT="/config/ssl/server.crt"
    SSL_KEY="/config/ssl/server.key"
    if [ -f "/config/ssl/ca.crt" ]; then
      mkdir -p "/etc/ssl/certs"
      cat "/config/ssl/ca.crt" >>"/etc/ssl/certs/ca-certificates.crt"
    fi
  else
    [ -d "/config/ssl" ] || mkdir -p "/config/ssl"
    export SSL_DIR="/config/ssl"
    create-ssl-cert
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Update ssl certificates
[ -f "/config/ssl/ca.crt" ] && cat "/config/ssl/ca.crt" >>"/etc/ssl/certs/ca-certificates.crt"
type update-ca-certificates &>/dev/null && update-ca-certificates
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Export variables
export TZ HOSTNAME
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
case "$1" in
--help) # Help message
  echo 'Docker container for '$APPNAME''
  echo "Usage: $APPNAME [healthcheck, bash, command]"
  echo "Failed command will have exit code 10"
  echo
  exitCode=$?
  ;;

healthcheck) # Docker healthcheck
  __heath_check || exit 10
  echo "$(uname -s) $(uname -m) is running"
  exitCode=$?
  ;;

*/bin/sh | */bin/bash | bash | shell | sh) # Launch shell
  shift 1
  __exec_command "${@:-/bin/bash}"
  exitCode=$?
  ;;

*) # Execute primary command
  if [ $# -eq 0 ]; then
    cherokee-server
    exitCode=$?
  else
    __exec_command "$@"
    exitCode=$?
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end of entrypoint
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
