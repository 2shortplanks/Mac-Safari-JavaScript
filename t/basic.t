#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Mac::Safari::JavaScript qw(safari_js);

is_deeply safari_js "return 'string'", "string", "string";
is_deeply safari_js "return 1+2+3" , 6, "number";
ok safari_js "return true", "truth, true";
ok !safari_js "return false", "truth, false";
is_deeply safari_js "return { 'a': 'b'}" , { a => "b"}, "object/hash";
is_deeply safari_js "return [1,2,3]" , [1,2,3], "object/array";
is_deeply safari_js 'return "L\\u00e9on"', "L\x{e9}on", "unicode \\u sequence";
is safari_js "return 'L\x{e9}on'.length", 4, "length";
is safari_js "return '\x{2603}'", "\x{2603}", "snowman roundtrip";
is safari_js <<'JAVASCRIPT', "bobbuzz", "multiline";
// this is a multi line example
var foo = "bob";
var bar = "buzz";
return foo+bar;
JAVASCRIPT
