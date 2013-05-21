package Mojolicious::Plugin::Util::RandomString;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Session::Token;

our $VERSION = 0.01;


# Register plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  $param //= {};

  # Load parameter from Config file
  if (my $config_param = $mojo->config('Util-RandomString')) {
    $param = { %$config_param, %$param };
  };

  my (%generator, %default);

  # Reseed on fork
  Mojo::IOLoop->timer(
    0 => sub {

      # Create generators by param
      foreach (keys %$param) {

	# Named generator
	if (ref $param->{$_} && ref $param->{$_} eq 'HASH') {

	  # Construct object
	  unless ($generator{$_} = Session::Token->new(
	    %{ $param->{$_} }
	  )) {

	    $mojo->log->fatal(qq!Unable to create generator for "$_"!);
	    next;
	  };
	}

	# Default parameter
	else {
	  $default{$_} = $param->{$_};
	};
      };

      # Create default generator
      $generator{'default'} //= Session::Token->new( %default );
    });


  # Establish 'random_string' helper
  $mojo->helper(
    random_string => sub {

      # Start Loop unless it is running
      Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      my $gen = $_[1];

      # Generate from generator
      unless ($_[2]) {

	# Generator doesn't exist
	if ($gen && !exists $generator{$gen}) {
	  $mojo->log->warn(qq!RandomString generator "$gen" is unknown!);
	  return '';
	};

	# Get from generator
	return $generator{$gen // 'default'}->get;
      };

      # Controller
      shift;

      # Overwrite default configuration
      return Session::Token->new(%default, @_)->get unless @_ % 2;

      $gen = shift;
      return Session::Token->new(%default, @_)->get if $gen eq 'default';

      # Overwrite specific configuration
      if ($param->{ $gen }) {
	return Session::Token->new(% {$param->{ $gen } } , @_)->get;
      };

      # Generator is unknown
      $mojo->log->warn(qq!RandomString generator "$gen" is unknown!);
      return '';
    }
  );
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::Util::RandomString - Generate Secure Random Strings in Mojolicious


=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'Util::RandomString' => {
    entropy => 256,
    length  => 18,
    printable => {
      alphabet => '2345679bdfhmnprtFGHJLMNPRT',
      length   => 20
    }
  };

  # Generate string with default configuration
  <%= random_string %>

  # Generate string with 'printable' configuration
  <%= random_string 'printable' %>

  # Generate string with 'showable' configuration
  # and overwrite length
  <%= random_string 'printable', length => 16 %>

  # Generate string with default configuration
  # and overwrite character set in a Controller
  $c->random_string(alphabet => ['a' .. 'z']);


=head1 DESCRIPTION

L<Mojolicious::Plugin::Util::RandomString> is a plugin to generate
random strings for session tokens, encryption salt, temporary
password generation etc. Internally it uses L<Session::Token>
(see L<this comparison|http://neilb.org/reviews/passwords.html#Session::Token>
for reasons of this decision).

This plugin will automatically reseed the random number generator in
a forking environment like Hypnotoad (although it is untested in other
forking envoironments).


=head1 METHODS

L<Mojolicious::Plugin::Util::RandomString> inherits all methods from
L<Mojolicious::Plugin> and implements the following new one.


=head2 register

  # Mojolicious
  $app->plugin('Util::RandomString');

  # Mojolicious::Lite
  plugin 'Util::RandomString' => {
    entropy => 256,
    length  => 18,
    printable => {
      alphabet => '2345679bdfhmnprtFGHJLMNPRT',
      length   => 20
    }
  };

  Or in your config file
  {
    'Util-RandomString' => {
      entropy => 256,
      length  => 18,
      printable => {
        alphabet => '2345679bdfhmnprtFGHJLMNPRT',
        length   => 20
      }
    }
  }


Called when registering the plugin.
Expects a hash reference containing parameters as defined in
L<Session::Token> for the default generator.
To specify named generators, use a name key (other than C<alphabet>,
C<length>, and C<entropy>) and specify the parameters as a hash reference.
The name key 'default' can overwrite the default configuration.

All parameters can be set either on registration or
as part of the configuration file with the key C<Util-RandomString>.

The default alphabet is base62. This is good for a lot of use cases.
If you want to generate human readable tokens, you can define another scheme
(e.g. the above shown 'printable' base26 scheme with a character set with
visually distinctive character, that also makes it unlikely to generate
insulting words due to missing vocals).


=head1 HELPERS

=head2 random_string

  # In Controller
  print $c->random_string;
  print $c->random_string('printable');
  print $c->random_string(length => 45)
  print $c->random_string('printable', length => 45)

  # In Template
  %= random_string;
  %= random_string('printable');
  %= random_string(length => 45)
  %= random_string('printable', length => 45)

Generate a random string.
In case of no parameters, the default configuration is used.
In case of one parameter, this is treated as the key of a
chosen configuration. The following parameters can be used to modify
a given configuration for one request (but please B<note>: each
modified request creates a new and seeded L<Session::Token> generator,
which is bad for performance).

=head1 DEPENDENCIES

L<Mojolicious> (best with SSL support),
L<Session::Token>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Util-RandomString


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut