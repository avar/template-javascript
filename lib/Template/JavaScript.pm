package Template::JavaScript;
# vim: ft=perl ts=4 sw=4 et:

use strict;
use warnings;

use v5.010.1;
use Any::Moose;

use JavaScript::V8;

use File::Spec::Functions qw(catdir catfile);
use File::Slurp qw(slurp);
use Template;

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

has _tt => (
    is            => 'rw',
    isa           => 'Template',
    lazy_build    => 1,
    documentation => 'Our Template Toolkit object',
);

has include_path => (
    is            => 'rw',
    isa           => 'Str|ArrayRef',
    documentation => 'The include path for the templates',
);

sub _build__tt {
    my ($self) = @_;

    my $tt = Template->new({
        INCLUDE_PATH => $self->include_path, # or list ref
        INTERPOLATE  => 0,         # expand "$var" in plain text
        POST_CHOMP   => 0,         # cleanup whitespace 
        EVAL_PERL    => 0,         # evaluate Perl code blocks
        ABSOLUTE     => 1,         # all includes are absolute
    });

    return $tt;
}

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

    $context->bind_function( javascript_output => sub {
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

sub tmpl_file {
    my ($self, $file) = @_;

    my $output;
    $self->_tt->process($file, {}, \$output) || die $self->_tt->error;

    $self->template( $output );
}

sub run {
    my ($self) = @_;
    my $context = $self->_context;

    my $js_code = '';

    for my $line (split /\n/, $self->template) {
        chomp $line;
        if ( substr($line, 0, 1) ne '%' ) {
            $js_code .= qq[;javascript_output('$line');\n];
        } else {
            substr($line, 0, 1, '');

            $js_code .= $line . "\n";
        }
    }

    # for debugging
    # say STDERR "CODE:{$js_code}";

    unless ( my $retval = $context->eval($js_code) ){
        $retval //= '<undef>';
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
