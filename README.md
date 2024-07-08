# Example for using the OSGi Whiteboard Specification for Jakarta™ RESTful Web Services

This repository contains an example to show how to create a REST-based service out of an OSGi service by using the 
[Whiteboard Specification for Jakarta™ RESTful Web Services](https://docs.osgi.org/specification/osgi.cmpn/8.1.0/service.jakartars.html)
and the [OSGi Technology Whiteboard Implementation for Jakarta RESTful Web Services](https://github.com/osgi/jakartarest-osgi) reference implementation.

There are blog posts related to this repository that explain the details:  
- [Build REST services with the OSGi Whiteboard Specification for Jakarta™ RESTful Web Services](https://vogella.com/blog/build-rest-services-with-osgi-jakarta-rs-whiteboard/)
- [CRaCin` your OSGi application - start so fast I want to CRIU](https://vogella.com/blog/cracin-your-osgi-application/)

## Build Images with CRaC Support

This repository also contains sources to create container images with checkpoints, to increase the startup time.

First you need to build the application from the commandline in the repository root folder via

```
mvn clean verify -f jakartars/pom.xml
```

Once the build succeeds, the application jar files are copied to the *checkpoint_container* folder. You can now execute the *build_\** scripts, to create different types of images, either via __*Docker*__ oder __*Podman*__.

For example:

**Build Application Container Image with Azul Zulu JRE on Ubuntu (Docker)**

```
./build_crac.sh docker ubuntu_jre
```

**Build Application Container Image with OpenJ9 JRE on UBI (Podman)**

```
./build_criu.sh podman ubi_crac_jre
```