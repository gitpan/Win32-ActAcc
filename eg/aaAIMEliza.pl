# Copyright 2001, Phill Wolf.  See README.
# pbwolf@cpan.org

# Win32::ActAcc (Active Accessibility) sample

=head1 NAME

aaAIMEliza - Chatbot::Eliza answers your incoming AOL Instant Messages

=head1 SYNOPSIS

This Perl script auto-responds to "AOL Instant Messenger" messages,
using the Eliza chatbot.  (You can easily supply a different response strategy.)

The script will obviously need an update every time AIM changes.  
By the time you read this, probably it won't work anymore until you hack away at it.
Therefore, its value is principally in the splendor of its usage of Active Accessibility,
rather than in its solving your correspondents' immediate psychological problems.

=head1 HOW IT WORKS

This script's AIMEventMonitor runs until you stop it.  Usually, it is dormant.

AIMEventMonitor wakes up whenever an "Instant Message" window is in the foreground,
and checks who the correspondent is.

AIMEventMonitor establishes an AIMSession for each IM correspondent, 
using a factory that in this sample
actually creates ElizaSession objects.

AIMEventMonitor sends each incoming message to the AIMSession (here ElizaSession)
for its correspondent.

An ElizaSession maintains an Eliza engine for its correspondent.  So, in case 
more than one person AIMs you while this script is running, each correspondent
gets the complete and secure attention of one dedicated psychotherapist.

=cut

use strict;
use Data::Dumper;
use Win32::OLE;
use Win32::ActAcc;

Win32::OLE->Initialize();

#-------------------------------------- AIMSession
#
# This is the base class of the response strategies.

package AIMSession;
use strict;

#  'correspondent' member is name of the sender of messages we're receiving.
#  'onMessage' event is how we handle each incoming instant message.

# Do not override 'new' in a derived package. 
sub new
{
    my $class = shift;
    my $self = +{};
    bless $self, $class;
    return $self;
}

# onMessage is given the incoming message.
# It returns the response (or undef if no response is to be made).
sub onMessage {
  my $self = shift;
  my $msg = shift;
  print "New message: $msg\n";
  return undef; # i.e., do not respond
}

#-------------------------------------- AIMEventMonitor
#
# AIMEventMonitor is the long-running procedure (run) and 
# supporting procedures.
# 
# 

package AIMEventMonitor;

use strict;
use HTML::Parser 3.19;
use Win32::GuiTest (qw(SendKeys));
use Data::Dumper;

# find conversation child-window, given the AIM frame window.
sub findConversation {
  my $aoIM = shift;
  my @clients = grep($_->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_CLIENT(), $aoIM->AccessibleChildren());
  do { print @clients." clients!\n"; return undef } unless @clients==1;
  my $client = $clients[0];
  my @htmls = grep($_->get_accName() =~ /\<HTML\>/, $client->AccessibleChildren());
  if (@htmls != 1  &&  @htmls != 2) {print @htmls." HTMLs!\n"; return undef}
  return $htmls[0];
}

# 'run' is the long-running procedure.
# Its algorithm is more or less:
#    - Find AIM window in the foreground.
#    - Monitor the HTML conversation pane of the AIM window for a change.
#    - See that the change is an incoming message, not an outgoing one.
#    - Pass the new message to the chatbot.
#    - Transmit the chatbot's response to the AIM window.
#    - Close the AIM window. 
#    - Repeat.
# But, in the event of a change in focus (EVENT_SYSTEM_FOREGROUND),
# go find, or wait for, a new AIM window before repeating the above.
#
# One rude twist is that the AIM window sometimes disappears
# without the script receiving word that another window has 
# come to the foreground.  In particular, "command prompt" windows
# seem to be delinquent in sending foreground notifications.

# We close the AIM window after each message because:
#  (1) otherwise multiple correspondents would get tangled up. (?)
#  (2) there seems to be a buffer size limit somewhere and
#      as the conversation gets to be about 4k long, we see
#      only the first 4k or so.

sub run {
  my $sinkFactory = shift;
  my %mapCorrespondentToSession;
  my $eh = Win32::ActAcc::createEventMonitor(1);

  while (1) {
    my $aoAim = $eh->waitForEvent(+{
				    'event'=>Win32::ActAcc::EVENT_SYSTEM_FOREGROUND(),
				    'name'=>qr/ - Instant Message/,
				    'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW() });

    my $title = $aoAim->get_accName();
    die unless $title =~ / - Instant Message/;
    my $correspondent = $`;
    if (!exists($mapCorrespondentToSession{$correspondent})) {
      my $s = $mapCorrespondentToSession{$correspondent} = &$sinkFactory();
      $$s{'correspondent'} = $correspondent;
    }
    my $session = $mapCorrespondentToSession{$correspondent};

    processInputIfAny($session, $aoAim, $correspondent);

    # Close window since someone (AIM? Windows?) has a limited buffer size.
    SendKeys("%{F4}");  
  }
}

# AIM's conversation window reveals its contents as HTML!
# This procedure reduces the conversation to plaintext
# using an HTML parser.
# Luckily, HTML::Parser comes with a sample showing just how to do this.
sub getConversationAsText {
  my $aoAim = shift;

  my $aoBanter = findConversation($aoAim);
  my $html = $aoBanter->get_accName();

  my %inside;
  my $accumulator;

  my $tagsub = sub {
      my($tag, $num) = @_;
      $inside{$tag} += $num;
      if ($tag =~ /^br$/i) { $accumulator .= "\n"; }
    };

  my $textsub = sub {
      return if $inside{script} || $inside{style};
      $accumulator .= $_[0];
    };

  my $hparser = HTML::Parser->new('api_version'=>3,
				  'handlers'=>['start' => [$tagsub, "tagname, '+1'"],
					     'end'   => [$tagsub, "tagname, '-1'"],
					     'text'  => [$textsub, "dtext"],],
				  'marked_sections'=>1);
  $hparser->parse($html);

  return $accumulator;
}


sub processInputIfAny {
  my ($session, $aoAim, $correspondent) = @_;

  my $t = getConversationAsText($aoAim);

  if ($t ne $$session{'text'}) {
    $$session{'text'} = $t;
    my @L = split("\n", $t);
    my $lastLine = $L[$#L];

    # Respond only to *incoming* messages.
    if ($lastLine =~ /^$correspondent: /) {
      my $pith = $';
      my $answer = $session->onMessage($pith);
      if (defined($answer)) {
	$answer =~ tr/\{\}\~\+\^\%//d; # elide GuiTest commando chars (yuck)
	SendKeys($answer);
	SendKeys("~"); # enter key
      }
    }
  }
}

#-------------------------------------- ElizaSession
#
# This is the chatbot strategy that adapts Eliza and AIM specifically to each other.

package ElizaSession;

use vars qw(@ISA);
@ISA=qw(AIMSession);

use Chatbot::Eliza;

sub onMessage {
  my $self = shift;
  my $msg = shift;
  my $rv;
  if (!exists($$self{'doctor'})) {
    $$self{'doctor'} = new Chatbot::Eliza;
    # seed the random number generator (taken from Eliza sample)
    srand( time ^ ($$ + ($$ << 15)) ); 
    # The introductory message, comes from Emacs' "doctor" facility
    # rather than Chatbot::Eliza.
    $rv = "I am the psychotherapist.  Please, describe your problems.";
  }
  else {
    $rv = $$self{'doctor'}->transform($msg);
  }

  print "$$self{'correspondent'}:$msg\n  -->$rv\n";

  return $rv;
}

#-------------------------------------- main
package main;

print "I'm going to wait until an AOL Instant Message window is in the foreground.\n";
&AIMEventMonitor::run( 
   sub { new ElizaSession(); }  # factory method for AIM sessions
);


