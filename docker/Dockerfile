FROM ghcr.io/anomalyco/opencode:1.3.17

ARG USER_ID=1000
ARG GROUP_ID=1000

USER root

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
  && addgroup -g "$GROUP_ID" opencode \
  && adduser -D -u "$USER_ID" -G opencode -h /home/opencode -s /bin/bash opencode \
  && mkdir -p \
    /home/opencode/.config \
    /home/opencode/.cache \
    /home/opencode/.local/share \
    /workspace \
  && chown -R "$USER_ID:$GROUP_ID" /home/opencode /workspace

ENV HOME=/home/opencode

USER opencode
WORKDIR /workspace

ENTRYPOINT ["opencode"]
