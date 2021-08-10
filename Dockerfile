FROM --platform=$BUILDPLATFORM curlimages/curl AS downloader

ARG TARGETPLATFORM

WORKDIR /home/curl_user

# renovate: datasource=repology depName=homebrew_casks/FileBot
ARG FILEBOT_VERSION=4.9.3
RUN curl -L -o filebot.deb https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}_universal.deb

FROM debian:10.10-slim

ENV FILEBOT_INPUT_DIR=/input \
    FILEBOT_OUTPUT_DIR=/output \
    FILEBOT_LICENCE=/config/filebot.psm

COPY --from=downloader /home/curl_user/filebot.deb /tmp/

# HACK workaround jre install bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199#23
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && \
    apt install -y /tmp/*.deb && \
    rm /tmp/*.deb && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

RUN groupadd -r filebot && useradd --no-log-init -r -m -d /config -g filebot filebot
USER filebot

ENTRYPOINT [ "./entrypoint.sh" ]
