FROM alpine:3.11.3 as action
ARG GITHUB_SHA
ARG GITHUB_WORKFLOW
ARG GITHUB_RUN_NUMBER
ARG VERSION
ARG GIT_TREE_DIRTY=false

LABEL org.opencontainers.image.authors="Prasad Tengse<tprasadtp@users.noreply.github.com>" \
      org.opencontainers.image.source="https://github.com/tprasadtp/forklift" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      com.github.actions.workflow="${GITHUB_WORKFLOW}" \
      com.github.actions.run="${GITHUB_RUN_NUMBER}" \
      vcs.git.commit.sha="${GITHUB_SHA}" \
      vsc.git.commit.tree.dirty="${GIT_TREE_DIRTY}"

ENV GITHUB_REF="${VERSION}"
ENV GITHUB_SHA="${GITHUB_SHA}"
# hadolint ignore=DL3018
RUN apk add --no-cache bash git openssh-client
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["--help"]
