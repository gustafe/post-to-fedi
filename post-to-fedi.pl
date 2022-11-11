#! /usr/bin/env perl
use Modern::Perl '2015';
use FindBin qw/$Bin/;
use LWP;
use lib "$FindBin::Bin";
use Postfedi qw/get_dbh $sql/;

use utf8;
use open qw/ :std :encoding(utf8) /;
binmode( STDOUT, ':encoding(UTF-8)' );

# code adapted from https://codeberg.org/kvibber/fedbotrandom

# Load config file
my $configPath = $ARGV[0] || "$Bin/fedbot.config";
my %CONFIG;
open configFile, '<',
    $configPath || die "Cannot open configuration at $configPath";
my @lines = <configFile>;
close configFile;
foreach my $configLine (@lines) {
    if ( $configLine =~ /^\s*([A-Za-z0-9_]+)\s*:\s*(.*)\s*$/ ) {
        $CONFIG{$1} = $2;
    }
}

my $dbh = get_dbh();

my $unposted = $dbh->selectall_arrayref( $sql->{unposted} )
    || die $dbh->errstr;

exit 0 if scalar @$unposted == 0;

my $entry = $unposted->[0];    # choose first unposted

my $url     = $entry->[0];
my $content = $entry->[1];

my $destination
    = "https://${CONFIG{'INSTANCE_HOST'}}/api/v1/statuses?access_token=${CONFIG{'API_ACCESS_TOKEN'}}";

my $message = "🤖 $content\n\n$url";
say "Attempting to post: ";
say "--------------------";
say $message;
say "--------------------";
say "to $CONFIG{'INSTANCE_HOST'}...";

my $browser  = LWP::UserAgent->new;
my $response = $browser->post(
    $destination,
    [   status     => $message,
        visibility => 'public'
    ],
);

if ( $response->is_success ) {
    my $sth = $dbh->prepare( $sql->{update_status} ) or warn $dbh->errstr;
    $sth->execute($url);
    print "... done!\n";
}
else {
    print STDERR "Failed: ", $response->status_line, "\n";
}
