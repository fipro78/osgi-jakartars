# syntax=docker/dockerfile:1
ARG BASE_IMAGE=azul/zulu-openjdk:21-jdk-crac-latest

FROM $BASE_IMAGE AS builder

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-XX:CRaCEngine=warp \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac"

EXPOSE 8080

# copy the application jar to the image
COPY app-crac.jar /app/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/

# start the application for checkpoint creation
WORKDIR /app

# We use here-doc syntax to inline the script that will
# start the application, warm it up and checkpoint
RUN <<END_OF_SCRIPT
#!/bin/bash
java $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar
PID=$!

# Wait until the process completes, returning success
# (wait would return exit code 137)
wait $PID || true
END_OF_SCRIPT

# application container image with checkpoint image files
FROM $BASE_IMAGE
# copy the application folder
COPY --from=builder /app /app
# copy the OSGi tmp folder
COPY --from=builder /tmp /tmp
CMD ["java", "-XX:CRaCEngine=warp", "-XX:CRaCRestoreFrom=/app/checkpoint"]