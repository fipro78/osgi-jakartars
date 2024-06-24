FROM ubuntu:22.04

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

RUN apt-get update -y

# ADD "https://cdn.azul.com/zulu/bin/zulu17.50.19-ca-crac-jdk17.0.11-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz
# ADD "https://cdn.azul.com/zulu/bin/zulu17.50.21-ca-crac-jre17.0.11-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

# ADD "https://cdn.azul.com/zulu/bin/zulu21.30.23-ca-crac-jdk21.0.1-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz
ADD "https://cdn.azul.com/zulu/bin/zulu21.34.21-ca-crac-jre21.0.3-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

RUN \
  tar --extract --file $JAVA_HOME/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1; \
  rm $JAVA_HOME/openjdk.tar.gz; \
  apt-get clean; \
  mkdir -p /app/checkpoint; \
  chmod 755 /app/start.sh

WORKDIR /app
CMD ["./start.sh"]
