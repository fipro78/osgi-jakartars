#! /bin/bash

CMD=${1:-docker}
VAR=${2:-ubuntu_jdk}
RESTORE_NAME=crac_${VAR}_restore

while getopts "h" flag; do
 case $flag in
   h) # Handle the -h flag
   # Display script help information
   echo
   echo This script is used to build a Java application container with a checkpoint using the Azul Zulu OpenJDK with CRaC
   echo
   echo Use it in the following format:
   echo "  ./run_crac.sh <docker|podman> <variant>"
   echo
   echo The following variants are available to build
   echo "  ubuntu_jdk (default)"
   echo "  ubuntu_jre"
   echo "  alpine_jre"
   echo
   echo Example: ./run_crac.sh podman alpine_jre
   exit 0
   ;;
 esac
done

echo Start the container with application from checkpoint
echo $(date +%s%3N)

$CMD run \
-p 8080:8080 \
--rm \
--name ${RESTORE_NAME} \
${RESTORE_NAME}