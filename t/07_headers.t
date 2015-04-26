use Test;
use lib 'lib';

plan 10;

use Pod::Perl5; pass "Import Pod::Perl5";

ok my $match = Pod::Perl5::parse_file('test-corpus/headers.pod'), 'parse headers';

is $match<head1>.elems, 1, 'Parser extracted one head1';
is $match<head1>[0]<paragraph>.Str, "heading 1\n\n", 'Parser extracted header 1';

is $match<head2>.elems, 1, 'Parser extracted one head2';
is $match<head2>[0]<paragraph>.Str, "heading 2\n\n", 'Parser extracted header 2';

is $match<head3>.elems, 1, 'Parser extracted one head3';
is $match<head3>[0]<paragraph>.Str, "heading 3\n\n", 'Parser extracted header 3';

is $match<head4>.elems, 1, 'Parser extracted one head4';
is $match<head4>[0]<paragraph>.Str, "heading 4\n\n", 'Parser extracted header 4';
