#! /usr/bin/env perl
use Modern::Perl '2015';
###
use FindBin qw/$Bin/;
use Data::Dump qw/dump/;
use HTML::TreeBuilder;
use JSON;
use lib "$FindBin::Bin";
use Postfedi qw/get_dbh $sql get_feed/;

use utf8;

use open qw/ :std :encoding(utf8) /;
binmode( STDOUT, ':encoding(UTF-8)' );

my $feed_data = get_feed();
# compare what we have to the stuff in the DB
my $dbh     = get_dbh;
my $db_urls = $dbh->selectall_hashref( $sql->{all_urls}, 'url' );
my $sth     = $dbh->prepare( $sql->{insert_entry} ) or die $dbh->errstr;
my $offset =0;
for my $url ( sort keys %$feed_data ) {
    if ( !exists $db_urls->{$url} ) {
        say "==> adding $url";
	my $posted = $feed_data->{$url}{content} =~ /nopost/ ? 1 : 0;
        my $rv = $sth->execute( $url, $posted, time + 3600+$offset, $feed_data->{$url}{content} );
	$offset += 30 * 60;
#	say "DEBUG: Items in feed: $count";
    }
}


__END__
my $feed_file = '/home/gustaf/public_html/m/feed.json';

my $json_text = do {
    open( my $json_fh, "<:encoding(UTF-8)", $feed_file )
        or die "Can't open $feed_file: $!\n";
    local $/;
    <$json_fh>;
};
my $json = JSON->new();
my $feed = $json->decode($json_text);
my %feed_data;
my $count = 0;
for my $item ( @{ $feed->{items} } ) {

    my $tree = HTML::TreeBuilder->new_from_content( $item->{content_html} );
    my $out;
    $out = recurse( $tree, 0, $out );

    my @content_list;
    for my $idx ( 3 .. scalar @$out - 1 )
    {    # first 3 elements are html/head/body
        if ( $out->[$idx]{content} ) {
            push @content_list, $out->[$idx]{content};
#            last;
        }
    }
    my $content = $content_list[0] ? $content_list[0] : 'NO CONTENT';
    if (scalar @content_list == 1 and $content ne 'NO CONTENT') { # only one piece of content
	$content .= '';
    } else {
	$content .= ' ⤵️';
    }
    $feed_data{ $item->{url} } = $content;
    $count++;
}

#say "Number of items in feed: $count";
# say "Items in feed: ", scalar keys %feed_data;

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
