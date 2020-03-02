FROM alpine:3.11.3 as action

# OCI
ARG IMAGE_TITLE
ARG IMAGE_DESC
ARG IMAGE_URL
ARG IMAGE_SOURCE
ARG IMAGE_VERSION
ARG IMAGE_REVISION
ARG IMAGE_LICENSES
ARG IMAGE_DOCUMENTATION_URL
ARG IMAGE_BUILD_HOST
ARG IMAGE_BUILD_DATE
ARG IMAGE_VENDOR="Prasad Tengse<tprasadtp@users.noreply.github.com>"

# Custom Metadata
# -----------------
# CI Which built the image
ARG IMAGE_BUILD_SYSTEM
# Usually Available on builder
ARG GITHUB_WORKFLOW
ARG GITHUB_RUN_NUMBER
ARG GITHUB_SHA_SHORT
ARG GITHUB_ACTOR
ARG GITHUB_REF

# If the tree was dirty on build
ARG GIT_TREE_DIRTY
ARG GIT_REF

LABEL org.opencontainers.image.vendor="${IMAGE_VENDOR}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.url="${IMAGE_URL}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.documentation="${IMAGE_DOCUMENTATION_URL}" \
      org.opencontainers.image.title="${IMAGE_TITLE}" \
      org.opencontainers.image.description="${IMAGE_DESC}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.licenses="${IMAGE_LICENSES}" \
      io.github.tprasadtp.build.system="${IMAGE_BUILD_SYSTEM}" \
      io.github.tprasadtp.build.host="${IMAGE_BUILD_HOST}" \
      io.github.tprasadtp.build.date="${IMAGE_BUILD_DATE}" \
      io.github.tprasadtp.actions.workflow="${GITHUB_WORKFLOW}" \
      io.github.tprasadtp.actions.build="${GITHUB_RUN_NUMBER}" \
      io.github.tprasadtp.actions.actor="${GITHUB_ACTOR}" \
      io.github.tprasadtp.actions.ref="${GITHUB_REF}" \
      io.github.tprasadtp.git.ref="${GIT_REF}" \
      io.github.tprasadtp.git.short-sha="${GITHUB_SHA_SHORT}" \
      io.github.tprasadtp.git.dirty="${GIT_TREE_DIRTY}"

ENV GITHUB_REF="${VERSION}"
ENV GITHUB_SHA="${GITHUB_SHA}"
# hadolint ignore=DL3018
RUN apk add --no-cache bash git openssh-client
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["--help"]
