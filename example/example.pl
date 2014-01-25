#!/usr/bin/env perl
use Mojolicious::Lite;

BEGIN {
  unshift(@INC, '../lib');
};

app->config(hypnotoad => {
  listen => ['http://*:1234'],
  workers => 5,
  accepts => 5,
  keep_alive_requests => 1
});

plugin 'Util::RandomString' => {
  length => 20
};

get '/' => sub {
  my $c = shift;
  my @array;
  foreach (1..10) {
    push(@array, $c->random_string);
  };

  return $c->render(
    text => "$$<br><br>" . join("<br>", @array)
  );
};

app->start;
