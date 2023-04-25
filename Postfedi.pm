package Postfedi;
use Modern::Perl '2015';
use Exporter;

#use Digest::SHA qw/hmac_sha256_hex/;
#use Config::Simple;
use DBI;
use LWP::UserAgent;
use JSON;
use HTML::TreeBuilder;
use Time::Piece;
#use DateTime;
#use URI;
#use Reddit::Client;
#use Carp;
use utf8;
use open qw/ :std :encoding(utf8) /;
binmode( STDOUT, ':encoding(UTF-8)' );
use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 1.00;
@ISA     = qw/Exporter/;
@EXPORT  = ();
@EXPORT_OK =
  qw/get_dbh get_ua $sql $ua sec_to_dhms get_feed/;
%EXPORT_TAGS = ( DEFAULT => [qw/&get_dbh &get_ua/] );

my $dsn = "DBI:SQLite:dbname=/home/gustaf/prj/Post-to-fedi/database.db";

our $sql = {
	    all_urls=>qq{select url from entries},
	    unposted=>qq{select url,content from entries where posted = 0 and age <= strftime('%s', 'now') order by url, age},
	    update_status=>qq{update entries set posted = 1 where url=?},
	    insert_entry=>qq{insert into entries (url, posted, age, content) values (?, ? , ?, ? )},
	    status => qq{select url, posted, age, content from entries order by url desc},
	    delete_entry=>qq{delete from entries where url=?},

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
sub get_feed {
    my $ua = get_ua;
    my $r = $ua->get('https://gerikson.com/m/feed.json');
    
    if (!$r->is_success() or $r->header('Content-Type') !~ m{application/json}) {
	    warn "no results returned for feed URL!";
	    return {};
	}

#    my $json = JSON->new();
    my $feed = decode_json( $r->decoded_content() );
    my $feed_data;
    for my $item (@{$feed->{items}}) {

	my $ts1 = $item->{date_published};
	$ts1 =~ s/:(\d+)$/$1/;
	my $ts=Time::Piece->strptime($ts1,"%FT%T%z");
	my $tree = HTML::TreeBuilder->new_from_content($item->{content_html});
	my $out;
	$out = recurse( $tree, 0, $out );
	my @content_list;
	for my $idx (3.. scalar @$out -1) {
	    if ($out->[$idx]{content}) {
		push @content_list, $out->[$idx]{content};
	    }
	}

	my $content = $content_list[0] ? $content_list[0] : 'NO CONTENT';
	if (scalar @content_list == 1 and $content ne 'NO CONTENT') {
	$content .= ' 🔚';
    } else {
	$content .= ' ⤵️';
    }
	$feed_data->{$item->{url}}={content=>$content, ts=>$ts->epoch+6*60*60};
    }
    return $feed_data;
}

sub sec_to_dhms {
    my ($sec) = @_;
    my $days = int( $sec / ( 24 * 60 * 60 ) );
    my $hours   = ( $sec / ( 60 * 60 ) ) % 24;
    my $mins    = ( $sec / 60 ) % 60;   
    my $seconds = $sec % 60;

    my $out;
    $out = sprintf("%dd", $days) if $days;
    $out .= sprintf("%02dh", $hours?$hours:0);
    $out .= sprintf("%02dm",$mins?$mins:0) ;
    $out .= sprintf("%02ds",$seconds?$seconds:0);
    return $out;
}

sub recurse { # flatten the HTML tree into a list 
    my ( $node, $depth, $output ) = @_;

    my $unit;
    if ( ref $node ) {

        my $tag = $node->tag;
        push @$output, { tag => $tag };
        my @children = $node->content_list();
        for my $child_node (@children) {
            recurse( $child_node, $depth + 1, $output );
        }
    }
    else {

        push @$output, { content => $node };
    }
    return $output;
}
