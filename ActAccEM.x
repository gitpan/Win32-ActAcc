/* Copyright 2000, Phill Wolf.  See README. */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

// Inproc Active Accessibility event handler for Win32::ActAcc

// Design rules:

//    No C runtime library usage (it could conflict with AUT)

#pragma warning(disable: 4514) // unreferenced inline function has been removed
#pragma warning(disable: 4201) // nonstandard extension used : nameless struct/union
#define STRICT

#include <wtypes.h>
#include <winerror.h>
#include <winuser.h>
#include <commctrl.h>
#include <winable.h>

#define ActAccEM_LINKAGE __declspec(dllexport)

#include "AAEvtMon.h"

HINSTANCE g_hinstDll = NULL;

// We don't want to require ANY runtime library support.
#pragma check_stack(off)
#pragma intrinsic(memset)
#pragma intrinsic(memcpy)
#pragma intrinsic(strcpy)
#pragma intrinsic(strlen)
#pragma warning(disable:4127)

BOOL WINAPI DllMain(HINSTANCE hinstDll, DWORD fdwReason, LPVOID /*fImpLoad*/)
{
    switch (fdwReason) 
    {
    case DLL_PROCESS_ATTACH:
        g_hinstDll = hinstDll;
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

bool oriented = false;
bool live = false;
HANDLE hMx = 0;
HANDLE hFM = 0;
struct aaevbuf * pEvBuf = 0;

void orient()
{
	hMx = CreateMutex(NULL, FALSE, AAEvtMon_MUTEX);
	if (hMx)
	{
		hFM = CreateFileMapping(
				(HANDLE)0xffffffff, 
				NULL, 
				PAGE_READWRITE, 
				0, sizeof(struct aaevbuf), 
				AAEvtMon_MAP);
		if (hFM)
		{
			pEvBuf = (struct aaevbuf *) MapViewOfFile(
					hFM, 
					FILE_MAP_WRITE|FILE_MAP_READ, 
					0, 0, 
					sizeof(struct aaevbuf));
			if (pEvBuf)
			{
				live = true;
			}
			else
			{
				CloseHandle(hMx);
				hMx = 0;
				CloseHandle(hFM);
				hFM = 0;
			}
		}
		else
		{
			CloseHandle(hMx);
			hMx = 0;
		}
	}
	oriented = true; // regardless whether it worked.
}

int incAndWrap(int a, const int lim, const int increment =1)
{
	a += increment;
	while (lim<=a)
		a -= lim;
	return a;
}

// called only when buffer is locked
void logEvent(DWORD event, HWND hwnd, LONG idObject, LONG idChild, DWORD dwmsEventTime, HWINEVENTHOOK hWinEventHook)
{
	pEvBuf->cumulativeCounter++;

	int cached_wc = pEvBuf->wc;

	pEvBuf->ae[cached_wc].event = event;
	pEvBuf->ae[cached_wc].hwnd = hwnd;
	pEvBuf->ae[cached_wc].idObject = idObject;
	pEvBuf->ae[cached_wc].idChild = idChild;
	pEvBuf->ae[cached_wc].dwmsEventTime = dwmsEventTime;
	pEvBuf->ae[cached_wc].hWinEventHook = hWinEventHook;

	pEvBuf->wc = incAndWrap(pEvBuf->wc, BUF_CAPY_IN_EVENTS);
}

extern "C" {
	ActAccEM_LINKAGE VOID CALLBACK WinEventProc(
	  HWINEVENTHOOK hWinEventHook,
	  DWORD event,
	  HWND hwnd,
	  LONG idObject,
	  LONG idChild,
	  DWORD dwEventThread,
	  DWORD dwmsEventTime
	);
};

//http://msdn.microsoft.com/library/default.asp?URL=/library/psdk/msaa/msaaccrf_9x9q.htm
VOID CALLBACK WinEventProc(
  HWINEVENTHOOK hWinEventHook,
  DWORD event,
  HWND hwnd,
  LONG idObject,
  LONG idChild,
  DWORD, // dwEventThread
  DWORD dwmsEventTime
)
{
	// First time, obtain handle to shared mutex.
	if (!oriented)
	{
		orient();
	}

	// Grab mutex. Log event. Release mutex.
	if (live)
	{
		if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
		{
			logEvent(event, hwnd, idObject, idChild, dwmsEventTime, hWinEventHook);
			ReleaseMutex(hMx);
		}
	}
}

long emGetCounter()
{
	int rv = -1; // pessimistic

	// First time, obtain handle to shared mutex.
	if (!oriented)
	{
		orient();
	}

	// Grab mutex. Log event. Release mutex.
	if (live)
	{
		if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
		{
			rv = pEvBuf->cumulativeCounter;
			ReleaseMutex(hMx);
		}
	}

	return rv;
}

bool emLock()
{
	bool rv = false;

	// First time, obtain handle to shared mutex.
	if (!oriented)
	{
		orient();
	}

	// Grab mutex. Log event. Release mutex.
	if (live)
	{
		if (WAIT_OBJECT_0 == WaitForSingleObject(hMx, AAEvtMon_PATIENCE_ms))
			rv = true;
	}

	return rv;
}

void emUnlock()
{
	ReleaseMutex(hMx);
}

// call only when locked
// readCursorQume is cumulative - not relative to start of buffer. It does not wrap.
void emGetEventPtr(const long readCursorQume, const int max, int *actual, struct aaevt **pp)
{
	// pessimistic
	*actual = 0;
	*pp = 0;

	// Translate cumulative readCursor to relative.
	int readCursor = readCursorQume % BUF_CAPY_IN_EVENTS;

	// Ordinarily, the max block size is BUF_CAPY_IN_EVENTS - readCursor.
	int eventsInReadableBlock = BUF_CAPY_IN_EVENTS - readCursor;

	// But readCursorQume may never exceed cumulativeCounter.
	if (eventsInReadableBlock > (pEvBuf->cumulativeCounter - readCursorQume))
		eventsInReadableBlock = pEvBuf->cumulativeCounter - readCursorQume;

	// And impose the user's ceiling, if lower.
	*actual = (max < eventsInReadableBlock) ? max : eventsInReadableBlock;

	*pp = pEvBuf->ae + readCursor;
}

// call only when locked.
// returns readCursor that will (at the moment) have nothing to read.
long emSynch()
{
	return pEvBuf->cumulativeCounter;
}
