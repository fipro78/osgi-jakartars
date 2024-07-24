ARG MODULE_NAME=org.fipro.service.modifier.app

# Build image

FROM azul/zulu-openjdk:21-jdk-crac-latest AS build

ARG MODULE_NAME
ARG EXTRA_MODULES=jdk.crac
# accepted values are zip-[0-9], where zip-0 provides no compression, and zip-9 provides the best compression. Default is zip-6.
ARG COMPRESS=zip-6

# copy the application jar to the image
COPY app-crac.jar /tmp/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start_jlink.sh /app/bin/start.sh

# create the folder for the checkpoint files and make the start scripts executable
# create the custom jre
RUN \
mkdir -p /app/checkpoint && \
chmod 755 /app/bin/start.sh && \
$JAVA_HOME/bin/jlink \
  --add-modules $MODULE_NAME${EXTRA_MODULES:+,$EXTRA_MODULES} \
  --compress=$COMPRESS \
  --module-path /tmp/app.jar \
  --no-header-files \
  --no-man-pages \
  --output /app/jre

# Production image

FROM ubuntu:22.04

ARG MODULE_NAME
ENV MODULE_NAME=${MODULE_NAME}

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac"

EXPOSE 8080

RUN useradd -s /bin/bash appuser

COPY --from=build --chown=appuser:appuser /app /app

ENV PATH=/app/jre/bin:$PATH

WORKDIR /app
USER appuser

CMD ["/app/bin/start.sh"]