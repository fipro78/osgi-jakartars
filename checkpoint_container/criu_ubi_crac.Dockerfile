ARG IMAGE_NAME=icr.io/appcafe/ibm-semeru-runtimes
ARG VERSION=open-21-jre-ubi-minimal

FROM ${IMAGE_NAME}:${VERSION}

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac \
-Dopenj9.internal.criu.unprivilegedMode=true"

USER root

EXPOSE 8080

# copy the application jar to the image
COPY app-crac.jar /app/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start.sh /app/

# create the folder for the crac files inside the image
RUN \
  mkdir -p /app/checkpoint && \
  chmod 777 /app/checkpoint && \
  chmod 755 /app/start.sh

USER 1001

# start the application for checkpoint creation
WORKDIR /app
CMD ["./start.sh"]