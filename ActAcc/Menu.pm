# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::MenuPopup;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

sub menuPick
{
    Win32::ActAcc::MenuItem::menuPick(@_);
}


package Win32::ActAcc::Menubar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;
use Data::Dumper;

sub menuPick
{
    Win32::ActAcc::MenuItem::menuPick(@_);
}

sub open
{
    my $self = shift;
    return $self;
}

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
        return new Win32::ActAcc::MenuIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

package Win32::ActAcc::MenuItem;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

our $BetweenClicksToCloseThenOpen = 0.25; # seconds
our $MenuPopupRetrospective = 750; # milliseconds
our $MenuStartTimeout = 3; # seconds

sub menuPick
{
    my $self = shift;
    my $pCriteriaList = shift;
    my $pflags = shift;
    if (!defined($pflags)) { $pflags = +{}; }
    croak "flags must be a HASH" unless ref($pflags)eq'HASH';

    my %flags = (%$pflags, 'max'=>1);
    # Do not override min. Let caller decide.
    my $mi = $self->dig($pCriteriaList, \%flags);
    if (defined($mi))
    {
        $mi->accDoDefaultAction();
    }
}

sub open
{
    my $self = shift;

    my $popup;

    # See if MENUPOPUPSTART has already just happened
    Win32::ActAcc::IEH()->dropHistory($MenuPopupRetrospective);
    $popup = Win32::ActAcc::IEH()->waitForEvent(
	    +{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART() }, 0);

    if (!defined($popup))
    {
        if ("Open" ne ($self->get_accDefaultAction()||""))
        {
            # close it so we can reopen it and catch the event
            eval{$self->accDoDefaultAction()}; # HRESULT 80020003, "member not found" ???!
            select(undef,undef,undef,$BetweenClicksToCloseThenOpen);
        }

        eval{$self->accDoDefaultAction()}; # HRESULT 80020003, "member not found" ???!
        # wait for menu to start. timeout is important since nonfocused windows may ignore menu-start request.
        $popup = Win32::ActAcc::IEH()->waitForEvent(
	        +{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART() }, $MenuStartTimeout);
    }
    return $popup; # which is undef if timeout expired
}

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
        return new Win32::ActAcc::MenuIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

package Win32::ActAcc::ButtonMenu;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::MenuIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;
use Data::Dumper;

our $HoverDwell = 0.25; # seconds

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    return 1 if ($ao->isa(Win32::ActAcc::Menubar::));
    eval 
    {
        my ($left, $top, $width, $height) = $ao->accLocation();
        Win32::ActAcc::mouse_button($left+1, $top+1, "m");
        select(undef,undef,undef,$HoverDwell);
    };
    my $rv = ("Open" eq ($ao->get_accDefaultAction()||"")) || ("Close" eq ($ao->get_accDefaultAction()||"")); # Avoid "Execute"!
    return $rv;
}

sub open
{
    my $self = shift;

    my $actualMenu = $$self{'aoroot'}->open();
    if (defined($actualMenu))
    {
        $$self{'iter'} = new Win32::ActAcc::AONavIterator($actualMenu);
        $$self{'iter'}->open();
    }
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    my $rv;
    if (defined($$self{'iter'}))
    {
        $rv = $$self{'iter'}->nextAO();
    }
    return $rv;
}

sub close
{
    my $self = shift;
    if (defined($$self{'iter'}))
    {
        $$self{'iter'}->close();
    }
    $self->SUPER::close();
}

1;
