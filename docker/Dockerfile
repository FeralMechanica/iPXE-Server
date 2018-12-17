# Get a fresh Debian image
FROM debian:stable-slim as debian-current

FROM debian-current as debian-updated

RUN echo 'deploy-api		443/tcp			# deployment.sh iPXE-agent'| tee -a /etc/services
ARG version="0.0.1"
ARG build="unknown"
LABEL version="$version" \
      channel="experimental" \
      maintainer.name="Alex Rakulenko" \
      maintainer.email="me@rakul.info"

# Stays in the image
ENV build="$build"
ENV version="$version"

# Only for the build; need to break the cache of apt layer
ARG cache_timestamp=1543333330

RUN apt-get -y update && \
  apt-get -y upgrade && \
  apt-get -y dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install bash nullmailer localepurge && \
  apt-get -y autoremove && \
  apt-get -y clean && \
  localepurge

ENTRYPOINT [ "/bin/bash" ]


# Build deploy-agent image
FROM debian-updated as deploy-agent
ARG tmp=/tmp/build

#RUN which add-apt-repository \
#      || apt install -f software-properties-common
#add-apt-repository 'deb http://archive.getdeb.net/ubuntu wily-getdeb games'

# Install deps
RUN DEBIAN_FRONTEND=noninteractive yes|apt-get -y install xinetd && \
  mkdir -p ${tmp}
RUN for lib in $(ldd $(which xinetd)| cut -d'>' -f2 -s| cut -d' ' -f2); do echo copying $lib to ${tmp}; cp $lib ${tmp}; done
ARG dhcp_iface="eth0"
ENV dhcp_iface="$dhcp_iface"
COPY xinetd.conf /etc/xinetd.d/api
COPY deploy-agent.sh /srv/deploy-agent.sh
ADD 'https://tools.ietf.org/html/rfc2616#section-10' /srv/rfc2616.10
RUN sed -rne 's/<a\s+href\s*=\s*"#section-[0-9\.]+"\s*>[0-9\.]+<\/a>\s+([0-9]{3})\s*([a-zA-Z ]+)\.+.*$/\1 \2/p' /srv/rfc2616.10 > /srv/http_codes
RUN echo 'deploy-api		5900/tcp			# deployment.sh iPXE-agent' >> /etc/services

ENTRYPOINT [ "/usr/sbin/xinetd", "-dontfork" , "-f /etc/xinetd.d/api", "-pidfile /run/xinetd.pid", "-stayalive", "-filelog /srv/xinetd.log", "-cc 120" , "-d" ]


FROM layer_one as deploy-nginx

# Install webservices
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install nginx 
COPY nginx.conf /etc/nginx.conf.d/ipxe.conf
RUN echo 'deploy-api		5900/tcp			# deployment.sh iPXE-agent' >> /etc/services

ENTRYPOINT [ "/usr/bin/nginx", "-o", "no-daemon;" ]
