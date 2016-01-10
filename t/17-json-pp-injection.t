use strict;
use warnings;

use Test::More;

# this is just like t/09-unicode.t, except the minimum perl prereq is not known
# to be at least 5.008006, so a prereq on JSON::PP is injected to enable the
# target toolchain to be able to deal with non-ascii characters in META.json
# (not soon enough for the distribution being installed, sadly)

use Path::Tiny;
my $code = path('t', '09-unicode.t')->slurp_utf8;

$code =~ s/perl => '5.010'/perl => '0'/g;
$code =~ s/^(\s+)(configure => \{ requires => \{ perl => '0' \} \},)$/$1$2\n$1runtime => { requires => { 'JSON::PP' => '2.27300' } },/m;

eval $code;
die $@ if $@;
