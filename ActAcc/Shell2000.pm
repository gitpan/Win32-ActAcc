# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Shell2000;

@EXPORT_OK = qw(
StartButton
StartButtonMenu
);

use Win32::ActAcc;

sub StartButton
{
    my $btnStart = Win32::ActAcc::Desktop()->dig([ 
        +{'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW(), 'name'=>''}, 
            "{window}Start", 
            "{push button}Start" ], 
        +{'max'=>1,'min'=>1} );
    die unless defined($btnStart);
    return $btnStart;
}

sub StartButtonMenu # clicks Start and returns the resulting menu
{
    my $btnStart = StartButton();
    eval {$btnStart->accDoDefaultAction();}; # causes HRESULT b7 "Cannot create file if file already exists" ???!
    my $menu = Win32::ActAcc::waitForEvent(
      +{ 'event'=>EVENT_SYSTEM_MENUPOPUPSTART() }, 10);
    return $menu;
}

sub Tray
{
    my $tray = Win32::ActAcc::Desktop()->dig([ 
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW(), 'name'=>'', 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}}, 
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW(), 'name'=>'', 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}}, 
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW(), 'name'=>'', 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}}, 
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW(), 'name'=>'Tray', 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}}, 
            +{'role'=>Win32::ActAcc::ROLE_SYSTEM_PAGETABLIST(), 'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}} ], 
        +{'max'=>1,'min'=>1} );
    die unless defined($tray);
    return $tray;
}

sub ShowDesktopButton
{
    return Tray()->get_accParent()->get_accParent()->get_accParent()->get_accParent()->
        drill(+{'role'=>ROLE_SYSTEM_PUSHBUTTON(), 
            'name'=>qr/Show Desktop/, 
            'state'=>+{'mask'=>Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 'value'=>0}},
            +{'max'=>1,'min'=>1} );
}

sub ShowDesktop
{
    ShowDesktopButton()->accDoDefaultAction();
}

1;
