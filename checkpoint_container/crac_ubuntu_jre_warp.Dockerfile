# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ubuntu:22.04

FROM $BASE_IMAGE AS builder

ENV JAVA_HOME=/opt/jdk
ENV PATH=$JAVA_HOME/bin:$PATH

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

RUN apt-get update -y

# ADD "https://cdn.azul.com/zulu/bin/zulu17.54.21-ca-crac-jre17.0.13-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz
ADD "https://cdn.azul.com/zulu/bin/zulu21.38.21-ca-crac-jre21.0.5-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

RUN \
  tar --extract --file $JAVA_HOME/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1; \
  rm $JAVA_HOME/openjdk.tar.gz; \
  apt-get clean;

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

ENV JAVA_HOME=/opt/jdk
ENV PATH=$JAVA_HOME/bin:$PATH

# copy the Java installation
COPY --from=builder $JAVA_HOME $JAVA_HOME
# copy the application folder
COPY --from=builder /app /app
# copy the OSGi tmp folder
COPY --from=builder /tmp /tmp
CMD ["java", "-XX:CRaCEngine=warp", "-XX:CRaCRestoreFrom=/app/checkpoint"]
