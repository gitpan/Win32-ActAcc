# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Event;

sub getAO
{
	my $self = shift;
	return Win32::ActAcc::AccessibleObjectFromEvent($$self{'hwnd'}, $$self{'idObject'}, $$self{'idChild'});
}

sub AccessibleObjectFromEvent
{
	my $self = shift;
	return Win32::ActAcc::AccessibleObjectFromEvent($$self{'hwnd'}, $$self{'idObject'}, $$self{'idChild'});
}

sub evDescribe
{
	my $e = shift;

	my $L = Win32::ActAcc::EventConstantName($$e{'event'});
	my $ao = eval {$e->getAO()};
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

my $EventPollInterval = 0.5; # seconds 

sub waitForEvent
{
	my $self = shift;
	my $pQuarry = shift;
	my $timeoutSecs = shift; # optional

        my $maxIters = defined($timeoutSecs) ? $timeoutSecs / $EventPollInterval : undef;

	my $pComparator;
	if (ref($pQuarry) eq 'HASH')
	{
		$pComparator = sub{waitForEvent_dfltComparator($pQuarry, @_)};
	}
	else
	{
		$pComparator = $pQuarry;
	}
	
	my $rv; 

	PATIENTLY_AWAITING_QUARRY: for (my $sc = 0; !defined($maxIters) || ($sc <= $maxIters); $sc++)
	{
		DEVOUR_BACKLOG: for (;;)
		{
			my $e = $self->getEvent();
			last DEVOUR_BACKLOG unless defined($e);
			last PATIENTLY_AWAITING_QUARRY if (defined($rv = &$pComparator($e)));
		}
		select(undef,undef,undef,$EventPollInterval) unless ($sc == (defined($maxIters)?$maxIters:-1));
	}
	return $rv;
}

sub waitForEvent_dfltComparator
{
    my $pQuarry = shift;
    my $e = shift;

    if (ref($pQuarry) eq 'CODE')
    {
        return &$pQuarry($e);
    }
    else
    {
        if (exists($$pQuarry{'event'}))
        {
	    return undef unless $$e{'event'} == $$pQuarry{'event'};
        }

	if (exists($$pQuarry{'hwnd'}))
	{
		return undef unless $$e{'hwnd'} == $$pQuarry{'hwnd'};
	}

	my $ao = eval { $e->getAO() };
        # note: undef if the window is being destroyed

	    if (exists($$pQuarry{'role'}))
	    {
                return undef unless defined($ao);
                my $mr = eval{$ao->get_accRole()} || "";
	        return undef unless $mr == $$pQuarry{'role'};
	    }

	    if (exists($$pQuarry{'name'}))
	    {
                return undef unless defined($ao);
		    my $aoname = $ao->get_accName();
		    if ('Regexp' eq ref($$pQuarry{'name'}))
		    {
			    return undef unless defined($aoname) && ($aoname =~ /$$pQuarry{'name'}/);
		    }
		    else
		    {
			    return undef unless defined($aoname) && $aoname eq $$pQuarry{'name'};
		    }
	    }

	    if (exists($$pQuarry{'aoToEqual'}))
	    {
                return undef unless defined($ao);
                return undef unless $ao->Equals($$pQuarry{'aoToEqual'});
	    }

        # has 'return', must be last
        if (exists($$pQuarry{'code'}))
        {
            return &{$$pQuarry{'code'}}($e) ;
        }

	return $ao;
    }
}

sub debug_spin
{
	my $self = shift;
	my $secs = shift;

	$self->waitForEvent(sub{print Win32::ActAcc::Event::evDescribe(@_)."\n";undef}, $secs);
}

sub eventLoop
{
    my $self = shift;
    my $pQuarryList = shift;
    my $timeoutSecs = shift; # optional

    my $maxIters = defined($timeoutSecs) ? $timeoutSecs / $EventPollInterval : undef;

    # make quarry an array if it is not an array.
    if ('ARRAY' ne ref($pQuarryList))
    {
        $pQuarryList = +[ $pQuarryList ];
    }

    my $rv; 

    PATIENTLY_AWAITING_QUARRY: for (my $sc = 0; !defined($maxIters) || ($sc <= $maxIters); $sc++)
    {
	    DEVOUR_BACKLOG: for (;;)
	    {
		    my $e = $self->getEvent();
		    last DEVOUR_BACKLOG unless defined($e);
                    my @m = grep(waitForEvent_dfltComparator($_, $e), @$pQuarryList);
                    if (@m)
                    {
                        $rv = shift(@m);
                        last PATIENTLY_AWAITING_QUARRY;
                    }
	    }
	    select(undef,undef,undef,$EventPollInterval) unless ($sc == (defined($maxIters)?$maxIters:-1));
    }
    return $rv;
}

1;
