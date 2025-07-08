#!/bin/bash

SRC=$(realpath $(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd))

TARGETS=()

PUSH=0
IMAGE=docker.io/kenshaw/argocd-helm-secrets
DOCKER_USER=kenshaw
DOCKER_PASSFILE=$HOME/.config/argocd-helm-secrets/token

OPTIND=1
while getopts "o:t:g:v:pi:" opt; do
case "$opt" in
  t) TARGETS+=($OPTARG) ;;
  p) PUSH=1 ;;
  i) IMAGE=$OPTARG ;;
esac
done

set -e

github_release() {
  curl -s "https://api.github.com/repos/$1/releases/latest"|jq -r .tag_name
}

ARGOCD_VERSION=$(github_release "argoproj/argo-cd")
SOPS_VERSION=$(github_release "getsops/sops")
KUBECTL_VERSION=$(github_release "kubernetes/kubernetes")
VALS_VERSION=$(github_release "helmfile/vals")
HELM_SECRETS_VERSION=$(github_release "jkroepke/helm-secrets")

echo "ARGOCD:       $ARGOCD_VERSION"
echo "SOPS:         $SOPS_VERSION"
echo "KUBECTL:      $KUBECTL_VERSION"
echo "VALS:         $VALS_VERSION"
echo "HELM_SECRETS: $HELM_SECRETS_VERSION"
echo "IMAGE:        $IMAGE [tags: $ARGOCD_VERSION latest]"

# determine targets
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=(amd64 arm64)
fi

IMAGES=()
for TARGET in ${TARGETS[@]}; do
  NAME=localhost/$(basename $IMAGE):$ARGOCD_VERSION-$TARGET
  IMAGES+=($NAME)

  if [ ! -z "$(buildah images --noheading --filter=reference=$NAME)" ]; then
    echo -e "\n\nSKIPPING BUILD FOR $NAME ($(date))"
    continue
  fi

  echo -e "\n\nBUILDING $NAME ($(date))"
  (set -x;
    buildah build \
      --platform linux/$TARGET \
      --build-arg ARGOCD_VERSION="$ARGOCD_VERSION" \
      --build-arg SOPS_VERSION="$SOPS_VERSION" \
      --build-arg KUBECTL_VERSION="$KUBECTL_VERSION" \
      --build-arg VALS_VERSION="$VALS_VERSION" \
      --build-arg HELM_SECRETS_VERSION="$HELM_SECRETS_VERSION" \
      --tag $NAME \
      $SRC
  )
done

(set -x;
  buildah login docker.io \
    --username $DOCKER_USER \
    --password-stdin < $DOCKER_PASSFILE
)

REPO=$(sed -e 's%^docker\.io/%%' <<< "$IMAGE")
for TAG in $ARGOCD_VERSION latest; do
  NAME=localhost/$(basename $IMAGE):$TAG

  # create manifest
  echo -e "\n\nCONFIGURING MANIFEST $NAME ($(date))"
  if `buildah manifest exists $NAME`; then
    for HASH in $(buildah manifest inspect $NAME|jq -r '.manifests[]|.digest'); do
      (set -x;
        buildah manifest remove $NAME $HASH
      )
    done
  else
    (set -x;
      buildah manifest create $NAME
    )
  fi

  # add images
  for IMG in ${IMAGES[@]}; do
    (set -x;
      buildah manifest add $NAME $IMG
    )
  done

  if [ $PUSH -eq 1 ]; then
    echo -e "\n\nPUSHING MANIFEST $NAME ($(date))"
    (set -x;
      buildah manifest push \
        --all \
        $NAME \
        docker://$REPO:$TAG
    )
  fi
done
