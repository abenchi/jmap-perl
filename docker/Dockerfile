FROM phusion/baseimage:0.9.0
MAINTAINER Romain Pignolet <rpignolet@linagora.com>

WORKDIR /root

RUN apt-get update
RUN apt-get -y install build-essential \
	libanyevent-httpd-perl \
	libdata-uuid-libuuid-perl \
	libdatetime-perl \
	libdbd-sqlite3-perl \
	libdbi-perl \
	libemail-address-perl \
	libemail-mime-perl \
	libhtml-parser-perl \
	libhtml-strip-perl \
	libhttp-tiny-perl \
	libhttp-date-perl \
	libimage-size-perl \
	libio-socket-ssl-perl \
	libjson-perl \
	libjson-xs-perl \
	liblocale-gettext-perl \
	libswitch-perl \
	git \
	nginx

RUN cpan; true

RUN curl -L -O http://search.cpan.org/CPAN/authors/id/C/CI/CINDY/AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2.tar.gz && \
	tar xf AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2.tar.gz && \
	cd AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2 && \
	perl Makefile.PL && \
	make install

RUN cpan AnyEvent::HTTPD::CookiePatch AnyEvent::IMAP Cookie::Baker Date::Parse HTML::GenerateUtil Email::Sender:Simple Moose IO:All AnyEvent:HTTP Net::Server::PreFork

RUN mkdir -p /home/jmap/data

RUN cd /home/jmap && git clone -b docker https://github.com/rpignolet/jmap-perl.git

WORKDIR /home/jmap/jmap-perl

RUN rm /etc/nginx/sites-enabled/default

ADD nginx.conf /etc/nginx/sites-enabled/
ADD entrypoint.sh /root/

EXPOSE 80

ENTRYPOINT ["sh", "/root/entrypoint.sh"]

