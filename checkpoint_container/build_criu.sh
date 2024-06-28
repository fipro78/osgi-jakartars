#! /bin/bash

CMD=${1:-docker}
VAR_RUNTIME=${2:-ubi_crac_jre}
VAR=${VAR_RUNTIME%_*}
RUNTIME=${VAR_RUNTIME##*_}

if [ "$RUNTIME" == "jdk" ]
then 
  VERSION="open-21-jdk-ubi-minimal"
else
  VERSION="open-21-jre-ubi-minimal"
fi

CHECKPOINT_NAME=criu_${VAR_RUNTIME}_checkpoint
RESTORE_NAME=criu_${VAR_RUNTIME}_restore

while getopts "h" flag; do
 case $flag in
   h) # Handle the -h flag
   # Display script help information
   echo This script is used to build a Java application container with a checkpoint using the OpenJ9 CRIU Support
   echo
   echo Use it in the following format:
   echo "  ./build_criu.sh <docker|podman> <variant>"
   echo
   echo The following variants are available to build
   echo "  ubi_crac_jre (default)"
   echo "  ubi_crac_jdk"
   echo
   echo Example: ./build_criu.sh podman ubi_crac_jre
   exit 0
   ;;
 esac
done

if [ "$CMD" != "docker" ] && [ "$CMD" != "podman" ]
then 
  echo The first parameter for this script needs to be either \"docker\" or \"podman\"!; 
  exit 0
fi

if [ "$CMD" == "podman" ]
then 
  CMD="sudo podman"
fi

# first build the image to create the checkpoint
$CMD build -t ${CHECKPOINT_NAME} --build-arg VERSION=${VERSION} -f criu_${VAR}.Dockerfile .

# run the container with necessary capabilities
$CMD run \
-it \
--cap-drop=ALL \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE --cap-add=SETPCAP \
--security-opt seccomp=unconfined \
--name ${CHECKPOINT_NAME} \
${CHECKPOINT_NAME}

# get the container id to be able to create a new image from the container with the checkpoint data
CONTAINER_ID=$($CMD inspect --format="{{.Id}}" ${CHECKPOINT_NAME})

# create a new image from the previous one that adds the checkpoint files
$CMD container commit \
--change='CMD ["criu", "restore", "--unprivileged", "-D", "/app/checkpoint", "--shell-job", "-v4", "--log-file=restore.log"]' \
$CONTAINER_ID \
${RESTORE_NAME}

# Delete the checkpoint creation container
$CMD container rm ${CHECKPOINT_NAME}
# Delete the checkpoint creation image
$CMD image rm ${CHECKPOINT_NAME}

# Delete the dangling images
$CMD rmi $($CMD images -q --filter "dangling=true")
