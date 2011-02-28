package Mac::Safari::JavaScript;
use base qw(Exporter);

# This isn't a problem, all Macs have at least 5.8
use 5.008;

use strict;
use warnings;

use Mac::AppleScript qw(RunAppleScript);
use JSON::XS qw(decode_json);
use Encode qw(encode decode);

our @EXPORT_OK;
our $VERSION = "0.01";

=head1 NAME

Mac::Safari::JavaScript - Run JavaScript in Safari on Mac OS X

=head1 SYNOPSIS

  use Mac::Safarai::JavaScript qw(safari_js);

  // do an alert
  safari_js 'alert("Hello Safari User")';

  // return some value
  var $arrayref = safari_js 'return [1,2,3]';

  // multiple lines are okay
  safari_js <<'JAVASCRIPT';
    var fred = "bob";
    return fred;
  JAVASCRIPT

=head1 DESCRIPTION

This module allows you to execute JavaScript code in the Safari web
browser on Mac OS X.

The current implementation wraps the JavaScript in Applescript,
compiles it, and executes it in order to control Safari.

=head1 FUNCTION

=over

=item safari_js($javascript)

Runs the JavaScript in the first tab of the front window of the
currently running Safari.

Your code is automatically executed in a function to avoid namespace
polution.

If you JavaScript returns something (via the C<return> keyword) then,
as long as it can be represented by JSON, it will be returned as
the result of this.

=cut

sub safari_js($) {
  my $javascript = shift;

  # wrap the javascript in helper functions so we always
  # return a javascript string in order to be consistent
  $javascript = <<"ENDOFJAVASCRIPT";
  JSON.stringify((function () { $javascript; })());
ENDOFJAVASCRIPT

  # escape the backslashes
  $javascript =~ s/\\/\\\\/xg;

  # escape the quotes
  $javascript =~ s/"/\\"/xg;

  # wrap it in applescript
  my $applescript = <<"ENDOFAPPLESCRIPT";
tell application "Safari"
  -- execute the javascript
  set result to do JavaScript "$javascript" in document 1

  -- then make sure we're returning a string to be consistent'
  "" & result
end tell
ENDOFAPPLESCRIPT

  # compile it an execute it using the cocca api
  # (make sure to pass it in as utf-8 bytes)
  my $json = RunAppleScript($applescript);

  # $json is now a string where each character represents a byte
  # in a utf-8 encoding of the real characters (ARGH!).  Fix that so
  # each character actually represents the character it should, um,
  # represent.
  $json = encode("iso-8859-1", $json);
  $json = decode("utf-8", $json);

  # strip off any applescript string wrapper
  $json =~ s/\A"//x;
  $json =~ s/"\z//x;
  $json =~ s/\\"/"/gx;
  $json =~ s/\\\\/\\/gx;

  # and decode this from json
  my $coder = JSON::XS->new;
  $coder->allow_nonref(1);
  return $coder->decode($json);
}
push @EXPORT_OK, "safari_js";

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

Copryright Mark Fowler 2011. All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs should be reported to me via the CPAN RT system. http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac::Safari::JavaScript

=head1 SEE ALSO

L<Mac::Applescript>

=cut

1;
