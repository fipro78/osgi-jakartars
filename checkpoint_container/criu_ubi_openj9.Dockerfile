FROM icr.io/appcafe/ibm-semeru-runtimes:open-21-jre-ubi-minimal

ENV JAVA_OPTS_EXTRA="-XX:+EnableCRIUSupport"

USER root

EXPOSE 8080

# copy the application jar to the image
COPY app-criu.jar /app/app.jar
# copy the shell scripts to the image
COPY start.sh /app/

# create the folder for the checkpoint files and make the start script executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start.sh

# start the application for checkpoint creation
WORKDIR /app
CMD ["./start.sh"]