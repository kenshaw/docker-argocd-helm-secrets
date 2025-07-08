ARG ARGOCD_VERSION

FROM quay.io/argoproj/argocd:$ARGOCD_VERSION
ARG \
  ARGOCD_VERSION=$ARGOCD_VERSION \
  SOPS_VERSION \
  KUBECTL_VERSION \
  VALS_VERSION \
  HELM_SECRETS_VERSION

ENV \
  HELM_SECRETS_BACKEND=sops \
  HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
  HELM_PLUGINS=/home/argocd/.local/share/helm/plugins/ \
  HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
  HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false \
  HELM_PLUGINS=/gitops-tools/helm-plugins/ \
  HELM_SECRETS_CURL_PATH=/usr/bin/curl \
  HELM_SECRETS_SOPS_PATH=/gitops-tools/sops \
  HELM_SECRETS_VALS_PATH=/gitops-tools/vals \
  HELM_SECRETS_KUBECTL_PATH=/gitops-tools/kubectl \
  HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=true \
  HELM_SECRETS_WRAPPER_ENABLED=true \
  PATH=$PATH:/gitops-tools

USER root

RUN \
  echo "argocd:${ARGOCD_VERSION} sops:${SOPS_VERSION} kubectl:${KUBECTL_VERSION} vals:${VALS_VERSION} helm-secrets:${HELM_SECRETS_VERSION}"

RUN \
  apt-get update && \
  apt-get install -y curl wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir -p /gitops-tools/helm-plugins

# sops backend installation (optional)
RUN \
  GO_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') && \
  wget -qO \
    "/gitops-tools/sops" \
    "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${GO_ARCH}" && \
  wget -qO \
    "/gitops-tools/kubectl" \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${GO_ARCH}/kubectl" && \
  wget -qO- \
    "https://github.com/helmfile/vals/releases/download/${VALS_VERSION}/vals_${VALS_VERSION#v}_linux_${GO_ARCH}.tar.gz" \
    | tar zxv -C /gitops-tools vals && \
  wget -qO- \
    "https://github.com/jkroepke/helm-secrets/releases/download/${HELM_SECRETS_VERSION}/helm-secrets.tar.gz" \
    | tar -C /gitops-tools/helm-plugins -xzf- && \
  chmod +x /gitops-tools/* && \
  ln -sf /gitops-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /usr/local/sbin/helm

USER 999
