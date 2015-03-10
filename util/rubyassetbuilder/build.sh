#!/bin/bash

set -exo pipefail

tree=$(pwd)
tmpdir=$(mktemp --directory)

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "${ROOT}/script/lib/ui.sh"

usage() {
  cat <<USAGE >&2
usage: $0 <image|app> <dashboard|installer>
USAGE
}

main() {
  local target
  case $2 in
    dashboard)
      target=$2
      ;;
    installer)
      target=$2
      ;;
    *)
      echo "unknown target"
      exit 1
      ;;
  esac

  case $1 in
    image)
      image $target
      ;;
    app)
      app $target
      ;;
    *)
      echo "unknown command"
      exit 1
      ;;
  esac

  rm --recursive --force "${tmpdir}"
}

image() {
  local target
  target=$1

  cp ${ROOT}/util/rubyassetbuilder/Dockerfile ${ROOT}/${target}/app/Gemfile* "${tmpdir}"
  docker build --tag flynn/${target}-builder "${tmpdir}"
}

app() {
  local target
  target=$1

  cp --recursive ${ROOT}/${target}/app/* "${tmpdir}"
  cd "${tmpdir}"

  docker run \
    --volume "${tmpdir}:/build" \
    --workdir /build \
    --user $(id -u) \
    flynn/${target}-builder \
    bash -c "cp --recursive /app/.bundle . && cp --recursive /app/vendor/bundle vendor/ && bundle exec rake compile"

  if [ $target == "dashboard" ]
  then
    tar --create --directory build . > "${tree}/${target}.tar"
  fi
}

main "$@"
