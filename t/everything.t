use Any::Moose;
use Template::JavaScript;
use Test::More qw(no_plan);

my $template = <<"TEMPLATE";
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
TEMPLATE

my $t = Template::JavaScript->new(
    bind => [
        [
            iloveyou => {
                banana => 1,
                rama => 2,
                cazzi_mazzi => 0,
            }
        ],
    ],
    template => $template,
);

$t->run;

