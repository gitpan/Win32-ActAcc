# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::AO;

use Data::Dumper;
use Carp;

our $accDoDefaultActionHook; # coderef

sub accDoDefaultAction
{
    my $ao = shift;
    if (defined($accDoDefaultActionHook))
    {
        &$accDoDefaultActionHook($ao);
    }
    $ao->accDoDefaultAction_();
}

sub describe_meta
{
	return "role:name {state,(location),id,hwnd}: defaultAction"; # keep synchronized with describe()
}

sub describe
{
	my $ao = shift;
	my $name = $ao->get_accName();
	my $role = "?";
        my $outlineprefix = "";
	eval { 
            my $ir = $ao->get_accRole();
            $role = Win32::ActAcc::GetRoleText($ir); 
            if ($ir == Win32::ActAcc::ROLE_SYSTEM_OUTLINEITEM()) { $outlineprefix='>'x($ao->get_accValue()); }
        };
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
	my $itemID = "(no ID)";
	eval
	  {
	    $itemID = 'id=' . $ao->get_itemID();
	  };
        my $dfltAction = eval{$ao->get_accDefaultAction()} || "";
        if (defined($dfltAction)) { $dfltAction=": " . $dfltAction;}
	$name = "(undef)" unless defined($name);
	$location = "(location error)" unless defined($location);
	return "$role:$outlineprefix$name {$state,$location,$itemID,$hwnd}$dfltAction"; # keep synchronized with describe_meta()
}

#deprecate NavigableChildren: use iterator
sub NavigableChildren
{
	my $ao = shift;
	my @rv;
	my $ch = undef;
        # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
        eval { $ch = $ao->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD()); };
	while (defined($ch))
	{
		push(@rv,$ch);
		my $nx = undef;
		eval { $nx = $ch->accNavigate(Win32::ActAcc::NAVDIR_NEXT()); };
		$ch = $nx;
	}
	return @rv;
}

# findDescendant deprecated, use drill.
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
			croak if (@L>1);
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

sub drill
{
    my $self = shift;
    my $pCriterion = shift;
    my $pflags = shift;
    $pflags = +{} if (!defined($pflags));
    croak "Criteria must not be a list" if (ref($pCriterion) eq 'ARRAY'); # confused with dig
    croak "Flags must be a hash" unless ref($pflags) eq 'HASH';
    if (!exists($$pflags{'min'})) { $$pflags{'min'}=1; }
    if (!exists($$pflags{'max'})) { $$pflags{'max'}=-1; }
    if (!exists($$pflags{'pruneOnMatch'})) { $$pflags{'pruneOnMatch'}=1; }
    if (!exists($$pflags{'prunes'})) 
    { 
        $$pflags{'prunes'}=+[
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_MENUBAR()},
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_BUTTONMENU()},
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_OUTLINE()}
        ]; 
    }
    if ('HASH' ne ref($crit)) { $crit = matchHashUpCriteria($crit); };
    # if visible window is wanted, it can't be within an invisible window...
    if (exists($$crit{'state'}))
    {
        my $mask = ${$$crit{'state'}}{'mask'};
        my $val = ${$$crit{'state'}}{'value'};
        if ($mask & Win32::ActAcc::STATE_SYSTEM_INVISIBLE())
        {
            if (0 == ($val & Win32::ActAcc::STATE_SYSTEM_INVISIBLE()))
            {
                push(@{$$pflags{'prunes'}}, +{'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE()}});
            }
        }
    }

    my @found;

    $self->tree(
        sub 
        {
            my $ao = shift;
            my $treeTour = shift;

            my $level = $treeTour->level();
            if ($level > 0)
            {
                print "Matching " . $ao->describe() . "..." . ($ao->match($pCriterion)) . "\n" if ($$pflags{'trace'});
                if ($ao->match($pCriterion))
                {
                    $treeTour->prune() unless !$$pflags{'pruneOnMatch'};
                    push(@found,$ao);
                    if ($$pflags{'max'}==@found)
                    {
                        $treeTour->stop();
                    }
                }
                if (exists($$pflags{'prunes'}))
                {
                    if (grep($ao->match($_),@{$$pflags{'prunes'}}))
                    {
                        $treeTour->prune();
                    }
                }
            }
        }
        , $$pflags{'iterflags'} || +{});
    
    croak "Fewer than ".$$pflags{'min'}." found" if (0+@found < $$pflags{'min'});

    if ($$pflags{'max'}==1)
    {
        return $found[0];
    }
    else
    {
        return @found;
    }
}

use Carp qw(croak verbose carp);
use Data::Dumper;

sub dig
{
    my $self = shift;
    my $pCriteriaList = shift;
    my $pflags = shift;

    $pflags = +{} if (!defined($pflags));
    croak "Criteria must be a list" unless ref($pCriteriaList) eq 'ARRAY';
    croak "Flags must be a hash" unless ref($pflags) eq 'HASH';
    if (!exists($$pflags{'min'})) { $$pflags{'min'}=1; }
    if (!defined($$pflags{'max'})) { $$pflags{'max'}=-1; }
    if (!defined($$pflags{'trace'})) { $$pflags{'trace'}=0; }
    my @found;
    my $maxlevel=0;

    if ($$pflags{'trace'})
    {
        print STDERR "dig is using these criteria:\n";
        print STDERR join("\n", map("  " . describeCriteria($_), @$pCriteriaList));
    }

    # warn if conflict between array context and max.
    if ((0+wantarray) == (0+($$pflags{'max'}==1)))
    {
        carp "Only use scalar context with dig if you specify 'max'=>1, or you really know what you are doing.\n";
    }

    $self->tree(
        sub 
        {
            my $ao = shift;
            my $treeTour = shift;

            my $level = $treeTour->level();
            if ($level > 0)
            {
                my $mismatch;
                my $m = $ao->match($$pCriteriaList[$level-1], \$mismatch);
                if ($$pflags{'trace'})
                {
                    print STDERR "Match ".$ao->describe()."? " . ($m ? "yes":"no:$mismatch") . "  level=$level, criteria=".(1+$#$pCriteriaList)."\n";
                }
                if (!$m)
                {
                    $treeTour->prune();
                }
                elsif ($level==1+$#$pCriteriaList)
                {
                    push(@found,$ao);
                    $treeTour->pin();
                    if ($$pflags{'max'}==@found)
                    {
                        $treeTour->stop();
                    }
                    if ($level > $maxlevel)
                    {
                        $maxlevel = $level+1;
                    }
                }
            }
        }
        , +{'lax'=>1, 'active'=>1});
    
    croak "Fewer than ".$$pflags{'min'}." found; max match chain length was ".$maxlevel if (0+@found < $$pflags{'min'});

    if ($$pflags{'max'}==1)
    {
        return $found[0];
    }
    else
    {
        return @found;
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
        $ao->tree(sub{my $ao=shift;my $tree=shift;print ' 'x($tree->level()).$ao->describe."\n";});
}

sub match
{
    my $self = shift;
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $mismatch = shift;
    my $rv = $self->match_($crit,$mismatch ) || '';
    #print STDERR "match OF ".$self->describe() ." AGAINST " .Dumper($crit). " YIELDS ".$rv ."\n";
    return $rv;
}

sub matchHashUpCriteria
{
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $rcrit = ref($crit);

    if ($rcrit eq 'HASH')
    {
        if (exists($$crit{'rolename'}))
        {
            $$crit{'role'}=Win32::ActAcc::RoleFriendlyNameToNumber($$crit{'rolename'});
            delete $$crit{'rolename'};
        }
        return $crit;
    }
    elsif ($rcrit eq 'Regexp')
    {
        return +{'name'=>$crit, 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0} };
    }
    elsif ($rcrit eq 'CODE')
    {
        return +{'code'=>$crit, 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0} };
    }
    elsif ($rcrit eq '')
    {
	my $seekingRole = undef;
	my $seekingName = $crit || '';
	if ($seekingName =~ /^\{(.*)\}/)
	{
		$seekingRole = Win32::ActAcc::RoleFriendlyNameToNumber($1);
                croak unless defined($seekingRole);
		$seekingName = $';
	}
	if (0==length($seekingName)) { $seekingName = undef; }
        my %h;
        $h{'name'}=$seekingName unless !defined($seekingName);
        $h{'role'}=$seekingRole unless !defined($seekingRole);
        $h{'state'}=+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0};
        return \%h;
    }
    else
    {
        croak "Don't know what to do with criteria ref $rcrit";
    }
}

sub describeCriteria
{
    my $nhcrit = shift; 
    my @rv;
    my $crit = matchHashUpCriteria($nhcrit);
    if (exists($$crit{'rolename'}))
    {
        push @rv, "rolename='$$crit{'rolename'}'";
    }
    if (exists($$crit{'role'}))
    {
        push @rv, "role=". Win32::ActAcc::GetRoleText($$crit{'role'});
    }
    if (exists($$crit{'name'}))
    {
        push @rv, "name='$$crit{'name'}'";
    }
    if (exists($$crit{'state'}) && exists(${$$crit{'state'}}{'value'}))
    {
        push @rv, "state-value=". Win32::ActAcc::GetStateTextComposite(${$$crit{'state'}}{'value'});
    }
    if (exists($$crit{'code'}))
    {
        push @rv, "code(...)";
    }
    my $rv = join(',',@rv);
    if ($rv eq '' )
    {
        $rv = "NO CRITERIA!?"
    }
    return $rv;
}

sub match_
{
    my $self = shift;
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $mismatch = shift;
    my $rcrit = ref($crit);

    if ($rcrit eq 'HASH')
    {
        if (exists($$crit{'rolename'}))
        {
            $$crit{'role'}=Win32::ActAcc::RoleFriendlyNameToNumber($$crit{'rolename'});
            delete $$crit{'rolename'};
        }
        if (exists($$crit{'role'}))
        {
            my $r = $self->get_accRole();
            if ($r != $$crit{'role'})
            {
                if (defined($mismatch)) { $$mismatch='role'; }
                return undef;
            }
        }
        if (exists($$crit{'name'}))
        {
            my $n = $self->get_accName() || '';
            if (ref($$crit{'name'}) eq 'Regexp')
            {
                if ($n !~ /$$crit{'name'}/)
                {
                    if (defined($mismatch)) { $$mismatch='name'; }
                    return undef;
                }
            }
            else
            {
                if ($n ne $$crit{'name'})
                {
                    if (defined($mismatch)) { $$mismatch='name'; }
                    return undef;
                }
            }
        }
        if (exists($$crit{'state'}))
        {
            croak unless exists(${$$crit{'state'}}{'mask'});
            croak unless exists(${$$crit{'state'}}{'value'});
            my $s = eval{$self->get_accState()}; # some servers give error 
            if (!defined($s))
            {
                if (defined($mismatch)) { $$mismatch='state-value(ao state not available)'; }
                return undef;
            }
            my $mask = ${$$crit{'state'}}{'mask'};
            my $val = ${$$crit{'state'}}{'value'};
            $s = $s & $mask;
            if ($s != $val)
            {
                if (defined($mismatch)) { $$mismatch='state-value'; }
                return undef;
            }
        }
        if (exists($$crit{'code'}))
        {
            $_=$self; 
            my $rv = &{$$crit{'code'}}($self, $crit, $mismatch);
            if (!$rv && defined($mismatch) && !defined($$mismatch))
            {
                $$mismatch='code';
            }
            return $rv;
        }
        return 1;
    }
    else
    {
        return $self->match_(matchHashUpCriteria($crit), $mismatch);
    }
}

sub tree
{
    my $self = shift;
    my $coderef = shift;
    croak "Not a code ref" unless ref($coderef) eq 'CODE';
    my $pflags = shift;

    my $v = new Win32::ActAcc::TreeTour($coderef, $pflags);

    $v->run($self);
}

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'perfunctory'})
    {
        return new Win32::ActAcc::AOIterator($self);
    }
    elsif (defined($pflags) && $$pflags{'nav'})
    {
        return new Win32::ActAcc::NavIterator($self);
    }
    else
    {
        return new Win32::ActAcc::AONavIterator($self);
    }
}

sub waitForEvent
{
    my $self = shift;
    my $pQuarry = shift;
    croak "Must use HASH" if 'HASH' ne ref($pQuarry);
    my $timeoutSecs = shift; # optional
    $$pQuarry{'aoToEqual'} = $self;
    return Win32::ActAcc::IEH()->waitForEvent($pQuarry, $timeoutSecs);
}


1;
