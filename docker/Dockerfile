FROM ghcr.io/cambridge-collection/xslt-transformation-engine@sha256:0da8baf57e953b02c061932827b2db95e48a5c5da950073d42fa04a4dcc55aeb

WORKDIR /opt/cdcp
COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
