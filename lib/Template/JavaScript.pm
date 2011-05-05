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

has _result => (
    is            => 'rw',
    isa           => 'Str',
    default       => '',
    documentation => 'Result accumulator',
);

has template => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Things to bind',
);

has say => (
    is            => 'ro',
    isa           => 'Any',
    default       => sub { sub { say @_ } },
    documentation => 'Your callback for say, instead of ours',
);

has output => (
    is            => 'rw',
    isa           => 'Any',
);

sub BUILD {
    my ($self) = @_;
    my $context = $self->_context;

    # Maybe the user wants to override say

    # Standard library
    $context->bind_function( say => $self->say );

    $context->bind_function( o => sub {
        $self->{_result} .= $_[0];
        $self->{_result} .= "\n";
    });

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

sub tmpl_string {
    my ($self, $string) = @_;

    $self->template( $string );
}

sub tmpl_fh {
    my ($self, $fh) = @_;

    my $code;
    {
        local $/;
        $code = < $fh >;
    }

    $self->template( $code );
}

sub run {
    my ($self) = @_;
    my $context = $self->_context;

    my $js_code = '';

    for my $line (split /\n/, $self->template) {
        chomp $line;
        if ( substr($line, 0, 1) ne '%' ) {
            $js_code .= qq[;o('$line');];
        } else {
            substr($line, 0, 1, '');

            $js_code .= $line;
        }
    }

    unless ( my $retval = $context->eval($js_code) ){
        die "retval:[$retval] \$\@:[$@]";
    }

    given ( ref $self->{output} ) {
        when ( 'SCALAR' ){
            ${ $self->{output} } = $self->{_result};
        }
        when ( 'GLOB' ){
            print { $self->{output} } $self->{_result};
        }
    }
}

1;
