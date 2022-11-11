#! /usr/bin/env perl
use Modern::Perl '2015';
use FindBin qw/$Bin/;
use lib "$FindBin::Bin";
use Postfedi qw/get_dbh $sql sec_to_dhms/;

###
use utf8;
binmode(STDOUT, ':encoding(UTF-8)');
use open qw/ :std :encoding(utf8) /;

my $dbh = get_dbh();

my $entries = $dbh->selectall_arrayref( $sql->{status} );
my $rownr=1;
for my $e (@$entries) {
    my ( $url, $posted, $age, $content ) = @$e;

    $url = (split(/\#/, $url))[-1];
    $posted = $posted?'yes':'no';
    my $timestamp = gmtime( $age );
    my $hours =  time-$age>0 ? sec_to_dhms(time-$age):time-$age;
#    $content = substr( $content,0, 30);
    printf("%2d. %-23s %3s %12s %s\n", $rownr, $url, $posted, $hours, $content);
    #    say join(',',($url, $posted, $hours, $content));
    $rownr++;
}
