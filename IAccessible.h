// NOTE:  THIS IS COPIED/EXCERPTED FROM "OLEACC.H", PART OF THE JULY 2000 "PLATFORM SDK".

#pragma warning( disable: 4049 )  /* more than 64k source lines */

/* this ALWAYS GENERATED file contains the definitions for the interfaces */


 /* File created by MIDL compiler version 5.03.0279 */
/* at Fri Sep 24 19:29:20 1999
 */
/* Compiler settings for oleacc.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32 (32b run), ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
//@@MIDL_FILE_HEADING(  )


#define IAccessible_QueryInterface(This,riid,ppvObject)	\
    (This)->lpVtbl -> QueryInterface(This,riid,ppvObject)

#define IAccessible_AddRef(This)	\
    (This)->lpVtbl -> AddRef(This)

#define IAccessible_Release(This)	\
    (This)->lpVtbl -> Release(This)


#define IAccessible_GetTypeInfoCount(This,pctinfo)	\
    (This)->lpVtbl -> GetTypeInfoCount(This,pctinfo)

#define IAccessible_GetTypeInfo(This,iTInfo,lcid,ppTInfo)	\
    (This)->lpVtbl -> GetTypeInfo(This,iTInfo,lcid,ppTInfo)

#define IAccessible_GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)	\
    (This)->lpVtbl -> GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)

#define IAccessible_Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)	\
    (This)->lpVtbl -> Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)


#define IAccessible_get_accParent(This,ppdispParent)	\
    (This)->lpVtbl -> get_accParent(This,ppdispParent)

#define IAccessible_get_accChildCount(This,pcountChildren)	\
    (This)->lpVtbl -> get_accChildCount(This,pcountChildren)

#define IAccessible_get_accChild(This,varChild,ppdispChild)	\
    (This)->lpVtbl -> get_accChild(This,varChild,ppdispChild)

#define IAccessible_get_accName(This,varChild,pszName)	\
    (This)->lpVtbl -> get_accName(This,varChild,pszName)

#define IAccessible_get_accValue(This,varChild,pszValue)	\
    (This)->lpVtbl -> get_accValue(This,varChild,pszValue)

#define IAccessible_get_accDescription(This,varChild,pszDescription)	\
    (This)->lpVtbl -> get_accDescription(This,varChild,pszDescription)

#define IAccessible_get_accRole(This,varChild,pvarRole)	\
    (This)->lpVtbl -> get_accRole(This,varChild,pvarRole)

#define IAccessible_get_accState(This,varChild,pvarState)	\
    (This)->lpVtbl -> get_accState(This,varChild,pvarState)

#define IAccessible_get_accHelp(This,varChild,pszHelp)	\
    (This)->lpVtbl -> get_accHelp(This,varChild,pszHelp)

#define IAccessible_get_accHelpTopic(This,pszHelpFile,varChild,pidTopic)	\
    (This)->lpVtbl -> get_accHelpTopic(This,pszHelpFile,varChild,pidTopic)

#define IAccessible_get_accKeyboardShortcut(This,varChild,pszKeyboardShortcut)	\
    (This)->lpVtbl -> get_accKeyboardShortcut(This,varChild,pszKeyboardShortcut)

#define IAccessible_get_accFocus(This,pvarChild)	\
    (This)->lpVtbl -> get_accFocus(This,pvarChild)

#define IAccessible_get_accSelection(This,pvarChildren)	\
    (This)->lpVtbl -> get_accSelection(This,pvarChildren)

#define IAccessible_get_accDefaultAction(This,varChild,pszDefaultAction)	\
    (This)->lpVtbl -> get_accDefaultAction(This,varChild,pszDefaultAction)

#define IAccessible_accSelect(This,flagsSelect,varChild)	\
    (This)->lpVtbl -> accSelect(This,flagsSelect,varChild)

#define IAccessible_accLocation(This,pxLeft,pyTop,pcxWidth,pcyHeight,varChild)	\
    (This)->lpVtbl -> accLocation(This,pxLeft,pyTop,pcxWidth,pcyHeight,varChild)

#define IAccessible_accNavigate(This,navDir,varStart,pvarEndUpAt)	\
    (This)->lpVtbl -> accNavigate(This,navDir,varStart,pvarEndUpAt)

#define IAccessible_accHitTest(This,xLeft,yTop,pvarChild)	\
    (This)->lpVtbl -> accHitTest(This,xLeft,yTop,pvarChild)

#define IAccessible_accDoDefaultAction(This,varChild)	\
    (This)->lpVtbl -> accDoDefaultAction(This,varChild)

#define IAccessible_put_accName(This,varChild,szName)	\
    (This)->lpVtbl -> put_accName(This,varChild,szName)

#define IAccessible_put_accValue(This,varChild,szValue)	\
    (This)->lpVtbl -> put_accValue(This,varChild,szValue)

