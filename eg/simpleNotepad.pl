# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use Win32::OLE;
use Win32::ActAcc;
use Win32::ActAcc::Shell2000;

Win32::OLE->Initialize();
$menu = Win32::ActAcc::Shell2000::StartButtonMenu();
Win32::ActAcc::clearEvents();
$menu->menuPick([ qr/^Programs/, qr/Accessories/i, qr/Notepad/i ]);
$aoNotepad = Win32::ActAcc::waitForEvent(
    +{ 'event'=>EVENT_OBJECT_SHOW(),
    'name'=>qr/Notepad/,
    'role'=>ROLE_SYSTEM_WINDOW()});
$aoNotepad->menuPick(+["File", "Exit"]);