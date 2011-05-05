package Template::JavaScript;
# vim: ft=perl ts=4 sw=4 et:

use v5.010.1;
use Any::Moose;

# For compiling our output
use JavaScript::V8;

# For generating our output
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

has template => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Things to bind',
);

has include_path => (
    is            => 'rw',
    isa           => 'Str|ArrayRef',
    documentation => 'The include path for the templates',
);

has output => (
    is            => 'rw',
    isa           => 'Any',
);

has _context => (
    is            => 'ro',
    isa           => 'JavaScript::V8::Context',
    lazy_build    => 1,
    documentation => '',
);

sub _build__context {
    JavaScript::V8::Context->new;
}

has _result => (
    is            => 'rw',
    isa           => 'Str',
    default       => '',
    documentation => 'Result accumulator',
);

has _tt => (
    is            => 'rw',
    isa           => 'Template',
    lazy_build    => 1,
    documentation => 'Our Template Toolkit object',
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

sub BUILD {
    my ($self) = @_;
    my $context = $self->_context;

    # Standard library
    $context->bind_function( say => sub {
        $self->{_result} .= $_[0];
        $self->{_result} .= "\n";
    });
    $context->bind_function( whisper => sub {
        $self->{_result} .= $_[0];
    });

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

    for my $line (split /^/, $self->template) {
        chomp $line;
        if ( substr($line, 0, 1) ne '%' ) {
            my @parts;
            # Parse inline variables
            while($line =~ /(.*?)<%\s*([^%]*?)\s*%>(.*)/s) {
                push (@parts, ( [ 'str', $1 ], [ 'expr', $2 ] ));
                $line = $3;
            }
            push (@parts, ['str', $line]) if ($line ne '');
            # use Data::Dumper;
            # say STDERR "begin";
            # say STDERR Dumper \@parts;
            # say STDERR "end";

            if (@parts == 0 || @parts == 1) {
                $js_code .= qq[;say('$line');];
            } else {
            # join them up
                $js_code .= join '', map {
                    my ($what, $value) = @$_;
                    my $ret;
                    if ($what eq 'str') {
                        $ret = qq[;whisper('$value');];
                    } elsif ($what eq 'expr') {
                        $ret = ";whisper($value);";
                    } else {
                        die;
                    }
                } @parts;
                $js_code .= qq[;whisper("\\n");];
            }
        } else {
            substr($line, 0, 1, '');

            $js_code .= $line . "\n";
        }
    }

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

__PACKAGE__->meta->make_immutable;
