@echo off
setlocal EnableDelayedExpansion

if "%1"=="" (
   SET CMD=docker
   SET NETWORK=
   SET SECCOMP=
) else if "%1"=="docker" (
   SET CMD=docker
   SET NETWORK=
   SET SECCOMP=
) else if "%1"=="podman" (
   SET CMD=podman
   SET NETWORK=--network host
   SET SECCOMP=--security-opt seccomp=unconfined
) else if "%1"=="-h" (
   echo:
   echo This script is used to build a Java application container with a checkpoint using the Azul Zulu OpenJDK with CRaC
   echo:
   echo Use it in the following format: 
   echo   "build_crac.bat <docker|podman> <variant>"
   echo:
   echo The following variants are available to build
   echo   ubuntu_jdk [default]
   echo   ubuntu_jre
   echo   alpine_jre
   echo:
   echo Example: build_crac.bat podman alpine_jre
   exit /b
) else (
   echo The first parameter for this script needs to be either "docker" or "podman"!
   exit /b
)

if "%2"=="" (SET VAR=ubuntu_jdk) else (SET VAR=%2)

SET CHECKPOINT_NAME=crac_%VAR%_checkpoint
SET RESTORE_NAME=crac_%VAR%_restore

rem first build the image to create the checkpoint
%CMD% build %NETWORK% -t %CHECKPOINT_NAME% -f crac_%VAR%.Dockerfile .

rem run the container with necessary capabilities
%CMD% run ^
-it ^
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE %SECCOMP% ^
--name %CHECKPOINT_NAME% ^
%CHECKPOINT_NAME%

rem get the container id to be able to create a new image from the container with the checkpoint data
for /f %%i in ('%CMD% inspect --format="{{.Id}}" %CHECKPOINT_NAME%') do set CONTAINER_ID=%%i

rem create a new image from the previous one that adds the checkpoint files
%CMD% container commit ^
--change="CMD [\"java\", \"-XX:CRaCRestoreFrom=/app/checkpoint\"]" ^
%CONTAINER_ID% ^
%RESTORE_NAME%

rem Delete the checkpoint creation container
%CMD% container rm %CHECKPOINT_NAME%
rem Delete the checkpoint creation image
%CMD% image rm %CHECKPOINT_NAME%

rem Delete the dangling images
for /f %%i in ('%CMD% images -q --filter "dangling=true"') do set DANGLING_ID=%%i
%CMD% rmi %DANGLING_ID%