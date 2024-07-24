ARG MODULE_NAME=org.fipro.service.modifier.app

# Build image

FROM icr.io/appcafe/ibm-semeru-runtimes:open-21-jdk-ubi-minimal AS build

ARG MODULE_NAME
ARG EXTRA_MODULES=openj9.criu
# accepted values are zip-[0-9], where zip-0 provides no compression, and zip-9 provides the best compression. Default is zip-6.
ARG COMPRESS=zip-6

# copy the application jar to the image
COPY app-criu.jar /tmp/app.jar
# copy the shell scripts to the image
COPY start_jlink_redirect.sh /app/bin/start.sh

USER root

# create the folder for the checkpoint files and make the start scripts executable
# create the custom jre
RUN \
mkdir -p /app/checkpoint && \
chmod 777 /app/checkpoint && \
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

ENV JAVA_OPTS_EXTRA="-XX:+EnableCRIUSupport"

EXPOSE 8080

RUN useradd -s /bin/bash appuser
# RUN useradd -s /bin/bash appuser && \
#   apt-get -q -y --no-install-recommends install criu && \
#   apt-get clean && \
#   rm -rf /var/lib/apt/lists/*

COPY --from=build --chown=appuser:appuser /app /app

ENV PATH=/app/jre/bin:$PATH

WORKDIR /app
USER appuser

CMD ["/app/bin/start.sh"]