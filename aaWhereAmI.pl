# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Track mouse

use strict;
use Win32::OLE;
use Win32::ActAcc;
use Data::Dumper;

sub describeAncestors
{
	my $ao = shift;
	my $level = shift;
	my $rv = "";
	$level = 0 unless defined($level);
	my $rv = '' . ('  ' x $level) . $ao->describe() . "\n";
	my $p = $ao->get_accParent();
	if (defined($p))
	{
		$rv = $rv . describeAncestors($p,1+$level);
	}
	return $rv;
}

sub describeMouseLocation
{
	my $e = shift;
	my $L;
	my $aoCursor = $e->getAO();
	my ($left,$top,$width,$height) = $aoCursor->accLocation();
	my $ao = Win32::ActAcc::AccessibleObjectFromPoint($left,$top);
	my $rv;
	if (defined($ao))
	{
		$rv = describeAncestors($ao); #->describe() . "\n";
	}
	else
	{
		$rv = "undef\n";
	}
	return $rv;
}

# main
sub main
{
	my $IDLE_SECS_TO_QUIT = 4;
	print "\n"."aaWhereAmI - Track mouse"."\n\n";
	print "(runs until no mouse events for $IDLE_SECS_TO_QUIT seconds)\n\n";
	Win32::OLE->Initialize();
	my $eh = Win32::ActAcc::createEventMonitor(1);
	$eh->clear();
	my $idle = 0;
	my $oldMloc;
	while ($idle < $IDLE_SECS_TO_QUIT)
	{
		my $iterWasIdle = 1;
		print "----- idle: $idle\n";
		while (1) 
		{
			my $e = $eh->getEvent();
			last unless defined($e);
			if (Win32::ActAcc::EVENT_OBJECT_LOCATIONCHANGE() == $$e{'event'})
			{
				if (Win32::ActAcc::OBJID_CURSOR() == $$e{'idObject'})
				{
					my $mloc = describeMouseLocation($e);
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
	print "Thank you\n";
}

&main;

