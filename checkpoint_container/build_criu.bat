@echo off
setlocal EnableDelayedExpansion

if "%1"=="" (
   SET CMD=docker
   SET NETWORK=
) else if "%1"=="docker" (
   SET CMD=docker
   SET NETWORK=
) else if "%1"=="podman" (
   SET CMD=podman
   SET NETWORK=--network host
) else if "%1"=="-h" (
   echo:
   echo This script is used to build a Java application container with a checkpoint using the OpenJ9 CRIU Support
   echo:
   echo Use it in the following format: 
   echo   "build_criu.bat <docker|podman> <variant>"
   echo:
   echo The following variants are available to build
   echo   ubi_crac_jre [default]
   echo   ubi_crac_jdk
   echo   ubi_openj9_jre
   echo   ubi_openj9_jdk
   echo:
   echo Example: build_criu.bat podman ubi_crac_jre
   exit /b
) else (
   echo The first parameter for this script needs to be either "docker" or "podman"!
   exit /b
)

if "%2"=="" (SET VAR_RUNTIME=ubi_crac_jre) else (SET VAR_RUNTIME=%2)

for /f "tokens=1,2,3 delims=_" %%a in ("%VAR_RUNTIME%") do (
  SET VAR=%%a_%%b
  SET RUNTIME=%%c
)

if "%RUNTIME%"=="jdk" (
   SET VERSION=open-21-jdk-ubi-minimal
) else (
   SET VERSION=open-21-jre-ubi-minimal
)

SET CHECKPOINT_NAME=criu_%VAR%_checkpoint
SET RESTORE_NAME=criu_%VAR%_restore

rem first build the image to create the checkpoint
%CMD% build %NETWORK% -t %CHECKPOINT_NAME% --build-arg VERSION=%VERSION% -f criu_%VAR%.Dockerfile .

rem run the container with necessary capabilities
%CMD% run ^
-it ^
--cap-drop=ALL ^
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE --cap-add=SETPCAP ^
--security-opt seccomp=unconfined ^
--name %CHECKPOINT_NAME% ^
%CHECKPOINT_NAME%

rem get the container id to be able to create a new image from the container with the checkpoint data
for /f %%i in ('%CMD% inspect --format="{{.Id}}" %CHECKPOINT_NAME%') do set CONTAINER_ID=%%i

rem create a new image from the previous one that adds the checkpoint files
%CMD% container commit ^
--change="CMD [\"criu\", \"restore\", \"--unprivileged\", \"-D\", \"/app/checkpoint\", \"--shell-job\", \"-v4\", \"--log-file=restore.log\"]" ^
%CONTAINER_ID% ^
%RESTORE_NAME%

rem Delete the checkpoint creation container
%CMD% container rm %CHECKPOINT_NAME%
rem Delete the checkpoint creation image
%CMD% image rm %CHECKPOINT_NAME%

rem Delete the dangling images
for /f %%i in ('%CMD% images -q --filter "dangling=true"') do set DANGLING_ID=%%i
%CMD% rmi %DANGLING_ID%