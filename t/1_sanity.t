# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) test suite

use strict;
use Data::Dumper;
use Win32::GuiTest;
use Win32::ActAcc;
use Win32::ActAcc::Shell2000;
use Win32::OLE;
use Config;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# locate notepad.exe
my @notepads = map("$_\\notepad.exe", grep(-f "$_\\notepad.exe", split(/;/,$ENV{'PATH'})));
my $notepadexe;
if (@notepads)
{
    $notepadexe = 'notepad.exe';
}
else
{
    print STDERR "\nFull path/filename of Notepad.exe? ";
    $notepadexe = <STDIN>;
    chomp $notepadexe;
}

# locate explorer.exe
my @explorers = map("$_\\explorer.exe", grep(-f "$_\\explorer.exe", split(/;/,$ENV{'PATH'})));
my $explorerexe;
if (@explorers)
{
    $explorerexe = "explorer.exe";
}
else
{
    print STDERR "\nFull path/filename of Explorer.exe? ";
    $explorerexe = <STDIN>;
    chomp $explorerexe;
}

my $hmm;
print STDERR "\nIs Notepad at Start->Programs->Accessories->Notepad? ";
$hmm = <STDIN>;
print STDERR qq(\nPlease go make sure Start->Programs->Accessories->Notepad hasn't been "helpfully" hidden.  Then press Enter. );
$hmm = <STDIN>;

my @t;
push(@t, sub{&t_RoleFriendlyNameToNumber;});
push(@t, sub{&t_Desktop;});
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
push(@t, sub{&t_startmenu;});
push(@t, sub{&t_outline;});
push(@t, sub{&t_equals;});

######################### We start with some black magic to print on failure.

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
		'System'=>ROLE_SYSTEM_MENUBAR(),
		''=>ROLE_SYSTEM_TITLEBAR(),
		'Application'=>ROLE_SYSTEM_MENUBAR(),
		'Desktop'=>ROLE_SYSTEM_CLIENT(),
		'Vertical'=>ROLE_SYSTEM_SCROLLBAR(),
		'Horizontal'=>ROLE_SYSTEM_SCROLLBAR(),
		'Size box'=>ROLE_SYSTEM_GRIP(),
	};
}

sub t_RoleFriendlyNameToNumber
{
    die unless Win32::ActAcc::RoleFriendlyNameToNumber("menu bar") == Win32::ActAcc::ROLE_SYSTEM_MENUBAR;
    die unless Win32::ActAcc::RoleFriendlyNameToNumber("ROLE_SYSTEM_MENUBAR") == Win32::ActAcc::ROLE_SYSTEM_MENUBAR;
    "ok";
}

sub t_Desktop
{
	my $dt1 = Win32::GuiTest::GetDesktopWindow();
	my $ia1 = AccessibleObjectFromWindow($dt1);
        my $dt1a = $ia1->WindowFromAccessibleObject();

        my $ia2 = Win32::ActAcc::Desktop();
        my $dt2a = $ia2->WindowFromAccessibleObject();

        die unless $dt1a==$dt2a;
        "ok";
}

sub t_AccessibleObjectFromWindow_and_reverse
{
	my $dt = Win32::GuiTest::GetDesktopWindow();
	my $ia=AccessibleObjectFromWindow($dt);
	die unless 'Win32::ActAcc::Window' eq ref($ia);
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
	die unless 0==CHILDID_SELF();
	die unless 1==ROLE_SYSTEM_TITLEBAR();
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
	my $k = STATE_SYSTEM_INVISIBLE();
	my $n = Win32::ActAcc::StateConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::StateName))."\n";
	die unless 'STATE_SYSTEM_INVISIBLE' eq $n;
	"ok";
}

sub t_EventConstantName
{
	my $k = EVENT_OBJECT_SHOW();
	my $n = Win32::ActAcc::EventConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::StateName))."\n";
	die unless 'EVENT_OBJECT_SHOW' eq $n;
	"ok";
}

sub t_ObjectIdConstantName
{
	my $k = OBJID_WINDOW();
	my $n = Win32::ActAcc::ObjectIdConstantName($k);
	die unless 'OBJID_WINDOW' eq $n;
	"ok";
}

sub t_GetStateTextComposite
{
	my $k1 = STATE_SYSTEM_INVISIBLE();
	my $t1 = Win32::ActAcc::GetStateText($k1);
	my $k2 = STATE_SYSTEM_SIZEABLE();
	my $t2 = Win32::ActAcc::GetStateText($k2);
	my $k3 = STATE_SYSTEM_FOCUSABLE();
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

	Win32::ActAcc::clearEvents();
	system(qq(start $notepadexe));
	$rvNotepad = Win32::ActAcc::waitForEvent(
			+{ 'event'=>EVENT_OBJECT_SHOW(),
			'name'=>qr/Notepad/,
			'role'=>ROLE_SYSTEM_WINDOW()});
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
	my $f = STATE_SYSTEM_FOCUSABLE();
	#print sprintf("state=%08lx (%s)\nwant =%08lx\n", $s, Win32::ActAcc::GetStateTextComposite($s), $f);
	die unless $s & $f;
	"ok";
}

sub t_click
{
	return "skip" unless defined($wNotepadApp);
	my $menubar = $wNotepadApp->mainMenu();

        die unless defined($menubar);

	# Unfortunately different versions of Notepad put Font
	# under different menus. Figure out which we have here.
	my $hasFormatMenu = !! $menubar->dig(+['{menu item}Format'], +{'max'=>1,'min'=>0,'trace'=>0});
#$menubar->debug_tree();
	my $reMenu = $hasFormatMenu ? qr/Format/ : qr/Edit/;

	# Make menu selection and wait for dialog box to appear.
        $wNotepadApp->menuPick(+[ $reMenu, qr/Font/ ]);
	my $fontdlg = Win32::ActAcc::waitForEvent(
		+{ 'event'=>EVENT_SYSTEM_DIALOGSTART() });

	# deal with dialog box.
        $fontdlg->findDescendant(
                sub{
                    my $n = $_->get_accName(); 
                    (defined($n) && $n eq "Cancel") && 
                    ($_->get_accRole() == ROLE_SYSTEM_PUSHBUTTON())  })->accDoDefaultAction();

	"ok";
}

sub t_accDoDefaultAction
{
	return "skip" unless defined($wNotepadApp);

	my $btnClose = 	$wNotepadApp->titlebar()->btnClose();
        die unless defined($btnClose);
	$btnClose->accDoDefaultAction();

	"ok";
}

sub t_startmenu
{
	my $menu = Win32::ActAcc::Shell2000::StartButtonMenu();
	$menu->menuPick([ qr/^Programs/, qr/Accessories/i, qr/Notepad/i ]);
	my $rvNotepad = Win32::ActAcc::waitForEvent(
			+{ 'event'=>EVENT_OBJECT_SHOW(),
			'name'=>qr/Notepad/,
			'role'=>ROLE_SYSTEM_WINDOW()});
	die unless defined($rvNotepad);
	my $btnClose = 	$rvNotepad->titlebar()->btnClose();
	$btnClose->accDoDefaultAction();

	"ok";
}

sub t_outline
{
    my $rvExplorer;
    my $eh;
    my $folder = $Config{'sitearchexp'} . "\\auto\\Win32\\ActAcc";
    my ($drivepart, $folderspart) = $folder=~ /^([a-z]:)\\(.*)/i;
    my $dpqm = quotemeta $drivepart;
    my @folderspart = split(/\\/, $folderspart);
    system("start $explorerexe /e,$drivepart");

    $rvExplorer = Win32::ActAcc::waitForEvent(
		    +{ 'event'=>EVENT_OBJECT_SHOW(),
		    'name'=>uc($drivepart)."\\",
		    'role'=>ROLE_SYSTEM_WINDOW()});
    die unless defined($rvExplorer);
    undef $eh;
    
    my $outline = $rvExplorer->findDescendant(
        sub{ 
	    ($_->get_accRole() == ROLE_SYSTEM_OUTLINE()) 
        });
    my $rootitem = $outline->getRoot();

    my $outlineitem = $rootitem->outlinenav(+[qr(My Computer), qr((?i:$dpqm)), map(do{my $b = quotemeta(ucfirst($_));qr/(?i:^$b)/ },@folderspart)]);

    die unless $outlineitem->get_accName() eq $folderspart[$#folderspart];

    my $btnClose = $rvExplorer->titlebar()->btnClose();
    $btnClose->accDoDefaultAction();

    "ok";
}

sub t_equals
{
    my $dt = Win32::ActAcc::Desktop();
    my $e1 = $dt->Equals($dt);
    die unless $e1;

    my $fdc = $dt->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD())->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD());
    my $e2 = $dt->Equals($fdc );
    die("HWNDs:".$dt->WindowFromAccessibleObject().",".$fdc->WindowFromAccessibleObject()) unless !$e2;

    my $e3 = $dt->Equals(Win32::ActAcc::Desktop()); # their IAccessible* values will be different. yuck.
    die unless $e3;

    "ok";
}

