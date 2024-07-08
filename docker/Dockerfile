FROM ghcr.io/cambridge-collection/xslt-transformation-engine:latest

COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
