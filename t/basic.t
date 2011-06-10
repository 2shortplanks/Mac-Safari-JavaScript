#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Mac::Safari::JavaScript qw(safari_js);
use Scalar::Util qw(blessed);
use Data::Dumper;

########################################################################
# return values
########################################################################

# simple values returned
is_deeply safari_js "return 'string'", "string", "string";
is_deeply safari_js 'return "string"', "string", "string";
is_deeply safari_js "return 1+2+3" , 6, "number";

# truth values returned
ok safari_js "return true", "truth, true";
ok !safari_js "return false", "truth, false";

# return simple object
is_deeply safari_js "return { 'a': 'b'}" , { a => "b"}, "object/hash";
is_deeply safari_js "return [1,2,3]" , [1,2,3], "object/array";

# return various forms of undef
is_deeply [safari_js "1+1"], [], "doesn't return anything";
is_deeply [safari_js "return"], [undef], "bare return";
is_deeply [safari_js "return undefined"], [undef], "return undefined";
is_deeply [safari_js "return null"], [undef], "return null";

# unicode
is_deeply safari_js 'return "L\\u00e9on"', "L\x{e9}on", "unicode \\u sequence";
is safari_js "return 'L\x{e9}on'.length", 4, "length";
is safari_js "return '\x{2603}'", "\x{2603}", "snowman roundtrip";

# multiline, including a comment
is safari_js <<'JAVASCRIPT', "bobbuzz", "multiline";
// this is a multi line example
var foo = "bob";
var bar = "buzz";
return foo+bar;
JAVASCRIPT

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
