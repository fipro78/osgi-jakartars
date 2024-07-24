#!/bin/sh

# invoke a dummy command 1000 times so the Java process can start with PID/TIDs >1000, which on restore are very likely to be free
for i in $(seq 1000)
do
    /bin/true
done

java $JAVA_OPTS $JAVA_OPTS_EXTRA -m $MODULE_NAME/aQute.launcher.pre.EmbeddedLauncher