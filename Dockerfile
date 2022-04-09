FROM centos:7

# epel for cabextract
RUN yum update -y \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
    && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 \
    && yum install -y --setopt=tsflags=nodocs \
    java-1.8.0-openjdk \
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

ENV LIBREOFFICE_VERSION=7.3.0.3
ENV LIBREOFFICE_MIRROR=https://downloadarchive.documentfoundation.org/libreoffice/old/

RUN echo "Downloading LibreOffice ${LIBREOFFICE_VERSION}..." \
    && echo ${LIBREOFFICE_MIRROR}${LIBREOFFICE_VERSION}/rpm/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz \
    && wget ${LIBREOFFICE_MIRROR}${LIBREOFFICE_VERSION}/rpm/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz \
    && tar -xf LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz \
    && cd LibreOffice_*_Linux_x86-64_rpm/RPMS \
    && (rm -f *integ* || true) \
    && (rm -f *desk* || true) \
    && yum localinstall -y --setopt=tsflags=nodocs *.rpm \
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

ENV DOCMOSIS_VERSION=2.9.1

RUN DOCMOSIS_VERSION_SHORT=$(echo $DOCMOSIS_VERSION | cut -f1 -d_) \
    && echo "Downloading Docmosis Tornado ${DOCMOSIS_VERSION}..." \
    && echo https://resources.docmosis.com/Downloads/Tornado/${DOCMOSIS_VERSION_SHORT}/docmosisTornado${DOCMOSIS_VERSION}.zip \
    && wget --quiet https://resources.docmosis.com/Downloads/Tornado/${DOCMOSIS_VERSION_SHORT}/docmosisTornado${DOCMOSIS_VERSION}.zip \
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
    'java.util.logging.ConsoleHandler.format=%1$tH:%1$tM:%1$tS,%1$tL [%2$s] %3$s  %4$s - %5$s %6$s%n' \
    > /home/docmosis/javaLogging.properties

USER docmosis
RUN mkdir /home/docmosis/templates /home/docmosis/workingarea

# Tornado configuration
ENV DOCMOSIS_OFFICEDIR=/opt/libreoffice \
    DOCMOSIS_TEMPLATESDIR=templates \
    DOCMOSIS_WORKINGDIR=workingarea

EXPOSE 8080
VOLUME /home/docmosis/templates
CMD java -Dport=8080 -Djava.util.logging.config.file=javaLogging.properties -Ddocmosis.tornado.render.useUrl=http://localhost:8080/ -jar docmosisTornado.war
