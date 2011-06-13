#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Mac::Safari::JavaScript qw(safari_js);
use Scalar::Util qw(blessed);
use Data::Dumper;

########################################################################
# return values
########################################################################

# simple values returned
is_deeply safari_js("return 'string'"), "string", "string";
is_deeply safari_js('return "string"'), "string", "string";
is_deeply safari_js("return 1+2+3"), 6, "number";

# truth values returned
ok safari_js("return true"), "truth, true";
ok !safari_js("return false"), "truth, false";

# return simple object
is_deeply safari_js("return { 'a': 'b'}") , { a => "b"}, "object/hash";
is_deeply safari_js("return [1,2,3]") , [1,2,3], "object/array";

# return various forms of undef
is_deeply [safari_js "1+1"], [], "doesn't return anything";
is_deeply [safari_js "return"], [undef], "bare return";
is_deeply [safari_js "return undefined"], [undef], "return undefined";
is_deeply [safari_js "return null"], [undef], "return null";

# unicode
is_deeply safari_js('return "L\\u00e9on"'), "L\x{e9}on", "unicode \\u sequence";
is safari_js("return 'L\x{e9}on'.length"), 4, "length";
is safari_js("return '\x{2603}'"), "\x{2603}", "snowman roundtrip";

# multiline, including a comment
is safari_js(<<'JAVASCRIPT'), "bobbuzz", "multiline";
// this is a multi line example
var foo = "bob";
var bar = "buzz";
return foo+bar;
JAVASCRIPT

########################################################################
# passing things in
########################################################################

is_deeply [safari_js "return foo + bar", foo => 2, bar => 3], [5], "basic in";
is_deeply [safari_js "return [number,hash,array, truth,falsehood,nully]",

  number => 6,

  hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ] } },

  array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}", { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ]}}],

  truth => JSON::XS::true,

  falsehood => JSON::XS::false,

  nully => undef,
], [[
  6,
  
  { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ] } },

  [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}", { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ], hash => { foo => 1, bar => "a", baz => JSON::XS::true, buzz => JSON::XS::false, bizz => undef, array => [1,"a", JSON::XS::true, buzz => JSON::XS::false, undef, "\x{e9}" ]}}],

  JSON::XS::true,

  JSON::XS::false,

  undef,
]], "round trip";

eval { 
  safari_js "return true;", "uneven"
};
like ($@, qr/Uneven number of parameters passed to safari_js/, "Uneven number of parameters");

########################################################################

# testing exceptions
sub error_like (&$$) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $uboat = shift;
  my $re = shift;
  my $description = shift;
  eval { $uboat->() };
  unless (defined($@) && blessed($@) && $@->isa("Mac::JavaScript::Safari::Exception") && "$@" =~ $re) {
    ok(1, $description);
    return 0;
  }
  return ok(1, $description);
}

error_like {
  safari_js "++++";
} qr/Parse error/, "invalid js";

error_like {
  safari_js "{";
} qr/Parse error/, "stray }";
