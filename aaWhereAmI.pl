# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Track mouse

use strict;
use Win32::OLE;
use Win32::ActAcc;
use Win32::ActAcc::MouseTracker;  


sub main
{
    print "\n"."aaWhereAmI - Track mouse - hold mouse still for a while to stop the program"."\n\n";
    Win32::OLE->Initialize();
    aaTrackMouse();
    print "Thank you\n";
}

&main;

