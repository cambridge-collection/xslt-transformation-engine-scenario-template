FROM ghcr.io/cambridge-collection/xslt-transformation-engine@sha256:a922c0fc5ce56a8a746358d3b055ced1a8f584186df994212720da1afc3c75f2

WORKDIR /opt/cdcp
COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
