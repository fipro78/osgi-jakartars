FROM alpine:3.20

ENV JAVA_HOME /opt/jdk
ENV PATH $JAVA_HOME/bin:$PATH

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac"

EXPOSE 8080

# copy the application jar to the image
COPY app-crac.jar /app/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start.sh /app/

# ADD "https://cdn.azul.com/zulu/bin/zulu17.50.19-ca-crac-jdk17.0.11-linux_musl_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz
# ADD "https://cdn.azul.com/zulu/bin/zulu17.50.19-ca-crac-jre17.0.11-linux_musl_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

# ADD "https://cdn.azul.com/zulu/bin/zulu21.34.19-ca-crac-jdk21.0.3-linux_musl_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz
ADD "https://cdn.azul.com/zulu/bin/zulu21.34.19-ca-crac-jdk21.0.3-linux_musl_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

RUN \
  apk --no-cache add tini; \
  tar --extract --file $JAVA_HOME/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1; \
  rm $JAVA_HOME/openjdk.tar.gz; \
  mkdir -p /app/checkpoint; \
  chmod 755 /app/start.sh

WORKDIR /app
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./start.sh"]
