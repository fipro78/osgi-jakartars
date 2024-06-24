#! /bin/bash

CMD=${1:-docker}
VAR=${2:-ubuntu_jdk}
CHECKPOINT_NAME=crac_${VAR}_checkpoint
RESTORE_NAME=crac_${VAR}_restore

while getopts "h" flag; do
 case $flag in
   h) # Handle the -h flag
   # Display script help information
   echo
   echo This script is used to build a Java application container with a checkpoint using the Azul Zulu OpenJDK with CRaC
   echo
   echo Use it in the following format:
   echo "  build_crac.bat <docker|podman> <variant>"
   echo
   echo The following variants are available to build
   echo "  ubuntu_jdk (default)"
   echo "  ubuntu_jre"
   echo "  alpine_jre"
   echo
   echo Example: build_crac.bat podman alpine_jre
   exit 0
   ;;
 esac
done

if [ "$CMD" != "docker" ] && [ "$CMD" != "podman" ]
then 
  echo The first parameter for this script needs to be either \"docker\" or \"podman\"!; 
  exit 0
fi

# first build the image to create the checkpoint
$CMD build -t ${CHECKPOINT_NAME} -f crac_${VAR}.Dockerfile .

# run the container with necessary capabilities
$CMD run \
-it \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE \
--name ${CHECKPOINT_NAME} \
${CHECKPOINT_NAME}

# get the container id to be able to create a new image from the container with the checkpoint data
CONTAINER_ID=$($CMD inspect --format="{{.Id}}" ${CHECKPOINT_NAME})

# create a new image from the previous one that adds the checkpoint files
$CMD container commit \
--change='CMD ["java", "-XX:CRaCRestoreFrom=/app/checkpoint"]' \
$CONTAINER_ID \
${RESTORE_NAME}

# Delete the checkpoint creation container
$CMD container rm ${CHECKPOINT_NAME}
# Delete the checkpoint creation image
$CMD image rm ${CHECKPOINT_NAME}

# Delete the dangling images
$CMD rmi $($CMD images -q --filter "dangling=true")