# Copyright 2001, Phill Wolf.  See README.

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
        @rolesk %rolesn $rolesn_setup @eventsk @statesk @objidsk @selflagsk @navdirsk
);

$VERSION = '1.0';

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@rolesk = qw(
ROLE_SYSTEM_TITLEBAR ROLE_SYSTEM_MENUBAR ROLE_SYSTEM_SCROLLBAR ROLE_SYSTEM_GRIP ROLE_SYSTEM_SOUND ROLE_SYSTEM_CURSOR 
ROLE_SYSTEM_CARET ROLE_SYSTEM_ALERT ROLE_SYSTEM_WINDOW ROLE_SYSTEM_CLIENT ROLE_SYSTEM_MENUPOPUP ROLE_SYSTEM_MENUITEM 
ROLE_SYSTEM_TOOLTIP ROLE_SYSTEM_APPLICATION ROLE_SYSTEM_DOCUMENT ROLE_SYSTEM_PANE ROLE_SYSTEM_CHART ROLE_SYSTEM_DIALOG 
ROLE_SYSTEM_BORDER ROLE_SYSTEM_GROUPING ROLE_SYSTEM_SEPARATOR ROLE_SYSTEM_TOOLBAR ROLE_SYSTEM_STATUSBAR 
ROLE_SYSTEM_TABLE ROLE_SYSTEM_COLUMNHEADER ROLE_SYSTEM_ROWHEADER ROLE_SYSTEM_COLUMN ROLE_SYSTEM_ROW ROLE_SYSTEM_CELL 
ROLE_SYSTEM_LINK ROLE_SYSTEM_HELPBALLOON ROLE_SYSTEM_CHARACTER ROLE_SYSTEM_LIST ROLE_SYSTEM_LISTITEM 
ROLE_SYSTEM_OUTLINE ROLE_SYSTEM_OUTLINEITEM ROLE_SYSTEM_PAGETAB ROLE_SYSTEM_PROPERTYPAGE ROLE_SYSTEM_INDICATOR 
ROLE_SYSTEM_GRAPHIC ROLE_SYSTEM_STATICTEXT ROLE_SYSTEM_TEXT ROLE_SYSTEM_PUSHBUTTON ROLE_SYSTEM_CHECKBUTTON 
ROLE_SYSTEM_RADIOBUTTON ROLE_SYSTEM_COMBOBOX ROLE_SYSTEM_DROPLIST ROLE_SYSTEM_PROGRESSBAR ROLE_SYSTEM_DIAL 
ROLE_SYSTEM_HOTKEYFIELD ROLE_SYSTEM_SLIDER ROLE_SYSTEM_SPINBUTTON ROLE_SYSTEM_DIAGRAM ROLE_SYSTEM_ANIMATION 
ROLE_SYSTEM_EQUATION ROLE_SYSTEM_BUTTONDROPDOWN ROLE_SYSTEM_BUTTONMENU ROLE_SYSTEM_BUTTONDROPDOWNGRID 
ROLE_SYSTEM_WHITESPACE ROLE_SYSTEM_PAGETABLIST ROLE_SYSTEM_CLOCK
);

@eventsk = qw(
EVENT_SYSTEM_SOUND EVENT_SYSTEM_ALERT EVENT_SYSTEM_FOREGROUND EVENT_SYSTEM_MENUSTART EVENT_SYSTEM_MENUEND 
EVENT_SYSTEM_MENUPOPUPSTART EVENT_SYSTEM_MENUPOPUPEND EVENT_SYSTEM_CAPTURESTART EVENT_SYSTEM_CAPTUREEND 
EVENT_SYSTEM_MOVESIZESTART EVENT_SYSTEM_MOVESIZEEND EVENT_SYSTEM_CONTEXTHELPSTART EVENT_SYSTEM_CONTEXTHELPEND 
EVENT_SYSTEM_DRAGDROPSTART EVENT_SYSTEM_DRAGDROPEND EVENT_SYSTEM_DIALOGSTART EVENT_SYSTEM_DIALOGEND 
EVENT_SYSTEM_SCROLLINGSTART EVENT_SYSTEM_SCROLLINGEND EVENT_SYSTEM_SWITCHSTART EVENT_SYSTEM_SWITCHEND 
EVENT_SYSTEM_MINIMIZESTART EVENT_SYSTEM_MINIMIZEEND EVENT_OBJECT_CREATE EVENT_OBJECT_DESTROY EVENT_OBJECT_SHOW 
EVENT_OBJECT_HIDE EVENT_OBJECT_REORDER EVENT_OBJECT_FOCUS EVENT_OBJECT_SELECTION EVENT_OBJECT_SELECTIONADD 
EVENT_OBJECT_SELECTIONREMOVE EVENT_OBJECT_SELECTIONWITHIN EVENT_OBJECT_STATECHANGE EVENT_OBJECT_LOCATIONCHANGE 
EVENT_OBJECT_NAMECHANGE EVENT_OBJECT_DESCRIPTIONCHANGE EVENT_OBJECT_VALUECHANGE EVENT_OBJECT_PARENTCHANGE 
EVENT_OBJECT_HELPCHANGE EVENT_OBJECT_DEFACTIONCHANGE EVENT_OBJECT_ACCELERATORCHANGE
);

@statesk = qw(
STATE_SYSTEM_NORMAL STATE_SYSTEM_UNAVAILABLE STATE_SYSTEM_SELECTED STATE_SYSTEM_FOCUSED STATE_SYSTEM_PRESSED 
STATE_SYSTEM_CHECKED STATE_SYSTEM_MIXED STATE_SYSTEM_INDETERMINATE STATE_SYSTEM_READONLY STATE_SYSTEM_HOTTRACKED 
STATE_SYSTEM_DEFAULT STATE_SYSTEM_EXPANDED STATE_SYSTEM_COLLAPSED STATE_SYSTEM_BUSY STATE_SYSTEM_FLOATING 
STATE_SYSTEM_MARQUEED STATE_SYSTEM_ANIMATED STATE_SYSTEM_INVISIBLE STATE_SYSTEM_OFFSCREEN STATE_SYSTEM_SIZEABLE 
STATE_SYSTEM_MOVEABLE STATE_SYSTEM_SELFVOICING STATE_SYSTEM_FOCUSABLE STATE_SYSTEM_SELECTABLE STATE_SYSTEM_LINKED 
STATE_SYSTEM_TRAVERSED STATE_SYSTEM_MULTISELECTABLE STATE_SYSTEM_EXTSELECTABLE STATE_SYSTEM_ALERT_LOW 
STATE_SYSTEM_ALERT_MEDIUM STATE_SYSTEM_ALERT_HIGH STATE_SYSTEM_PROTECTED STATE_SYSTEM_VALID
);

@objidsk  = qw(
CHILDID_SELF
OBJID_WINDOW OBJID_SYSMENU OBJID_TITLEBAR OBJID_MENU OBJID_CLIENT OBJID_VSCROLL OBJID_HSCROLL OBJID_SIZEGRIP 
OBJID_CARET OBJID_CURSOR OBJID_ALERT OBJID_SOUND
);

@selflagsk  = qw(
SELFLAG_NONE SELFLAG_TAKEFOCUS SELFLAG_TAKESELECTION SELFLAG_EXTENDSELECTION SELFLAG_ADDSELECTION 
SELFLAG_REMOVESELECTION SELFLAG_VALID
);

@navdirsk = qw(
NAVDIR_MIN NAVDIR_UP NAVDIR_DOWN NAVDIR_LEFT NAVDIR_RIGHT NAVDIR_NEXT NAVDIR_PREVIOUS NAVDIR_FIRSTCHILD 
NAVDIR_LASTCHILD NAVDIR_MAX
);




@EXPORT = (qw(EVENT_OBJECT_SHOW
Desktop
AccessibleObjectFromEvent 
AccessibleObjectFromWindow 
AccessibleObjectFromPoint
createEventMonitor
),@rolesk,@eventsk,@statesk,@objidsk,@selflagsk,@navdirsk);

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

bootstrap Win32::ActAcc $VERSION;

# This AUTOLOAD is used to 'autoload' constants from the constant()
# XS function.  If a constant is not found then control is passed
# to the AUTOLOAD in AutoLoader.
sub AUTOLOAD {
  return if our $AUTOLOAD =~ /::DESTROY$/;
  # Braces used to preserve $1 et al.
  {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "'constant' not defined" if $constname eq 'constant';
    $! = undef;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
      croak "Don't know what to do with $constname";
    }
    return $val;
  }
}

use vars qw(%AO_);

########
our $ieh; # event monitor

sub IEH
{
    if (!defined($ieh))
    {
        $ieh = createEventMonitor(1);
    }
    $ieh;
}

########

sub createEventMonitor
{
    my $active = shift;
    my $rv = events_register($active);
    return $rv;
}

sub waitForEvent
{
    IEH()->waitForEvent(@_);
}

sub clearEvents
{
    IEH()->clear();
}

sub RoleFriendlyNameToNumber
{
    my $rolefriendlyname = shift;
    if (!$rolesn_setup)
    {
        $rolesn_setup = 1;
        for (@rolesk) 
        {
            my $n = eval("$_()");
            $rolesn{GetRoleText($n)}=$n; # push button
            $rolesn{$_}=$n; # ROLE_SYSTEM_PUSHBUTTON
            /ROLE_SYSTEM_/;
            $rolesn{$'}=$n; # PUSHBUTTON
            my $p = GetRolePackage($n);
            $rolesn{$p}=$n; # Win32::ActAcc::Pushbutton
            $p =~ /Win32::ActAcc::/;
            $rolesn{$'}=$n; # Pushbutton
        }
    }
    return $rolesn{$rolefriendlyname};
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

#deprecate nav: use dig
sub nav
{
	my $ao = shift;

	# Default to the desktop window
	$ao = Win32::ActAcc::AccessibleObjectFromWindow(Win32::ActAcc::GetDesktopWindow()) unless defined($ao);

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

#deprecate navlist: use dig
sub navlist
#never debugged
{
	my $ao = shift;
	my $pChain = shift;
	my $level = shift;
	my $pResults = shift;

	# Default to the desktop window
	$ao = Win32::ActAcc::AccessibleObjectFromWindow(Win32::ActAcc::GetDesktopWindow()) unless defined($ao);

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

#deprecated: use the oo version
sub menuPick
{
	my $self = shift;
        my $ppeh = shift; # obsolete.
        $self->menuPick(@_);
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

	if (defined($peventMonitorOptional))
	{
		$$peventMonitorOptional->activate(1);
	}
        Win32::ActAcc::IEH()->clear();

	Win32::ActAcc::mouse_button($x, $y, "du");
}

sub Desktop
{
	return AccessibleObjectFromWindow(GetDesktopWindow());
}

package Win32::ActAcc::Iterator;
use vars qw(@ISA);
use Carp;

sub new
{
    my $class = shift;
    my $aoroot = shift;
    croak "undef iteration root?" unless defined($aoroot);
    my $self = +{'aoroot'=>$aoroot};
    bless $self, $class;
    return $self;
}

sub open
{
    my $self = shift;
    croak("open already") if($$self{'opened'});
    $$self{'opened'} = 1;
}

sub close
{
    my $self = shift;
    croak("Must call open() before close()") unless exists($$self{'opened'});
    delete $$self{'opened'};
}

sub isOpen
{
    my $self = shift;
    return $$self{'opened'};
}

sub all
{
    my $self = shift;
    my @rv;
    my $iopened = !$self->isOpen();
    if ($iopened)
    {
        $self->open();
    }
    my $ao;
    while ($ao = $self->nextAO())
    {
        push @rv, $ao;
    }
    if ($iopened)
    {
        $self->close();
    }
    return @rv;
}

sub leaveOpen
{
    my $self = shift;
    my $lo = shift; # discard
}



require Win32::ActAcc::AO;

require Win32::ActAcc::Event;

require Win32::ActAcc::Outline;

require Win32::ActAcc::Window;

require Win32::ActAcc::Menu;

require Win32::ActAcc::MiscRoles;

require Win32::ActAcc::Iterators;


package Win32::ActAcc;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

