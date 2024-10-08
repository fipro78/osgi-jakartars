#!/bin/sh

# invoke a dummy command 1000 times so the Java process can start with PID/TIDs >1000, which on restore are very likely to be free
# for i in $(seq 1000)
# do
#     /bin/true
# done

# In unprivileged mode we can't easily re-attach std out/err/in to terminals, we need to tie stdin to /dev/null and redirect stdout and stderr to files, 
# and those files need to be present at the same path on restore. The easiest solution is to just dump them to the checkpoint data dir.
# java $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar 0</dev/null 1>/app/checkpoint/stdout 2>/app/checkpoint/stderr

# exec java $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar
java -XX:CRaCMinPid=1000 $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar
# java -XX:CRaCMinPid=1000 $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar 0</dev/null 1>/app/checkpoint/stdout 2>/app/checkpoint/stderr