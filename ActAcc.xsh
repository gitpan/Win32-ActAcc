double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

U32
foo(hwnd)
	INPUT:
	HWND	hwnd
	CODE:
	RETVAL = (U32) hwnd;
	croak("Croaking");
	OUTPUT:
	RETVAL

HWND
GetDesktopWindow()
	CODE:
	RETVAL = GetDesktopWindow();
	OUTPUT:
	RETVAL

void
mouse_button(x,y, ops)
	int x
	int y
	char *ops
	CODE:
	mouse_button(x, y, ops);

void
AccessibleObjectFromEvent(hwnd, objectId, childId)
	INPUT:
	HWND	hwnd
	int	objectId
	int	childId
	PREINIT:
	HRESULT hr = S_OK;
	IAccessible *pAccessible = 0;
	ActAcc *pActAcc = 0;
	VARIANT varChild;
	PPCODE:
	VariantInit(&varChild);
	hr = AccessibleObjectFromEvent(hwnd, objectId, childId, &pAccessible, &varChild);
	croakIf(hr, S_OK != hr, "AccessibleObjectFromEvent");
	warnIf(hr, !SUCCEEDED(hr), "AccessibleObjectFromEvent");
	if (VT_I4 != varChild.vt) 
		croak("oog88");
	pActAcc = ActAcc_from_IAccessible(pAccessible, varChild.lVal);
	IAccessible_Release(pAccessible);
	XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(pActAcc), pActAcc));

void
AccessibleObjectFromWindow(hwnd, ...)
	INPUT:
	HWND	hwnd
	PREINIT:
	I32	objectId = CHILDID_SELF;
	HRESULT hr = S_OK;
	IAccessible *pAccessible = 0;
	ActAcc *pActAcc = 0;
	PPCODE:
	if (items > 1)
		objectId = SvIV(ST(1));
	if (!IsWindow(hwnd)) 
	{
		char work[100];
		sprintf(work, "%08lx is not a valid HWND", (unsigned long)hwnd);
		croak(work);
	}
	hr = AccessibleObjectFromWindow(hwnd, objectId, USEGUID(IID_IAccessible), (void**)&pAccessible);
	croakIf(hr, S_OK != hr, "AccessibleObjectFromWindow");
	warnIf(hr, !SUCCEEDED(hr), "AccessibleObjectFromWindow");
	pActAcc = ActAcc_from_IAccessible(pAccessible, objectId);
	IAccessible_Release(pAccessible);
	XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(pActAcc), pActAcc));

void
AccessibleObjectFromPoint(x, y)
	INPUT:
	long x
	long y
	PREINIT:
	VARIANT childId;
	HRESULT hr;
	POINT point;
	IAccessible *ia = 0;
	ActAcc *pActAcc = 0;
	PPCODE:
	VariantInit(&childId);
	point.x = x;
	point.y = y;
	hr = AccessibleObjectFromPoint(point, &ia, &childId);
	croakIf(hr, !SUCCEEDED(hr), "AccessibleObjectFromPoint");
	pActAcc = ActAcc_from_IAccessible(ia, childId.lVal);
	IAccessible_Release(ia);
	XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(pActAcc), pActAcc));

char *
GetRoleText(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	char w[100];
	CODE:
	ZeroMemory(w, sizeof(w));
	if (!GetRoleText(i, w, sizeof(w)-1))
	{
		hr = GetLastError();
		croakIf(hr, !SUCCEEDED(hr), "GetRoleText");
	}
	RETVAL = w;
	OUTPUT:
	RETVAL

char *
GetRolePackage(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	CODE:
	RETVAL = packageForRole(i);
	OUTPUT:
	RETVAL

char *
GetStateText(i)
	INPUT:
	int	i
	PREINIT:
	HRESULT hr = S_OK;
	char w[20];
	CODE:
	ZeroMemory(w, sizeof(w));
	if (!GetStateText(i, w, sizeof(w)-1))
	{
		hr = GetLastError();
		croakIf(hr, !SUCCEEDED(hr), "GetStateText");
	}
	RETVAL = w;
	OUTPUT:
	RETVAL

EventMonitor *
events_register(active)
	INPUT:
	int active
	PREINIT:
	CODE:
	RETVAL = EventMonitor_new();
	if (active)
	{
		EventMonitor_activate(RETVAL);
		EventMonitor_synch(RETVAL);
	}
	OUTPUT:
	RETVAL

int 
GetSystemMetrics(mnum)
	INPUT:
    int mnum
	CODE:
    RETVAL = GetSystemMetrics(mnum);
	OUTPUT:
	RETVAL

