FROM ghcr.io/cambridge-collection/xslt-transformation-engine@sha256:9cb41a6fc7598400b9490d13ee2c7a55cb77a2b2ea32ee9196de7a7107c267d8

WORKDIR /opt/cdcp
COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
