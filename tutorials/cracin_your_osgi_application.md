# CRaCin` your OSGi application - start so fast I want to CRIU

When creating a new application, you nowadays need to think about all the different ways the application or its functionality will be consumed. The usage as a desktop application is not as important anymore, compared to the usage in the web, or in the cloud (which is basically the same as "in the web" but with more focus on scalability). Especially the usage in the cloud typically comes in combination with the containerization of an application. Such containers need to be started and stopped frequently, and to do this efficiently, the containers, and especially the applications inside the containers, need to start fast. It is quite annoying that you need to wait for an application to become available when you start a container. The expectation today is that once the container is started, the application is ready. For several programming languages this is the case, like for example a web application based on Javascript or a Python application. Java applications are typically not known for such fast startups. The reason lies in the architecture and the startup process of a Java application.

From [Sustainable Java Applications With Quick Warmup by Dmitry Chuyko](https://dzone.com/articles/sustainable-java-applications-with-quick-warmup):
> Java application startup and warmup technically include several consecutive processes: JVM startup, application startup, and JVM warmup. In these processes, the JVM gets extra time to provide application peak performance. 
>
> The warmup phase is taken by JVM to compile and optimize the code. This process is needed for code interpretation and optimization and lasts substantially longer than the startup in cases of large complex applications, taking up to several minutes. 
>
> Every time you start your program, these processes begin from scratch.

For more details on this, watch [What the CRaC (Gerrit Grunwald at Voxxed Athens)](https://www.youtube.com/watch?v=Y9sEXOGlvoA), or any other recording of this talk at other conferences.

From shared class caches to native compilation, there are several approaches that are trying to reduce the startup time. Statically compiling the application to a native application (AOT) shows the best startup performance measures, but it also avoids the benefits of the HotSpot runtime to improve over time. And it also brings up other issues, e.g. the runtime behavior of the statically compiled application differs to the one on the Java runtime while developing and testing.

Gerrit has a nice [What the CRaC - AOT vs JIT](https://www.slideshare.net/slideshow/what-the-crac-superfast-jvm-startup-252967592/252967592#50) slide where AOT and JIT are compared. In short, AOT starts faster and has a smaller memory footprint, but is way more complicated to achieve and the native application does not need to be 100% the same thing as you develop and debug. The JIT on the other side does support reflections etc. without problems and the application you deploy is the same thing as you develop. But it requires more time to startup and has a larger memory footprint.

By using [CRIU (Checkpoint/Restore in Userspace)](https://criu.org/Main_Page), the startup time of a Java application can be on the same level as a native compiled application, by keeping the runtime improvements and behaviors of the HotSpot JRE.

## OpenJDK CRaC vs. OpenJ9 CRIU Support

For Java there are currently two implementations available that support [CRIU (Checkpoint/Restore in Userspace)](https://criu.org/Main_Page):
- OpenJDK CRaC (Coordinated Restore at Checkpoint)
- OpenJ9 CRIU Support

While both use the same base library at the end, the usage is different. The following section provides some basic informations on both implementations. Further details will be placed in the concrete sections.

__*Note:*__  
Most of the information you find about OpenJDK CRaC and OpenJ9 in the web are already outdated. Some of them are up-to-date, like the [Azul Docs](https://docs.azul.com/core/crac/crac-introduction) or the [OpenJ9 Docs](https://eclipse.dev/openj9/docs/criusupport/). But most of the blog posts contain information that are not up-to-date. So expect that this blog post does also not contain the latest information, dependent on when you read it. But similar to the other blog posts (links at the bottom), it contains relevant information that should help in understanding the topic and to get started.

### OpenJDK Coordinated Restore at Checkpoint (CRaC)

CRaC (Coordinated Restore at Checkpoint) is an OpenJDK project to solve the problem of "slow" startup times of the Java Virtual Machine in a microservice environment. It provides mechanisms to checkpoint a Java instance while it is executing. Restoring from the checkpoint solves the problems with the start-up and warm-up times.  
It was developed by [Azul](https://www.azul.com/) who also provide a pre-build JDK with CRaC support.

- [OpenJDK Projects - CRaC](https://openjdk.org/projects/crac/index.html)
- [OpenJDK Wiki - CRaC Project](https://wiki.openjdk.org/display/crac)

The reference implementation is provided by [Azul Systems](https://www.azul.com/). You can download the a JDK with CRaC support via the downloads page or via the CDN directly:
- [Azul Zulu OpenJDK Downloads](https://www.azul.com/downloads/?package=jdk-crac#zulu)
- [Azul CDN - Zulu](https://cdn.azul.com/zulu/bin/)

__*Note:*__  
There are JDKs with CRaC support available for Windows and macOS. But they are intended for development only as described in [Running CRaC on Windows or macOS](https://docs.azul.com/core/crac/crac-guidelines#run-on-windows-macos). CRIU is currently a Linux only feature.

The [Azul CRaC Product Page](https://www.azul.com/products/components/crac/) provides some initial information (especially the FAQ at the bottom). Azul also provides a very nice [documentation about the CRaC](https://docs.azul.com/core/crac/crac-introduction), which is a good read to get better insights and is quite helpful in case of issues.

A checkpoint can be created
- manually via `jcmd`
- programmatically via API  
You can use the `jdk.crac` API provided by the JDK directly, but it is recommended to use the [org.crac API](https://github.com/crac/org.crac), as it does not introduce a dependency to a JDK specific package.

### OpenJ9 CRIU Support

The OpenJ9 CRIU Support provides the same functionality as CRaC. It also uses CRIU and includes an API to create the checkpoint.

OpenJ9 is included in the IBM Semeru Runtimes, which can be downloaded via the IBM Developer website or GitHub:
- [IBM Semeru Downloads](https://developer.ibm.com/languages/java/semeru-runtimes/downloads/)
- [GitHub Semeru 17 Binaries](https://github.com/ibmruntimes/semeru17-binaries/releases)
- [GitHub Semeru 21 Binaries](https://github.com/ibmruntimes/semeru21-binaries/releases)

__*Note:*__  
Only the IBM Semeru Runtime for Linux contains the OpenJ9 VM with CRIU Support.

There is a basic [OpenJ9 CRIU Support documentation](https://eclipse.dev/openj9/docs/criusupport/) available that contains some links to blog posts with further information.

A checkpoint can only be created programmatically via OpenJ9 `CRIUSupport` API. In the most current version the usage of the `org.crac` API is also supported.

__*Note:*__  
It is possible to create a checkpoint manually using the `jcmd` tool with the OpenJ9 CRaC support. As OpenJ9 does not yet "officially" support CRaC, this fact is not yet documented. Note that the OpenJ9 `jcmd` tool is a different implementation that is specific to OpenJ9, and is not related to the HotSpot tool of the same name (see [OpenJ9 - Java diagnostic command (`jcmd`) tool](https://eclipse.dev/openj9/docs/tool_jcmd/))

## Image Creation Process

If you read through this blog post and follow the steps, you should have gained a better understanding of how to use CRaC/CRIU in your Java project and created your first CRaC/CRIU enabled container image. The process of creating such an image basically consists of the following steps:

1. Build the container image with the Java application
2. Run a container with the necessary capabilities
3. Create a checkpoint
4. Create a new image from the previous one that adds the checkpoint files

This of course also implies that the application supports the creation of checkpoints and restoring it from there again. Several frameworks already provide CRaC/CRIU support. Further information will be provided later.

### Container Image

The first step in creating a Java application container image with checkpoint data, is the creation of a _Dockerfile_. In this section we will create the _Dockerfile_ in different variants.

#### Choose the base container

Azul provides [pre-build containers with CRaC support](https://hub.docker.com/r/azul/zulu-openjdk). These containers are based on Ubuntu and have a JDK included.

**Azul Zulu Build of OpenJDK 21 based on Ubuntu**
```dockerfile
FROM azul/zulu-openjdk:21-jdk-crac-latest
```

If you care about the size of the application containers, you can create your own container that only contains a JRE and is based on Alpine for example.
To create a new container choose the base Linux image and install an Azul Zulu JRE with CRaC support. The Azul Zulu with CRaC support can be downloaded from the [Azul CDN](https://cdn.azul.com/zulu/bin/).

__*Note:*__  
The Azul Zulu Builds of OpenJDK with CRaC are only available for a [limited set of Linux systems](https://docs.azul.com/core/release-notes/#azul-zulu-builds-of-openjdk-with-crac).

**Ubuntu / Azul Zulu JRE with CRaC**

The following snippet is the start of a _Dockerfile_ that creates an image based on Ubuntu with an Azul Zulu JRE with CRaC support.

```dockerfile
FROM ubuntu:22.04

ENV JAVA_HOME /opt/jdk
ENV PATH $JAVA_HOME/bin:$PATH

ADD "https://cdn.azul.com/zulu/bin/zulu21.34.21-ca-crac-jre21.0.3-linux_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

RUN \
    tar --extract --file $JAVA_HOME/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1; \
    rm $JAVA_HOME/openjdk.tar.gz;
```

**Alpine / Azul Zulu JRE with CRaC**

The following snippet is the start of a _Dockerfile_ that creates an image based on Alpine with an Azul Zulu JRE with CRaC support.

```dockerfile
FROM alpine:3.20

ENV JAVA_HOME /opt/jdk
ENV PATH $JAVA_HOME/bin:$PATH

ADD "https://cdn.azul.com/zulu/bin/zulu21.34.21-ca-crac-jre21.0.3-linux_musl_x64.tar.gz" $JAVA_HOME/openjdk.tar.gz

RUN \
    tar --extract --file $JAVA_HOME/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1; \
    rm $JAVA_HOME/openjdk.tar.gz;
```

For OpenJ9 CRIU Support you can use one of the provided IBM Semeru Runtime containers. These containers are based on Red Hat Universal Images (UBI) 8 and 9.

**IBM Semeru Runtime 21 UBI 9**
```dockerfile
FROM icr.io/appcafe/ibm-semeru-runtimes:open-21-jre-ubi-minimal
```

The information about the container image tags are described at the [IBM Support - Semeru Runtimes installation](https://www.ibm.com/support/pages/semeru-runtimes-installation).

__*Note:*__  
There is no musl support and therefore not Alpine Linux images planned in the OpenJ9 project.
https://github.com/ibmruntimes/Semeru-Runtimes/issues/6

#### Common Docker Instructions

The next step in the Dockerfile is common to both variants. The following example is based on my [OSGi Jakarta™ RESTful Web Services Example](https://vogella.com/blog/build-rest-services-with-osgi-jakarta-rs-whiteboard/). You can simply checkout the project from [GitHub](https://github.com/fipro78/osgi-jakartars) and run the build via `mvn clean verify`. Copy the resulting single-executable _app.jar_ file to the image and expose port 8080 on which the embedded Jetty server is available. Additionally create a directory in which the checkpoint files should be stored.

```dockerfile
EXPOSE 8080

# copy the application jar to the image
COPY app.jar /app/

# create the folder for the checkpoint files inside the image
RUN \
  mkdir -p /app/checkpoint
```

__*Note:*__  
The Semeru images based on UBI 8 and 9 specify a non-root user (`USER 1001`) to run as inside the container. Trying to create a directory on top level will result in a `Permission denied` error when trying to build the image.
In order to be able to create a directory in the IBM Semeru UBI Runtime image, you need to switch the user to `root` via 

```dockerfile
USER root
```

To follow best practices you might want to switch back to the non-root user afterwards. Just don't forget to make the created folder accessible to anyone in that case.

```dockerfile
USER root

# create the folder for the checkpoint files inside the image
RUN \
  mkdir -p /app/checkpoint && \
  chmod 777 /app/checkpoint

USER 1001
```

#### Application start

To start the application and be able to create a checkpoint, you need to provide an additional JVM flag. For the OpenJDK CRaC variant the JVM flag is `-XX:CRaCCheckpointTo={PATH}`, where `{PATH}` is the directory in which the checkpoint files should be written.

**Azul Zulu OpenJDK with CRaC**
```dockerfile
# start the application for checkpoint creation
CMD ["java", "-XX:CRaCCheckpointTo=/app/checkpoint", "-jar", "/app/app.jar"]
```

With OpenJ9 you need to enable the CRIU Support via [`-XX:+EnableCRIUSupport`](https://eclipse.dev/openj9/docs/xxenablecriusupport/). The option enables the use of `org.eclipse.openj9.criu.CRIUSupport` APIs, for example to create a checkpoint.

__*Note:*__  
If you want to use the `org.crac` API with OpenJ9, you need to use `-XX:CRaCCheckpointTo={PATH}` instead, as the `-XX:+EnableCRIUSupport` is not compatible with that.

**OpenJ9 CRIU Support**
```dockerfile
# start the application for checkpoint creation
CMD ["java", "-XX:+EnableCRIUSupport", "-jar", "/app/app.jar"]
```

### Create the image and start the application container

First we create the image for the application which is simple as that.

```
docker build -t application_checkpoint .
```

To start the application in the container and be able to create a checkpoint, the container needs to be started with [additional capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) that are not granted by default. 

OpenJDK CRaC only needs 
- `CAP_CHECKPOINT_RESTORE` - Allow checkpoint/restore related operations. Introduced in kernel 5.9.
- `CAP_SYS_PTRACE` - Trace arbitrary processes using ptrace(2).

**Azul Zulu OpenJDK with CRaC**
```
docker run \
-it \
-p 8080:8080 \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE \
--name application_checkpoint \
application_checkpoint
```

**OpenJ9 CRIU Support**

OpenJ9 CRIU Support additionally needs 
- `CAP_SETPCAP` - Modify process capabilities.
so that any unnecessary caps that the container runtime may give can be dropped (using `-cap-drop=ALL`). And the container needs to be run without the default [seccomp profile](https://docs.docker.com/engine/security/seccomp/).

```
docker run \
-it \
-p 8080:8080 \
--cap-drop=ALL \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE --cap-add=SETPCAP \
--security-opt seccomp=unconfined \
--name application_checkpoint \
application_checkpoint
```

__*Note:*__  
If you are on Windows 11 and use a WSL2 with `networkingMode=mirrored`, instead of the port configuration you need to connect to the host network:

```
--network=host
```

Verify that the application in the container is ready and accessible by opening the following URL in a browser:  
http://localhost:8080/modify/fubar

### Create a checkpoint

In the following section I will describe different ways how to create a checkpoint and how to deal with possible issues at checkpoint creation, like handling open resources.

#### Manually creating a checkpoint

Even though the goal of this article is to automatically create an application container image with checkpoint data, it is a good idea to try to generate a checkpoint manually. This helps in finding and understanding possible issues early and be able to resolve them before the automation process.

__*Note:*__  
Creating a checkpoint manually is only possible with the OpenJDK CRaC implementation or the not yet officially released OpenJ9 CRaC support. And it is only available if you use a base image with a JDK, as there is no `jcmd` available in the JRE.

Once the application in the container is ready, 

- Connect to the container inside a new shell window via:

```
docker exec -ti application_checkpoint /bin/bash
```

- Run the `jcmd` command on the bash to trigger the checkpoint creation via 

```
jcmd app.jar JDK.checkpoint
```

Without additional preparations, this action will fail throwing a `jdk.internal.crac.mirror.CheckpointException`. How to solve this is covered in the following section.

#### Resource handling

Trying to create the checkpoint without additional configurations fails with a `jdk.internal.crac.mirror.CheckpointException`, which contains several entries for `jdk.internal.crac.mirror.impl.CheckpointOpenFileException`. This means that the checkpoint can't be created because there are open files, as described in [Coordinated Restore at Checkpoint Exceptions](https://docs.azul.com/core/crac/crac-errors). The reasoning behind this is the argument, that files could be moved or deleted between application starts, which would then cause issues in further processing.

This is an issue for OSGi applications, because the bundle jar files are kept open by the OSGi framework to access the OSGi metadata. But inside a container, the argument of removed files is arguable, as we are in a controlled environment. CRaC therefore added an option to configure the behavior for file descriptors via [File Descriptor Policies](https://docs.azul.com/core/crac/fd-policies).

- Create a __fd_policies.yaml__ file with the following content, to handle the files that are kept open by the OSGi framework

```yaml
type: FILE
path: **/*.jar
action: reopen
warn: false
---
type: FILE
path: **/bundleFile
action: reopen
warn: false
```

- Update the _Dockerfile_ to copy the  file to the image and add the system property `jdk.crac.resource-policies` to the startup:

```dockerfile
EXPOSE 8080

# copy the application jar to the image
COPY app.jar /app/
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/

# create the folder for the checkpoint files inside the image
RUN \
  mkdir -p /app/checkpoint

# start the application for checkpoint creation
CMD [ "java", \
        "-XX:CRaCCheckpointTo=/app/crac-files", \
        "-Djdk.crac.resource-policies=/app/fd_policies.yaml", \
        "-jar", \
        "/app/app.jar" \
]
```

If you now still get a `jdk.internal.crac.mirror.CheckpointException`, but this time of type `jdk.internal.crac.mirror.impl.CheckpointOpenSocketException`, you have an open socket. In our case this actually means that the Jetty is still running and has an open socket on port 8080. It is also possible to configure a rule for sockets, but the `reopen` action is not supported as described in [File Descriptor Policies - Sockets](https://docs.azul.com/core/crac/fd-policies#sockets). This makes it quite useless for our use case.

I explain how to programmatically deal with open resources in later sections:
- For CRaC using the `org.crac` API in [Programmatically handle open resources](#programmatically-handle-open-resources)
- For OpenJ9 using the `CRIUSupport` API in [OpenJ9 resource handling](#openj9-resource-handling)

__*Note:*__  
For the OSGi Jakarta-RS Whiteboard I have [created a pull request](https://github.com/osgi/jakartarest-osgi/pull/45) to add CRaC support. The review is in progress. Until it is merged and a new version with CRaC support is published, you need to handle the open socket in the Jetty yourself, as described in the sections linked above.

__*Note:*__  
Other frameworks like Micronaut, Spring Boot and Quarkus also provide CRaC support. At the end of this blog post you will find some links to the corresponding resources.

Once the checkpoint creation succeeded, we are on the right path for the automization. You should note that the application terminates after the checkpoint creation.  

If it fails, move on with the programmatic checkpoint creation approach.

#### Automated checkpoint creation via `jcmd`

You can use the `jcmd` to manually create a checkpoint. But in an automatized process, manual interactions are not useful. One way to handle this is to execute the `jcmd` asynchronously after a delay by using a shell script.

- Create the script file *start_create_checkpoint.sh* with the following content:

```shell
# sleep for 15 seconds to ensure everything is ready
sleep 15
# create the checkpoint
jcmd app.jar JDK.checkpoint
```

To be able to start the *start_create_checkpoint.sh* script asynchronously after the application was started, create an additional *start_jcmd.sh* script and change the Dockerfile accordingly.

- Create the script file *start_jcmd.sh* with the following content:

```shell
#!/bin/sh
. ./start_create_checkpoint.sh &
java \
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-jar \
/app/app.jar
```

- Update the Dockerfile to add the additional scripts

```Dockerfile
# copy the application jar to the image
COPY app.jar /app/
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start_create_checkpoint.sh /app/
COPY start_jcmd.sh /app/

# create the folder for the checkpoint files and make the start scripts executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start_jcmd.sh && \
  chmod 755 /app/start_create_checkpoint.sh

WORKDIR /app
CMD ["./start_jcmd.sh"]
```

#### Programmatic checkpoint creation using the `org.crac` API

Although it is possible to create a checkpoint using `jcmd`, this might not always be a suitable solution because of the following reasons: 

- `jcmd` is only available in a JDK. If you want to create smaller containers, for example using Alpine with a JRE on musl, it is not possible to create the checkpoint manually.
- It is a manual interaction. Even though it can be scripted via a shell script (see above).
- OpenJ9 does not support a manual checkpoint creation via `jcmd`.

To create a checkpoint programmatically it is a best practice to use the [`org.crac` API](https://github.com/CRaC/org.crac).

**_Note:_**  
You can also try to use the `jdk.crac` API from the OpenJDK directly, but that makes even the development environment dependent on the JDK and is not recommended.

Creating a checkpoint programmatically does not mean directly that it should happen automatically. Although it often means exactly this. Frameworks like Spring Boot or Open Liberty provide options to create a checkpoint at a certain point of time without the need to write any additional code (see links for further information at the bottom). If such a framework is not used or you want to provide your own mechanism to trigger the checkpoint creation programmatically, you need to write some code and define the place or time when to trigger it. Basically you have the following options to trigger the checkpoint creation, e.g.

- at a certain point of time in the startup process  
If you have full control of the application startup, you can add the code where it makes the most sense (e.g. after the server start call). Or you can register some event listener in case the framework you use fires according startup events. Or even add the code for checkpoint creation at multiple places in the startup process and select the point of time via a system property, which is probably something Spring Boot and InstantOn are doing.
- by calling a function in the application, e.g. a REST resource  
This way you can trigger the execution also manually whenever you think it is a good point in time. In this case you should then ensure that the checkpoint creation REST resource is not working anymore once you restore the application (e.g. disable it after `Core.checkpointRestore()`).
- automatically triggered asynchronously with some delay after starting the application (similar to the `jcmd` approach above)

The example I use to show the usage of CRaC/CRIU with OSGi applications is based on the [OSGi Technology Whiteboard Implementation for Jakarta RESTful Web Services](https://github.com/osgi/jakartarest-osgi). By using the [Whiteboard Pattern](https://docs.osgi.org/whitepaper/whiteboard-pattern/) we actually do not have a dedicated point in time on startup where we could definitely say that everything is up and running. It is the nature of this pattern that it is not known if the server or the resources are available first. And because of the dynamics in OSGi, there are also no events that would say _"the server is started and all available resources are registered"_. I therefore decided to implement an _Immediate Component_ that triggers the checkpoint creation asynchronously with some delay.

If you want to follow the steps I describe next with the OSGi Jakarta-RS example, you can checkout my GitHub repository and switch to the `jakartars` branch:

```
git clone https://github.com/fipro78/osgi-jakartars.git
cd osgi-jakartars
git fetch
git switch jakartars
```

- Create a new Maven submodule in the _jakartars_ folder via

```
mvn archetype:generate \
-DarchetypeArtifactId=maven-archetype-quickstart \
-DgroupId=org.fipro.service.modifier \
-DartifactId=crac \
-Dversion=1.0.0-SNAPSHOT \
-Dpackage=org.fipro.service.modifier.crac \
-DinteractiveMode=false
```

- Open the file _jakartars/pom.xml_ and add the following to the `dependencyManagement` section:
```xml
<dependency>
  <groupId>org.crac</groupId>
  <artifactId>crac</artifactId>
  <version>1.5.0</version>
</dependency>
```

__*Note:*__  
The OSGi metadata was added to the `org.crac` API with version 1.5.0. Be sure to use at least that version to make it work in an OSGi project.

- Open the file _jakartars/crac/pom.xml_ and replace the `dependencies` section with the following one:

```xml
<dependencies>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>osgi.core</artifactId>
  </dependency>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>osgi.annotation</artifactId>
  </dependency>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>org.osgi.service.component.annotations</artifactId>
  </dependency>
  <dependency>
    <groupId>org.crac</groupId>
    <artifactId>crac</artifactId>
  </dependency>
</dependencies>
```

- Add the following `build` section:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-baseline-maven-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

- Create an _Immediate Component_ in the package `org.fipro.service.modifier.crac` that schedules the execution of the checkpoint creation on activation. To create the checkpoint use the `org.crac.Core#checkpointRestore()` API.

```java
package org.fipro.service.modifier.crac;

import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.crac.CheckpointException;
import org.crac.Core;
import org.crac.RestoreException;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

@Component
public class CheckpointCreationComponent {

    @Activate
    void activate() {
        Executors.newSingleThreadScheduledExecutor().schedule(() -> {
            try {
                Core.checkpointRestore();

                // Note:
                // any code written after checkpointRestore() will be executed on restore

            } catch (CheckpointException|RestoreException|UnsupportedOperationException e) {
                // Note:
                // Only print the stacktrace to verify the execution and behavior in
                // different environments. In production we would probably catch the
                // UnsupportedOperationException silently.
                e.printStackTrace();
            }
        }, 
        10, TimeUnit.SECONDS);
    }
}
```

#### Programmatically handle open resources

CRIU does not like open resources, like files or sockets. While it is possible to add policies on how to handle the open files, the policies for sockets do not work that easy. The reason is that for sockets the reopening part is not implemented as described in [File Descriptor Policies - Sockets](https://docs.azul.com/core/crac/fd-policies#sockets).

It is possible to handle open resources programmatically using the `org.crac` API. To do this you need to implement an regisgter a `org.crac.Resource` where the necessary steps are performed. The challenge is that you need to have access to the resources like the server instance to be able to shutdown on `beforeCheckpoint()` and restart on `afterRestore()`. In most of the cases the server instance is not directly accessible from the outside, which makes it kind of impossible to register a `Resource` at some other place that is able to handle this situation.

If the Jakarta-RS Whiteboard implementation does not yet support CRaC (provided via my [PR](https://github.com/osgi/jakartarest-osgi/pull/45)), we can implement the Jetty integration ourselves. Of course this is not the best solution, as it would be better to have it directly in the Jakarta-RS Whiteboard implementation itself. But for testing and to show how to handle open resources it is a good example.

- Open the file _jakartars/crac/pom.xml_ and add the following dependencies to the `dependencies` section:

```xml
<dependency>
  <groupId>org.eclipse.osgi-technology.rest</groupId>
  <artifactId>org.eclipse.osgitech.rest</artifactId>
  <scope>compile</scope>
</dependency>
<dependency>
  <groupId>org.apache.felix</groupId>
  <artifactId>org.apache.felix.http.jetty</artifactId>
  <scope>compile</scope>
</dependency>
```

- Create a new package `org.fipro.service.modifier.crac.jetty`
- Copy the two classes `JettyBackedWhiteboardComponent` and `JettyServerRunnable` from [org.eclipse.osgitech.rest.jetty](https://github.com/osgi/jakartarest-osgi/tree/main/org.eclipse.osgitech.rest.jetty/src/main/java/org/eclipse/osgitech/rest/jetty) to that package

- Add the following code to `JettyBackedWhiteboardComponent`
  - Add a new field `cracHandler` of type `org.crac.Resource`
  - Implement the `org.crac.Resource` and register it in the `activate()` method

    **_Note:_**  
    The following approach is taken and adapted from the CRaC project that provides several examples
    - [Step-by-step CRaC support for a Jetty app](https://github.com/CRaC/docs/blob/master/STEP-BY-STEP.md)
    - [CRaC example-jetty](https://github.com/CRaC/example-jetty/blob/master/src/main/java/com/example/App.java) which shows an improved mechanism for the shutdown and restart, that avoids killing the whole server.
    - [Tips and Tricks for CRaC - Implementing Resource as Inner Class](https://docs.azul.com/core/crac/crac-tips-tricks#implementing-resource-as-inner-class)


```java
private Resource cracHandler;

...

@Activate
public void activate(BundleContext context, Map<String, Object> properties) throws ConfigurationException {
  
  ... 
  
  cracHandler = new Resource() {
      @Override
      public void beforeCheckpoint(Context<? extends Resource> context) {
        if (jettyServer != null && !jettyServer.isStopped()) {
          // Stop the connectors only and keep the expensive application running
          Arrays.asList(jettyServer.getConnectors()).forEach(c -> LifeCycle.stop(c));
        }
      }

      @Override
      public void afterRestore(Context<? extends Resource> context) {
        if (jettyServer != null && !jettyServer.isStopped()) {
          Arrays.asList(jettyServer.getConnectors()).forEach(c -> LifeCycle.start(c));
        }
      }
  };
  Core.getGlobalContext().register(cracHandler);
}
```

- Create an additional _app-crac.bndrun_ run file in _jakartars/app_ to build another application variant that contains the CRaC support

```
index: target/index.xml;name="app-crac"

-standalone: ${index}

-runrequires: \
	bnd.identity;id='org.fipro.service.modifier.impl',\
	bnd.identity;id='org.fipro.service.modifier.rest',\
	bnd.identity;id='org.fipro.service.modifier.crac',\
	bnd.identity;id='org.fipro.service.modifier.app',\
	bnd.identity;id='org.eclipse.parsson.jakarta.json',\
	bnd.identity;id='com.sun.xml.bind.jaxb-osgi',\
    bnd.identity;id='org.glassfish.jersey.media.jersey-media-multipart',\
	bnd.identity;id='slf4j.simple'
    
-runfw: org.eclipse.osgi
-runee: JavaSE-17
-resolve.effective: active

-runblacklist: \
	bnd.identity;id='org.apache.felix.http.jetty'
-resolve: manual
```

- Update the file _jakartars/app/pom.xml_
  - Add the dependency to the new `crac` module in the `dependencies` section
```xml
<dependency>
  <groupId>org.fipro.service.modifier</groupId>
  <artifactId>crac</artifactId>
  <version>${project.version}</version>
</dependency>
```
  - Add the _app-crac.bndrun_ to the `bnd-resolver-maven-plugin` and the `bnd-export-maven-plugin`

```xml
<build>
  <plugins>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-indexer-maven-plugin</artifactId>
      <configuration>
        <includeJar>true</includeJar>
      </configuration>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-export-maven-plugin</artifactId>
      <configuration>
        <bndruns>
          <bndrun>app.bndrun</bndrun>
          <bndrun>app-crac.bndrun</bndrun>
          <bndrun>debug.bndrun</bndrun>
        </bndruns>
      </configuration>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-resolver-maven-plugin</artifactId>
      <configuration>
        <bndruns>
          <bndrun>app.bndrun</bndrun>
          <bndrun>app-crac.bndrun</bndrun>
          <bndrun>debug.bndrun</bndrun>
        </bndruns>
      </configuration>
    </plugin>
  </plugins>
</build>
```

- Build the application

```
mvn clean verify
```

This will produce a new executable jar _app-crac.jar_ in the folder _jakartars/app/target_. Update the Dockerfiles to copy that jar to the image.

```dockerfile
# copy the application jar to the image
COPY app-crac.jar /app/app.jar
```

__*Note:*__  
There are different ways to organize the code and the files for the containerization in your project. You can put them for example in the _app_ project where the executable jar is created. Or you create an additional folder on top level where the files for the containerization are collected. I personally prefer the separate folder. To ease the process, you can use the `maven-clean-plugin` and the `maven-resources-plugin`.

```xml
<!-- delete copied jar from checkpoint_container folder -->
<plugin>
  <artifactId>maven-clean-plugin</artifactId>
  <version>3.3.2</version>
  <configuration>
    <filesets>
      <fileset>
        <directory>${basedir}/../../checkpoint_container</directory>
        <includes>
          <include>app.jar</include>
          <include>app-crac.jar</include>
        </includes>
      </fileset>
    </filesets>
  </configuration>
</plugin>

<!-- copy resulting executable jar to the checkpoint_container folder -->
<plugin>
  <artifactId>maven-resources-plugin</artifactId>
  <version>3.3.1</version>
  <executions>
    <execution>
      <id>copy-configuration</id>
      <phase>package</phase>
      <goals>
        <goal>copy-resources</goal>
      </goals>
      <configuration>
        <outputDirectory>${basedir}/../../checkpoint_container</outputDirectory>
        <resources>
          <resource>
            <directory>${project.build.directory}</directory>
            <includes>
              <include>app.jar</include>
              <include>app-crac.jar</include>
            </includes>
          </resource>
        </resources>
      </configuration>
    </execution>
  </executions>
</plugin>
```

##### Some hints about the `org.crac` API

1. It uses reflection to load classes either from `javax.crac` or `jdk.crac`
2. It first tries to load the CRaC classes from the package `javax.crac` then from `jdk.crac`. Azul Zulu provides the CRaC classes in the package in `jdk.crac`. You can optimize the loading (and avoid the `ClassNotFoundException` in the back for the classes in the `javax.crac` package) by setting the system property `-Dorg.crac.Core.Compat=jdk.crac`
3. If no CRaC implementation is available, a dummy implementation is used. This way you can add CRaC support to your application without dependencies to a specific implementation at development time, and it also works at runtime if no CRaC implementation is available (e.g. on Windows or a JDK that does not support CRaC).
4. The package `jdk.crac` is in the module `jdk.crac` in the OpenJDK provided by Azul.

##### OpenJ9 CRIU Support / CRaC

OpenJ9 recently added support for using the `org.crac` API. In general it should work to run the application that triggers the checkpoint creation and handles resources via the `org.crac` API from the previous section. At the time writing this blog post, the `jdk.crac` package is contained in the `java.base` module of OpenJ9, and it is not exported and therefore not added to the system packages automatically. To make it work the following entry needs to be added to the _app-crac.bndrun_:

```
-runsystempackages: jdk.crac
```

This is not necessary for OpenJDK CRaC, but does also not cause any trouble there. So we can add it in general to the _app-crac.bndrun_ file.

The OpenJ9 CRIU Support provides several configuration options, that are available via the `CRIUSupport` API (see below). When using the `org.crac` API for checkpoint creation, these options are of course not available in the same way. But there are a number of options that can be set via system properties, e.g. to enable the unprivileged mode.

| System Property | Description |
| ---             | ---         |
| `openj9.internal.criu.unprivilegedMode ` | Controls whether CRIU will be invoked in privileged or unprivileged mode.            |
| `openj9.internal.criu.tcpEstablished` | Controls whether to re-establish TCP connects. |
| `openj9.internal.criu.ghostFileLimit` | Set the size limit for ghost files when taking a checkpoint. File limit can not be greater than 2^32 - 1 or negative. |
| `openj9.internal.criu.logLevel` | Sets the verbosity of log output. Available levels:<br>1. Only errors<br>2. Errors and warnings<br>3. Above + information messages and timestamps<br>4. Above + debug |
| `openj9.internal.criu.logFile` | The name of the file to write log output to. |

We at least need to add `-Dopenj9.internal.criu.unprivilegedMode=true` when starting the application. The Dockerfile for starting the application for checkpoint creation with the OpenJ9 and `org.crac` API would then look like this:

```dockerfile
ARG IMAGE_NAME=icr.io/appcafe/ibm-semeru-runtimes
ARG VERSION=open-21-jre-ubi-minimal

FROM ${IMAGE_NAME}:${VERSION}

ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml \
-Dorg.crac.Core.Compat=jdk.crac \
-Dopenj9.internal.criu.unprivilegedMode=true"

USER root

EXPOSE 8080

# copy the application jar to the image
COPY app-crac.jar /app/app.jar
# copy the file descriptor policies to the image
COPY fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start.sh /app/

# create the folder for the crac files inside the image
RUN \
  mkdir -p /app/checkpoint && \
  chmod 777 /app/checkpoint && \
  chmod 755 /app/start.sh

USER 1001

# start the application for checkpoint creation
WORKDIR /app
CMD ["./start.sh"]
```

#### Programmatic checkpoint creation using the OpenJ9 `CRIUSupport` API

You can directly use the `org.eclipse.openj9.criu.CRIUSupport` API to create a checkpoint. To be able to use it you need to use the `-XX:+EnableCRIUSupport` option on application start.

In the following section we will create a new bundle that creates a checkpoint using the OpenJ9 `CRIUSupport` API, similar to the bundle created in the previous section that uses the `org.crac` API.

- Create a new Maven submodule in the _jakartars_ folder via

```
mvn archetype:generate \
-DarchetypeArtifactId=maven-archetype-quickstart \
-DgroupId=org.fipro.service.modifier \
-DartifactId=criu \
-Dversion=1.0.0-SNAPSHOT \
-Dpackage=org.fipro.service.modifier.criu \
-DinteractiveMode=false
```

- Open the file _jakartars/criu/pom.xml_ and replace the `dependencies` section with the following one:

```xml
<dependencies>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>osgi.core</artifactId>
  </dependency>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>osgi.annotation</artifactId>
  </dependency>
  <dependency>
    <groupId>org.osgi</groupId>
    <artifactId>org.osgi.service.component.annotations</artifactId>
  </dependency>
  <dependency>
    <groupId>org.eclipse.osgi-technology.rest</groupId>
    <artifactId>org.eclipse.osgitech.rest</artifactId>
    <scope>compile</scope>
  </dependency>
  <dependency>
    <groupId>org.apache.felix</groupId>
    <artifactId>org.apache.felix.http.jetty</artifactId>
    <scope>compile</scope>
  </dependency>
</dependencies>
```

- Add the following `build` section:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-baseline-maven-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

- Create a new package `org.fipro.service.modifier.criu.jetty`
- Copy the two classes `JettyBackedWhiteboardComponent` and `JettyServerRunnable` from [org.eclipse.osgitech.rest.jetty](https://github.com/osgi/jakartarest-osgi/tree/main/org.eclipse.osgitech.rest.jetty/src/main/java/org/eclipse/osgitech/rest/jetty) to that package

- Add the following code to `JettyBackedWhiteboardComponent`
  - Add the following snippet at the end of the `activate()` method

  ```java
  Executors.newSingleThreadScheduledExecutor().schedule(() -> {
      if (CRIUSupport.isCRIUSupportEnabled()) {
          new CRIUSupport(Paths.get("checkpoint"))
              .setLeaveRunning(false)
              .setShellJob(true)
              .setFileLocks(true)
              .setTCPEstablished(true)
              .setLogLevel(4)
              .setUnprivileged(true)
              .registerPreCheckpointHook(() -> {
                  if (jettyServer != null && !jettyServer.isStopped()) {
                      logger.info("stop lifecycle");
                      // Stop the connectors only and keep the expensive application running
                      Arrays.asList(jettyServer.getConnectors()).forEach(c -> LifeCycle.stop(c));
                  }
              }, HookMode.CONCURRENT_MODE, 90)
              .registerPostRestoreHook(() -> {
                  if (jettyServer != null && !jettyServer.isStopped()) {
                      logger.info("start lifecycle");
                      Arrays.asList(jettyServer.getConnectors()).forEach(c -> LifeCycle.start(c));
                  }
              }, HookMode.CONCURRENT_MODE, 90)
              .checkpointJVM();
      } else {
          logger.warning("CRIU is not enabled: " + CRIUSupport.getErrorMessage());
      }
  }, 
  10, TimeUnit.SECONDS);
  ```

  The above snippet creates a checkpoint by using the `org.eclipse.openj9.criu.CRIUSupport` APIs
  - Create a new `CRIUSupport` instance, where the parameter defines the directory in which the checkpoint images should be generated.
  - Use the `CRIUSupport` instance methods to configure the checkpoint creation (e.g. `setUnprivileged(true)`)
  - Use `registerPreCheckpointHook()` and `registerPostRestoreHook()` to handle open resources on checkpoint and restore, in our case to close the connectors on checkpoint creation and to open them again on restore.
  - Call `CRIUSupport#checkpointVM()` on the `CRIUSupport` instance to trigger the checkpoint creation.

  ##### OpenJ9 resource handling

  Especially the registration of hooks to handle with open resources is different compared to using the `org.crac` API. Using the `org.crac` API it is possible to register the `Resource` by using static methods. This way the registration is independent of the place where the checkpoint is actually created. Using the OpenJ9 `CRIUSupport` API, the registration needs to be done on the `CRIUSupport` instance that is used to create the checkpoint by using `registerPreCheckpointHook()` and `registerPostRestoreHook()`. The advantage here is that you can have multiple instances of `CRIUSupport` in your application, although I am not sure where this could be helpful in the example. While of course it would be possible to introduce some custom API that allows static registration of hooks, it introduces dependencies that might not be wanted. Using the static `org.crac` API it is possible to registrer a `Resource` where the resource is managed (e.g. the Jetty server instance) without the need to know other code places or additional API. But at the end there are arguments for and against both variants.

  Also note the `HookMode` that is used on `registerPreCheckpointHook()` and `registerPostRestoreHook()`. By default hooks are registered in `SINGLE_THREAD_MODE` which means no other application threads will be active. As an OSGi application highly uses multi-threading (e.g. the declarative services are managed in the additional SCR thread), we need to use the `CONCURRENT_MODE`, which means the hook will be run alongside all other active Java threads. The priority parameter defines the order in which hooks are executed. High-priority hooks are run last before checkpoint, and vice-versa for low-priority hooks.


- Create an additional _app-criu.bndrun_ run file in _jakartars/app_ to build another application variant that contains the OpenJ9 CRIU Support bundle

```
index: target/index.xml;name="app-criu"

-standalone: ${index}

-runsystempackages: org.eclipse.openj9.criu

-runrequires: \
  bnd.identity;id='org.fipro.service.modifier.impl',\
  bnd.identity;id='org.fipro.service.modifier.rest',\
  bnd.identity;id='org.fipro.service.modifier.criu',\
  bnd.identity;id='org.fipro.service.modifier.app',\
  bnd.identity;id='org.eclipse.parsson.jakarta.json',\
  bnd.identity;id='com.sun.xml.bind.jaxb-osgi',\
  bnd.identity;id='org.glassfish.jersey.media.jersey-media-multipart',\
  bnd.identity;id='slf4j.simple'

-runfw: org.eclipse.osgi
-runee: JavaSE-17
-resolve.effective: active

-runblacklist: \
  bnd.identity;id='org.apache.felix.http.jetty'
-resolve: manual
```

__*Note:*__  
Similar to the `jdk.crac` package when using OpenJ9 CRIU Support with `org.crac` API, you need to add the `org.eclipse.openj9.criu` to the system packages, otherwise the special OpenJ9 classes for CRIU support are not found by the OSGi runtime.

- Update the file _jakartars/app/pom.xml_ 
  - Add the dependency to the new `criu` module in the `dependencies` section

```xml
<dependency>
  <groupId>org.fipro.service.modifier</groupId>
  <artifactId>criu</artifactId>
  <version>${project.version}</version>
</dependency>
```

  - Add the _app-criu.bndrun_ to the `configuration` section of the `bnd-resolver-maven-plugin`, the `bnd-export-maven-plugin`, the `maven-clean-plugin` and the `maven-resources-plugin`.

```xml
<build>
  <plugins>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-maven-plugin</artifactId>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-indexer-maven-plugin</artifactId>
      <configuration>
        <includeJar>true</includeJar>
      </configuration>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-export-maven-plugin</artifactId>
      <configuration>
        <bndruns>
          <bndrun>app.bndrun</bndrun>
          <bndrun>app-crac.bndrun</bndrun>
          <bndrun>app-criu.bndrun</bndrun>
          <bndrun>debug.bndrun</bndrun>
        </bndruns>
      </configuration>
    </plugin>
    <plugin>
      <groupId>biz.aQute.bnd</groupId>
      <artifactId>bnd-resolver-maven-plugin</artifactId>
      <configuration>
        <bndruns>
          <bndrun>app.bndrun</bndrun>
          <bndrun>app-crac.bndrun</bndrun>
          <bndrun>app-criu.bndrun</bndrun>
          <bndrun>debug.bndrun</bndrun>
        </bndruns>
      </configuration>
    </plugin>

    <!-- delete copied jar from checkpoint_container folder -->
    <plugin>
      <artifactId>maven-clean-plugin</artifactId>
      <version>3.3.2</version>
      <configuration>
        <filesets>
          <fileset>
            <directory>${basedir}/../../checkpoint_container</directory>
            <includes>
              <include>app.jar</include>
              <include>app-crac.jar</include>
              <include>app-criu.jar</include>
            </includes>
          </fileset>
        </filesets>
      </configuration>
    </plugin>

    <!-- copy resulting executable jar to the checkpoint_container folder -->
    <plugin>
      <artifactId>maven-resources-plugin</artifactId>
      <version>3.3.1</version>
      <executions>
        <execution>
          <id>copy-configuration</id>
          <phase>package</phase>
          <goals>
            <goal>copy-resources</goal>
          </goals>
          <configuration>
            <outputDirectory>${basedir}/../../checkpoint_container</outputDirectory>
            <resources>
              <resource>
                <directory>${project.build.directory}</directory>
                <includes>
                  <include>app.jar</include>
                  <include>app-crac.jar</include>
                  <include>app-criu.jar</include>
                </includes>
              </resource>
            </resources>
          </configuration>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

- Build the application

```
mvn clean verify
```

Without further modification of the parent _pom.xml_ of the example you will get a __Compilation failure__ with the message `package org.eclipse.openj9.criu does not exist`. The reason is that the build is using the `maven-compiler-plugin` with the `release` configuration (if you checked out my `osgi-jakartars` repository). Using the `release` configuration means, it uses the javac `--release` option. And the documentation on this says

> Compiles against the public, supported and documented API for a specific VM version.

With this option the `org.eclipse.openj9.criu` package is not resolved, as it is not declared as a _public, supported and documented_ API. To make the Maven build succeed, add the following `properties` in the parent _pom.xml_

```xml
<maven.compiler.source>17</maven.compiler.source>
<maven.compiler.target>17</maven.compiler.target>
```

and remove the `release` configuration from the `maven-compiler-plugin`.

Running the build again should now succeed and will produce a new executable jar _app-criu.jar_ in the folder _jakartars/app/target_.

- Create a new Dockerfile that uses this jar file and sets the `-XX:+EnableCRIUSupport` option to enable the OpenJ9 CRIU Support

```dockerfile
FROM icr.io/appcafe/ibm-semeru-runtimes:open-21-jre-ubi-minimal

ENV JAVA_OPTS_EXTRA="-XX:+EnableCRIUSupport"

USER root

EXPOSE 8080

# copy the application jar to the image
COPY app-criu.jar /app/app.jar
# copy the shell scripts to the image
COPY start.sh /app/

# create the folder for the checkpoint files and make the start script executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 777 /app/checkpoint && \
  chmod 755 /app/start.sh

USER 1001

# start the application for checkpoint creation
WORKDIR /app
CMD ["./start.sh"]
```

__*Note:*__  
The dependency to `org.eclipse.openj9.criu.CRIUSupport` API has actually two unfortunate dependencies:
- First it is not only a runtime dependency, it is also a compile time dependency. So even while writing code, the `org.eclipse.openj9.criu.CRIUSupport` API needs to be available. This means you need to develop using the OpenJ9 JDK.
- Second, CRIU is a Linux only feature, so you need to develop on Linux, as the `org.eclipse.openj9.criu` package is only available in the OpenJ9 JDK for Linux.

For developers that work on Windows the only option is to use the Windows Subsystem for Linux (WSL). There are at least 3 options to choose from:
- Use VSCode and a devcontainer
- Use VSCode inside the WSL
- Use Eclipse inside the WSL

Further details on this are described in [Developing OpenJ9 CRIU checkpoint creation on Windows](openj9_criu_dev_on_windows.md).

### PID Handling

In the unprivileged mode the goal is to need no additional capabilities or permissions. To make this work the PID is a topic that needs to be considered. Unfortunately it is a bit confusing in the documentation and communication. The [Azul Documentation](https://docs.azul.com/core/crac/crac-guidelines#run-in-container) contains the following note
> In order to restore without additional capabilities (see below), you should make java to be PID 1 process.

But I found [this ticket](https://github.com/openjdk/crac/pull/86) that talks about issues with low PID and the following statement in the description
> By default, if checkpointing, PID is adjusted only if Java's PID is 1 that means Java is run in a container.

Younes Manton [@ymanton](https://github.com/ymanton) from the OpenJ9 team provided me a nice hint on this topic in [this ticket](https://github.com/eclipse-openj9/openj9/issues/18229#issuecomment-1819583191).

> When CRIU restores a checkpointed process the original PID and TIDs of the process must be available. When we run in containers we are in a new (empty) PID namespace, so processes tend to get very low PIDs/TIDs. This is a problem for CRIU because on restore unless you pay close attention to every process that starts and their ordering it's likely that at least some of the required low PIDs/TIDs are taken.

Let's see the different effects.

1. Start the CRaC variant with the following command

```
java -XX:CRaCCheckpointTo=/app/checkpoint -jar /app/app.jar
```

Creating a checkpoint using the `jcmd` will find the PID 9 for example. Restoring the application from the checkpoint might bring up the following error:

```
Error (criu/cr-restore.c:1518): Can't fork for 9: Read-only file system
Error (criu/cr-restore.c:1835): Pid 17 do not match expected 9
Error (criu/cr-restore.c:2605): Restoring FAILED.
```

2. Start the CRaC variant using `exec`

`exec` is a builtin command of the Bash shell which allows you to execute a command that completely replaces the current process, i.e., the current shell process is destroyed, and entirely replaced by the command you specify.

If we change the command to use `exec`, the PID becomes 129 in our example, which seems to be caused by the automatic PID adjustment if Java's PID is 1 (see above).

```
exec java -XX:CRaCCheckpointTo=/app/checkpoint -jar /app/app.jar
```

Unfortunately the `exec` command does not have the desired effect in an Alpine image, so there you will again get the error we have already seen in 1. Also the automatic PID adjustment is not available in the OpenJ9 CRIU Support.

3. Use `-XX:CRaCMinPid={value}`

The JVM flag `-XX:CRaCMinPid={value}` is at the time writing this blog post not documented. I found it by accident via [this ticket](https://github.com/openjdk/crac/pull/86).

```
java -XX:CRaCCheckpointTo=/app/checkpoint -XX:CRaCMinPid=512 -jar /app/app.jar
```

Starting the application in the container with the additional JVM flag on an Ubuntu base image, the PID is 513 and the restore works fine. Trying the same on an Alpine base image results in 

```
Error (criu/pstree.c:404): Current gid 8 intersects with pid (1) in images
```

And you might guess, that this JVM flag is also not available for OpenJ9 CRIU Support.

4. Invoke a dummy command

The only solution that worked across different base images and OpenJDK CRaC vs. OpenJ9 CRIU, is the idea of [@ymanton](https://github.com/ymanton) to invoke a dummy command 1000 times so the Java process can start with PID/TIDs >1000, which on restore are very likely to be free.

```bash
for ((i=0;i<1000;i++))
  do
    /usr/bin/true
done
```

To make this work, create a shell script _start.sh_ to invoke the dummy command in the loop before starting the application. And to avoid a dependency to the runtime in the script, introduce an environment variable in the Dockerfiles.

**Start Script**

```bash
#!/bin/sh

for i in $(seq 1000)
do
    /bin/true
done

java $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar
```

**Azul Zulu OpenJDK with CRaC**
```dockerfile
ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml"

# copy the application jar to the image
COPY app.jar /app/
# copy the file descriptor policies to the image
COPY crac_fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start.sh /app/

# create the folder for the checkpoint files and make the start scripts executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start.sh

# start the application for checkpoint creation
CMD ["./start.sh"]
```

**Azul Zulu OpenJDK with CRaC with automized `jcmd` execution**

- Update the _start_jcmd.sh_ to call the _start.sh_ script instead of executing the Java command directly

```shell
#!/bin/sh
. ./start_create_checkpoint.sh &
. ./start.sh
```

- Update the Dockerfile

```dockerfile
ENV JAVA_OPTS_EXTRA="\
-XX:CRaCCheckpointTo=/app/checkpoint \
-Djdk.crac.resource-policies=/app/fd_policies.yaml"

# copy the application jar to the image
COPY app.jar /app/
# copy the file descriptor policies to the image
COPY crac_fd_policies.yaml /app/
# copy the shell scripts to the image
COPY start_create_checkpoint.sh /app/
COPY start_jcmd.sh /app/
COPY start.sh /app/

# create the folder for the checkpoint files and make the start scripts executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start_jcmd.sh && \
  chmod 755 /app/start.sh && \
  chmod 755 /app/start_create_checkpoint.sh

WORKDIR /app
CMD ["./start_jcmd.sh"]
```

**OpenJ9 CRIU Support**
```dockerfile
ENV JAVA_OPTS_EXTRA="-XX:+EnableCRIUSupport"

# create the folder for the checkpoint files and make the start script executable
RUN \
  mkdir -p /app/checkpoint && \
  chmod 755 /app/start.sh

# start the application for checkpoint creation
CMD ["./start.sh"]
```

### Create a new image with checkpoint data

After the checkpoint is created by starting the application container, we are able to create a new container image with checkpoint data. This can be done via [`docker container commit`](https://docs.docker.com/reference/cli/docker/container/commit/), which creates a new image from a container's changes. Additionally we use the `--change` option so the application is restored from the checkpoint and not started from scratch again.

As a first step you need to get the container id to be able to create a new image from the container with the checkpoint data. As the container is already stopped, you can not use `docker ps` as shown in the Docker documentation. But you can use [`docker container inspect`](https://docs.docker.com/reference/cli/docker/container/inspect/) to get the id 

```
docker container inspect --format="{{.Id}}" application_checkpoint
```

The result of the above command is the container id, which can now be used to create the new image (replace `$CONTAINER_ID` in the following example commands).

**Azul Zulu OpenJDK with CRaC**
To restore the JVM from checkpoint with the OpenJDK CRaC implementation, use the `-XX:CRaCRestoreFrom={PATH}` option. This actually does not start the JVM, it executes CRIU which starts the restored process as its child. Find further information in [Anatomy of CRaC Processes](https://docs.azul.com/core/crac/anatomy).

```
docker container commit \
--change='CMD ["java", "-XX:CRaCRestoreFrom=/app/checkpoint"]' \
$CONTAINER_ID \
application_restore
```

**OpenJ9 CRIU Support**
At the time writing this blog post, OpenJ9 does not support `-XX:CRaCRestoreFrom`. Instead you need to call `criu` directly to restore the process. This works for the `org.crac` support as well as for the OpenJ9 `CRIUSupport`.

```
docker container commit \
--change='CMD ["criu", "restore", "--unprivileged", "-D", "/app/checkpoint", "--shell-job", "-v4", "--log-file=restore.log"]' \
$CONTAINER_ID \
application_restore
```

**_Note:_**  
Remember that you should not run the container for the checkpoint creation with the `--rm` option, as this automatically removes the container when it exits, and then you are not able to create a new image out of it. The checkpoint creation stops the Java application, which typically shuts down the container.

With all this information in place, we are able to create a shell script that executes all of these commands to create a container with checkpoint data without manual interaction.

**Azul Zulu OpenJDK with CRaC**
```shell
#! /bin/bash

CHECKPOINT_NAME=application_checkpoint
RESTORE_NAME=application_restore

# first build the image to create the checkpoint
docker build -t ${CHECKPOINT_NAME} .

# run the container with necessary capabilities
docker run \
-it \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE \
--name ${CHECKPOINT_NAME} \
${CHECKPOINT_NAME}

# get the container id to be able to create a new image from the container with the checkpoint data
CONTAINER_ID=$(docker inspect --format="{{.Id}}" ${CHECKPOINT_NAME})

# create a new image from the previous one that adds the checkpoint files
docker container commit \
--change='CMD ["java", "-XX:CRaCRestoreFrom=/app/checkpoint"]' \
$CONTAINER_ID \
${RESTORE_NAME}

# Delete the checkpoint creation container
docker container rm ${CHECKPOINT_NAME}
# Delete the checkpoint creation image
docker image rm ${CHECKPOINT_NAME}

# Delete the dangling images
docker rmi $(docker images -q --filter "dangling=true")
```

**OpenJ9 CRIU Support**
```shell
#! /bin/bash

CHECKPOINT_NAME=application_checkpoint
RESTORE_NAME=application_restore

# first build the image to create the checkpoint
docker build -t ${CHECKPOINT_NAME} .

# run the container with necessary capabilities
docker run \
-it \
--cap-drop=ALL \
--cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE --cap-add=SETPCAP \
--security-opt seccomp=unconfined \
--name ${CHECKPOINT_NAME} \
${CHECKPOINT_NAME}

# get the container id to be able to create a new image from the container with the checkpoint data
CONTAINER_ID=$(docker inspect --format="{{.Id}}" ${CHECKPOINT_NAME})

# create a new image from the previous one that adds the checkpoint files
docker container commit \
--change='CMD ["criu", "restore", "--unprivileged", "-D", "/app/checkpoint", "--shell-job", "-v4", "--log-file=restore.log"]' \
$CONTAINER_ID \
${RESTORE_NAME}

# Delete the checkpoint creation container
docker container rm ${CHECKPOINT_NAME}
# Delete the checkpoint creation image
docker image rm ${CHECKPOINT_NAME}

# Delete the dangling images
docker rmi $(docker images -q --filter "dangling=true")
```

Executing this script performs all the tasks I described before automatically, and we get an application image with checkpoint data. Additionally it cleans up the container registry at the end.

## Run container with checkpoint data

After the application container image with checkpoint data is created, new containers based on that image can be created, e.g.

**OpenJDK CRaC - Docker from WSL**
```
docker run \
-it \
-p 8080:8080 \
--rm \
--name restore_test \
application_restore:latest
```

__*Note:*__  
Remember that if you are on Windows 11 and use a WSL2 with `networkingMode=mirrored`, the port configuration needs to be replaced with `--network=host`.

**OpenJDK CRaC - Docker Desktop from Windows Host**

Starting a container that uses the Azul Zulu JRE with CRaC on Windows with Docker Desktop fails with a PID error. Although everything is prepared to run in an unprivileged mode, it is necessary on Windows to add the `CHECKPOINT_RESTORE` capability. So the command to start the container needs to look like this

```
docker run ^
-it ^
--rm ^
-p 8080:8080 ^
--cap-add=CHECKPOINT_RESTORE ^
--name restore_test ^
application_restore:latest
```

**OpenJ9 CRIU Support**

Compared to the OpenJDK CRaC implementation, the OpenJ9 CRIU Support needs additional capabilities and security options when starting the application from checkpoint in a container. You basically need the same capabilities and security options as for the checkpoint creastion:

```
docker run \
-it \
--rm \
-p 8080:8080 \
--cap-add=CHECKPOINT_RESTORE \
--cap-add=SYS_PTRACE \
--security-opt seccomp=unconfined \
--name restore_test \
application_restore:latest
```

### Terminal

If you start the restore container now, you probably see the following TTY error:

```
Error (criu/tty.c:843): tty: Can't set tty params on 0x17, trying to skip...: Operation not permitted
```

This error can be neglected. It seems CRIU attempts to restore TTY setting. [@AntonKozlov](https://github.com/AntonKozlov) mentioned that it would be more correct to do this in the CRaC JVM. You can simply ignore the issue, or redirect the stdout and stderr to files. 

The server should be available, but the error might be confusing. The reason is that in unprivileged mode we can't easily re-attach std out/err/in to terminals. In the initial version of the Jakarta-RS Whiteboard Tutorial I used SLF4J Simple Logging provider, which writes the logs to stdout.

The issue can be neglected for OpenJDK CRaC or if you run the OpenJ9 CRIU Support container with an interactive terminal (`-ti`). If you start the OpenJ9 restore container without an interactive terminal, the container will exit immediately because trying to attach to a terminal in unprivileged mode without `-ti` causes an error. 

One solution to this is to tie stdin to /dev/null and redirect stdout and stderr to files, and those files need to be present at the same path on restore. The easiest solution is to just dump them to the checkpoint data dir. (as suggested by [@ymanton](https://github.com/ymanton)).

```shell
. ./start_create_checkpoint.sh &
exec java $JAVA_OPTS $JAVA_OPTS_EXTRA -jar app.jar 0</dev/null 1>/app/crac-files/stdout 2>/app/crac-files/stderr
```

__*Note:*__  
Redirecting std out/err/in to files lead to errors on restore with OpenJDK CRaC, e.g.

```
Error (criu/files-reg.c:2097): File app/checkpoint/stderr has bad size 9521 (expect 9514)
```

So for CRaC we ignore the issue, for OpenJ9 we need to redirect to files.

Other options would be to configure logging to directly write to log files and ensure programmatically that the log files are handled on checkpoint and restore. But this topic actually extends the scope of this blog post, so I will not cover it further here.

## Troubleshooting

In case of troubles on creating the checkpoint, you often need to check the checkpoint logfiles for additional information. If the container is not yet closed as a result of checkpoint exception, you can simply connect to the container via [docker container exec](https://docs.docker.com/reference/cli/docker/container/exec/).

**Ubuntu / UBI based images**
```
docker exec -ti application_checkpoint /bin/bash
```

**Alpine based images**
```
docker exec -ti application_checkpoint /bin/ash
```

You can then check for the log files via `cat`

**Azul Zulu CRaC**
```
cat checkpoint/dump4.log
```

**OpenJ9 CRIU Support**
```
cat checkpoint/criu.log
```

If the container is closed before you can connect to it, you can perform the checkpoint creation steps manually either by calling the `jcmd` or the _start.sh_ script manually, to be able to inspect the logs:

1. Create the checkpoint container

    ```
    docker build -t application_checkpoint .
    ```

2. Run it with a different start command in interactive mode
    ```
    docker run \
    -it \
    --rm \
    --cap-add=CHECKPOINT_RESTORE --cap-add=SYS_PTRACE \
    --name application_checkpoint \
    application_checkpoint:latest \
    /bin/bash
    ```

3. Start the application
   
   **Script that uses `jcmd`**
   ```
   ./start_jcmd.sh
   ```
   
   **Start script with application that uses programmatic checkpoint creation**
   ```
   ./start.sh
   ```

4. After a failure, check the logs (see above)

### OpenJ9 checkpoint creation failures

If the checkpoint creation with OpenJ9 fails with errors like this

```
suspending seccomp failed: Operation not permitted
```

It indicates that seccomp is not disabled inside the container. Ensure that `--security-opt seccomp=unconfined` is set on starting the container.

If it happens even though `--security-opt seccomp=unconfined` is set, you might run into an issue with WSL2 and `networkingMode=mirrored`. In this mode the seccomp configuration is not working, as the mirrored networking mode requires registering some seccomp filters and the presence of those filters is causing issues in generating the checkpoint. I have [created a GitHub Issue](https://github.com/microsoft/WSL/issues/10981) to get the issue hopefully addressed someday.

Until this get solved, the only solution to get a checkpoint created in a container on Windows, is to switch back to `networkingMode=NAT`.

If you have not heard about the WSL2 networking mode, here are some resources about it:
- [Accessing network applications with WSL - Mirrored mode networking](https://learn.microsoft.com/en-us/windows/wsl/networking#mirrored-mode-networking)
- [Advanced settings configuration in WSL - Configuration settings for .wslconfig](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configuration-settings-for-wslconfig)

### Build the containers on Windows host with Podman  

If you want to build the containers with Podman on a Windows host (which means you have Podman Desktop installed) you need to use the `--network host` parameter so the container is able to communicate to the outside world. Otherwise you will get an error similar to the following, when trying to install packages in the container:

```
fetch https://dl-cdn.alpinelinux.org/alpine/v3.20/community/x86_64/APKINDEX.tar.gz
WARNING: fetching https://dl-cdn.alpinelinux.org/alpine/v3.20/community: temporary error (try again later)
```

You also need to disable the default seccomp profile on running the container for checkpoint creation to avoid `Operation not permitted` errors (similar to OpenJ9).

## Checkpoint Costs

Comparing timestamps on startup, we see that from starting the container until the last entry related to starting the server and registering the resources (before the checkpoint logs), it takes around 3 to 4 seconds until the containerized application is ready. And on restoring the application the container the time between `docker run` and the application is ready, is about 500ms.

__*Note:*__  
I measured the startup time by printing a timestamp before calling `docker run` and comparing the timestamp with a log entry that shows that the application is ready. The measurement therefore also includes the container startup time, which is the reason why the number is probably bigger than shown in the measurements in other blog posts and documentations.

But the improved startup time does of course come with some costs. In this case the cost of additional disk space. A fact that is not mentioned. Probably because it seems to be obvious that checkpoint files need space on the disk. As this was one of the first questions I got asked when talking about CRaC and CRIU, here is the table to compare the image sizes.

|Base Image                | Size w/o checkpoint | Size with checkpoint |
|:---                      |                 ---:|                  ---:|
| Azul Zulu / Ubuntu / JDK |                495MB|                 645MB|
| Azul Zulu / Ubuntu / JRE |                376MB|                 519MB|
| Azul Zulu / Alpine / JRE |                257MB|                 399MB|
| OpenJ9 / UBI / JDK       |                572MB|                 661MB|
| OpenJ9 / UBI / JRE       |                356MB|                 444MB|

For the OpenJDK CRaC the checkpoint image files are around 130 - 150 MB.
For the OpenJ9 CRIU Support the checkpoint image files are around 90 MB.

While testing I noticed that the size varies if I run the checkpoint process multiple times.

## Further Information / Link Collection

In the following section I collected the links to documentations and blog posts.

### CRaC

- [CRaC @Github](https://github.com/CRaC)
- [CRaC Introduction @Azul](https://www.azul.com/products/components/crac/)
- [CRaC Documentation @Azul](https://docs.azul.com/core/crac/crac-introduction)
- [How to Run a Java Application with CRaC in a Docker Container](https://foojay.io/today/how-to-run-a-java-application-with-crac-in-a-docker-container/)
- [What the CRaC (Gerrit Grunwald at Voxxed Athens)](https://www.youtube.com/watch?v=Y9sEXOGlvoA)
- [What the CRaC - Superfast JVM startup @slideshare](https://www.slideshare.net/slideshow/what-the-crac-superfast-jvm-startup-252967592/252967592)

### OpenJ9 CRIU

- [OpenJ9 CRIU Support](https://eclipse.dev/openj9/docs/criusupport/)
- [Fast JVM startup with OpenJ9 CRIU Support](https://blog.openj9.org/2022/09/26/fast-jvm-startup-with-openj9-criu-support/)
- [Getting started with OpenJ9 CRIU Support](https://blog.openj9.org/2022/09/26/getting-started-with-openj9-criu-support/)
- [Unprivileged OpenJ9 CRIU Support](https://blog.openj9.org/2022/09/29/unprivileged-openj9-criu-support/)
- [OpenJ9 CRIU Support: A look under the hood](https://blog.openj9.org/2022/10/14/openj9-criu-support-a-look-under-the-hood/)
- [OpenJ9 CRIU Support: A look under the hood (part II)](https://blog.openj9.org/2022/10/14/openj9-criu-support-a-look-under-the-hood-part-ii/)
- [How We Developed the Eclipse OpenJ9 CRIU Support for Fast Java Startup](
https://foojay.io/today/how-we-developed-the-eclipse-openj9-criu-support-for-fast-java-startup/)
- [How to package your cloud-native Java application for rapid startup](https://openliberty.io/blog/2023/06/29/rapid-startup-instanton.html)
- [How to containerize your Spring Boot application for rapid startup](https://openliberty.io/blog/2023/09/26/spring-boot-3-instant-on.html)

### Frameworks with CRaC / CRIU Support

- [Spring Framework - JVM Checkpoint Restore](https://docs.spring.io/spring-framework/reference/integration/checkpoint-restore.html)
- [SpringBoot 3.2 + CRaC @foojay.io](https://foojay.io/today/springboot-3-2-crac/)
- [Micronaut CRaC](https://guides.micronaut.io/latest/tag-crac.html)
- [Quarkus AWS Lambda SnapStart Configuration](https://quarkus.io/guides/aws-lambda-snapstart)
- [Open Liberty InstantOn](https://openliberty.io/docs/latest/instanton.html)
- [Sustainable Java Applications With Quick Warmup](https://dzone.com/articles/sustainable-java-applications-with-quick-warmup)

### Discussions on GitHub Issues

These are the tickets in which I had quite some discussion about CRaC and CRIU with the experts. Again many thanks to [@AntonKozlov](https://github.com/AntonKozlov), [@HanSolo](https://github.com/HanSolo), [@tajila](https://github.com/tajila), [@tjwatson](https://github.com/tjwatson), [@ymanton](https://github.com/ymanton) and everyone else from the Azul and OpenJ9 support.

- [GitHub Ticket @OpenJ9](https://github.com/eclipse-openj9/openj9/issues/18229)
- [GitHub Ticket @OSGi](https://github.com/osgi/osgi/issues/631)
