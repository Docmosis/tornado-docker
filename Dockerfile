# This is a example Dockerfile showing one way to get Tornado running.  Components can and should
# be varied as required in accordance with local policies and procedures.
#
# Note: the Tornado Console password must be set or explicitly disabled (see
#       commented out settings near the bottom of this file).
#       Without a password set, security of the configuration and operation of Tornado relies heavily
#       on local network/host security.


FROM fedora:latest

# epel for cabextract
RUN yum update -y \
    && yum install -y --setopt=tsflags=nodocs \
    java-11-openjdk \
    #
    # libreoffice requirements
    cairo \
    cups-libs \
    dbus-glib \
    glib2 \
    libSM \
    libXinerama \
    mesa-libGL \
    #
    # extra fonts
    open-sans-fonts \
    gnu-free-mono-fonts \
    gnu-free-sans-fonts \
    gnu-free-serif-fonts \
    #
    # mscorefonts dependencies
    cabextract \
    curl \
    #
    # utilities
    unzip \
    wget \
    #
    && yum clean all \
    && rm -rf /var/cache/yum

RUN yum install -y https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum

ENV LIBREOFFICE_VERSION=7.5.9.2
ENV LIBREOFFICE_MIRROR=https://s3.us-west-2.amazonaws.com/com.docmosis.public.download.archive/downloads/libreoffice/
ENV LIBREOFFICE_ARCHIVE=LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_Collabora-Build.rpm.tar.gz

RUN  echo "Downloading LibreOffice ${LIBREOFFICE_VERSION}..." \
    && echo ${LIBREOFFICE_MIRROR}${LIBREOFFICE_ARCHIVE} \
    && wget ${LIBREOFFICE_MIRROR}${LIBREOFFICE_ARCHIVE} \
    && tar -xf ${LIBREOFFICE_ARCHIVE} \
    && cd LibreOffice_*_Linux_x86-64_rpm/RPMS \
    && (rm -f *integ* || true) \
    && (rm -f *desk* || true) \
    && yum install -y --setopt=tsflags=nodocs *.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && cd ../.. \
    && rm -rf LibreOffice_*_Linux_x86-64_rpm \
    && rm -f LibreOffice_*_Linux_x86-64_rpm.tar.gz \
    && ln -s /opt/libreoffice* /opt/libreoffice

# mscorefonts2 does not currently install cambria.ttc
RUN echo "Downloading Cambria font collection..." \
    && wget --quiet -O PowerPointViewer.exe http://downloads.sourceforge.net/mscorefonts2/PowerPointViewer.exe \
    && cabextract --lowercase -F 'ppviewer.cab' PowerPointViewer.exe \
    && cabextract --lowercase -F '*.ttc' --directory=/usr/share/fonts/msttcore ppviewer.cab \
    && rm -f PowerPointViewer.exe ppviewer.cab

RUN groupadd docmosis \
    && useradd -g docmosis \
    --create-home \
    --shell /sbin/nologin \
    --comment "Docmosis user" \
    docmosis

WORKDIR /home/docmosis

ENV DOCMOSIS_VERSION=2.10.0

RUN DOCMOSIS_VERSION_SHORT=$(echo $DOCMOSIS_VERSION | cut -f1 -d_) \
    && echo "Downloading Docmosis Tornado ${DOCMOSIS_VERSION}..." \
    && echo https://resources.docmosis.com/SoftwareDownloads/Tornado/${DOCMOSIS_VERSION_SHORT}/docmosisTornado${DOCMOSIS_VERSION}.zip \
    && wget --quiet https://resources.docmosis.com/SoftwareDownloads/Tornado/${DOCMOSIS_VERSION_SHORT}/docmosisTornado${DOCMOSIS_VERSION}.zip \
    && unzip docmosisTornado${DOCMOSIS_VERSION}.zip docmosisTornado*.war docs/* licenses/* \
    && mv docmosisTornado*.war docmosisTornado.war \
    && rm -f docmosisTornado${DOCMOSIS_VERSION}.zip

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

# add tini to manage zombie/defunct processes since java process has pid=1
# if using "docker run" you can use the "--init" parameter which uses tini directly
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

USER docmosis
RUN mkdir /home/docmosis/templates /home/docmosis/workingarea

# Tornado configuration
ENV DOCMOSIS_OFFICEDIR=/opt/libreoffice \
    DOCMOSIS_TEMPLATESDIR=templates \
    DOCMOSIS_WORKINGDIR=workingarea

# Set password (recommended)
# Need not be hard coded here, it could be passed as a variable from the system invoking Docker,
#ENV DOCMOSIS_ADMINPW=

# Allow blank password (local network and host security has been configured to remove the need).
#ENV DOCMOSIS_ADMINPWALLOWBLANK=true

# Allow UNC paths in Tornado configuration.  Disabled by default because of inherent security risk).
#ENV DOCMOSIS_ALLOWUNCPATHS=true

EXPOSE 8080
VOLUME /home/docmosis/templates
CMD java -Dport=8080 -Djava.util.logging.config.file=javaLogging.properties -Ddocmosis.tornado.render.useUrl=http://localhost:8080/ -jar docmosisTornado.war
