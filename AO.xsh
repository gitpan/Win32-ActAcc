int
Equals(a,b)
	INPUT:
	ActAcc * a
	ActAcc * b
	CODE:
	RETVAL = !!((a->ia == b->ia) && (a->id == b->id));
	if (!RETVAL && a->id==CHILDID_SELF && b->id==CHILDID_SELF)
	{
		HRESULT hr;
		HWND ha, hb;
		hr = WindowFromAccessibleObject(a->ia, &ha);
		if (SUCCEEDED(hr))
		{
			hr = WindowFromAccessibleObject(b->ia, &hb);
			if (SUCCEEDED(hr))
				RETVAL = 2*!!(ha == hb);			
		}
	}
	OUTPUT:
	RETVAL

void
Release(p)
	INPUT:
	ActAcc * p
	CODE:
	if (p->ia) // idempotent
	{
		rmv_from_hash(p);
		IAccessible_Release(p->ia);
		p->ia = 0;
	}

void
DESTROY(p)
	INPUT:
	ActAcc * p
	CODE:
	ActAcc_free_incl_hash(p);

HWND
WindowFromAccessibleObject(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	HWND hwnd = 0;
	CODE:
	croakIfNullIAccessible(p);
	if (p->id != CHILDID_SELF)
		croak("WindowFromAccessibleObject only works for CHILDID_SELF");
	hr = WindowFromAccessibleObject(p->ia, &hwnd);
	croakIf(hr, S_OK != hr, "WindowFromAccessibleObject");
	RETVAL = hwnd;
	OUTPUT:
	RETVAL

int
get_accRole(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	VARIANT childid;
	VARIANT vrole;
	CODE:
	croakIfNullIAccessible(p);
	childid.vt=VT_I4;
	childid.lVal=p->id;
	VariantInit(&vrole);
	hr = IAccessible_get_accRole(p->ia, childid, &vrole);
	croakIf(hr, S_OK != hr, "get_accRole");
	if (vrole.vt==VT_I4)
		RETVAL = vrole.lVal;
	else
		croak("illegal response from get_accRole");
	VariantClear(&childid);
	VariantClear(&vrole);
	OUTPUT:
	RETVAL

int
get_accState(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	VARIANT childid;
	VARIANT v;
	CODE:
	croakIfNullIAccessible(p);
	childid.vt=VT_I4;
	childid.lVal=p->id;
	VariantInit(&v);
	hr = IAccessible_get_accState(p->ia, childid, &v);
	croakIf(hr, S_OK != hr, "get_accState");
	if (v.vt==VT_I4)
		RETVAL = v.lVal;
	else
		croak("illegal response from get_accState");
	VariantClear(&childid);
	VariantClear(&v);
	OUTPUT:
	RETVAL

void
get_accName(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accName));

char *
get_accValue(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accValue));

char *
get_accDescription(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accDescription));

char *
get_accHelp(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accHelp));

char *
get_accDefaultAction(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accDefaultAction));

char *
get_accKeyboardShortcut(p)
	INPUT:
	ActAcc * p
	PPCODE:
	XPUSHs(textAccessor(p, p->ia->lpVtbl->get_accKeyboardShortcut));

int
get_accChildCount(p)
	INPUT:
	ActAcc * p
	PREINIT:
	long cch = 0;
	CODE:
	croakIfNullIAccessible(p);
	if (CHILDID_SELF == p->id) 
		cch = getAccChildCount(p->ia);
	RETVAL = cch;
	OUTPUT:
	RETVAL

void
get_accChild(p, id)
	INPUT:
	ActAcc * p
	int	id
	PREINIT:
	HRESULT hr = S_OK;
	IDispatch *pDispatch = 0;
        ActAcc *pActAcc = 0;
	VARIANT vch;
	PPCODE:
	croakIfNullIAccessible(p);
	if (CHILDID_SELF != p->id) 
		croak("Item has no children");
	VariantInit_VT_I4(&vch, id);
	hr = IAccessible_get_accChild(p->ia, vch, &pDispatch);
	if (S_OK == hr)
		pActAcc = ActAcc_from_IDispatch(pDispatch);
	else if ((S_FALSE == hr) || (E_INVALIDARG == hr))
		pActAcc = ActAcc_from_IAccessible(p->ia, id);
	else
	{
		croak("Oops5");
	}
	XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(pActAcc), pActAcc));
	if (pDispatch) IDispatch_Release(pDispatch);

void
AccessibleChildren(p, ...)
	INPUT:
	ActAcc * p
	PREINIT:
	VARIANT childIdSelf;
	HRESULT hrAC = S_OK;
	long nChildrenDescribed = 0;
	long nChildren = 0;
	VARIANT *varCh = 0;
	int i;
	ActAcc *aa = 0;
	// By default, find only visible windows: where STATE_SYSTEM_INVISIBLE is not set.
	int sigStateBits = STATE_SYSTEM_INVISIBLE;
	int cmpStateBits = 0;
	PPCODE:
	if (items > 2)
	{
		sigStateBits = SvIV(ST(1));
		cmpStateBits = SvIV(ST(2)); 
	}
	croakIfNullIAccessible(p);
	if (CHILDID_SELF == p->id) 
	{
		VariantInit_VT_I4(&childIdSelf, CHILDID_SELF);
		nChildren = getAccChildCount(p->ia);

		New(7, varCh, nChildren, VARIANT); 
		for (i = 0; i < nChildren; i++)
		{
			VariantInit(&varCh[i]);
			varCh[i].vt = VT_DISPATCH;
		}
		hrAC = AccessibleChildren(p->ia, 0, nChildren, varCh, &nChildrenDescribed);
		// Note: S_FALSE is documented as a potential problem sign,
		// but it occurs pretty often so probably is not exceptional
		if (SUCCEEDED(hrAC))
		{
			for (i = 0; i < nChildrenDescribed; i++)
			{
				aa = 0;

				// Find or make Accessible Object
				if(VT_DISPATCH == varCh[i].vt)
				{
					aa = ActAcc_from_IDispatch(varCh[i].pdispVal);
				}
				else if (VT_I4 == varCh[i].vt)
				{
					aa = ActAcc_from_IAccessible(p->ia, varCh[i].lVal);
				}
				else
				{
					croak("hmm99");
				}

				// Eliminate Accessible Object if it fails the test
				if ((sigStateBits != 0) && aa)
				{
					VARIANT vs;
					VARIANT idChild;
					int isOk = 0;
					HRESULT hr = S_OK;
					VariantInit(&vs);
					VariantInit_VT_I4(&idChild, aa->id);
					hr = IAccessible_get_accState(aa->ia, idChild, &vs);
					if ((S_OK == hr) && (VT_I4 == vs.vt))
					{
						long L = vs.lVal;
						if ((L & sigStateBits) == cmpStateBits)
						{
							isOk = 1;
						}
					}
					if (!isOk)
					{
						ActAcc_free_incl_hash(aa);
						aa = 0;
					}
				}
				
				// Add Accessible Object to the return list
				if (aa)
					XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));

				VariantClear(&varCh[i]);
			}
		}
	}

void
get_accParent(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	VARIANT vch;
	PPCODE:
	croakIfNullIAccessible(p);
	if (CHILDID_SELF != p->id) 
	{
		ActAcc *aa = ActAcc_from_IAccessible(p->ia, CHILDID_SELF);
		XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
	}
	else
	{
		IDispatch *pDispatch = 0;
		hr = IAccessible_get_accParent(p->ia, &pDispatch);
		if (S_OK == hr)
		{
			ActAcc *aa = ActAcc_from_IDispatch(pDispatch);
			XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
			IDispatch_Release(pDispatch);
		}
		else if (S_FALSE == hr)
		{
			XPUSHs(&PL_sv_undef);
		}
		else
		{
			croak("Oops5");
		}
	}

void
get_accFocus(p)
	INPUT:
	ActAcc * p
	PREINIT:
	HRESULT hr = S_OK;
	VARIANT v;//IDispatch *pDispatch = 0;
	PPCODE:
	croakIfNullIAccessible(p);
	VariantInit(&v);
	if (CHILDID_SELF != p->id) 
	{
		croak("Items do not support this - TBD - make ActAcc smarter");
	}
	else
	{
		hr = IAccessible_get_accFocus(p->ia, &v);
		if (S_OK == hr)
		{
			if (VT_DISPATCH == v.vt)
			{
				ActAcc *aa = ActAcc_from_IDispatch(v.pdispVal);
				XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
			}
			else if (VT_I4 == v.vt)
			{
				ActAcc *aa = ActAcc_from_IAccessible(p->ia, v.lVal);
				XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(aa), aa));
			}
			else if (VT_EMPTY == v.vt)
			{
				XPUSHs(&PL_sv_undef);
			}
		}
		else if ((S_FALSE == hr) || (DISP_E_MEMBERNOTFOUND == hr))
			XPUSHs(&PL_sv_undef);
		else
		{
			croak("Egad1");
		}
	}
	VariantClear(&v);

void
accDoDefaultAction_(p)
	INPUT:
	ActAcc * p
	PREINIT:
	VARIANT childId;
	HRESULT hrAC = S_OK;
	CODE:
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hrAC = IAccessible_accDoDefaultAction(p->ia, childId);
	if (!SUCCEEDED(hrAC))
		croakHRESULTAndWin32Error(hrAC, "accDoDefaultAction");

int
get_itemID(p)
	INPUT:
	ActAcc * p
	CODE:
	croakIfNullIAccessible(p);
	RETVAL = p->id;
	OUTPUT:
	RETVAL

void
accSelect(p, flags)
	INPUT:
	ActAcc * p
	long flags
	PREINIT:
	VARIANT childId;
	HRESULT hrAC = S_OK;
	CODE:
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hrAC = IAccessible_accSelect(p->ia, flags, childId);
	croakIf(hrAC, !SUCCEEDED(hrAC), "accSelect");

void
accLocation(p)
	INPUT:
	ActAcc * p
	PREINIT:
	long left, top, width, height;
	VARIANT childId;
	HRESULT hr;
	PPCODE:
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&childId, p->id);
	hr = IAccessible_accLocation(p->ia, &left, &top, &width, &height, childId);
	croakIf(hr, !SUCCEEDED(hr), "accLocation");
	XPUSHs(sv_2mortal(newSViv(left)));
	XPUSHs(sv_2mortal(newSViv(top)));
	XPUSHs(sv_2mortal(newSViv(width)));
	XPUSHs(sv_2mortal(newSViv(height)));

void
accNavigate(p, navDir)
	INPUT:
	ActAcc * p
	long navDir
	PREINIT:
	VARIANT varStart;
	VARIANT varEnd;
	HRESULT hr;
	ActAcc *rv = 0;
	PPCODE:
	croakIfNullIAccessible(p);
	VariantInit_VT_I4(&varStart, p->id);
	hr = IAccessible_accNavigate(p->ia, navDir, varStart, &varEnd);
	croakIf(hr, !SUCCEEDED(hr), "accNavigate");
	if (S_FALSE != hr)
	{
		if (VT_DISPATCH == varEnd.vt)
			rv = ActAcc_from_IDispatch(varEnd.pdispVal);
		else if (VT_I4 == varEnd.vt)
			rv = ActAcc_from_IAccessible(p->ia, varEnd.lVal);
	}
	VariantClear(&varEnd);
	if (rv)
		XPUSHs(sv_setref_pv(sv_newmortal(), packageForAO(rv), rv));
	else
		XPUSHs(&PL_sv_undef);

