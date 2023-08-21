#! /usr/bin/env perl
use Modern::Perl '2015';
###
use FindBin qw/$Bin/;
use Data::Dump qw/dump/;
use HTML::TreeBuilder;
use JSON;
use lib "$FindBin::Bin";
use Postfedi qw/get_dbh $sql get_feed/;
use Data::Dump qw/dump/;
use utf8;

use open qw/ :std :encoding(utf8) /;
binmode( STDOUT, ':encoding(UTF-8)' );

### don't act if we have unposted items

my $dbh = get_dbh;

my $rv = $dbh->selectall_arrayref( "select * from entries where posted = 0");

if (scalar @$rv > 0) {
    say "There are unposted items in the store, exiting.";
    exit 0;
      
}

$rv= $dbh->do("delete from entries where posted=1") or die $DBI::errstr; 

my $sql = "insert into entries ( url, posted, age, content) values (?,?,?,?)";
my $sth = $dbh->prepare( $sql ); 

my $f = get_feed();

for my $url (sort keys %$f) {
    say "==> $url";
    $sth->execute( $url, 1, $f->{$url}{ts}, $f->{$url}{content}) or die $DBI::errstr;
    
}
