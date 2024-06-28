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
   echo "  ubi_openj9_jre"
   echo "  ubi_openj9_jdk"
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

echo Start the container with application from checkpoint
echo $(date +%s%3N)

$CMD run \
-p 8080:8080 \
--rm \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE \
--security-opt seccomp=unconfined \
--name ${RESTORE_NAME} \
${RESTORE_NAME}