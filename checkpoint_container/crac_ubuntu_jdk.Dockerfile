FROM azul/zulu-openjdk:21-jdk-crac-latest

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac"

EXPOSE 8080

# copy the application jar to the image
# COPY app.jar /app/
COPY app-crac.jar /app/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start_create_checkpoint.sh /app/
COPY start_jcmd.sh /app/
COPY start.sh /app/

# create the folder for the checkpoint files and make the start scripts executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start_jcmd.sh && \
  chmod 755 /app/start.sh && \
  chmod 755 /app/start_create_checkpoint.sh

# start the application for checkpoint creation
WORKDIR /app
# CMD ["./start_jcmd.sh"]
CMD ["./start.sh"]