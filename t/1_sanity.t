# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) test suite

use strict;
use Data::Dumper;
use Win32::GuiTest;
use Win32::ActAcc;
use Win32::OLE;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

my @t;

push(@t, sub{&t_AccessibleObjectFromWindow_and_reverse;});
push(@t, sub{&t_AccessibleChildren_all;});
push(@t, sub{&t_AccessibleChildren_dflt;});
push(@t, sub{&t_consts;});
push(@t, sub{&t_get_accName;});
push(@t, sub{&t_get_accRole;});
push(@t, sub{&t_StateConstantName;});
push(@t, sub{&t_EventConstantName;});
push(@t, sub{&t_ObjectIdConstantName;});
push(@t, sub{&t_GetStateTextComposite;});
#push(@t, sub{&t_get_accParent;});
push(@t, sub{&t_events_1;});
push(@t, sub{&t_get_accState;});
push(@t, sub{&t_click;});
push(@t, sub{&t_accDoDefaultAction;});

print "1..".@t."\n";

Win32::OLE->Initialize();

for (my $i = 1; $i <= @t; $i++)
{
	my $passed;
	eval { my $r = &{$t[$i-1]}; $passed=1; print "$r $i\n"; };
	if (!$passed)
	{
		print "not ok $i\n";
		print STDERR $@."\n";
	}
}

sub expectedChildrenOfDesktop
{
	return +{		
		'System'=>Win32::ActAcc::ROLE_SYSTEM_MENUBAR(),
		''=>Win32::ActAcc::ROLE_SYSTEM_TITLEBAR(),
		'Application'=>Win32::ActAcc::ROLE_SYSTEM_MENUBAR(),
		'Desktop'=>Win32::ActAcc::ROLE_SYSTEM_CLIENT(),
		'Vertical'=>Win32::ActAcc::ROLE_SYSTEM_SCROLLBAR(),
		'Horizontal'=>Win32::ActAcc::ROLE_SYSTEM_SCROLLBAR(),
		'Size box'=>Win32::ActAcc::ROLE_SYSTEM_GRIP(),
	};
}

sub t_AccessibleObjectFromWindow_and_reverse
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	die unless 'Win32::ActAcc::AO' eq ref($ia);
	my $h2=$ia->WindowFromAccessibleObject(); 
	die unless ($dt == $h2);
	"ok";
}

sub t_AccessibleChildren_all
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia= AccessibleObjectFromWindow($dt);
	my @ch = $ia->AccessibleChildren(0,0);
	my $pxch = expectedChildrenOfDesktop();
	die unless 7==keys(%$pxch);
	"ok";
}

sub t_AccessibleChildren_dflt
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	my @ch = $ia->AccessibleChildren();
	die unless 1==@ch;
	#'Desktop'=>'client',
	"ok";
}

sub t_consts
{
	# confirm the constants mechanism by comparing
	# a couple of values with their H-file values.
	die unless 0==Win32::ActAcc::CHILDID_SELF();
	die unless 1==Win32::ActAcc::ROLE_SYSTEM_TITLEBAR();
	"ok";
}

sub t_get_accName
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	my @ch = $ia->AccessibleChildren(0,0);
	my $ch;
	my $pxch = expectedChildrenOfDesktop();
	foreach $ch (@ch)
	{
		my $name = $ch->get_accName();
		if (!defined($name)) { $name = ''; }
		die unless exists($$pxch{$name});
		delete $$pxch{$name};
	}
	die "left over: " . join(',',keys(%$pxch))  if (%$pxch);
	"ok";
}

sub t_get_accRole
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	my @ch = $ia->AccessibleChildren(0,0);
	my $ch;
	my $pxch = expectedChildrenOfDesktop();
	foreach $ch (@ch)
	{
		my $name = $ch->get_accName();
		if (!defined($name)) { $name = ''; }
		die unless ($$pxch{$name} == $ch->get_accRole());
	}
	"ok";
}

sub t_StateConstantName
{
	my $k = Win32::ActAcc::STATE_SYSTEM_INVISIBLE();
	my $n = Win32::ActAcc::StateConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::StateName))."\n";
	die unless 'STATE_SYSTEM_INVISIBLE' eq $n;
	"ok";
}

sub t_EventConstantName
{
	my $k = Win32::ActAcc::EVENT_OBJECT_SHOW();
	my $n = Win32::ActAcc::EventConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::StateName))."\n";
	die unless 'EVENT_OBJECT_SHOW' eq $n;
	"ok";
}

sub t_ObjectIdConstantName
{
	my $k = Win32::ActAcc::OBJID_WINDOW();
	my $n = Win32::ActAcc::ObjectIdConstantName($k);
	die unless 'OBJID_WINDOW' eq $n;
	"ok";
}

sub t_GetStateTextComposite
{
	my $k1 = Win32::ActAcc::STATE_SYSTEM_INVISIBLE();
	my $t1 = Win32::ActAcc::GetStateText($k1);
	my $k2 = Win32::ActAcc::STATE_SYSTEM_SIZEABLE();
	my $t2 = Win32::ActAcc::GetStateText($k2);
	my $k3 = Win32::ActAcc::STATE_SYSTEM_FOCUSABLE();
	my $t3 = Win32::ActAcc::GetStateText($k3);

	my $kc = $k1 | $k2 | $k3;
	my $tc = Win32::ActAcc::GetStateTextComposite($kc);

	$tc =~ /$t1/ or die "Didn't find $t1 in $tc";
	$tc = "$`$'";

	$tc =~ /$t2/ or die "Didn't find $t2 in $tc";
	$tc = "$`$'";

	$tc =~ /$t3/ or die "Didn't find $t3 in $tc";
	$tc = "$`$'";

	die if ($tc =~ /a-z/i);
	"ok";
}

# fails since desktop AND its client map to same HWND!! aaugh
sub t_get_accParent
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	my @ch = $ia->AccessibleChildren();
	my $ch = $ch[0];
	die unless $ia->WindowFromAccessibleObject() == $dt;
	die unless $ch->WindowFromAccessibleObject() != $dt;
	my $chp = $ch->get_accParent();
	die unless $chp->WindowFromAccessibleObject() == $dt;
	"ok";
}

my $wNotepadApp;

sub runNotepad
{
	my $rvNotepad;
	my $eh = Win32::ActAcc::createEventMonitor(1);
	system("start notepad");
	$rvNotepad = $eh->waitForEvent(
			+{ 'event'=>Win32::ActAcc::EVENT_OBJECT_SHOW(),
			'name'=>qr/Notepad/,
			'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW()});
	die unless defined($rvNotepad);
	return $rvNotepad;
}

sub t_events_1
{
	$wNotepadApp = runNotepad();
	die unless defined($wNotepadApp);
	"ok";
}

sub t_get_accState
{
	return "skip" unless defined($wNotepadApp);
	my $s = $wNotepadApp->get_accState();
	my $f = Win32::ActAcc::STATE_SYSTEM_FOCUSABLE();
	#print sprintf("state=%08lx (%s)\nwant =%08lx\n", $s, Win32::ActAcc::GetStateTextComposite($s), $f);
	die unless $s & $f;
	"ok";
}

sub t_click
{
	return "skip" unless defined($wNotepadApp);
	my $menubar = $wNotepadApp->findDescendant(
		sub
		{ 
			my $n = $_->get_accName(); 
			(defined($n) && $n eq "Application") && 
				($_->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_MENUBAR()) 
		});

	# Unfortunately different versions of Notepad put Font
	# under different menus. Figure out which we have here.
	my $hasFormatMenu = !! $menubar->findDescendant(
		sub
		{ 
			my $n = $_->get_accName(); 
			(defined($n) && $n =~ /Format/) && 
				($_->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_MENUITEM()) 
		});

	my $reMenu = $hasFormatMenu ? qr/Format/ : qr/Edit/;

	# Make menu selection and wait for dialog box to appear.
	my $ehDlg = Win32::ActAcc::createEventMonitor(0);
	Win32::ActAcc::menuPick($menubar, +[ $reMenu, qr/Font/ ], \$ehDlg);
	$ehDlg->waitForEvent(
		+{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_DIALOGSTART() });

	# deal with dialog box.
	Win32::GuiTest::SendKeys("{ESC}"); # close leaf menu
	"ok";
}

sub t_accDoDefaultAction
{
	return "skip" unless defined($wNotepadApp);

	my $btnClose = $wNotepadApp->findDescendant( sub{ my $n = $_->get_accName(); (defined($n) && $n eq "Close") && ($_->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_PUSHBUTTON()) });

	$btnClose->accDoDefaultAction();
	"ok";
}
