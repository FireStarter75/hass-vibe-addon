ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="FireStarter75"
LABEL org.opencontainers.image.title="Vibe Code for Home Assistant"
LABEL org.opencontainers.image.description="Mistral Vibe Code CLI with web terminal and HA integration"
LABEL org.opencontainers.image.source="https://github.com/FireStarter75/hass-vibe-addon"
LABEL org.opencontainers.image.licenses="MIT"

ENV \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssh-client \
    ncurses \
    vim \
    nano \
    tmux \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    ca-certificates \
    openssl \
    ripgrep \
    socat

ARG BUILD_ARCH
RUN case "${BUILD_ARCH}" in \
        amd64) TTYD_ARCH="x86_64" ;; \
        aarch64) TTYD_ARCH="aarch64" ;; \
        armv7|armhf) TTYD_ARCH="armhf" ;; \
        i386) TTYD_ARCH="i686" ;; \
        *) TTYD_ARCH="x86_64" ;; \
    esac && \
    curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
        "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/bin/ttyd && \
    chmod +x /usr/bin/ttyd

RUN pip3 install --no-cache-dir --break-system-packages "mistral-vibe" && \
    vibe --version > /etc/vibe-code-version && \
    pip3 install --no-cache-dir --break-system-packages hass-mcp tomli-w

ARG HA_CLI_VERSION=5.2.0
RUN case "${BUILD_ARCH}" in \
        amd64|aarch64) \
            curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
                "https://github.com/home-assistant/cli/releases/download/${HA_CLI_VERSION}/ha_${BUILD_ARCH}" \
                -o /usr/local/bin/ha && \
            chmod +x /usr/local/bin/ha ;; \
        *) \
            echo "[WARN] Home Assistant CLI is not published for ${BUILD_ARCH}; the 'ha' command will be unavailable" ;; \
    esac

RUN mkdir -p /homeassistant /root/.config /root/.local/bin

COPY rootfs/root/.tmux.conf /root/.tmux.conf
COPY rootfs/root/.bashrc /root/.bashrc
COPY vibe-stats /usr/local/bin/vibe-stats
COPY vibe-login /usr/local/bin/vibe-login
RUN chmod +x /usr/local/bin/vibe-stats /usr/local/bin/vibe-login

RUN echo 'source ~/.bashrc' > /root/.profile

ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /homeassistant

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:7681/ || exit 1

COPY run.sh /
RUN chmod +x /run.sh

ENTRYPOINT []
CMD ["/run.sh"]
