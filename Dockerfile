###############################################################################
# THIS IS AN EXAMPLE
#
# Example Dockerfile showing one way to run Tornado.
# Adjust components and configuration to suit your own environment,
# standards, and operational requirements.
#
# Note: the Tornado Console password must be set or explicitly disabled
#       (see commented settings near the bottom of this file).
#       Without a password set, security of the configuration and operation
#       of Tornado relies heavily on local network and host security.
###############################################################################

###############################################################################
# Base image
#
# Fedora is used here as an example base image.
# Choose the Linux distribution that best fits your environment and standards.
###############################################################################

FROM fedora:42

###############################################################################
# System packages and runtime dependencies
###############################################################################

RUN dnf update -y \
    && dnf install -y --setopt=tsflags=nodocs \
    java-21-openjdk \
    \
    # LibreOffice requirements
    cairo \
    cups-libs \
    dbus-glib \
    glib2 \
    libSM \
    libXinerama \
    mesa-libGL \
    \
    # Font and archive utilities
    cabextract \
    curl \
    unzip \
    wget \
    && dnf clean all

###############################################################################
# Fonts
###############################################################################

RUN dnf install -y --setopt=tsflags=nodocs \
    open-sans-fonts \
    gnu-free-mono-fonts \
    gnu-free-sans-fonts \
    gnu-free-serif-fonts \
    && dnf clean all

# Use the community mscorefonts installer for Microsoft core fonts,
# since these are not provided directly as standard Linux packages.
RUN dnf install -y \
    https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm \
    && dnf clean all

# mscorefonts2 does not currently install cambria.ttc
RUN wget --show-progress -O PowerPointViewer.exe http://downloads.sourceforge.net/mscorefonts2/PowerPointViewer.exe \
    && cabextract --lowercase -F 'ppviewer.cab' PowerPointViewer.exe \
    && cabextract --lowercase -F '*.ttc' --directory=/usr/share/fonts/msttcore ppviewer.cab \
    && rm -f PowerPointViewer.exe ppviewer.cab

###############################################################################
# LibreOffice
###############################################################################

ENV LIBREOFFICE_VERSION=7.5.9.2
ENV LIBREOFFICE_MIRROR=https://s3.us-west-2.amazonaws.com/com.docmosis.public.download.archive/downloads/libreoffice/
ENV LIBREOFFICE_ARCHIVE=LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_Collabora-Build.rpm.tar.gz

RUN wget --show-progress ${LIBREOFFICE_MIRROR}${LIBREOFFICE_ARCHIVE} \
    && tar -xf ${LIBREOFFICE_ARCHIVE} \
    && cd LibreOffice_*_Linux_x86-64_rpm/RPMS \
    && (rm -f *integ* || true) \
    && (rm -f *desk* || true) \
    && dnf install -y --setopt=tsflags=nodocs *.rpm \
    && dnf clean all \
    && cd ../.. \
    && rm -rf LibreOffice_*_Linux_x86-64_rpm \
    && rm -f LibreOffice_*_Linux_x86-64_rpm.tar.gz \
    && ln -s /opt/libreoffice* /opt/libreoffice

###############################################################################
# Application user and working directory
###############################################################################

RUN groupadd docmosis \
    && useradd -g docmosis \
    --create-home \
    --shell /sbin/nologin \
    --comment "Docmosis user" \
    docmosis

WORKDIR /home/docmosis

###############################################################################
# Tornado application
###############################################################################

ENV DOCMOSIS_VERSION=2.10.3

RUN DOCMOSIS_VERSION_SHORT=$(echo $DOCMOSIS_VERSION | cut -f1 -d_) \
    && wget --show-progress https://resources.docmosis.com/SoftwareDownloads/Tornado/${DOCMOSIS_VERSION_SHORT}/docmosisTornado${DOCMOSIS_VERSION}.zip \
    && unzip docmosisTornado${DOCMOSIS_VERSION}.zip docmosisTornado*.war docs/* licenses/* \
    && mv docmosisTornado*.war docmosisTornado.war \
    && rm -f docmosisTornado${DOCMOSIS_VERSION}.zip

###############################################################################
# Java logging
###############################################################################

# Default Java logging configuration.
# This can be overridden at runtime using DOCMOSIS_JAVA_LOGGING_CONFIG_FILE.
RUN printf '%s\n' \
    "handlers=java.util.logging.ConsoleHandler" \
    "#Normal logging at INFO level" \
    ".level=INFO" \
    "" \
    "#Detailed logging at DEBUG level" \
    "#.level=FINE" \
    "" \
    "java.util.logging.ConsoleHandler.level=FINE" \
    "java.util.logging.ConsoleHandler.formatter=com.docmosis.webserver.launch.logging.TornadoLogFormatter" \
    'com.docmosis.webserver.launch.logging.TornadoLogFormatter.format=%1$tF %1$tT,%1$tL [%2$s] %3$s %4$s - %5$s %6$s%n' \
    > /home/docmosis/javaLogging.properties

###############################################################################
# Init / process handling
###############################################################################

# Add tini to manage zombie/defunct processes since the Java process has pid=1.
# If using "docker run" you can use the "--init" parameter which uses tini directly.
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

###############################################################################
# Tornado runtime configuration
###############################################################################

USER docmosis

# Create the default templates directory used when sourcing templates
# from a local directory configuration.
# Create the default working area used for logs and other runtime files.
RUN mkdir /home/docmosis/templates /home/docmosis/workingarea

ENV DOCMOSIS_OFFICEDIR=/opt/libreoffice \
    DOCMOSIS_TEMPLATESDIR=templates \
    DOCMOSIS_WORKINGDIR=workingarea \
    LANG=C.UTF-8

# Key runtime settings such as license, site, and admin password are
# typically supplied when the container is started.
#ENV DOCMOSIS_KEY=
#ENV DOCMOSIS_SITE=
#ENV DOCMOSIS_ADMINPW=

# Allow blank password if local network and host security remove the need.
#ENV DOCMOSIS_ADMINPWALLOWBLANK=true

# Allow UNC paths in Tornado configuration.
# Disabled by default because of the inherent security risk.
#ENV DOCMOSIS_ALLOWUNCPATHS=true

###############################################################################
# Container interface
###############################################################################

EXPOSE 8080

# Templates are typically provided by mounting a host directory to this path.
VOLUME /home/docmosis/templates

CMD ["java", "-Dport=8080", "-Djava.util.logging.config.file=javaLogging.properties", "-Ddocmosis.tornado.render.useUrl=http://localhost:8080/", "-jar", "docmosisTornado.war"]