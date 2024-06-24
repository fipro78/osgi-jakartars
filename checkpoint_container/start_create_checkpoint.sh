# sleep for 15 seconds to ensure everything is ready
sleep 15
# create the checkpoint
echo "execute: jcmd app.jar JDK.checkpoint"
jcmd app.jar JDK.checkpoint