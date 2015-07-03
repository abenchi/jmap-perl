#!/usr/bin/perl -w

use strict;
use lib '/home/jmap/jmap-perl';
package JMAP::IMAPSync;

#use Mail::IMAPTalk qw(:trace);

use AnyEvent;
use AnyEvent::Handle;
use JSON::XS qw(encode_json decode_json);
use Net::Server::PreFork;
use JMAP::Sync::Gmail;

use base qw(Net::Server::PreFork);

# we love globals
my $hdl;
my $cv;
my $id;
my $backend;

$0 = '[jmap proxy imapsync]';

sub setup {
  my $config = shift;
  $backend = JMAP::Sync::Gmail->new($config) || die "failed to setup $id";
  warn "Connected $id";
  $0 = "[jmap proxy imapsync] $id";
  $hdl->push_write(json => [ 'setup', { folders => $backend->folders() } ]);
  $hdl->push_write("\n");
}

sub process_request {
  my $server = shift;
  $cv = AnyEvent->condvar;

  close STDIN;
  close STDOUT;
  $hdl = AnyEvent::Handle->new(
    fh => $server->{server}{client},
    on_error => sub {
      my ($hdl, $fatal, $msg) = @_;
      $hdl->destroy;
      $cv->send;
    },
    on_disconnect => sub {
      my ($hdl, $fatal, $msg) = @_;
      $hdl->destroy;
      $cv->send;
    },
  );

  # first item is always an authentication
  $hdl->push_read(json => sub {
    my $handle = shift;
    my $json = shift;
    $id = $json->{username};
    setup($json);
    $handle->push_read(json => mk_handler());
  });

  $cv->recv;
  $cv->send;
  exit 0;
}

JMAP::IMAPSync->run(host => '127.0.0.1', port => 5005);

sub handle_ping {
  return ['pong', $id];
}

sub handle_status {
  my $args = shift;
  my $status = $backend->fetch_status(@$args);
  return ['status', $status];
}

sub handle_folder {
  my $args = shift;
  my $folder = $backend->fetch_folder(@$args);
  return ['folder', $folder];

}

sub mk_handler {
  my ($db) = @_;

  # don't last forever
  $hdl->{killer} = AnyEvent->timer(after => 600, cb => sub { warn "SHUTTING DOWN $id ON TIMEOUT\n"; undef $hdl; $cv->send });

  return sub {
    my ($hdl, $json) = @_;

    # make sure we have a connection

    my ($cmd, $args, $tag) = @$json;
    my $res = eval {
      if ($cmd eq 'ping') {
        return handle_ping($args);
      }
      if ($cmd eq 'status') {
        return handle_status($args);
      }
      die "Unknown command $cmd";
    };
    unless ($res) {
      $res = ['error', "$@"]
    }
    $res->[2] = $tag;
    use Data::Dumper;
    warn Dumper($res);
    $hdl->push_write(json => $res);
    $hdl->push_write("\n");

    warn "HANDLED $cmd ($tag) => $res->[0] ($id)\n";
    $hdl->push_read(json => mk_handler($db));
  };
}
