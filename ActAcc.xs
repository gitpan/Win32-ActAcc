/* Copyright 2000, Phill Wolf.  See README. */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
// WORD is defined in old perly.h and conflicts with a Windows typedef
#undef WORD
#include <wtypes.h>
#define COBJMACROS
#define CINTERFACE
#include <oleauto.h>
#include <OleAcc.h>
#include <WinAble.h>
#include "AAEvtMon.h"
#include "ActAccEL.h"

// The SDK from VC 6.0 does not define C macros for IAccessible methods.
// But the (newer) Platform SDK does.
// Check that we've got the Platform SDK, to avoid confusing error messages.
#ifndef IAccessible_Release
#include "IAccessible.h"
#endif

//#define MONITOR_OBJPOOL
//#define MONITOR_OBJPOOL_EVENT_CONSOLIDATOR

HINSTANCE g_hinstDLL = 0;

BOOL WINAPI DllMain(
  HINSTANCE hinstDLL,  // handle to the DLL module
  DWORD fdwReason,     // reason for calling function
  LPVOID lpvReserved   // reserved
)
{
	if (DLL_PROCESS_ATTACH == fdwReason)
	{
		g_hinstDLL = hinstDLL;
	}
	return TRUE;
}



/* 
// todo: GetOleaccVersionInfo
*/

/*
// todo: get_accHelpTopic
// todo: get_accSelection
// todo: accHitTest
*/
#ifdef PERL_OBJECT
#define USEGUID(X) X
#else
#define USEGUID(X) &X
#endif

/* ----------------------------------------- */

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

void VariantInit_VT_I4(VARIANT *v, LONG i)
{
	VariantInit(v);
	v->vt = VT_I4;
	v->lVal = i;
}

void croakWin32Error(char const *f)
{
	char msg[140];
	DWORD le = GetLastError();
	sprintf(msg, "WinError=%08lx in %s", le, f);
	croak(msg);
}

void croakIf(HRESULT hr, BOOL pleaseCroak, char const *f)
{
	if (pleaseCroak)
	{
		char msg[140];
		sprintf(msg, "HRESULT=%08lx in %s", hr, f);
		croak(msg);
	}
}

void warnIf(HRESULT hr, BOOL pleaseWarn, char const *f)
{
	if (pleaseWarn)
	{
		char msg[140];
		sprintf(msg, "HRESULT=%08lx in %s", hr, f);
		warn(msg);
	}
}

/* ----------------------------------------- */

struct ActAcc_
{
	IAccessible *ia;
	DWORD id;
};

typedef struct ActAcc_ ActAcc;
typedef struct ActAcc_* ActAccPtr;

ActAcc *ActAcc_from_IAccessible(IAccessible *ia, DWORD id);

// caller must release the IAccessible
ActAcc *ActAcc_new_from_IAccessible(IAccessible *ia, DWORD id)
{
	ActAcc *rv = 0;
	New(7, rv, 1, ActAcc); 
	rv->ia = ia;
	IAccessible_AddRef(ia);
	rv->id = id;
#ifdef MONITOR_OBJPOOL
	fprintf(stderr, "new(%08lx)\n", rv);
#endif
	return rv;
}

// caller must release the IDispatch
ActAcc *ActAcc_new_from_IDispatch(IDispatch *pDispatch)
{
	ActAcc *rv = 0;
	IAccessible *pAccessible = 0;
	HRESULT hr = IDispatch_QueryInterface(pDispatch, USEGUID(IID_IAccessible), (void**)&pAccessible);
	croakIf(hr, !SUCCEEDED(hr), "ActAcc_new_from_IDispatch");
	rv = ActAcc_from_IAccessible(pAccessible, CHILDID_SELF);
	IAccessible_Release(pAccessible);
	return rv;
}

/* ----------------------------------------- */

struct EventConsolidator_
{
	HWINEVENTHOOK hhook;
	int refcount;
};

typedef struct EventConsolidator_ EventConsolidator;

EventConsolidator *EventConsolidator_new()
{
	char xsDllfile[300];
	DWORD xsDllLen;
	HMODULE hDll = 0;
	EventConsolidator *rv = 0;

	// Start with file name of ActAcc.DLL.
	xsDllLen = GetModuleFileName(
			g_hinstDLL,    // handle to module
			xsDllfile,  // file name of module
			sizeof(xsDllfile)/sizeof*xsDllfile         // size of buffer
			);

	// Modify file name, giving complete path to ActAccEM.DLL
	// (assuming they're in one directory)
	strcpy(xsDllfile + xsDllLen - 4, "EM.dll");

	New(7, rv, 1, EventConsolidator); 
	rv->refcount = 1;
	rv->hhook = 0;
	hDll = LoadLibrary(xsDllfile);
	if (hDll)
	{
		enum { EVENTS_FROM_ALL_PROCESSES = 0 };
		WINEVENTPROC pfWinEventProc = (WINEVENTPROC) GetProcAddress(hDll, "_WinEventProc@28");
		if (pfWinEventProc)
		{
			rv->hhook = SetWinEventHook(EVENT_MIN, EVENT_MAX,
				hDll, pfWinEventProc, EVENTS_FROM_ALL_PROCESSES,
				0,
				WINEVENT_INCONTEXT);
			if (!rv->hhook)
			{
				croakWin32Error("SetWinEventHook");
			}
			else
			{
#ifdef MONITOR_OBJPOOL_EVENT_CONSOLIDATOR
				fprintf(stderr, "CREATE EventConsolidator at %08lx\n", rv);
#endif
			}
		}
		else
		{
			croakWin32Error("GetProcAddress");
		}
	}
	else
	{
		croakWin32Error("LoadLibrary");
	}
	return rv;
}

void EventConsolidator_addref(EventConsolidator *self)
{
	self->refcount++;
}

int EventConsolidator_release(EventConsolidator *self)
{
	int new_refcount = --self->refcount;
	if (!new_refcount)
	{
#ifdef MONITOR_OBJPOOL_EVENT_CONSOLIDATOR
		fprintf(stderr, "DESTROY EventConsolidator at %08lx\n", self);
#endif
		UnhookWinEvent(self->hhook);
		Safefree(self);
	}
	return new_refcount;
}

EventConsolidator *g_eventConsolidator = 0;

EventConsolidator *getConsolidator()
{
	if (!g_eventConsolidator)
	{
		g_eventConsolidator = EventConsolidator_new();
	}
	else
	{
		EventConsolidator_addref(g_eventConsolidator);
	}
	return g_eventConsolidator;
}

void releaseConsolidator()
{
	if (!EventConsolidator_release(g_eventConsolidator))
		g_eventConsolidator = 0;
}

/* ----------------------------------------- */

struct EventMonitor_
{
	EventConsolidator *cons;
	long readCursorQume;
};

typedef struct EventMonitor_ EventMonitor;
typedef struct EventMonitor_* EventMonitorPtr;

EventMonitor *EventMonitor_new()
{
	EventMonitor *rv = 0;
	New(7, rv, 1, EventMonitor); 
	rv->cons = 0;
	rv->readCursorQume = 0;
#ifdef MONITOR_OBJPOOL
	fprintf(stderr, "new EventMonitor at %08lx\n", rv);
#endif
	return rv;
}

void EventMonitor_activate(EventMonitor *em)
{
	if (!em->cons)
	{
		em->cons = getConsolidator();
	}
}

void EventMonitor_deactivate(EventMonitor *em)
{
	if (em->cons)
	{
		releaseConsolidator();
		em->cons = 0;
	}
}

EventMonitor *EventMonitor_synch(EventMonitor *em)
{
	if (emLock())
	{
		em->readCursorQume = emSynch();
		emUnlock();
	}
	else
		croakWin32Error("EventMonitor_synch");
	return em;
}


/* ----------------------------------------- */

void croakIfNullIAccessible(ActAcc *p)
{
	if (!p->ia)
	{
		croak("Illegal use of null ActAcc (perhaps it has already been Release'd)");
	}
}

/* ----------------------------------------- */

typedef char accessibleKey[17];

char *textKey(IAccessible *ia, DWORD id, accessibleKey buf)
{
	sprintf(buf, "%08lx%08lx", ia, id);
	return buf;
}

#ifndef INT2PTR
#define INT2PTR(T,P) ((T)(P))
#endif

// lookup existing, or create new
ActAcc *ActAcc_from_IAccessible(IAccessible *ia, DWORD id)
{
	ActAcc *aa = 0;
	// get stash
	// get our hash of IAccessible+ID pairs
	// is the requested IA+ID in the hash?
	// if not, make a new one
	HV *hvStash = gv_stashpv("Win32::ActAcc", 0);
	accessibleKey ak;
	SV **ppActAcc;
	textKey(ia, id, ak);
	if (!hvStash)
		return 0;
	ppActAcc = hv_fetch(hvStash, ak, strlen(ak), 0);
	if (ppActAcc)
	{
		IV tmp;
		// get int value
		// cast to pointer
	    tmp = SvIV(*ppActAcc);
	    aa = INT2PTR(ActAccPtr,tmp);
		//fprintf(stderr, "hash: %s is there: the aa* is %08lx!\n", &ak, aa);
	}
	else
	{
		IV tmp;
		SV *svtmp;
		SV** psv = 0;
		// create new
		// put into hash
		aa = ActAcc_new_from_IAccessible(ia, id);
		//fprintf(stderr, "hash: %s is NOT there.. storing aa* of %08lx\n", &ak, aa);
		tmp = (IV)aa;
		svtmp = newSViv(tmp);
		psv = hv_store(hvStash, ak, strlen(ak), svtmp, 0);
		aa = ActAcc_from_IAccessible(ia, id);
	}
	return aa;
}

void rmv_from_hash(ActAcc *p)
{
	HV *hvStash = gv_stashpv("Win32::ActAcc", 0);
	accessibleKey ak;
	SV **ppActAcc;
	textKey(p->ia, p->id, ak);
	if (hvStash)
		hv_delete(hvStash, ak, strlen(ak), G_DISCARD);
}

// caller always responsible for freeing the IDispatch
ActAcc *ActAcc_from_IDispatch(IDispatch *pDispatch)
{
	ActAcc *rv = 0;
	IAccessible *pAccessible = 0;
	HRESULT hr = IDispatch_QueryInterface(pDispatch, USEGUID(IID_IAccessible), (void**)&pAccessible);
	croakIf(hr, !SUCCEEDED(hr), "ActAcc_from_IDispatch");
	rv = ActAcc_from_IAccessible(pAccessible, CHILDID_SELF);
	IAccessible_Release(pAccessible);
	return rv;
}

void ActAcc_free_incl_hash(ActAcc *p)
{
#ifdef MONITOR_OBJPOOL
	fprintf(stderr, "DESTROY(%08lx)\n", p);
#endif
	if (p->ia) 
	{
		IAccessible_Release(p->ia);
		rmv_from_hash(p);
	}
	ZeroMemory(p, sizeof(ActAcc));
	Safefree(p);
}

/* ----------------------------------------- */

SV *textAccessor(ActAcc *p, 
			HRESULT ( STDMETHODCALLTYPE __RPC_FAR *pfn )( 
				IAccessible __RPC_FAR * This,
				VARIANT varChild,
				BSTR __RPC_FAR *pszName))
{
	HRESULT hr = S_OK;
	BSTR bs = 0;
	int cch = 0;
	SV *rv = &PL_sv_undef;
	VARIANT childid;
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childid, p->id);
	hr = (*pfn)(p->ia, childid, &bs);
	VariantClear(&childid);
	if (S_OK == hr)
	{
		char *a = 0;
		cch = SysStringLen(bs);
		New(7, a, 1 + cch, char); 
		ZeroMemory(a, 1 + cch);
		WideCharToMultiByte(0,0,bs,1+cch,a,cch,0,0);
		rv = sv_2mortal(newSVpv(a,0));
		Safefree(a);
	}
	else if ((S_FALSE != hr) && (DISP_E_MEMBERNOTFOUND != hr) && (E_NOTIMPL != hr))
	{
		char w[100];
		sprintf(w, "Error %08lx in textAccessor", hr);
		warn(w);
	}
	SysFreeString(bs);
	return rv;
}

int getAccChildCount(IAccessible *iaParent)
{
	HWND hwnd = 0;
	long nChildren = 0;
	HRESULT hrCount = IAccessible_get_accChildCount(iaParent, &nChildren);
	if (RPC_E_SERVERFAULT == hrCount)
	{
		warn("Sorry!  An application thread just crashed.\n");
		nChildren = 0;
		hrCount = S_OK;
	}
	croakIf(hrCount, !SUCCEEDED(hrCount), "getAccChildCount");
	return nChildren;
}


#define CONST_TEST(X) if ((strlen(#X)==len) && !strncmp(namep,#X,sizeof(#X)-1)) return (int)X;

static double
constant(char *namep, int len, int arg)
{
	CONST_TEST(CHILDID_SELF)
	CONST_TEST(OBJID_WINDOW)
	CONST_TEST(OBJID_SYSMENU)
	CONST_TEST(OBJID_TITLEBAR)
	CONST_TEST(OBJID_MENU)
	CONST_TEST(OBJID_CLIENT)
	CONST_TEST(OBJID_VSCROLL)
	CONST_TEST(OBJID_HSCROLL)
	CONST_TEST(OBJID_SIZEGRIP)
	CONST_TEST(OBJID_CARET)
	CONST_TEST(OBJID_CURSOR)
	CONST_TEST(OBJID_ALERT)
	CONST_TEST(OBJID_SOUND)
	CONST_TEST(CCHILDREN_FRAME)

#ifndef STATE_SYSTEM_NORMAL
#define STATE_SYSTEM_NORMAL (0)
#endif
	CONST_TEST(STATE_SYSTEM_NORMAL)
	CONST_TEST(STATE_SYSTEM_UNAVAILABLE)
	CONST_TEST(STATE_SYSTEM_SELECTED)
	CONST_TEST(STATE_SYSTEM_FOCUSED)
	CONST_TEST(STATE_SYSTEM_PRESSED)
	CONST_TEST(STATE_SYSTEM_CHECKED)
	CONST_TEST(STATE_SYSTEM_MIXED)
#ifdef STATE_SYSTEM_INDETERMINATE
	CONST_TEST(STATE_SYSTEM_INDETERMINATE)
#endif
	CONST_TEST(STATE_SYSTEM_READONLY)
	CONST_TEST(STATE_SYSTEM_HOTTRACKED)
	CONST_TEST(STATE_SYSTEM_DEFAULT)
	CONST_TEST(STATE_SYSTEM_EXPANDED)
	CONST_TEST(STATE_SYSTEM_COLLAPSED)
	CONST_TEST(STATE_SYSTEM_BUSY)
	CONST_TEST(STATE_SYSTEM_FLOATING)
	CONST_TEST(STATE_SYSTEM_MARQUEED)
	CONST_TEST(STATE_SYSTEM_ANIMATED)
	CONST_TEST(STATE_SYSTEM_INVISIBLE)
	CONST_TEST(STATE_SYSTEM_OFFSCREEN)
	CONST_TEST(STATE_SYSTEM_SIZEABLE)
	CONST_TEST(STATE_SYSTEM_MOVEABLE)
	CONST_TEST(STATE_SYSTEM_SELFVOICING)
	CONST_TEST(STATE_SYSTEM_FOCUSABLE)
	CONST_TEST(STATE_SYSTEM_SELECTABLE)
	CONST_TEST(STATE_SYSTEM_LINKED)
	CONST_TEST(STATE_SYSTEM_TRAVERSED)
	CONST_TEST(STATE_SYSTEM_MULTISELECTABLE)
	CONST_TEST(STATE_SYSTEM_EXTSELECTABLE)
	CONST_TEST(STATE_SYSTEM_ALERT_LOW)
	CONST_TEST(STATE_SYSTEM_ALERT_MEDIUM)
	CONST_TEST(STATE_SYSTEM_ALERT_HIGH)
#ifdef STATE_SYSTEM_PROTECTED
	CONST_TEST(STATE_SYSTEM_PROTECTED)
#endif
	CONST_TEST(STATE_SYSTEM_VALID)

	CONST_TEST(ROLE_SYSTEM_TITLEBAR)
	CONST_TEST(ROLE_SYSTEM_MENUBAR)
	CONST_TEST(ROLE_SYSTEM_SCROLLBAR)
	CONST_TEST(ROLE_SYSTEM_GRIP)
	CONST_TEST(ROLE_SYSTEM_SOUND)
	CONST_TEST(ROLE_SYSTEM_CURSOR)
	CONST_TEST(ROLE_SYSTEM_CARET)
	CONST_TEST(ROLE_SYSTEM_ALERT)
	CONST_TEST(ROLE_SYSTEM_WINDOW)
	CONST_TEST(ROLE_SYSTEM_CLIENT)
	CONST_TEST(ROLE_SYSTEM_MENUPOPUP)
	CONST_TEST(ROLE_SYSTEM_MENUITEM)
	CONST_TEST(ROLE_SYSTEM_TOOLTIP)
	CONST_TEST(ROLE_SYSTEM_APPLICATION)
	CONST_TEST(ROLE_SYSTEM_DOCUMENT)
	CONST_TEST(ROLE_SYSTEM_PANE)
	CONST_TEST(ROLE_SYSTEM_CHART)
	CONST_TEST(ROLE_SYSTEM_DIALOG)
	CONST_TEST(ROLE_SYSTEM_BORDER)
	CONST_TEST(ROLE_SYSTEM_GROUPING)
	CONST_TEST(ROLE_SYSTEM_SEPARATOR)
	CONST_TEST(ROLE_SYSTEM_TOOLBAR)
	CONST_TEST(ROLE_SYSTEM_STATUSBAR)
	CONST_TEST(ROLE_SYSTEM_TABLE)
	CONST_TEST(ROLE_SYSTEM_COLUMNHEADER)
	CONST_TEST(ROLE_SYSTEM_ROWHEADER)
	CONST_TEST(ROLE_SYSTEM_COLUMN)
	CONST_TEST(ROLE_SYSTEM_ROW)
	CONST_TEST(ROLE_SYSTEM_CELL)
	CONST_TEST(ROLE_SYSTEM_LINK)
	CONST_TEST(ROLE_SYSTEM_HELPBALLOON)
	CONST_TEST(ROLE_SYSTEM_CHARACTER)
	CONST_TEST(ROLE_SYSTEM_LIST)
	CONST_TEST(ROLE_SYSTEM_LISTITEM)
	CONST_TEST(ROLE_SYSTEM_OUTLINE)
	CONST_TEST(ROLE_SYSTEM_OUTLINEITEM)
	CONST_TEST(ROLE_SYSTEM_PAGETAB)
	CONST_TEST(ROLE_SYSTEM_PROPERTYPAGE)
	CONST_TEST(ROLE_SYSTEM_INDICATOR)
	CONST_TEST(ROLE_SYSTEM_GRAPHIC)
	CONST_TEST(ROLE_SYSTEM_STATICTEXT)
	CONST_TEST(ROLE_SYSTEM_TEXT)
	CONST_TEST(ROLE_SYSTEM_PUSHBUTTON)
	CONST_TEST(ROLE_SYSTEM_CHECKBUTTON)
	CONST_TEST(ROLE_SYSTEM_RADIOBUTTON)
	CONST_TEST(ROLE_SYSTEM_COMBOBOX)
	CONST_TEST(ROLE_SYSTEM_DROPLIST)
	CONST_TEST(ROLE_SYSTEM_PROGRESSBAR)
	CONST_TEST(ROLE_SYSTEM_DIAL)
	CONST_TEST(ROLE_SYSTEM_HOTKEYFIELD)
	CONST_TEST(ROLE_SYSTEM_SLIDER)
	CONST_TEST(ROLE_SYSTEM_SPINBUTTON)
	CONST_TEST(ROLE_SYSTEM_DIAGRAM)
	CONST_TEST(ROLE_SYSTEM_ANIMATION)
	CONST_TEST(ROLE_SYSTEM_EQUATION)
	CONST_TEST(ROLE_SYSTEM_BUTTONDROPDOWN)
	CONST_TEST(ROLE_SYSTEM_BUTTONMENU)
	CONST_TEST(ROLE_SYSTEM_BUTTONDROPDOWNGRID)
	CONST_TEST(ROLE_SYSTEM_WHITESPACE)
	CONST_TEST(ROLE_SYSTEM_PAGETABLIST)
	CONST_TEST(ROLE_SYSTEM_CLOCK)
	CONST_TEST(SELFLAG_NONE)
	CONST_TEST(SELFLAG_TAKEFOCUS)
	CONST_TEST(SELFLAG_TAKESELECTION)
	CONST_TEST(SELFLAG_EXTENDSELECTION)
	CONST_TEST(SELFLAG_ADDSELECTION)
	CONST_TEST(SELFLAG_REMOVESELECTION)
	CONST_TEST(SELFLAG_VALID)

	CONST_TEST(NAVDIR_MIN)
	CONST_TEST(NAVDIR_UP)
	CONST_TEST(NAVDIR_DOWN)
	CONST_TEST(NAVDIR_LEFT)
	CONST_TEST(NAVDIR_RIGHT)
	CONST_TEST(NAVDIR_NEXT)
	CONST_TEST(NAVDIR_PREVIOUS)
	CONST_TEST(NAVDIR_FIRSTCHILD)
	CONST_TEST(NAVDIR_LASTCHILD)
	CONST_TEST(NAVDIR_MAX)

	CONST_TEST(EVENT_SYSTEM_SOUND)
	CONST_TEST(EVENT_SYSTEM_ALERT)
	CONST_TEST(EVENT_SYSTEM_FOREGROUND)
	CONST_TEST(EVENT_SYSTEM_MENUSTART)
	CONST_TEST(EVENT_SYSTEM_MENUEND)
	CONST_TEST(EVENT_SYSTEM_MENUPOPUPSTART)
	CONST_TEST(EVENT_SYSTEM_MENUPOPUPEND)
	CONST_TEST(EVENT_SYSTEM_CAPTURESTART)
	CONST_TEST(EVENT_SYSTEM_CAPTUREEND)
	CONST_TEST(EVENT_SYSTEM_MOVESIZESTART)
	CONST_TEST(EVENT_SYSTEM_MOVESIZEEND)
	CONST_TEST(EVENT_SYSTEM_CONTEXTHELPSTART)
	CONST_TEST(EVENT_SYSTEM_CONTEXTHELPEND)
	CONST_TEST(EVENT_SYSTEM_DRAGDROPSTART)
	CONST_TEST(EVENT_SYSTEM_DRAGDROPEND)
	CONST_TEST(EVENT_SYSTEM_DIALOGSTART)
	CONST_TEST(EVENT_SYSTEM_DIALOGEND)
	CONST_TEST(EVENT_SYSTEM_SCROLLINGSTART)
	CONST_TEST(EVENT_SYSTEM_SCROLLINGEND)
	CONST_TEST(EVENT_SYSTEM_SWITCHSTART)
	CONST_TEST(EVENT_SYSTEM_SWITCHEND)
	CONST_TEST(EVENT_SYSTEM_MINIMIZESTART)
	CONST_TEST(EVENT_SYSTEM_MINIMIZEEND)
	CONST_TEST(EVENT_OBJECT_CREATE)
	CONST_TEST(EVENT_OBJECT_DESTROY)
	CONST_TEST(EVENT_OBJECT_SHOW)
	CONST_TEST(EVENT_OBJECT_HIDE)
	CONST_TEST(EVENT_OBJECT_REORDER)
	CONST_TEST(EVENT_OBJECT_FOCUS)
	CONST_TEST(EVENT_OBJECT_SELECTION)
	CONST_TEST(EVENT_OBJECT_SELECTIONADD)
	CONST_TEST(EVENT_OBJECT_SELECTIONREMOVE)
	CONST_TEST(EVENT_OBJECT_SELECTIONWITHIN)
	CONST_TEST(EVENT_OBJECT_STATECHANGE)
	CONST_TEST(EVENT_OBJECT_LOCATIONCHANGE)
	CONST_TEST(EVENT_OBJECT_NAMECHANGE)
	CONST_TEST(EVENT_OBJECT_DESCRIPTIONCHANGE)
	CONST_TEST(EVENT_OBJECT_VALUECHANGE)
	CONST_TEST(EVENT_OBJECT_PARENTCHANGE)
	CONST_TEST(EVENT_OBJECT_HELPCHANGE)
	CONST_TEST(EVENT_OBJECT_DEFACTIONCHANGE)
	CONST_TEST(EVENT_OBJECT_ACCELERATORCHANGE)

	CONST_TEST(SM_CXSCREEN)
	CONST_TEST(SM_CYSCREEN)

#ifdef NOT_DEFINED
		char *c = (char*)malloc(1+len);
		strncpy(c, namep, len);
		c[len] = 0;
		fprintf(stderr, "Flunking constant(%s)\n", c);
		free(c);
#endif

    errno = EINVAL;
    return 0;
}

// translate POINT p from pixels to mickeys
void ScreenToMouseplane(POINT *p)
{
    p->x = MulDiv(p->x, 0x10000, GetSystemMetrics(SM_CXSCREEN));
    p->y = MulDiv(p->y, 0x10000, GetSystemMetrics(SM_CYSCREEN));
}

// mouse operations in pixels
void mouse_button(int x, int y, char *ops)
{
    POINT p;
    p.x = x;  p.y = y;
    ScreenToMouseplane(&p);
    while (*ops)
    {
        switch (*ops)
        {
        case 'm':
            mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE, p.x, p.y, 0, 0);
            break;
        case 'd':
            mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
            break;
        case 'u':
            mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
            break;
        case 'D':
            mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_RIGHTDOWN, p.x, p.y, 0, 0);
            break;
        case 'U':
            mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_RIGHTUP, p.x, p.y, 0, 0);
            break;
        }
        ops++;
    }
}

MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc		

INCLUDE: ActAcc.xsh



MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc::AO		

INCLUDE: AO.xsh



MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc::EventMonitor

INCLUDE: EM.xsh
