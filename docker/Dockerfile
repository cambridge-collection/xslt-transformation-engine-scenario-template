FROM ghcr.io/cambridge-collection/xslt-transformation-engine@sha256:264a6238bc3e2eba23092a23b6afcc7e766a8414941c45b00a62751555e47fa7

COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
