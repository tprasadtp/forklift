# DockerHub Image. Used to Run as User
FROM alpine:3.11.3 as action
ARG GITHUB_SHA
ARG GITHUB_WORKFLOW
ARG GITHUB_RUN_NUMBER
ARG VERSION

LABEL org.opencontainers.image.authors="Prasad Tengse<tprasadtp@noreply.labels.github.com>" \
      org.opencontainers.image.source="https://github.com/tprasadtp/sync-fork" \
      com.github.action.sha1="${GITHUB_SHA}" \
      com.github.action.name="${GITHUB_WORKFLOW}" \
      com.github.action.run="${GITHUB_RUN_NUMBER}" \
      org.opencontainers.image.version="${VERSION}"
      org.opencontainers.image.licenses="MIT"

RUN addgroup -g 1000 labels \
    && adduser -G labels -u 1000 -D -h /home/labels labels \
    && mkdir -p /home/labels \
    && chown -R 1000:1000 /home/labels

# hadolint ignore=DL3018
RUN apk add --no-cache curl git && rm -rf /var/cache/apk/*
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/labels/
USER labels

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["--help"]
