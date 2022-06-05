FROM alpine:latest

RUN apk add go-ipfs libc6-compat

ENV ZIM_DIR /mnt/zim

COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["crond", "-f"]
