# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::AONavIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;
use Data::Dumper;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    return (Win32::ActAcc::CHILDID_SELF() == $ao->get_itemID());
}

sub open
{
    my $self = shift;

    $$self{'children'} = +[$$self{'aoroot'}->AccessibleChildren(0,0)];
    my %ch = map(($_->describe(),$_), @{$$self{'children'}});
    my $oi = new Win32::ActAcc::NavIterator($$self{'aoroot'});
    $oi->open();
    my $oia;
    my $criteria = +{}; 

    while ($oia = $oi->nextAO())
    {
        if ($oia->match($criteria))
        {
            my $d = $oia->describe();
            if (!exists($ch{$d}))
            {
                $ch{$d}=$oia;
                push(@{$$self{'children'}}, $oia);
            }
        }
    }
    $oi->close();
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
    }
    $$self{'ao'} = shift @{$$self{'children'}};
    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;

    delete $$self{'ao'};
    $self->SUPER::close();
}


package Win32::ActAcc::NavIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    return (Win32::ActAcc::CHILDID_SELF() == $ao->get_itemID());
}

sub open
{
    my $self = shift;

    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
        $$self{'ao'} = eval{$$self{'ao'}->accNavigate(Win32::ActAcc::NAVDIR_NEXT())}; #80004005 sometimes signals end of run
    }
    elsif ($self->iterable())
    {
        $$self{'ao'} = eval{$$self{'aoroot'}->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD())}; #80004001 sometimes (E_NOTIMP)
    }
    else
    {
        $$self{'ao'} = undef;
    }
    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;

    delete $$self{'ao'};
    $self->SUPER::close();
}




package Win32::ActAcc::AOIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    return (Win32::ActAcc::CHILDID_SELF() == $ao->get_itemID());
}

sub open
{
    my $self = shift;

    $$self{'children'}=+[$$self{'aoroot'}->AccessibleChildren()];
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
    }
    $$self{'ao'} = shift @{$$self{'children'}};
    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;
    delete $$self{'ao'};
    $self->SUPER::close();
}

package Win32::ActAcc::DelveClientIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    return 1; # guess
}

sub open
{
    my $self = shift;

    # phases: 1, iterate on the window. 2, iterate on client area. 
    $$self{'phase'} = 1;
    $$self{'client'} = undef;
    $$self{'iter'} = new Win32::ActAcc::AOIterator($$self{'aoroot'});
    # why override default? because it may be us!
    $$self{'iter'}->open();
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});
    if ($$self{'phase'} == 3)
    {
        croak "undef has already been returned by nextAO. Hello? Hello?";
    }
    my $rv = $$self{'iter'}->nextAO();
    if (defined($rv) && ($$self{'phase'}==1) && ($rv->get_accRole()==Win32::ActAcc::ROLE_SYSTEM_CLIENT()))
    {
        $$self{'client'} = $rv;
    }
    elsif (!defined($rv) && ($$self{'phase'}==1) && defined($$self{'client'}))
    {
        $$self{'iter'}->close();
        $$self{'phase'} = 2;
        $$self{'iter'} = new Win32::ActAcc::AONavIterator($$self{'client'});
        $$self{'iter'}->open();
        $rv = $$self{'iter'}->nextAO();
        if (!defined($rv)) 
        {
            $$self{'phase'} = 3;
        }
    }
    return $rv;
}

sub close
{
    my $self = shift;
    $$self{'iter'}->close();
    $self->SUPER::close();
}

package Win32::ActAcc::TreeTour;
use Carp;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $coderef = shift;
    croak "Not a code ref" unless ref($coderef) eq 'CODE';
    my $pflags = shift;
    my $self = +{'code'=>$coderef, 'prune'=>undef, 'stop'=>undef, 'level'=>0, 'iterflags'=>+{}};
    if (defined($pflags))
    {
        $$self{'iterflags'} = $pflags;
    }
    bless $self, $class;
    return $self;
}

sub run
{
    my $self = shift;
    my $ao = shift;

    my $coderef = $$self{'code'};
    undef $$self{'stop'}; 
    $$self{'pin'} = undef;
    &$coderef($ao, $self);
    if (!$$self{'prune'} && !$$self{'stop'})
    {
        my $iter = $ao->iterator($$self{'iterflags'});
        if ($iter->iterable())
        {
            $iter->open();
            my $aoi;
            $$self{'level'}++;
            my $pin = undef;
            while (!$$self{'stop'} && ($aoi = $iter->nextAO()))
            {
                $self->run($aoi);
                if ($$self{'pin'})
                {
                    $pin = 1; 
                }
            }
            $$self{'level'}--;
            if ($pin)
            {
                $iter->leaveOpen(1);
            }
            $iter->close();
        }
    }
    undef $$self{'prune'}; # but leave 'stop' in place.
}

sub level
{
    my $self = shift;
    return $$self{'level'};
}

sub prune
{
    my $self = shift;
    $$self{'prune'} = 1;
}

sub stop
{
    my $self = shift;
    $$self{'stop'} = 1;
}

sub pin
{
    my $self = shift;
    $$self{'pin'} = 1;
}

1;
