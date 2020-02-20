FROM alpine:3.11.3 as action
ARG GITHUB_SHA
ARG GITHUB_WORKFLOW
ARG GITHUB_RUN_NUMBER
ARG VERSION

LABEL org.opencontainers.image.authors="Prasad Tengse<tprasadtp@users.noreply.github.com>" \
      org.opencontainers.image.source="https://github.com/tprasadtp/sync-fork" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      com.github.actions.workflow="${GITHUB_WORKFLOW}" \
      com.github.actions.run="${GITHUB_RUN_NUMBER}" \
      com.github.commit.sha="${GITHUB_SHA}"

ENV SYNC_FORK_VERSION="${VERSION}"
# hadolint ignore=DL3018
RUN apk add --no-cache curl bash git openssh-client && rm -rf /var/cache/apk/*
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["--help"]
