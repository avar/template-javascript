#!/usr/bin/env perl
package Template::JavaScript;
use v5.010.1;
use strict;
use warnings;
use JavaScript::V8;

my $context = JavaScript::V8::Context->new;

$context->bind_function( say => sub {
  say @_;
} );

$context->bind_function( include => sub {
  say "# including <$_[0]>...";
} );

$context->bind( b => {
    site_name => 'boob',
} );

$context->bind( iloveyou => {
    banana => 1,
    rama => 2,
    cazzi_mazzi => 0,
} );

my $code = '';

while (my $line = <DATA>) {
  chomp $line;
  if ( substr($line, 0, 1) ne '%' ){
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

1;

__DATA__
header

% if( iloveyou.banana ){
  <h1>banana active</h1>
% } else {
  (no banana)
% }

%  include ('sumthin.jmpl');

% if( typeof cazzi != 'undefined' && cazzi.mazzi );
% else say('nothing here');

% var foobar = function( me ){
%    say ("I am foobar and <" + me + ">");
% };
% var baz = function ( sumthin ){ };

<footeR>
