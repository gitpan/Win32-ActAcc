# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) tool: display what's under the mouse

# Usage:  use Win32::ActAcc::MouseTracker;  $ao = aaTrackMouse();

use strict;

package Win32::ActAcc::MouseTracker;

use Win32::ActAcc;
use Data::Dumper;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(aaTrackMouse);

sub aaTrackMouse
{
    my $IDLE_SECS_TO_QUIT = 4;
    my $eh = Win32::ActAcc::createEventMonitor(1);
    $eh->clear();
    my $idle = 0;
    my $oldMloc;
    my $ao;
    while ($idle < $IDLE_SECS_TO_QUIT)
    {
	my $iterWasIdle = 1;
	if ($idle != 0) {print "----- Hold still and I will exit in ". ($IDLE_SECS_TO_QUIT-$idle). " second(s)\n";}
	while (1) 
	{
	    my $e = $eh->getEvent();
	    last unless defined($e);
	    if (Win32::ActAcc::EVENT_OBJECT_LOCATIONCHANGE() == $$e{'event'})
	    {
		if (Win32::ActAcc::OBJID_CURSOR() == $$e{'idObject'})
		{
		    my $mloc = describeMouseLocation($e, \$ao);
		    if ($mloc ne $oldMloc)
		    {
			print $mloc;
			$oldMloc = $mloc;
		    }
		    $iterWasIdle = 0;
		}
	    }
	}
	if ($iterWasIdle)
	{
	    $idle++;
	}
	else
	{
	    $idle = 0;
	}
	sleep(1);
    }
    return $ao;
}

sub getAncestry
{
    my $ao = shift;
    my @rv;

    my $p = $ao->get_accParent();
    if (defined($p))
    {
	push @rv,getAncestry($p);
    }

    push @rv, $ao;
    return @rv;
}

sub describeAncestors
{
    my $ao = shift;
    my $i = 0;
    return join("\n", map(('  ' x $i++) . $_->describe(), getAncestry($ao)))."\n";
}

sub describeMouseLocation
{
    my $e = shift;
    my $pAoCursor = shift;
    my $L;
    my $aoCursor = $e->getAO();
    my ($left,$top,$width,$height) = $aoCursor->accLocation();
    $$pAoCursor = Win32::ActAcc::AccessibleObjectFromPoint($left,$top);
    my $rv;
    if (defined($$pAoCursor))
    {
	    $rv = describeAncestors($$pAoCursor); 
    }
    else
    {
	    $rv = "undef\n";
    }
    return $rv;
}

1;
