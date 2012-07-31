#!/usr/bin/perl

#################################################################################
#										#
#				 Announce - v0.1				#
#										#
# IMPORTANT: You have to set $url before the bot is able to work!		#
#################################################################################

## SET THIS UP! #
my $url = 0;	#
#################

use strict;
use warnings;
use Term::Cap;
use Term::ANSIColor;

use Net::IRC;
use Data::Dumper;

use XML::RSS::Parser::Lite;
#use LWP::Simple;
use LWP 5.64;
use HTTP::Cookies;

my $irc = new Net::IRC;

my $ownNick = "Announce";
my $logfile = "announce.log";

# unixtime of last poll
my $lastPoll = 0;

# unixtime of last pulic message in channel
my $lastActionInChannel = 0;

initialize();

# create connection
my $conn = $irc->newconn(
	Server		=> shift || 'localhost',
	Port		=> shift || '6667',
	Nick		=> "$ownNick",
	Ircname		=> 'I like to announce new threads!',
	Username	=> 'hello'
);

$conn->{channel} = shift || '#inf';


sub initialize {
	init_view();
	update_view();
}

sub on_connect {
	my $conn = shift;

	# join channel and greet
	$conn->join($conn->{channel});
	#$conn->privmsg($conn->{channel}, 'Hello everyone!');
	$conn->{connected} = 1;
}

sub on_join {

	# get connection and event object
	my ($conn, $event) = @_;

	# this is the nick that just joined
	my $nick = $event->{nick};
}

sub start_posting {
	eval {
		local $SIG{ALRM} = \&post;
		alarm 5;
	}
}


sub post {

	my $lastGuid = load_last_topic_guid();

	# get RSS data
	# initialize browser with the appropriate cookies
	my $browser = LWP::UserAgent->new;
	$browser->cookie_jar( HTTP::Cookies::Netscape->new(
		'file' => 'cookies.lwp',
		#'autosave' => 1
	));

	my $response = $browser->get( $url );

	die "Can't get $url -- ", $response->status_line
	 unless $response->is_success;

	my $rss = new XML::RSS::Parser::Lite;
	$rss->parse($response->content);

	my %newTitles;
	for (my $i=$rss->count()-1; $i>=0; $i--) {
		my $post = $rss->get($i);
		my $guid = get_guid_from_url($post->get('url'));
		if ( $guid > $lastGuid ) {
			$lastGuid = $guid;
			print "neues topic mit guid=" . $guid . "\n";
			(my $newTopicLink = $post->get('url') ) =~ s/&amp;/&/g;
			my $newTopicText = $post->get('title');
			if ( $newTitles{$newTopicText} == 1 ) {
				# this topic has already been announced this time
				# this is why it is not announced a second time
				#continue;
			} else {
				# add new topic to list of announced topics
				# and announce it now
				$newTitles{$newTopicText} = 1;
				$conn->privmsg($conn->{channel}, "Neues im Forum: $newTopicText. Link: $newTopicLink");
			}
		}
	}

	if ( $lastGuid > load_last_topic_guid() ) {
		save_last_topic_guid($lastGuid);
	}

	$lastPoll = time();
	update_view();

}

sub on_public {
	# connection object and event hash
	my ($conn, $event) = @_;

	# this is what was said in the event
	my $text = $event->{args}[0];

	$lastActionInChannel = time();
	update_view();

	# TODO: exclude own messages to the channel?! or lock it during execution of post()
	# poll the forum at most every 30 seconds
	if ( $lastPoll + 30 < time() ) {
		# update statistics
		$lastPoll = time();
		post();
	}

}

sub on_msg {
	my ($conn, $event) = @_;

	my $nick = $event->{nick};
	my $text = $event->{args}[0];
	# it is not necessary to /msg the bot
	if ( $text eq "check" ) {
		post();
		$conn->privmsg($nick, "Checked for new posts right now.");
	} else {
		$conn->privmsg($nick, "I don't like to speak to people;)");
	}
}


sub default {
	my ($conn, $event) = @_;
	print Dumper($event);
}

sub logging {
	# nothing to do
	#my $msg = shift;
	#print $msg. "\n";
}

sub init_view {
	my $size;
	my $rows;
	my $cols;
	eval { $size = `stty size` };
	if ( $size =~ /^\s*(\d+)\s(\d+)\s*$/ ) {
		$rows = $1;
		$cols = $2;
	}
}

# only called in initialize() by now
sub update_view {
	my $t = Tgetent Term::Cap {TERM=>undef, OSPEED=>9600};

	print $t->Tputs("cl");
	print $t->Tgoto("cm", 40, 1);
	print "Announce-Bot v0.1\n";
	print $t->Tgoto("cm", 10, 5);
	print "Nick: $ownNick\n\n";
	print $t->Tgoto("cm", 10, 7);
	print "Logfile: $logfile\n";
	print $t->Tgoto("cm", 10, 9);
	print "Last Topic: " . load_last_topic_guid() . "\n";
	print $t->Tgoto("cm", 10, 11);
	print "Last Poll: " . get_formatted_time($lastPoll) . "\n";
	print $t->Tgoto("cm", 10, 13);
	print "Last Action in Channel: " . get_formatted_time($lastActionInChannel) . "\n";
}


# load last topic GUID from file
sub load_last_topic_guid() {
        my $result = open LASTTOPICFILE, "< ./lastTopic.log" or die "Cannot open lastTopic-file to read: $!";

        my $lastTopic = "";
        $lastTopic = <LASTTOPICFILE>;

        close LASTTOPICFILE;
        return $lastTopic;
}

# save new last topic GUID to file
sub save_last_topic_guid {
        my $guid = shift;
        open LASTTOPICFILE, "> ./lastTopic.log" or die "Cannot open lastTopic-file to write: $!";
        print LASTTOPICFILE $guid;
        close LASTTOPICFILE;

}

sub get_guid_from_url($url) {
        my $url = shift;
        if ( $url =~ /postID=(\d*)/ ) {
                print "guid=" . $1 . "\n";
                return $1;
        } else {
                print "invalid url";
        }



}

# if called with a timestamp as argument, get_timestamp return a formatted time string
# if called without any argument, get_timestamp returns the current time as a formatted string
sub get_formatted_time {
	my $timestamp = shift || time();

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
        if ($mon < 10) { $mon = "0$mon"; }
        if ($hour < 10) { $hour = "0$hour"; }
        if ($min < 10) { $min = "0$min"; }
        if ($sec < 10) { $sec = "0$sec"; }
        $year=$year+1900;

        return $mday . "." . $mon . "." . $year . " " . $hour . ":" . $min . ":" . $sec;
}

sub ping {
	my ($self, $event) = @_;
	my $verbose = $self->verbose;

	# Reply to PING from server as quickly as possible.
	if ($event->type eq "ping") {
		$self->sl("PONG " . (CORE::join ' ', $event->args));
		post();
	}

}

# The end of MOTD (message of the day), numbered 376 signifies we've connect
$conn->add_handler('376', \&on_connect);
$conn->add_handler('join', \&on_join);
$conn->add_handler('public', \&on_public);
$conn->add_handler('msg', \&on_msg);
# $conn->add_handler('nick', \&default);
$conn->add_handler('disconnect', \&default);
$conn->add_handler('leaving', \&default);
$conn->add_handler('error', \&default);
$conn->add_handler('ping', \&ping);

$irc->start();
