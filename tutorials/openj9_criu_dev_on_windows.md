# Developing OpenJ9 CRIU checkpoint creation on Windows

If you want to programmatically create a checkpoint using the `org.eclipse.openj9.criu.CRIUSupport` APIs, you need to develop on Linux, as these APIs are only available in the OpenJ9 JDK for Linux.

For developers that work on Windows the only option is to use the Windows Subsystem for Linux (WSL). There are at least 3 options to choose from:

1. Develop in VS Code using a devcontainer with a Semeru JDK

    Add the following section in the _devcontainer.json_:

    ```json
        // according to https://github.com/devcontainers/images/tree/main/src/java
        "features": {
            "ghcr.io/devcontainers/features/java:1": {
                "version": "21",
                // use the Semeru Runtime to be able to implement CRIU support bundle
                "jdkDistro": "sem",
                "installGradle": "false",
                "installMaven": "true",
                "mavenVersion": "3.9.8"
            },
            "ghcr.io/devcontainers/features/git:1": {}
        },
    ```

    __Note:__  
    I faced issues when using the __Docker Maven Plugin__ and networking between containers started inside the devcontainer. I suppose an issue with the "Docker in Docker" approach.

2. Develop in VS Code inside the WSL ("open remote")  

    Install SDKMAN to install Java (WSL)  
    https://sdkman.io/install

    ```
    sudo apt-get install zip unzip

    curl -s "https://get.sdkman.io" | bash
    source "/home/fad8pl/.sdkman/bin/sdkman-init.sh"
    ```

- Install IBM Semeru Java SDK (WSL)  
https://sdkman.io/usage

    ```
    sdk install java 21.0.3-sem
    ```

    if not asked at installation, set the installed version as default (WSL)

    ```
    sdk default java 21.0.3-sem
    ```	
	
- Install Maven (WSL)

    ```
    sdk install maven
    ```	

    Restart WSL (Windows CMD)

    ```
    wsl --shutdown
    ```

    Then start the WSL distro again and open VS Code in the workspace folder (Windows CMD)

    ```
    Code .
    ```	

3. Develop in Eclipse inside the WSL with guiApplications support and a Semeru JDK installed

    Ensure there is a wsl configuration file C:\Users\<userid>\.wslconfig that has at least the following entry:

    ```
    [wsl2]
    guiApplications=true
    ```

    __Note:__  
    This setting enables [WSLg](https://github.com/microsoft/wslg). Although WSL2 comes with WSLg enabled by default, I prefer to set it explicitly. Especially because it might interfere with other situations.
    For example if you want to use Podman on Windows as alternative to Docker Desktop and open a workspace in VS Code in a devcontainer, you might get the following error:

    ```
    unsupported UNC path
    ```

    This is due to the fact that by default WSLg is enabled to support Linux GUI apps. If this is enabled, Podman and the devcontainer extension trying to establish a UNC mount, which is not supported.
    The only solution here is to disable WSLg by setting 

    ```
    [wsl2]
    guiApplications=false
    ```

    Download an Eclipse package from https://www.eclipse.org/downloads/packages/

    Extract it e.g. to ~/dev/eclipse

    Make sure the eclipse launcher is executable via 

    ```
    chmod 777 ~/dev/eclipse/eclipse
    ```

    Try to start Eclipse via the launcher 

    ```
    ./eclipse
    ```

    If it fails with a `JVM terminated. exit code=13` error, you need to configure the correct JVM that should be used to start. The reason might be that the JustJ JVM that is included in the package you downloaded is not matching the WSL architecture.
    Open the eclipse.ini file, search for the -vm entry and replace the line below with the folder of the JVM you installed before via SDKman, e.g.

    ```
    -vm
    /home/fad8pl/.sdkman/candidates/java/current/bin
    ```
