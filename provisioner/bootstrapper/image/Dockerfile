# The sovereign ephemeral bootstrapper image: pinned toolchain + baked pinned Talos image.
# Build args pin every tool (see versions.env). docker build pulls the base + tool binaries (network).
FROM debian:12-slim
ARG KAPP_VERSION KBLD_VERSION HELM_VERSION KUBECTL_VERSION TALOSCTL_VERSION=v1.13.5 \
    TALHELPER_VERSION ARGOCD_VERSION VAULT_VERSION SOPS_VERSION AGE_VERSION TERRAFORM_VERSION \
    TALOS_SCHEMATIC
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates jq unzip git bash gettext-base && rm -rf /var/lib/apt/lists/*
# each tool pinned; kubectl/kapp/kbld/helm/talosctl/talhelper/argocd/vault/sops/age/terraform + yq.
# (install steps elided for brevity in-plan; each is a pinned curl+chmod, matching versions.env.)
COPY orchestrator /opt/bootstrapper/orchestrator
COPY tests        /opt/bootstrapper/tests
# bake the pinned Talos Image-Factory nocloud image so bootstrap needs no factory.talos.dev.
RUN mkdir -p /opt/images && curl -fsSL \
      "https://factory.talos.dev/image/${TALOS_SCHEMATIC}/${TALOSCTL_VERSION}/nocloud-amd64.raw.xz" \
      -o /opt/images/talos-nocloud-amd64.raw.xz
ENTRYPOINT ["/opt/bootstrapper/orchestrator/run.sh"]
