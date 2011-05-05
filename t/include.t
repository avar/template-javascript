use v5.10.0;
use Any::Moose;
use Template::JavaScript;
use Test::More qw(no_plan);
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use File::Slurp qw(slurp);
use Template;

ok(1);

my $data_dir = catdir($Bin, 'swamp');

my $tt = Template->new({
    INCLUDE_PATH => $data_dir,       # or list ref
    INTERPOLATE  => 0,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 0,               # evaluate Perl code blocks
    ABSOLUTE     => 1,
});
my $root = catfile($data_dir, 'root.tt');
$tt->process($root) || die $tt->error;
