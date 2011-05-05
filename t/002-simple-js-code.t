#!/usr/bin/env perl

use strict;
use warnings;

# for the time being
use Test::More qw( no_plan );

use Template::JavaScript;

my $ctx = Template::JavaScript->new();

my $three_loops = <<'';
before
% for( var i = 3; i ; i-- ){
  this is a loop
% }
after

$ctx->output( \my $out );

$ctx->tmpl_string( $three_loops );

$ctx->run;

is( $out, <<'', 'can run simple JS code (loops)' );
before
  this is a loop
  this is a loop
  this is a loop
after

# :)
