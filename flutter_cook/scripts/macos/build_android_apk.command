#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${SKIP_CONFIRM:-false}" != "true" ]]; then
  printf '\n请选择执行方式：\n'
  printf '  [1] 只打包 APK\n'
  printf '  [2] 打包 APK + 上传蒲公英\n'
  printf '请输入 1 或 2，回车确认：'
  IFS= read -r choice || { printf '\n未收到输入，已取消执行。\n' >&2; exit 130; }

  case "${choice}" in
    1) export UPLOAD_PGYER=false ;;
    2) export UPLOAD_PGYER=true ;;
    *) printf '\n无效输入，已取消执行。\n' >&2; exit 130 ;;
  esac
fi

exec "${SCRIPT_DIR}/../shell/build_android_apk.sh" "$@"
