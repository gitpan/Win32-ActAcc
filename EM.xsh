int
getEventCount(h)
	INPUT:
	EventMonitor *h
	CODE:
	if (!h->cons)
		croak("EventMonitor not active");
	SetLastError(0);
	RETVAL = emGetCounter();
	if (RETVAL == -1)
		croakWin32Error("getEventCount");
	OUTPUT:
	RETVAL

void
getEvent(h)
	INPUT:
	EventMonitor *h
	PREINIT:
	HWINEVENTHOOK hhook;
	PPCODE:
	if (!h->cons)
		croak("EventMonitor not active");
	hhook = h->cons->hhook;
	if (emLock())
	{
		int actual = 0;
		struct aaevt *pEventsInBuf = 0;
		for (;;) 
		{
			emGetEventPtr(h->readCursorQume, 1, &actual, &pEventsInBuf);
			if (!actual)
				break;
			h->readCursorQume += actual;
			if (hhook == pEventsInBuf->hWinEventHook)
				break;
			else
			{
				//fprintf(stderr, "Bypassing event intended for %08lx\n", pEventsInBuf->hWinEventHook);
			}
		}
		if (actual) 
		{
			SV *perlevent = 0;
			HV *hvEventStash = 0;
			HV* hv = 0;
			hv = newHV();
// HEy! What to do in 5.003 without newSVuv ?
			hv_store(hv, "event", sizeof("event")-1, newSViv(pEventsInBuf->event), 0);
			hv_store(hv, "hwnd", sizeof("hwnd")-1, newSViv((long) pEventsInBuf->hwnd), 0);
			hv_store(hv, "idObject", sizeof("idObject")-1, newSViv(pEventsInBuf->idObject), 0);
			hv_store(hv, "idChild", sizeof("idChild")-1, newSViv(pEventsInBuf->idChild), 0);
			hv_store(hv, "dwmsEventTime", sizeof("dwmsEventTime")-1, newSViv(pEventsInBuf->dwmsEventTime), 0);
			hv_store(hv, "hWinEventHook", sizeof("hWinEventHook")-1, newSViv(pEventsInBuf->hWinEventHook), 0);

			perlevent = newRV_noinc((SV*) hv);
			hvEventStash = gv_stashpv("Win32::ActAcc::Event", 0);
			sv_bless(perlevent, hvEventStash);

			XPUSHs(perlevent);
		}
		else
			XPUSHs(&PL_sv_undef);
		emUnlock();
	}
	else
		croakWin32Error("clear");

void
clear(h)
	INPUT:
	EventMonitor *h
	PPCODE:
	if (!h->cons)
		croak("EventMonitor not active");
	EventMonitor_synch(h);

void
DESTROY(h)
	INPUT:
	EventMonitor *h
	CODE:
#ifdef MONITOR_OBJPOOL
	fprintf(stderr, "DESTROY EventMonitor at %08lx\n", h);
#endif
	EventMonitor_deactivate(h);
	Safefree(h);

void
synch(hThis,hOther)
	INPUT:
	EventMonitor *hThis
	EventMonitor *hOther
	CODE:
	if (!hThis->cons)
		croak("EventMonitor not active");
	if (!hOther->cons)
		croak("EventMonitor not active");
	hThis->readCursorQume = hOther->readCursorQume;

int
isActive(h)
	INPUT:
	EventMonitor *h
	CODE:
	RETVAL = !!(h->cons);
	OUTPUT:
	RETVAL

void
activate(h, a)
	INPUT:
	EventMonitor *h
	int a
	CODE:
	if (a && !h->cons)
	{
		EventMonitor_activate(h);
		EventMonitor_synch(h);
	}
	else if (!a && h->cons)
	{
		EventMonitor_deactivate(h);
	}
