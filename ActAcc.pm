# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc;

require 5.005_62;
use strict;
use warnings; 
use Carp;
use Config;

use vars qw(
	$VERSION
	%EventName
	$EventName_setup
	%ObjectId
	$ObjectId_setup
	%StateName
	$StateName_setup
    @ISA $VERSION $AUTOLOAD
	@EXPORT @EXPORT_OK
	$EMDllFile
);

$VERSION = '0.4';

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into caller's namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw(
AccessibleObjectFromEvent 
AccessibleObjectFromWindow 
AccessibleObjectFromPoint
createEventMonitor
);

@EXPORT_OK = qw(
GetStateText 
GetRoleText 
StateConstantName 
ObjectIdConstantName 
EventConstantName 
nav 
GetStateTextComposite
menuPick
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
	$! = undef;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Win32::ActAcc macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Win32::ActAcc $VERSION;

use vars qw(%AO_);

sub createEventMonitor
{
	my $active = shift;
	my $rv = events_register($active);
	return $rv;
}

sub StateConstantName
{
	if (!$StateName_setup)
	{
		$StateName_setup = 1;
		$StateName{Win32::ActAcc::STATE_SYSTEM_NORMAL()} = 'STATE_SYSTEM_NORMAL';
		$StateName{Win32::ActAcc::STATE_SYSTEM_UNAVAILABLE()} = 'STATE_SYSTEM_UNAVAILABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_SELECTED()} = 'STATE_SYSTEM_SELECTED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_FOCUSED()} = 'STATE_SYSTEM_FOCUSED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_PRESSED()} = 'STATE_SYSTEM_PRESSED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_CHECKED()} = 'STATE_SYSTEM_CHECKED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_MIXED()} = 'STATE_SYSTEM_MIXED';
		eval { $StateName{Win32::ActAcc::STATE_SYSTEM_INDETERMINATE()} = 'STATE_SYSTEM_INDETERMINATE'; };
		$StateName{Win32::ActAcc::STATE_SYSTEM_READONLY()} = 'STATE_SYSTEM_READONLY';
		$StateName{Win32::ActAcc::STATE_SYSTEM_HOTTRACKED()} = 'STATE_SYSTEM_HOTTRACKED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_DEFAULT()} = 'STATE_SYSTEM_DEFAULT';
		$StateName{Win32::ActAcc::STATE_SYSTEM_EXPANDED()} = 'STATE_SYSTEM_EXPANDED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_COLLAPSED()} = 'STATE_SYSTEM_COLLAPSED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_BUSY()} = 'STATE_SYSTEM_BUSY';
		$StateName{Win32::ActAcc::STATE_SYSTEM_FLOATING()} = 'STATE_SYSTEM_FLOATING';
		$StateName{Win32::ActAcc::STATE_SYSTEM_MARQUEED()} = 'STATE_SYSTEM_MARQUEED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_ANIMATED()} = 'STATE_SYSTEM_ANIMATED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_INVISIBLE()} = 'STATE_SYSTEM_INVISIBLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_OFFSCREEN()} = 'STATE_SYSTEM_OFFSCREEN';
		$StateName{Win32::ActAcc::STATE_SYSTEM_SIZEABLE()} = 'STATE_SYSTEM_SIZEABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_MOVEABLE()} = 'STATE_SYSTEM_MOVEABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_SELFVOICING()} = 'STATE_SYSTEM_SELFVOICING';
		$StateName{Win32::ActAcc::STATE_SYSTEM_FOCUSABLE()} = 'STATE_SYSTEM_FOCUSABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_SELECTABLE()} = 'STATE_SYSTEM_SELECTABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_LINKED()} = 'STATE_SYSTEM_LINKED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_TRAVERSED()} = 'STATE_SYSTEM_TRAVERSED';
		$StateName{Win32::ActAcc::STATE_SYSTEM_MULTISELECTABLE()} = 'STATE_SYSTEM_MULTISELECTABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_EXTSELECTABLE()} = 'STATE_SYSTEM_EXTSELECTABLE';
		$StateName{Win32::ActAcc::STATE_SYSTEM_ALERT_LOW()} = 'STATE_SYSTEM_ALERT_LOW';
		$StateName{Win32::ActAcc::STATE_SYSTEM_ALERT_MEDIUM()} = 'STATE_SYSTEM_ALERT_MEDIUM';
		$StateName{Win32::ActAcc::STATE_SYSTEM_ALERT_HIGH()} = 'STATE_SYSTEM_ALERT_HIGH';
		eval { $StateName{Win32::ActAcc::STATE_SYSTEM_PROTECTED()} = 'STATE_SYSTEM_PROTECTED'; };
	}
	my $oik = shift;
	return $StateName{$oik};
}

sub ObjectIdConstantName
{
	if (!$ObjectId_setup)
	{
		$ObjectId_setup = 1;
		$ObjectId{Win32::ActAcc::CHILDID_SELF()} = 'CHILDID_SELF';
		$ObjectId{Win32::ActAcc::OBJID_WINDOW()} = 'OBJID_WINDOW';
		$ObjectId{Win32::ActAcc::OBJID_SYSMENU()} = 'OBJID_SYSMENU';
		$ObjectId{Win32::ActAcc::OBJID_TITLEBAR()} = 'OBJID_TITLEBAR';
		$ObjectId{Win32::ActAcc::OBJID_MENU()} = 'OBJID_MENU';
		$ObjectId{Win32::ActAcc::OBJID_CLIENT()} = 'OBJID_CLIENT';
		$ObjectId{Win32::ActAcc::OBJID_VSCROLL()} = 'OBJID_VSCROLL';
		$ObjectId{Win32::ActAcc::OBJID_HSCROLL()} = 'OBJID_HSCROLL';
		$ObjectId{Win32::ActAcc::OBJID_SIZEGRIP()} = 'OBJID_SIZEGRIP';
		$ObjectId{Win32::ActAcc::OBJID_CARET()} = 'OBJID_CARET';
		$ObjectId{Win32::ActAcc::OBJID_CURSOR()} = 'OBJID_CURSOR';
		$ObjectId{Win32::ActAcc::OBJID_ALERT()} = 'OBJID_ALERT';
		$ObjectId{Win32::ActAcc::OBJID_SOUND()} = 'OBJID_SOUND';
	}
	my $oik = shift;
	return $ObjectId{$oik};
}

sub EventConstantName
{
	if (!$EventName_setup)
	{
		$EventName_setup = 1;
		$EventName{Win32::ActAcc::EVENT_SYSTEM_SOUND()} = 'EVENT_SYSTEM_SOUND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_ALERT()} = 'EVENT_SYSTEM_ALERT';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_FOREGROUND()} = 'EVENT_SYSTEM_FOREGROUND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MENUSTART()} = 'EVENT_SYSTEM_MENUSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MENUEND()} = 'EVENT_SYSTEM_MENUEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART()} = 'EVENT_SYSTEM_MENUPOPUPSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPEND()} = 'EVENT_SYSTEM_MENUPOPUPEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_CAPTURESTART()} = 'EVENT_SYSTEM_CAPTURESTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_CAPTUREEND()} = 'EVENT_SYSTEM_CAPTUREEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MOVESIZESTART()} = 'EVENT_SYSTEM_MOVESIZESTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MOVESIZEEND()} = 'EVENT_SYSTEM_MOVESIZEEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_CONTEXTHELPSTART()} = 'EVENT_SYSTEM_CONTEXTHELPSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_CONTEXTHELPEND()} = 'EVENT_SYSTEM_CONTEXTHELPEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_DRAGDROPSTART()} = 'EVENT_SYSTEM_DRAGDROPSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_DRAGDROPEND()} = 'EVENT_SYSTEM_DRAGDROPEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_DIALOGSTART()} = 'EVENT_SYSTEM_DIALOGSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_DIALOGEND()} = 'EVENT_SYSTEM_DIALOGEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_SCROLLINGSTART()} = 'EVENT_SYSTEM_SCROLLINGSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_SCROLLINGEND()} = 'EVENT_SYSTEM_SCROLLINGEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_SWITCHSTART()} = 'EVENT_SYSTEM_SWITCHSTART';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_SWITCHEND()} = 'EVENT_SYSTEM_SWITCHEND';
		$EventName{Win32::ActAcc::EVENT_SYSTEM_MINIMIZESTART()} = 'EVENT_SYSTEM_MINIMIZESTART';
		$EventName{Win32::ActAcc::EVENT_OBJECT_CREATE()} = 'EVENT_OBJECT_CREATE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_DESTROY()} = 'EVENT_OBJECT_DESTROY';
		$EventName{Win32::ActAcc::EVENT_OBJECT_SHOW()} = 'EVENT_OBJECT_SHOW';
		$EventName{Win32::ActAcc::EVENT_OBJECT_HIDE()} = 'EVENT_OBJECT_HIDE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_REORDER()} = 'EVENT_OBJECT_REORDER';
		$EventName{Win32::ActAcc::EVENT_OBJECT_FOCUS()} = 'EVENT_OBJECT_FOCUS';
		$EventName{Win32::ActAcc::EVENT_OBJECT_SELECTION()} = 'EVENT_OBJECT_SELECTION';
		$EventName{Win32::ActAcc::EVENT_OBJECT_SELECTIONADD()} = 'EVENT_OBJECT_SELECTIONADD';
		$EventName{Win32::ActAcc::EVENT_OBJECT_SELECTIONREMOVE()} = 'EVENT_OBJECT_SELECTIONREMOVE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_SELECTIONWITHIN()} = 'EVENT_OBJECT_SELECTIONWITHIN';
		$EventName{Win32::ActAcc::EVENT_OBJECT_STATECHANGE()} = 'EVENT_OBJECT_STATECHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_LOCATIONCHANGE()} = 'EVENT_OBJECT_LOCATIONCHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_NAMECHANGE()} = 'EVENT_OBJECT_NAMECHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_DESCRIPTIONCHANGE()} = 'EVENT_OBJECT_DESCRIPTIONCHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_VALUECHANGE()} = 'EVENT_OBJECT_VALUECHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_PARENTCHANGE()} = 'EVENT_OBJECT_PARENTCHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_HELPCHANGE()} = 'EVENT_OBJECT_HELPCHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_DEFACTIONCHANGE()} = 'EVENT_OBJECT_DEFACTIONCHANGE';
		$EventName{Win32::ActAcc::EVENT_OBJECT_ACCELERATORCHANGE()} = 'EVENT_OBJECT_ACCELERATORCHANGE';
	}
	my $ek = shift;
	return $EventName{$ek};
}

sub nav
{
	my $ao = shift;

	# Default to the desktop window
	$ao = Win32::ActAcc::AccessibleObjectFromWindow(Win32::GuiTest::GetDesktopWindow()) unless defined($ao);

	my $pChain = shift;
	my $level = shift;
	
	$level = 0 unless defined($level);

	my $rv;

	my @chain = @{$pChain};
	my $isLeaf = (1==@chain);
	#print STDERR Dumper(\@chain) . "\n";
	my $seeking = shift @chain; # string {role}title OR hashref {name,role,...}
	my $seekingRole;
	my $seekingName;
	if (ref($seeking) eq 'HASH')
	{
		$seekingRole = $$seeking{'role'}; # may be undef OR localized name
		$seekingName = $$seeking{'name'}; # may be string OR regexp OR undef
	}
	else
	{
		$seekingRole = undef;
		$seekingName = $seeking;
		if ($seekingName =~ /^\{(.*)\}/)
		{
			$seekingRole = $1;
			$seekingName = $';
			if (0==length($seekingName)) { $seekingName = undef; }
		}
	}

	#print STDERR (' ' x $level)."Looking for role=$seekingRole, name=$seekingName\n";

	my @ch = $ao->AccessibleChildren();
	my $ch;
	my $client;
	foreach $ch (@ch)
	{
		my $rc = $ch->get_accRole();
		if (Win32::ActAcc::ROLE_SYSTEM_CLIENT() == $rc) { $client = $ch; }

		# does it match?
		my $chName = $ch->get_accName();
		$chName = "" unless defined($chName);

		my $nameMatches;
		if (!defined($seekingName))
		{
			$nameMatches = 1;
		}
		else
		{
			if (ref($seekingName) eq 'Regexp')
			{
				$nameMatches = $chName =~ /$seekingName/;
			}
			else
			{
				$nameMatches = $chName eq $seekingName;
			}
		}

		next unless $nameMatches;

		if (defined($seekingRole))
		{
			my $chRole = Win32::ActAcc::GetRoleText($ch->get_accRole());
			next unless $chRole eq $seekingRole;
		}

		# if so, recurse OR return.
		if (!$isLeaf)
		{
			$rv = Win32::ActAcc::nav($ch, \@chain, 1+$level);
			last if (defined($rv));
		}
		else
		{
			$rv = $ch;
		}
	}

	# Traverse client area, if no direct hit and there is a client.
	if (!defined($rv) && defined($client))
	{
		$rv = nav($client, $pChain, 1+$level);
	}

	return $rv;
}

sub navlist
#never debugged
{
	my $ao = shift;
	my $pChain = shift;
	my $level = shift;
	my $pResults = shift;

	# Default to the desktop window
	$ao = Win32::ActAcc::AccessibleObjectFromWindow(Win32::GuiTest::GetDesktopWindow()) unless defined($ao);

	$level = 0 unless defined($level);

	my @chain = @{$pChain};
	my $isLeaf = (1==@chain);
	#print STDERR Dumper(\@chain) . "\n";
	my $seeking = shift @chain;
	my $seekingRole = '';
	my $seekingName = $seeking;
	if ($seeking =~ /^\{(.*)\}/)
	{
		$seekingRole = $1;
		$seekingName = $';
	}

	#print STDERR (' ' x $level)."Looking for role=$seekingRole, name=$seekingName\n";

	my @ch = $ao->AccessibleChildren();
print STDERR "---\n" . join("\n", map($_->describe(), @ch)) . "\n";

	my $ch;
	my $isSole = (1==@ch);
	foreach $ch (@ch)
	{
		# does it match?
		my $chName = $ch->get_accName();
		$chName = "" unless defined($chName);
		my $chRole = "";
		eval { $chRole = Win32::ActAcc::GetRoleText($ch->get_accRole()); };

		my $jatch = ($chName eq $seekingName) && (!defined($seekingRole) || ($chRole eq $seekingRole));
		if ($isSole && !$jatch && @chain)
		{
			$jatch = ($chName eq "") || ($ch->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_CLIENT());
		}

		if ($jatch)
		{
			if (!$isLeaf)
			{
				# look deeper
				Win32::ActAcc::navlist($ch, \@chain, 1+$level, $pResults);
			}
			else
			{
				# no more criteria to match: we have a hit.
				push(@$pResults, $ao);
			}
		}
		$isSole = 0;
	}
}

# menuPick usage:
#
# my $menubar = ...
# my $ehDlg = Win32::ActAcc::createEventMonitor(0);
# menuPick($menubar, +[ qr/Format/, qr/Font/ ], \$ehDlg);

sub menuPick
{
	my $self = shift;
	my $pchoices = shift; # list of regexp
	my $pListener = shift;

	my @choices = @$pchoices;

	croak("Not a menubar or menu item") unless (
			($self->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_MENUBAR()) || 
			($self->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_MENUITEM()));

	my $firstChoice = shift @choices;

	my $menuHead = $self->findDescendant(
		sub
		{ 
			my $n = $_->get_accName(); 
			(defined($n) && $n =~ /$firstChoice/) && 
				($_->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_MENUITEM()) 
		});

	# Click menu-head and, if further choices to be made, wait for popup menu
	{
		$menuHead->click($pListener);
		if (@choices)
		{
			$$pListener->waitForEvent(
				+{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART() });
			menuPick($menuHead, \@choices, $pListener);
		}
	}
}

sub GetStateTextComposite
{
	my $bits = shift;
	my @stateTexts;	
	my $acc = 1;  # bit-0
	for (my $b = 0; $b < 32; $b++)
	{
		if ($bits & $acc)
		{
			push(@stateTexts, GetStateText($acc));	
		}
		$acc <<= 1;
	}
	return join('+', @stateTexts);
}

sub click
{
	my $x = shift;
	my $y = shift;
	my $peventMonitorOptional = shift;

	my ($mx, $my) = pixelToMickeys($x,$y);

	if (defined($peventMonitorOptional))
	{
		$$peventMonitorOptional->activate(1);
	}

	Win32::GuiTest::SendMouseMoveAbs($mx, $my);
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
}

#general-purpose
sub pixelToMickeys
{
	my ($x,$y) = @_;

	# scale by desktop window size
	my $cxScreen = Win32::ActAcc::GetSystemMetrics(Win32::ActAcc::SM_CXSCREEN());
	my $cyScreen = Win32::ActAcc::GetSystemMetrics(Win32::ActAcc::SM_CYSCREEN());

	my $mickeysX = ($x << 16) / $cxScreen;
	my $mickeysY = ($y << 16) / $cyScreen;

	return ($mickeysX, $mickeysY);
}

#general-purpose
sub clickPix
{
	my ($pixX, $pixY) = @_;
	my ($mickeysX, $mickeysY) = pixelToMickeys($pixX, $pixY);
	Win32::GuiTest::SendMouseMoveAbs($mickeysX, $mickeysY);
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
}


package Win32::ActAcc::AO;

sub describe_meta
{
	return "role:name {state,(location),hwnd}"; # keep synchronized with describe()
}

sub describe
{
	my $ao = shift;
	my $name = $ao->get_accName();
	my $role = "?";
	eval { $role = Win32::ActAcc::GetRoleText($ao->get_accRole()); };
	my $state = "?";
	eval { $state = Win32::ActAcc::GetStateTextComposite($ao->get_accState()); };
	my ($left, $top, $width, $height);
	my $location;
	eval 
	{
		($left, $top, $width, $height) = $ao->accLocation();
		$location = "($left,$top,$width,$height)";
	};
	my $hwnd = "(no HWND)";
	eval 
	{
		my $h = $ao->WindowFromAccessibleObject();
		$hwnd = sprintf("%08lx",$h);
	};

	$name = "(undef)" unless defined($name);
	$location = "(location error)" unless defined($location);
	return "$role:$name {$state,($location),$hwnd}"; # keep synchronized with describe_meta()
}

sub NavigableChildren
{
	my $ao = shift;
	my @rv;
	my $ch = $ao->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD());
	while (defined($ch))
	{
		push(@rv,$ch);
		my $nx = undef;
		eval { $nx = $ch->accNavigate(Win32::ActAcc::NAVDIR_NEXT()); };
		$ch = $nx;
	}
	return @rv;
}

sub findDescendant
{
	my $ao = shift;
	my $comparator = shift;
	my $pResults = shift;

	if (!defined($pResults))
	{
		my @L;
		$ao->findDescendant($comparator, \@L);
		if (wantarray)
		{
			return @L;
		}
		else
		{
			die if (@L>1);
			my $rv = shift @L;
			return $rv;
		}
	}
	else
	{
		if (ref($comparator) eq "Regexp")
		{
			my $t = $ao->describe();
			if ($t =~ /$comparator/)
			{
				push(@$pResults, $ao);
			}
		}
		elsif (ref($comparator) eq "CODE")
		{
			if (eval{&$comparator($ao)})
			{
				push(@$pResults, $ao);
			}
		}
		else
		{
			croak("findDescendant must be given a Regexp or a CODE reference");
		}

		my @ch = $ao->AccessibleChildren();
		foreach(@ch)
		{
			findDescendant($_,$comparator, $pResults);
		}
	}
}

sub center
{
	my $self = shift;
	my $rv = undef;

	my ($left, $top, $width, $height) = $self->accLocation();

	my $centerX = $left + $width/2;
	my $centerY = $top + $height/2;

	$rv = +[ $centerX, $centerY ];
	return $rv;
}

sub click
{
	my $self = shift;
	my $peventMonitorOptional = shift;
	my $c = $self->center();
	Win32::ActAcc::click(@$c,$peventMonitorOptional);
}

sub debug_tree
{
	my $ao = shift;
	my $level = shift;

	print STDERR "" . (' ' x $level) . ($ao->describe()) . "\n";

	my @ch = $ao->AccessibleChildren();
	foreach(@ch)
	{
		debug_tree($_, 1+$level);
	}
}

package Win32::ActAcc::Event;

sub getAO
{
	my $self = shift;
	return Win32::ActAcc::AccessibleObjectFromEvent($$self{'hwnd'}, $$self{'idObject'}, $$self{'idChild'});
}

sub evDescribe
{
	my $e = shift;

	my $L = Win32::ActAcc::EventConstantName($$e{'event'});
	my $ao = eval {Win32::ActAcc::AccessibleObjectFromEvent($$e{'hwnd'}, $$e{'idObject'}, $$e{'idChild'}) };
	if (defined($ao))
	{
		$L = $L . ' ' . $ao->describe();
	}
	else
	{
		if (0 != $$e{'hwnd'})
		{
			$L = $L . ' ' . sprintf("hwnd:%08lx", $$e{'hwnd'});
		}
	}
	my $objname = Win32::ActAcc::ObjectIdConstantName($$e{'idObject'});
	if (defined($objname))
	{
		$L = $L . " $objname";
	}
	else
	{
		$L = $L . ' ' . sprintf("idObject:%d", $$e{'idObject'});
	}
	if (!defined($ao))
	{
		$L = $L . ' ' . sprintf("idChild:%d", $$e{'idChild'});
	}
	if (exists($$e{'hWinEventHook'}))
	{
		$L = $L . ' ' . sprintf("hook:%08x", $$e{'hWinEventHook'});
	}
	return $L;
}

package Win32::ActAcc::EventMonitor;

sub waitForEvent
{
	my $self = shift;
	my $pQuarry = shift;
	my $timeoutSecs = shift; # optional

	my $pComparator;
	if (ref($pQuarry) eq 'HASH')
	{
		$pComparator = sub{waitForEvent_dfltComparator($pQuarry, @_)};
	}
	else
	{
		$pComparator = $pQuarry;
	}
	
	my $return_ao; 

	PATIENTLY_AWAITING_QUARRY: for (my $sc = 0; !defined($timeoutSecs) || ($sc < $timeoutSecs); $sc++)
	{
		DEVOUR_BACKLOG: for (;;)
		{
			my $e = $self->getEvent();
			last DEVOUR_BACKLOG unless defined($e);
			#print STDERR $e->evDescribe() . "\n";
			if (&$pComparator($e))
			{
				eval { $return_ao = $e->getAO() }; # occasional HRESULT=80004005
				last PATIENTLY_AWAITING_QUARRY;
			}
		}
		sleep(1);
	}
	return $return_ao;
}

sub waitForEvent_dfltComparator
{
	my $pQuarry = shift;
	my $e = shift;

	return undef unless $$e{'event'} == $$pQuarry{'event'};

	my $ao = eval { $e->getAO() };
	return undef unless defined($ao);

	if (exists($$pQuarry{'role'}))
	{
		return undef unless $ao->get_accRole() == $$pQuarry{'role'};
	}

	if (exists($$pQuarry{'name'}))
	{
		my $aoname = $ao->get_accName();
		if ('Regexp' eq ref($$pQuarry{'name'}))
		{
			return undef unless defined($aoname) && ($aoname =~ /$$pQuarry{'name'}/);
		}
		else
		{
			return undef unless $aoname eq $$pQuarry{'name'};
		}
	}

	1;
}

sub debug_spin
{
	my $self = shift;
	my $secs = shift;

	$self->waitForEvent(sub{print Win32::ActAcc::Event::evDescribe(@_)."\n";undef}, $secs);
}

package Win32::ActAcc;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

