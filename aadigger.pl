# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Traverse window hierarchy

use strict;
use Win32::OLE;
use Win32::ActAcc;
use Win32::ActAcc::aaExplorer;

# main
sub main
{
	Win32::OLE->Initialize();
	my $ao = Win32::ActAcc::Desktop();
	print "\naaDigger - Navigates tree of Accessible Objects\n\n";
	Win32::ActAcc::aaExplorer::aaExplore($ao);
}

&main;

