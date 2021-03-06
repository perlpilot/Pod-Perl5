use Test;
use lib 'lib';

plan 20;

use Pod::Perl5; pass "Import Pod::Perl5";

ok my $match = Pod::Perl5::parse-file('test-corpus/over_back.pod'), 'parse over_back';
is $match<pod_section>[0]<over_back>.elems, 3, 'Parser extracted two over/back pair';

# tests for list 1
is $match<pod_section>[0]<over_back>[0]<_item>[0]<name>.Str, '1',
  'Parser extracted name from bullet point one';
is $match<pod_section>[0]<over_back>[0]<_item>[0]<paragraph><text>.Str, "bullet point one\n",
  'Parser extracted paragraph from bullet point one';

is $match<pod_section>[0]<over_back>[0]<_item>[1]<name>.Str, '*',
  'Parser extracted name from bullet point two';

is $match<pod_section>[0]<over_back>[0]<_item>[1]<paragraph><text>.Str, "bullet point two\n",
  'Parser extracted paragraph from bullet point two';

is $match<pod_section>[0]<over_back>[0]<_item>[2]<name>.Str,
  'some_code()',
  'Parser extracted name from bullet point three';

is $match<pod_section>[0]<over_back>[0]<_item>[2]<paragraph><text>.Str,
  "bullet point three\n",
  'Parser extracted paragraph from bullet point three';

is $match<pod_section>[0]<over_back>[0]<_item>[3]<name>.Str, 'NoPara',
  'Parser extracted name from bullet point four';

is $match<pod_section>[0]<over_back>[0]<_item>[4]<name>.Str,
  'NoParaTrailingWhitespace',
  'Parser extracted name from bullet point five';

is $match<pod_section>[0]<over_back>[0]<_item>[5]<name>,
  'ParaNextLine',
  'Parser extracted name from bullet point six';

is $match<pod_section>[0]<over_back>[0]<_item>[5]<paragraph><text>.Str,
  "This is the para for the bullet point\n",
  'Parser extracted paragraph from bullet point seven';

is $match<pod_section>[0]<over_back>[0]<_item>[6]<name>,
  'ParaNextLineTrailWhitespace',
  'Parser extracted name from bullet point seven';

is $match<pod_section>[0]<over_back>[0]<_item>[6]<paragraph><text>.Str,
  "This is the para for the bullet point after trailing whitespace\n",
  'Parser extracted paragraph from bullet point seven';

is $match<pod_section>[0]<over_back>[0]<pod>.Str,
  "=pod\n",
  'Pod was extracted from within the list';

# tests for list 2
is $match<pod_section>[0]<over_back>[1]<over>.Str,
  "=over 4\n",
  'Extracted the over and the number';

is $match<pod_section>[0]<over_back>[1]<_item>.elems,
  3, 'Extracted three items from the second list';

# tests for list 3
is $match<pod_section>[0]<over_back>[2]<over_back>[0]<_item>.elems,
  2, 'The inner list has two items';

is $match<pod_section>[0]<over_back>[2]<_item>.elems,
  3, 'The outer list has three items';

