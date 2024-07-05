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

SET RESTORE_NAME=crac_%VAR%_restore

rem run the container with necessary capabilities
%CMD% run ^
-p 8080:8080 ^
--rm ^
--cap-add=CHECKPOINT_RESTORE ^
--name %RESTORE_NAME% ^
%RESTORE_NAME%