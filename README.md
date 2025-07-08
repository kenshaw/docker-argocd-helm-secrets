# argocd-helm-secrets

Up-to-date ArgoCD image with Helm Secrets, SOPS, and other plugins included.

See [here](https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration).

## Usage

Use with the [ArgoCD `helm` Chart](https://artifacthub.io/packages/helm/argo/argo-cd):

```sh
# add argo repo
$ helm repo add argo-cd https://argoproj.github.io/argo-helm

# set up configuration
$ cat > values.yaml << EOF
repoServer:
  image:
    repository: docker.io/kenshaw/argocd-helm-secrets

configs:
  cm:
    helm.valuesFileSchemes: >-
      secrets+gpg-import, secrets+gpg-import-kubernetes,
      secrets+age-import, secrets+age-import-kubernetes,
      secrets, secrets+literal,
      https
EOF

# install/upgrade chart
$ helm upgrade \
    --install \
    --namespace argo-cd \
    --values values.yaml \
    argo-cd/argo-cd
```

## Building

```sh
$ ./build.sh
```

Notes:

- https://argo-cd.readthedocs.io/en/latest/user-guide/multiple_sources/
- https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration
- https://github.com/jkroepke/helm-secrets/wiki/ArgoCD-Integration#multi-source-application-support
- https://github.com/argoproj/argo-cd/issues/11866
- https://github.com/jkroepke/helm-secrets/issues/475
