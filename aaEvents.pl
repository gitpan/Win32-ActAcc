# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Display WinEvents

use strict;
use Win32::OLE;
use Win32::ActAcc;

# main
sub main
{
	print "\n"."aaEvents - Display WinEvents"."\n\n";
	print "(runs until interrupted, e.g., by ^C)\n";
	Win32::OLE->Initialize();
	my $eh = Win32::ActAcc::createEventMonitor(1);
	for (;;)
	{
		print "-----\n";
		$eh->debug_spin(1);
	}
}

&main;

