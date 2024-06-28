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

SET RESTORE_NAME=criu_%VAR%_restore

rem run the container with necessary capabilities
%CMD% run ^
-p 8080:8080 ^
--rm ^
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE ^
--security-opt seccomp=unconfined ^
--name %RESTORE_NAME% ^
%RESTORE_NAME%