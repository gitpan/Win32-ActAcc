# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Titlebar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

use Carp;

sub btnMaximize
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Maximize" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnMinimize
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Minimize" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnClose
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Close" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnRestore
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Restore" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

package Win32::ActAcc::Window;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'lax'})
    {
        return new Win32::ActAcc::DelveClientIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

sub mainMenu
{
    my $self = shift;
    my $menubar = $self->dig([ "{menu bar}Application" ], +{'max'=>1,'min'=>1} );
    croak unless defined($menubar);
    return $menubar;
}

sub systemMenu
{
    my $self = shift;
    my $sysmenu = $self->dig([ "{menu bar}System" ], +{'max'=>1,'min'=>1} );
    croak unless defined($sysmenu);
    return $sysmenu;
}

sub titlebar
{
    my $self = shift;
    my $tbar = $self->dig([ "{title bar}" ], +{'max'=>1,'min'=>1} );
    croak unless defined($tbar);
    return $tbar;
}

sub menuPick
{
    my $self = shift;
    $self->mainMenu()->menuPick(@_);
}

package Win32::ActAcc::Client;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

1;
