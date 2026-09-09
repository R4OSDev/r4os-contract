#!/bin/sh
set -eu
contract_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
exec pwsh -NoProfile -File "$contract_root/Build.ps1" "$@"
