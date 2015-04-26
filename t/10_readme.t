use Test;
use lib 'lib';

plan 9;

use Pod::Perl5; pass "Import Pod::Perl5";

ok my $match = Pod::Perl5::parse_file('test-corpus/readme_example.pod'),
  'parse readme example';

# basic counts
is $match<head1>.elems,     7, 'Parser extracted seven headings';
is $match<paragraph>.elems, 6, 'Parser extracted six paragraphs';
is $match<verbatim_paragraph>.elems, 4, 'Parser extracted four verbatim paragraphs';

# value checks
is $match<head1>[3]<paragraph><text>.Str, "SYNOPSIS", 'Parser extracted value from paragraph';
is $match<paragraph>[1]<text>.Str, "0.01", 'Parser extracted value from paragraph';
is $match<paragraph>[2]<text><format_codes>[0]<code><multiline_text>.Str, "Pod::Perl5::Grammar",
  'Parser extracted value from paragraph';
is $match<verbatim_paragraph>[0]<verbatim_text>.Str, "  use Pod::Perl5;",
  'Parser extracted text from verbatim paragraph';
