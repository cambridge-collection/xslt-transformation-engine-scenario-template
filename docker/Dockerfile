FROM ghcr.io/cambridge-collection/xslt-transformation-engine:pre

WORKDIR /opt/cdcp
COPY *bin bin
COPY --chmod=0755 ./pre.sh* ${LAMBDA_TASK_ROOT}
COPY --chmod=0755 ./post.sh* ${LAMBDA_TASK_ROOT}
COPY ./xslt xslt
COPY --chmod=0755 entrypoint.sh /usr/local/bin/xte-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/xte-entrypoint.sh"]
CMD [ "aws.sh.handler" ]
