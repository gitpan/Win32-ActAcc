# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use strict;
use Win32::OLE;
use Win32::GuiTest qw(SendKeys);
use Win32::ActAcc;
use Win32::ActAcc::Shell2000;
use Chatbot::Eliza;

Win32::OLE->Initialize();

sub StartNotepad
{
    my $menu = Win32::ActAcc::Shell2000::StartButtonMenu();
    my $eh = createEventMonitor(1);
    Win32::ActAcc::clearEvents();
    $menu->menuPick([ qr/^Programs/, qr/Accessories/i, qr/Notepad/i ]);
    my $aoNotepad = Win32::ActAcc::waitForEvent(
	+{ 'event'=>EVENT_OBJECT_SHOW(),
	'name'=>qr/Notepad/,
	'role'=>ROLE_SYSTEM_WINDOW()});
    die unless defined($aoNotepad);
    return $aoNotepad;
}

sub textArea
{
    my $aoNotepad = shift;
    my $ta = $aoNotepad->drill("{editable text}", +{'max'=>1, 'min'=>1});
    return $ta;
}

sub notepadEliza
{
    my $aoNotepad = shift;
    #print "Notepad: " . $aoNotepad->describe() . "\n";

    my $ta = textArea($aoNotepad);
    my $eliza = new Chatbot::Eliza;
    # The introductory message, comes from Emacs' "doctor" facility
    # rather than Chatbot::Eliza.
    my $msgToUser = "I am the psychotherapist.  Please, describe your problems. {ENTER}Press Enter to signal me to answer. {ENTER}{ENTER}";
    SendKeys($msgToUser);
    sleep(1);
    Win32::ActAcc::clearEvents();
    my $x = Win32::ActAcc::IEH()->eventLoop(+[
        +{'event'=>EVENT_OBJECT_VALUECHANGE(), 
        'role'=>ROLE_SYSTEM_TEXT(),
        'hwnd'=>$ta->WindowFromAccessibleObject(),
        'code'=> sub
            {
                my $v = $ta->get_accValue();
                if ($v =~ /(.+)\n\z/)
                {
                    my $p = $1;
                    if ($p && ($p !~ / \z/))
                    {
                        print "$p\n";
                        $msgToUser = "{ENTER}". join('', map("\{$_\}",split(//,$eliza->transform($p)))) . " {ENTER}{ENTER}";
                        SendKeys($msgToUser);
                        sleep(1);
                        Win32::ActAcc::clearEvents();
                    }
                }
                return undef;
            }
        }

        , 

        +{'event'=>EVENT_OBJECT_DESTROY(), 
        #'role'=>ROLE_SYSTEM_WINDOW(),
        'hwnd'=>$aoNotepad->WindowFromAccessibleObject(),
        'code'=> sub
            {
                1;
            }
        }


    ]);
}

# seed the random number generator (taken from Eliza sample)
srand( time ^ ($$ + ($$ << 15)) ); 
notepadEliza(StartNotepad);
