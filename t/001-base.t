#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

my $p = 'Template::JavaScript';

use_ok($p);

can_ok($p, 'new');

my $ctx = Template::JavaScript->new();

isa_ok($ctx, $p);

can_ok($ctx, 'output_ref');
can_ok($ctx, 'parse_string');

my $simple = <<'';
foobar

is($ctx->parse_string($simple), "foobar\n", 'can parse simple string');
