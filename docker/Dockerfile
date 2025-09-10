FROM ghcr.io/cambridge-collection/xslt-transformation-engine@sha256:c599026287dcb16b6fd170f20c80efe8dc1ff0a1e45f378dfdcb1dc893c562bd

WORKDIR /opt/cdcp
COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
