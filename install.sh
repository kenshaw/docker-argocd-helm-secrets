#!/bin/bash

# sudo loginctl enable-linger $USER
# systemctl enable --now --user argocd-helm-secrets.timer

SRC=$(realpath $(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd))

set -e

(set -x;
  mkdir -p $HOME/.config/systemd/user
  cp $SRC/*.{service,timer} $HOME/.config/systemd/user
  systemctl daemon-reload --user
)
