# Set the base image to Ubuntu
FROM ubuntu
FROM java

ENV MIRTH_CONNECT_VERSION 3.5.0.8232.b2153
# Install Nginx

# Add application repository URL to the default sources
RUN echo "deb http://old-releases.ubuntu.com/ubuntu/ raring main universe" >> /etc/apt/sources.list
# Update the repository
RUN apt-get update

# Install necessary tools
RUN apt-get install -y nano wget dialog net-tools

# Download and Install Nginx
RUN apt-get install -y nginx  

# Remove the default Nginx configuration file
RUN rm -v /etc/nginx/nginx.conf

# Copy a configuration file from the current directory
ADD nginx.conf /etc/nginx/

# Append "daemon off;" to the beginning of the configuration
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Mirth Connect is run with user `connect`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN useradd -u 1000 mirth

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu

VOLUME /opt/mirth-connect/appdata

RUN \
  cd /tmp && \
  wget http://downloads.mirthcorp.com/connect/$MIRTH_CONNECT_VERSION/mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  tar xvzf mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  rm -f mirthconnect-$MIRTH_CONNECT_VERSION-unix.tar.gz && \
  mv Mirth\ Connect/* /opt/mirth-connect/ && \
  chown -R mirth /opt/mirth-connect

WORKDIR /opt/mirth-connect

EXPOSE 8888 8443 80 3000 9661
ADD test.xml /
COPY /docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ./mirthconnect-wrapper.sh


