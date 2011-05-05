#!/usr/bin/env perl

use strict;
use warnings;

# for the time being
use Test::More qw( no_plan );

use Template::JavaScript;

my $ctx3 = Template::JavaScript->new();

$ctx3->tmpl_string( <<'' );
% var my_value = 'YES';
This is the value: <% my_value %> and I want it

$ctx3->output( \my $text );

$ctx3->run;

is( $text, <<'', 'can interpolate variables inline' );
This is the value: YES and I want it

undef $ctx3;  # safety net
