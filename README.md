![Docmosis](https://raw.githubusercontent.com/docmosis/tornado-docker/master/images/docmosis.png)

# Getting Started with Tornado Using Docker

## Introduction

Running Tornado using Docker is a simple way to get up and running quickly.
Tornado can be launched via Docker with only a few steps with a default
configuration and can also fully configured via the launching process.

This guide assumes the user is already familiar with Docker and focuses on the
Docmosis Tornado specifics.

## Contents

- [Running Tornado using Docker](#running-tornado-using-docker)
- [Container Settings](#container-settings)
  - [Logging outside of the Docker Container](#logging-outside-of-the-docker-container)
  - [Enabling Debug Logging](#enabling-debug-logging)
- [Running Tornado using Docker Compose](#running-tornado-using-docker-compose)
- [Running the Server and Testing](#running-the-server-and-testing)
  - [Creating Dummy Data](#creating-dummy-data)
  - [Creating a Document](#creating-a-document)
- [Generating Documents from Your Application](#generating-documents-from-your-application)
  - [Comparing Tornado with Docmosis Cloud](#comparing-tornado-with-docmosis-cloud)
- [Monitoring Tornado](#monitoring-tornado)
- [More Help](#more-help)
- [All Configuration Options](#all-configuration-options)
  - [Common Settings](#common-settings)
  - [Control of Logging](#control-of-logging)
  - [Enabling SSL/TLS Encryption](#enabling-ssltls-encryption)
  - [Enabling Email from Tornado](#enabling-email-from-tornado)
- [License](#license)

## Running Tornado using Docker

The following steps will create a running Tornado server for you to work with.

1. Obtain a Tornado Trial license key from
   https://www.docmosis.com/try/tornado.html

2. Create a folder on your computer (the docker host) where you will put your
   Docmosis templates. We will map this to a folder inside the Docker container
   and Tornado will find templates you place into this folder.

3. Build the Docmosis Tornado Docker image:

   Main choice based on Fedora:<br>
   `docker build --tag docmosis/tornado https://raw.githubusercontent.com/docmosis/tornado-docker/master/Dockerfile`

   Alternative choice based on Red Hat Universal Base Image (UBI):<br>
   `docker build --tag docmosis/tornado https://raw.githubusercontent.com/docmosis/tornado-docker/master/Dockerfile-ubi9`

4. Launch a Tornado container as follows, inserting your license key and path to
   templates folder.

For example, in **Linux** to use a folder `/home/docmosisTemplates` with a
Tornado host running on port 8080:

Linux Shell:

    docker run -p 8080:8080 \
      -v /home/docmosisTemplates:/home/docmosis/templates \
      -e DOCMOSIS_KEY=XXXX-XXXX-XXXX-XXXX-X-XXXX \
      -e DOCMOSIS_SITE="Free Trial Tornado" \
      -e DOCMOSIS_ADMINPW=xxxmypwxxx \
      docmosis/tornado

For example, in **Windows** to use a folder C:\docmosisTemplates with a Tornado
host running on port 8080:

Using Windows CMD:

    docker run -p 8080:8080 ^
      -v C:\docmosisTemplates:/home/docmosis/templates ^
      -e DOCMOSIS_KEY=XXXX-XXXX-XXXX-XXXX-X-XXXX ^
      -e DOCMOSIS_SITE="Free Trial Tornado" ^
      -e DOCMOSIS_ADMINPW=xxxmypwxxx ^
      docmosis/tornado

Using Windows PowerShell:

    docker run -p 8080:8080 `
      -v C:\docmosisTemplates:/home/docmosis/templates `
      -e DOCMOSIS_KEY=XXXX-XXXX-XXXX-XXXX-X-XXXX `
      -e DOCMOSIS_SITE="Free Trial Tornado" `
      -e DOCMOSIS_ADMINPW=xxxmypwxxx `
      docmosis/tornado

## Container Settings

The Docmosis Tornado Docker synopsis is (Linux style commands are used from here
on):

    docker run --name [container name] \
      -p [host port]:8080 \
      -v [host templates directory]:/home/docmosis/templates \
      -e DOCMOSIS_KEY=[license key] \
      -e DOCMOSIS_SITE=[license site] \
      -e DOCMOSIS_ADMINPW=xxxmypwxxx \
      docmosis/tornado

    Parameters:
      --name  The name of the container (default: auto generated).
      -p      The port mapping of the host port to the container port.
              Port 8080 is used for both the REST service and the web console.
      -v      The absolute path to your templates directory on the host system.
      -e      Set environment variables inside the container.

The -e flag can be used multiple times to set different configuration values as
shown by the examples and the synopsis above. There are a lot of parameters that
can be configured, as detailed in the section titled **[All Configuration
Options](#all-configuration-options)** below. Some examples are listed here for
typical use-cases.

### Logging outside of the Docker Container

The Tornado container will by default log to console. You may instead wish to have the logs
written to a file outside of the Docker container so they are accessible (and
persistent). To write the logs to file, you can override the configuration
to a blank value, and then map a volume to the default log folder
`/home/docmosis/workingarea/logs`.

To set the logging to write outside the container:

    docker run --name [container name] \
      -p [host port]:8080 \
      -v [host templates directory]:/home/docmosis/templates \
      -e DOCMOSIS_KEY=[license key] \
      -e DOCMOSIS_SITE=[license site] \
      -e DOCMOSIS_JAVA_LOGGING_CONFIG_FILE= \
      -v [host logging directory]:/home/docmosis/workingarea/logs \
      docmosis/tornado

### Enabling Debug Logging

To have more detailed logging enable debug by setting the log level as follows:

    docker run --name [container name] \
      -p [host port]:8080 \
      -v [host templates directory]:/home/docmosis/templates \
      -e DOCMOSIS_KEY=[license key] \
      -e DOCMOSIS_SITE=[license site] \
      -e DOCMOSIS_LOG_LEVEL=DEBUG
      docmosis/tornado

## Running Tornado using Docker Compose

It can be useful to define the launch configuration in a Docker Compose file.
The following content could be placed in your docker-compose.yml file:

    version: '3.3'

    services:

      tornado:
        build: https://raw.githubusercontent.com/docmosis/tornado-docker/master/Dockerfile
        ports:
         - "[host port]:8080"
        volumes:
         - [host templates directory]:/home/docmosis/templates
        environment:
          DOCMOSIS_KEY: "[license key]"
          DOCMOSIS_SITE: "[license site]"
          DOCMOSIS_ADMINPW: "[admin password]"
          

## Running the Server and Testing

When Docmosis Tornado has started successfully, you can point your browser to
Docker container to use the Tornado Web Console. If Tornado has started
successfully, you will be navigated to the Status tab and the engine status will
be Running. In this screen you can select templates and run test data to
generate Documents. This is a useful test-platform that can assist development
before generating documents via the API.

![Docmosis Tornado Status
Page](https://raw.githubusercontent.com/docmosis/tornado-docker/master/images/status.png)

If the start up is not succesful review the ouput logged from the Docker
command. This will typically indicate what has gone wrong.

The configuration that Tornado has started with can also be viewed via the
configuration tab of the Web Console should you need to debug the settings are
being correctly applied.

### Creating Dummy Data

From the Tornado Status Page can create dummy data (either JSON or XML) based on
the template you have selected. Tornado queries the template for fields and has
its "best guess" at creating data that matches the template.

Templates can contain complicated structures for repeating and nested data, so
you may need to adjust the generated data structure so that it looks like your
expected data.

Tornado will generate data values: "value1", "value2" and so on – which you can
change to look more like your data.

### Creating a Document

You can create a document from the Tornado Status Page.

If you render a PDF only and your browser is configured with a PDF viewer, the
output file will be displayed in the browser panel on the right.

If you choose any other formats, or combinations of formats, you will receive
the rendered document as a download.

## Generating Documents from Your Application

The Tornado Status Page displays the Render URL to use for calling the Render
service (just below the Engine status).

This is the URL to use with your client code / libraries to request documents to
be rendered.

You should refer to the Tornado Web Services Guide in the Resources area of the
Docmosis site https://www.docmosis.com/resources/tornado.html for details about
invoking the render service.

### Comparing Tornado with Docmosis Cloud

Note that Docmosis Tornado provides only the render service. The Docmosis Cloud
service provides other services to support producing documents in a cloud
environment. The render service is identical to that provided by the cloud
service except for:

1. The URL is different - you will direct the requests to your local Docmosis
   Tornado server instead of the public Cloud Service

2. The following REST web services are provided (more details are provided in
   the Tornado Web Services Guide):

   a. "render" – create a document

   b. "getTemplateStructure" – get a JSON description of the structure of a
   template

   c. "convert" – convert the supplied document to another format (without any
   data merging)

   d. "ping" and "status" – determine the Tornado operational status

3. Store-to directives for cloud and AWS (Amazon S3) storage are not available

4. REST clients do not need to supply an access key (unless you set one in the
   configuration tab)

5. Emailing documents is supported as long as you have configured an email
   gateway into Docmosis Tornado configuration

## Monitoring Tornado

Tornado includes two web service end-points to support automated monitoring:

"ping" e.g. http://localhost:8080/api/ping

"status" e.g. http://localhost:8080/api/status

See the Tornado Web Services Guide for details about these monitoring
end-points.

## More Help

Docmosis document generation provides a large number of features controlled from
both the templates and from the data. To get the most out of Docmosis, please
read the Developer Guide and Template Guides on the Docmosis web site under the
Resources area:

https://www.docmosis.com/resources/all-resources.html

We hope you enjoy using Tornado.

## All Configuration Options

### Common Settings

The following settings can be added to the Custom Settings on the Configuration
page to enable

- `port`  
  Specify the port on which the console and the web services will listen

  ```
  docker run -p 8080:8090 \
   -e DOCMOSIS_PORT=8090 \
   ...
  ```

- `license`  
   Specify the Tornado license all as one string. This includes the key and the
  site and overrides the key and site parameters below. "\n" is used to provide
  separate lines.

  ```
  docker run \
   -e DOCMOSIS_LICENSE="docmosis.key=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-X-XXXX\ndocmosis.site=Free Trial Tornado" \
   ...
  ```

- `key`  
   Specify the key part of the Tornado license. This requires the site or site1-3 parameters also.

  ```
  docker run \
  -e DOCMOSIS_KEY=XXXX-XXXX-XXXX-XXXX-X-XXXX \
  -e DOCMOSIS_SITE="Free Trial Tornado" \
  ...
  ```

  or

  ```
  docker run \
  -e DOCMOSIS_KEY=XXXX-XXXX-XXXX-XXXX-X-XXXX \
  -e DOCMOSIS_SITE1="Free Trial Tornado" \
  -e DOCMOSIS_SITE2="next line of site string" (if required)" \
  -e DOCMOSIS_SITE3="another line of site string" (if required)" \
  ...
  ```

- `site`  
   The full site string using "\n" to specify multiple lines as require (if key
  is multiple lines). Overrides the site1..site3 parameters and requires the
  key parameter.

- `site1`  
  Specify the first line of the site

- `site2`  
  Specify the second line of the site (if required)

- `site3`  
  Specify the third line of the site (if required)

- `officeDir`  
  Specify the office install location for LibreOffice

  ```
  docker run \
   -e DOCMOSIS_OFFICEDIR=/opt/libreoffice \
   ...
  ```

- `templatesDir`  
  Specify where templates will be sourced from (original templates)

  ```
  docker run \
   -e DOCMOSIS_TEMPLATESDIR=/home/docmosis/templates \
   ...
  ```

- `workingDir`  
   Specify where logs and working caches are to be stored

  ```
  docker run \
   -e DOCMOSIS_WORKINGDIR=/home/docmosis/workingarea \
   ...
  ```

- `allowUNCPaths`  
   Allow paths to be configured that are UNC paths.

  ```
  docker run \
   -e DOCMOSIS_ALLOWUNCPATHS=true \
   ...
  ```

- `adminPw`  
  Specify the admin password for access the web console. Optional.

  ```
  docker run \
   -e DOCMOSIS_ADMINPW=password \
   ...
  ```

- `adminPwAllowBlank`  
  Allow the password to be blank (assumes deployed in otherwise secured environment). Optional.

  ```
  docker run \
   -e DOCMOSIS_ADMINPWALLOWBLANK=true \
   ...
  ```

- `accessKey`  
  Specify the access key for calling the web service end points. Optional.

  ```
  docker run \
   -e DOCMOSIS_ACCESSKEY=access-key \
   ...
  ```

- `customSettings`  
  Specify any custom settings using the format key=value and separating settings
  by "\n".

  ```
  docker run \
   -e DOCMOSIS_CUSTOMSETTINGS="docmosis.xyz=abc\ndocmosis.xyz.2=def" \
   ...
  ```

- `templatePrefix`  
  Specify the template field prefix. Defaults to <<. Must be at least 2 chars.

  ```
  docker run \
   -e DOCMOSIS_TEMPLATEPREFIX=<< \
   ...
  ```

- `templateSuffix`  
  Specify the template field suffix. Defaults to >>. Must be at least 2 chars.

  ```
  docker run \
   -e DOCMOSIS_TEMPLATESUFFIX=>> \
   ...
  ```

- `installSamples`  
  Specify whether to install sample templates at startup. Defaults to true.

  ```
  docker run \
   -e DOCMOSIS_INSTALLSAMPLES=false \
   ...
  ```

### Control of Logging

Logging of information by Tornado can be controlled by several command line
settings:

- `log.level=debug|info|error`  
  Specify the level of logging to the console and log files.

  ```
  docker run \
   -e DOCMOSIS_LOG_LEVEL=debug= \
   ...
  ```

- `java.util.logging.config.file=path`  
  Specify the Java Util logging configuration file. Overrides log.level.

  ```
  docker run \
   -e DOCMOSIS_JAVA_UTIL_LOGGING_CONFIG_FILE=/home/docmosis/logging.properties \
   ...
  ```

- `log.dir.override`  
  Override the location where logs are to be written (default is `[working area]/logs`)

  ```
  docker run \
   -e DOCMOSIS_LOG_DIR_OVERRIDE=/home/docmosis/workingarea/logs \
   ...
  ```

### Enabling SSL/TLS Encryption

The following settings can be added to the Custom Settings on the Configuration
page to enable SSL/TLS Encryption:

- `ssl.port=port`  
  The port to listen for secured connections.

- `javax.net.ssl.keyStore=path`  
  The path to the key store file.

- `javax.net.ssl.keyStorePassword=password`  
  The key store file password.

- `javax.net.ssl.trustStore=path`  
  The path to the trust store file.

- `javax.net.ssl.trustStorePassword=password`  
  The trust store file password.

- `http.disable=true|false`  
  Determines whether the non-secure listener should be disabled. Defaults to
  false.

  ```
  docker run -p 8081:8081 \
   -e DOCMOSIS_SSL_PORT=8081 \
   -e DOCMOSIS_JAVAX_NET_SSL_KEYSTORE=/home/docmosis/keystore \
   -e DOCMOSIS_JAVAX_NET_SSL_KEYSTOREPASSWORD=password \
   -e DOCMOSIS_JAVAX_NET_SSL_TRUSTSTORE=/home/docmosis/truststore \
   -e DOCMOSIS_JAVAX_NET_SSL_TRUSTSTOREPASSWORD=password \
   -e DOCMOSIS_HTTP_DISABLE=true \
   ...
  ```

Please see your Java documentation for more information on the specifics of what
these settings do.

### Other Network Settings

The following settings provide network specific adjustments:

- `address.listen=<address>`  
  The network address on which to listen for requests. Defaults to
  all networks (0.0.0.0).

- `keepAlive=true|false`  
  Specify whether to set keep alive on network connections. This useful
  in environments where network infrastructure agressively closes idle
  connections. (eg long running renders in Azure). Defaults to false.

### Enabling Email from Tornado

- `mailEnabled`  
  Enable the mail server. Default is false.

- `mailHost`  
  The mail server hostname

- `mailPort`  
  The mail server port

- `mailUser`  
  The mail server user name

- `mailPw`  
  The mail server password

- `mailFrom`  
  The from email address

- `mailTimeout`  
  The mail server connect-timeout in milliseconds

- `mailUseTls`  
  Enable TLS security on the connection to the mail server. Default false.

- `mailUseSsl`  
  Enable SSL security on the connection to the mail server. Default false.

- `mailSecurityProtocols`  
  Specify the security protocols to use (comma separated) (default TLSv1.2.  Blank value means use JVM default).

- `mailConnectRetryMaxTimes`  
  Set the maximum number of attempts to connect to the mail server.
  Default 2.

- `mailConnectRetryMinWaitMillis`  
  Set the minimum wait time to get a connection to the mail server.
  Default 5000ms.

- `mailConnectRetryMaxWaitMillis`  
  Set the maximum wait time to get a connection to the mail server.
  Default 20000ms.

- `mailConnectRetryRebuildTransport`  
  Rebuild the Message Transport object on failure to connect. Default
  true.

- `mailSendRetryMaxTimes`  
  Set the maximum number of attempts to send email. Default 2.

- `mailCustomHeadersAdd`  
  Add a custom mail header. Default true.

- `mailCustomHeadersName`  
  Set the custom header name. Default X-DWS-Tag-1

  ```
  docker run \
   -e DOCMOSIS_MAILENABLED=true \
   -e DOCMOSIS_MAILHOST=example.com \
   -e DOCMOSIS_MAILPORT=25 \
   -e DOCMOSIS_MAILUSER=user \
   -e DOCMOSIS_MAILPW=password \
   -e DOCMOSIS_MAILFROM=user@example.com \
   -e DOCMOSIS_MAILTIMEOUT=60000 \
   -e DOCMOSIS_MAILUSETLS=true \
   -e DOCMOSIS_MAILUSESSL=true \
   ...
  ```

## License

By downloading Tornado you agree to our most recent [License Agreement
(PDF)](https://www.docmosis.com/download/DocmosisLicenseAgreement.pdf).

As with all Docker images, these likely also contain other software which may be
under other licenses (such as Bash, etc from the base distribution, along with
any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to
ensure that any use of this image complies with any relevant licenses for all
software contained within.
