use Test;
use lib 'lib';

plan 5;

use Pod::Perl5; pass "Import Pod::Perl5";

ok my $match = Pod::Perl5::parse-file('test-corpus/for.pod'), 'parse for command';

is $match<pod_section>[0]<_for>.elems, 1, 'Parser extracted one for';
is $match<pod_section>[0]<_for>[0]<name>.Str, 'HTML', 'Parser extracted name value is HTML';
is $match<pod_section>[0]<_for>[0]<singleline_text>.Str, "<a href='#'>some inline hyperlink</a>", 
  'Parser extracted the paragraph';
