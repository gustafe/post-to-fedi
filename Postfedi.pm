package Postfedi;
use Modern::Perl '2015';
use Exporter;

#use Digest::SHA qw/hmac_sha256_hex/;
#use Config::Simple;
use DBI;
#use LWP::UserAgent;
#use JSON;
#use DateTime;
#use URI;
#use Reddit::Client;
#use Carp;
use open qw/ :std :encoding(utf8) /;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 1.00;
@ISA     = qw/Exporter/;
@EXPORT  = ();
@EXPORT_OK =
  qw/get_dbh get_ua $sql $ua sec_to_dhms sec_to_human_time extract_host/;
%EXPORT_TAGS = ( DEFAULT => [qw/&get_dbh &get_ua/] );

my $dsn = "DBI:SQLite:dbname=/home/gustaf/prj/Post-to-fedi/database.db";

our $sql = {
	    all_urls=>qq{select url from entries},
	    unposted=>qq{select url,content from entries where posted = 0 and age <= strftime('%s', 'now') order by url, age},
	    update_status=>qq{update entries set posted = 1 where url=?},
	    insert_entry=>qq{insert into entries (url, posted, age, content) values (?, 0 , ?, ? )},

	   };

sub get_dbh {

    my $dbh = DBI->connect( $dsn, '', '', { PrintError => 0 } )
      or croak $DBI::errstr;
    $dbh->{sqlite_unicode} = 1;
    return $dbh;
}

sub get_ua {
    my $ua = LWP::UserAgent->new( agent => 'my post to fedi UA' );

    return $ua;
}
