FROM alpine:latest
RUN apk --no-cache add openssh-client
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]