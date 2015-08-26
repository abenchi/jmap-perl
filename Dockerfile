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
	libexpat1-dev \
	git \
	nginx

RUN cpan; true

RUN curl -L -O http://search.cpan.org/CPAN/authors/id/C/CI/CINDY/AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2.tar.gz && \
	tar xf AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2.tar.gz && \
	cd AnyEvent-HTTPD-SendMultiHeaderPatch-v0.1.2 && \
	perl Makefile.PL && \
	make install

RUN git clone https://github.com/brong/Net-CardDAVTalk.git && \
 	cd Net-CardDAVTalk && \
	perl Makefile.PL && \
	make install
	
RUN perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit'

RUN cpan Class::ReturnValue Class::Accessor Set::Infinite  \
		DateTime::Set DateTime::Event::Recurrence DateTime::TimeZone DateTime::Event::ICal \
		Text::vFile::asData Test::LongString Test::Warn  \
		Data::ICal UNIVERSAL::require Mail::IMAPTalk XML::Parser  \
		XML::SemanticDiff XML::Spice Email::Sender::Transport::SMTPS  \
		Net::DAVTalk Net::CalDAVTalk AnyEvent::HTTPD::CookiePatch  \
		AnyEvent::IMAP Cookie::Baker Date::Parse HTML::GenerateUtil  \
		Email::Sender:Simple Moose IO:All AnyEvent:HTTP Net::Server::PreFork \
		List::Pairwise IO::LockedFile Template EV Net::DNS || true
	
RUN mkdir -p /home/jmap/data

COPY . /home/jmap/jmap-perl

WORKDIR /home/jmap/jmap-perl

RUN rm /etc/nginx/sites-enabled/default

COPY docker/nginx.conf /etc/nginx/sites-enabled/

COPY docker/entrypoint.sh /root/

EXPOSE 80

ENTRYPOINT ["sh", "/root/entrypoint.sh"]
