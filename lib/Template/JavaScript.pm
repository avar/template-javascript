package Template::JavaScript;
# vim: ft=perl ts=4 sw=4 et:

use strict;
use warnings;

use v5.010.1;
use Any::Moose;

use JavaScript::V8;


=head1 NAME

Template::JavaScript - A templating engine using the L<JavaScript::V8> module

=cut

=head1 ATTRIBUTES

=cut

sub output_ref {
    my ($self) = @_;
}

sub parse_string {
    my ($class, $string) = @_;

    return $string;
}

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
    documentation => 'Things to bind',
);

has say => (
    is            => 'ro',
    isa           => 'Any',
    default       => sub { sub { say @_ } },
    documentation => 'Your callback for say, instead of ours',
);

sub BUILD {
    my ($self) = @_;
    my $context = $self->_context;

    # Maybe the user wants to override say

    # Standard library
    $context->bind_function( say => $self->say );

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
            $code .= qq[;say('$line');];
        } else {
            substr($line, 0, 1, '');

            $code .= $line;
        }
    }

 #   say "code:[$code]";

    unless ( my $retval = $context->eval($code) ){
#        say "retval:[$retval] \$\@:[$@]";
    }
}

1;
