# $Id: 2.0-generate.t,v 1.7 2003/01/18 01:13:42 comdog Exp $
use strict;

use Test::More tests => 25;

use_ok("XML::RSS");
use_ok("POSIX");

use constant DATE_TEMPLATE_LONG  => "%Y-%m-%dT%H:%M:%S%z";
use constant DATE_TEMPLATE_SHORT => "%Y/%m/%d";
use constant DATE_TEMPLATE_PUB   => "%c GMT";

my $current_date = &POSIX::strftime( DATE_TEMPLATE_LONG,  gmtime );
my $short_date   = &POSIX::strftime( DATE_TEMPLATE_SHORT, gmtime );
my $pub_date     = &POSIX::strftime( DATE_TEMPLATE_PUB,   gmtime );
ok( $current_date, "Current date: $current_date" );

use constant RSS_VERSION    => "2.0";
use constant RSS_SAVEAS     => "t/" . RSS_VERSION . "-generated.xml";

use constant RSS_MOD_PREFIX => "my";
use constant RSS_MOD_URI    => 'http://purl.org/my/rss/module/';

use constant RSS_BLOGCHANNEL_PREFIX => "blogChannel";
use constant RSS_BLOGCHANNEL_URI    => "http://backend.userland.com/blogChannelModule";

use constant RSS_CREATOR    => "joeuser\@example.com";
use constant RSS_ITEM_TITLE => "This is an item";
use constant RSS_ITEM_LINK  => "http://example.com/$short_date";
use constant RSS_ITEM_DESC  => "Yadda yadda yadda";


my $rss = XML::RSS->new( version => RSS_VERSION );
isa_ok( $rss, "XML::RSS" );

is( $rss->{'version'}, RSS_VERSION, 'Version is ' . RSS_VERSION );

# This includes all fields, only title, link, and description 
# are required.

ok( $rss->channel(
		 'title'        => "Test 2.0 Feed",
		 'link'         => "http://example.com/",
		 'description'  => "",
		 'language'     => 'en-us',
		 copyright      => 'Copyright 2002',
		 pubDate        => $current_date,
		 lastBuildDate  => $current_date,
		 docs           => 'http://backend.userland.com/rss',
		 managingEditor => 'editor\@example.com',
		 webMaster      => 'webmaster\@example.com',
		 category       => 'none',
		 ttl            => '60',
		 'generator'    => 'XML::RSS Test',
		), "Set RSS channel" );

ok($rss->image(
	       title       => 'Test Image',
	       url         => 'http://example.com/example.gif',
	       'link'      => 'http://example.com/',
	       description => 'Test Image',
	       height      => '25',
	       weight      => '144',
	      ), "Set RSS image" );

ok($rss->textinput(
		   title       => 'Search',
		   description => 'Search for an example',
		   name        => 'q',
		   'link'      => 'http://example.com/search.pl',
		  ), "Set RSS text input" );

ok($rss->add_item(
		  title       => RSS_ITEM_TITLE,
		  'link'      => RSS_ITEM_LINK,
		  description => RSS_ITEM_DESC,
		  author      => RSS_CREATOR,
		  category    => 'none',
		  comments    => "http://example.com/$short_date/comments.html",
		  permaLink   => "http://example.com/$short_date",
		  pubDate     => $pub_date,
		  source      => 'my brain',
		  sourceUrl   => 'http://example.com',
		 ), "Set one RSS item" );

my $len = length($rss->as_string());
ok( $len, "RSS feed has '$len' characters" );


ok( $rss->add_module( prefix => RSS_MOD_PREFIX, uri => RSS_MOD_URI ),
	"Added module: " . RSS_MOD_PREFIX );

# Dunno - some degree of weirdness
# with the constant that I don't
# feel like dealing with...
my $uri = RSS_MOD_URI;

is( $rss->{modules}->{$uri}, RSS_MOD_PREFIX, "Namespace URI is $uri" );

ok( $rss->save(RSS_SAVEAS), "Wrote to disk: " . RSS_SAVEAS );

my $size = -s (RSS_SAVEAS);
is( $size, $len, RSS_SAVEAS . " has '$size' characters.");

eval { $rss->parsefile( RSS_SAVEAS ) };
is( $@, '', "Parsed " . RSS_SAVEAS );

is( $rss->{channel}->{lastBuildDate}, $current_date,
       "Last built: " . $current_date );

cmp_ok( keys %{ $rss->{namespaces} }, ">=", 1,
       "RSS feed has at least one namespace");

my $prefix = RSS_BLOGCHANNEL_PREFIX;
ok( exists $rss->{namespaces}->{$prefix}, "$prefix namespace is registered" );

is($rss->{namespaces}->{$prefix}, RSS_BLOGCHANNEL_URI, RSS_BLOGCHANNEL_URI  );

isa_ok( $rss->{'items'} ,"ARRAY", "RSS object has an array of objects" );

is( scalar( @{$rss->{'items'}} ), 1, "RSS object has one item" );

is( $rss->{items}->[0]->{title},       RSS_ITEM_TITLE, RSS_ITEM_TITLE );

is( $rss->{items}->[0]->{link},        RSS_ITEM_LINK,  RSS_ITEM_LINK  );

is( $rss->{items}->[0]->{description}, RSS_ITEM_DESC,  RSS_ITEM_DESC  );

is( $rss->{items}->[0]->{author},      RSS_CREATOR,    RSS_CREATOR    );

#END{ unlink RSS_SAVEAS }

__END__

=head1 NAME

2.0-generate.t - tests for generating RSS 2.0 data with XML::RSS.pm

=head1 SYNOPSIS

 use Test::Harness qw (runtests);
 runtests (./XML-RSS/t/*.t);

=head1 DESCRIPTION

Tests for generating RSS 2.0 data with XML::RSS.pm

=head1 VERSION

$Revision: 1.7 $

=head1 DATE

$Date: 2003/01/18 01:13:42 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://backend.userland.com/rss2

=cu