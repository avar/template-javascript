#!/usr/bin/env perl
package Template::JavaScript;
use v5.10.0;

use Any::Moose;
use JavaScript::V8;

=head1 NAME

Template::JavaScript - A templating engine using the L<JavaScript::V8> module

=cut

=head1 ATTRIBUTES

=cut

has bind => (
    is            => 'ro',
    isa           => 'ArrayRef[Any]',
    default       => sub { +[] },
    documentation => 'Things to bind',
);

has _context => (
    is            => 'ro',
    isa           => 'JavaScript::V8::Context',
    lazy_build    => 1,
    builder       => sub {
        JavaScript::V8::Context->new;
    },
    documentation => '',
);

has template => (
    is            => 'ro',
    isa           => 'Str',
    default       => sub { +[] },
    documentation => 'Things to bind',
);

sub BUILD {
    my ($self) = @_;
    my $context = $self->_context;

    # Standard library
    $context->bind_function(
        say => sub {
            say @_;
        }
    );

    $context->bind_function(
        include => sub {
            say "# including <$_[0]>...";
        }
    );

    # User-supplied stuff
    my $bind = $self->bind;

    for my $b (@$bind) {
        $context->bind(@$b);
    }

    return;
}

sub run {
    my ($self) = @_;
    my $context = $self->_context;

    my $code = '';

    for my $line (split /\n/, $self->template) {
        chomp $line;
        if ( substr($line, 0, 1) ne '%' ) {
            $code .= q[;say('] . $line . q[');];
        } else {
            substr($line, 0, 1, '');

            $code .= $line;
        }
    }

    say "code:[$code]";

    unless ( my $retval = $context->eval($code) ){
        say "retval:[$retval] \$\@:[$@]";
    }
}

1;
