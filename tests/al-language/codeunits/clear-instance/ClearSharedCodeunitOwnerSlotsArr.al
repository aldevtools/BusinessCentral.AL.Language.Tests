// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   "CLS Arr Store" (codeunit 75596) of ClearSharedCodeunitSIOwner.al; "CLI Arr FStore" (codeunit 77331) and
//   interface "CLI Arr Face" of ClearSharedCodeunitHolderSlots.al; self-contained objects 77816 to 77933
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in an owner of a store codeunit while exactly one more variable (the holder slot) shares the
//   store's instance, for owner kinds that ClearSharedCodeunitHolderKinds.al and ClearSharedCodeunitHolderSlots.al
//   do not cover. The slots and their routines are the ones of those two files (same names, same steps):
//   VarParam, OtherGlobal, SIGlobal, CallerLocal, ArrayElement, SetterOut, SetterIn, ByValFill, ByValPassed,
//   ByValDeep, ByValSetterOut, ByValSetterIn, VariantLocal, VariantCallerLocal, VariantGlobal, IfaceLocal,
//   IfaceCallerLocal, IfaceGlobal, ListLocal, ListGlobal, DictLocal, DictGlobal, IfaceVarParam, IfaceByValPassed,
//   IfaceByValFill, IfaceByValFromCodeunit. Test names are <Owner><Store>_<Slot>_<State>.
//   Owners (each has the globals X: the store and Cnt: Integer, and the procedures WriteX, StateX, ShareAlias (var
//   getter), SetStore (var setter), SetStoreByVal, ClearAllGlobals (ClearAll), SetCnt, GetCnt):
//   - Plain, Normal (Subtype = Normal), TableNo (TableNo = "CLB Row"), Report (ProcessingOnly, used as a variable,
//     never run): one owner object per kind; each test uses a fresh local of it.
//   - SI: a SingleInstance owner of its own per test ("CLJ SI <store> nn"), so no state is carried between tests.
//     It implements "CLJ <store> Owner"; the holder routines take the owner as that Interface (by value). The
//     ArrayElement, SetterIn and ByValSetterIn cells call the owner codeunit directly.
//   - TG: the test codeunit itself is the owner ("CLJ TG <store> nn", one test each): X and Cnt are its globals and
//     ClearAllGlobals runs ClearAll() in the test codeunit. It implements "CLJ <store> Owner" and passes this to
//     the holder routines.
//   States: Rows / Written (the holder wrote the store before ClearAll) and Never (only the owner's Cnt was set).
//   Each test: share, write (or not), Cnt := 4, ClearAll in the owner, read owner, owner Cnt and holder, write
//   through the holder and read the owner, write through the owner and read the holder; the by-value and Interface
//   parameter slots then read through the caller's variable after return.
//   Stores: "CLS Arr Store" (arrays of temporary records, RecordRefs and Integers) for the slots without an
//   Interface, and its copy "CLI Arr FStore" (same globals, implements "CLI Arr Face") for ArrayElement and the
//   Interface, List and Dictionary slots. Owners: SI and TG. State text: rows1 / rows2 = rows counted through
//   elements 1 and 2 of the array of temporary records, ref1 = Number of RecordRef element 1, refrows = its rows,
//   int1 = Integer element 1.
//   Measured on BC 29.0 (Linux): every SI, TG, Normal, TableNo and Report cell reads the same values as
//   the plain-owner cells of the same slot and state in ClearSharedCodeunitHolderKinds.al and ClearSharedCodeunitHolderSlots.al ("Arr_<slot>_<state>", owner "CLS Arr Holder"):
//   ClearAll resets the store's instance in place and the holder stays on it. Temporary rows stay, RecordRefs
//   close, the Integers and the owner's Cnt go to 0. The next write through the holder shows through the owner and
//   the reverse. Caller variables read the same instance after return. A fresh by-value caller argument (ByValFill,
//   IfaceByValFill) stays its own, unwritten instance.
// BC versions: 27, 28, 29

interface "CLJ Arr Owner"
{
    procedure WriteX(E: Integer; V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLS Arr Store");
    procedure SetStore(var NewS: Codeunit "CLS Arr Store");
    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

interface "CLJ ArrF Owner"
{
    procedure WriteX(E: Integer; V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore");
    procedure SetStore(var NewS: Codeunit "CLI Arr FStore");
    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

codeunit 77816 "CLJ Arr SI Fam Holder"
{
    var
        G: Codeunit "CLS Arr Store";
        GV: Variant;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure VWrite(E: Integer; V: Integer)
    var
        C: Codeunit "CLS Arr Store";
    begin
        C := GV;
        C.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLS Arr Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ Arr Owner"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(O: Interface "CLJ Arr Owner"; var Hd: Codeunit "CLJ Arr SI Fam Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ Arr Owner"; var Hd: Codeunit "CLJ Arr SI Fam Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(O: Interface "CLJ Arr Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalRows(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLJ Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLJ Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure KeepLocalNever(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNever(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(O: Interface "CLJ Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 77817 "CLJ Arr SI Fam SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";

    procedure Pull(O: Interface "CLJ Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77818 "CLJ SI Arr 01" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77819 "CLJ SI Arr 02" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77820 "CLJ SI Arr 03" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77821 "CLJ SI Arr 04" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77822 "CLJ SI Arr 05" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77823 "CLJ SI Arr 06" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77824 "CLJ SI Arr 07" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77825 "CLJ SI Arr 08" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77826 "CLJ SI Arr 09" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77827 "CLJ SI Arr 10" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77828 "CLJ SI Arr 11" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77829 "CLJ SI Arr 12" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77830 "CLJ SI Arr 13" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77831 "CLJ SI Arr 14" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77832 "CLJ SI Arr 15" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77833 "CLJ SI Arr 16" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77834 "CLJ SI Arr 17" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77835 "CLJ SI Arr 18" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77836 "CLJ SI Arr 19" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77837 "CLJ SI Arr 20" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77838 "CLJ SI Arr 21" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77839 "CLJ SI Arr 22" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77840 "CLJ SI Arr 23" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77841 "CLJ SI Arr 24" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77842 "CLJ SI Arr 25" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77843 "CLJ SI Arr 26" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77844 "CLJ SI Arr 27" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77845 "CLJ SI Arr 28" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77846 "CLJ SI Arr 29" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77847 "CLJ SI Arr 30" implements "CLJ Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77848 "CLJ Arr SI Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArr_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 01";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 02";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.Pull(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 03";
        K: Codeunit "CLJ Arr SI Fam SI Holder";
    begin
        K.Pull(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 04";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 05";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(1, 3);
        A[2].Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 06";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Hander: Codeunit "CLJ Arr SI Fam Holder";
    begin
        Hander.Hand(O, K);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 07";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStore(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 08";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Z: Codeunit "CLS Arr Store";
    begin
        K.ViaByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 09";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 10";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 11";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Hander: Codeunit "CLJ Arr SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 12";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 13";
        K: Codeunit "CLJ Arr SI Fam Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 14";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 15";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.FillVarRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 16";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 17";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 18";
        K: Codeunit "CLJ Arr SI Fam SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 19";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 20";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 21";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Hander: Codeunit "CLJ Arr SI Fam Holder";
    begin
        Hander.Hand(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 22";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 23";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Z: Codeunit "CLS Arr Store";
    begin
        K.ViaByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 24";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 25";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 26";
        K: Codeunit "CLJ Arr SI Fam Holder";
        Hander: Codeunit "CLJ Arr SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 27";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 28";
        K: Codeunit "CLJ Arr SI Fam Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 29";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI Arr 30";
        K: Codeunit "CLJ Arr SI Fam Holder";
    begin
        K.FillVarNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;
}

codeunit 77849 "CLJ Arr TG Holder"
{
    var
        G: Codeunit "CLS Arr Store";
        GV: Variant;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure VWrite(E: Integer; V: Integer)
    var
        C: Codeunit "CLS Arr Store";
    begin
        C := GV;
        C.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLS Arr Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ Arr Owner"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(O: Interface "CLJ Arr Owner"; var Hd: Codeunit "CLJ Arr TG Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ Arr Owner"; var Hd: Codeunit "CLJ Arr TG Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(O: Interface "CLJ Arr Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalRows(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLJ Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLJ Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure KeepLocalNever(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNever(O: Interface "CLJ Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(O: Interface "CLJ Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ Arr Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 77850 "CLJ TG Arr 01" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77851 "CLJ TG Arr 02" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.Pull(this);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77852 "CLJ Arr TG SI Holder 03"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";

    procedure Pull(O: Interface "CLJ Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77853 "CLJ TG Arr 03" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG SI Holder 03";
    begin
        K.Pull(this);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77854 "CLJ TG Arr 04" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.KeepLocalRows(this, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77855 "CLJ TG Arr 05" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(A[2]);
        A[2].Write(1, 3);
        A[2].Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77856 "CLJ TG Arr 06" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Hander: Codeunit "CLJ Arr TG Holder";
    begin
        Hander.Hand(this, K);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77857 "CLJ TG Arr 07" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        this.SetStore(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77858 "CLJ TG Arr 08" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Z: Codeunit "CLS Arr Store";
    begin
        K.ViaByValFillRows(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77859 "CLJ TG Arr 09" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77860 "CLJ TG Arr 10" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77861 "CLJ TG Arr 11" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Hander: Codeunit "CLJ Arr TG Holder";
    begin
        Hander.HandByVal(this, K);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77862 "CLJ TG Arr 12" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        this.SetStoreByVal(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77863 "CLJ TG Arr 13" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77864 "CLJ TG Arr 14" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.KeepVarRows(this, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77865 "CLJ TG Arr 15" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.FillVarRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77866 "CLJ TG Arr 16" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77867 "CLJ TG Arr 17" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77868 "CLJ Arr TG SI Holder 18"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";

    procedure Pull(O: Interface "CLJ Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77869 "CLJ TG Arr 18" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG SI Holder 18";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77870 "CLJ TG Arr 19" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.KeepLocalNever(this, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77871 "CLJ TG Arr 20" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(A[2]);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77872 "CLJ TG Arr 21" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Hander: Codeunit "CLJ Arr TG Holder";
    begin
        Hander.Hand(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77873 "CLJ TG Arr 22" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        this.SetStore(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77874 "CLJ TG Arr 23" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Z: Codeunit "CLS Arr Store";
    begin
        K.ViaByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77875 "CLJ TG Arr 24" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77876 "CLJ TG Arr 25" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77877 "CLJ TG Arr 26" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        Hander: Codeunit "CLJ Arr TG Holder";
    begin
        Hander.HandByVal(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77878 "CLJ TG Arr 27" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
    begin
        this.SetStoreByVal(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77879 "CLJ TG Arr 28" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77880 "CLJ TG Arr 29" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.KeepVarNever(this, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77881 "CLJ TG Arr 30" implements "CLJ Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ Arr TG Holder";
    begin
        K.FillVarNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLS Arr Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77882 "CLJ ArrF SI Fam Holder"
{
    var
        G: Codeunit "CLI Arr FStore";
        GV: Variant;
        GI: Interface "CLI Arr Face";
        GL: List of [Interface "CLI Arr Face"];
        GD: Dictionary of [Integer, Interface "CLI Arr Face"];

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure VWrite(E: Integer; V: Integer)
    var
        C: Codeunit "CLI Arr FStore";
    begin
        C := GV;
        C.Write(E, V);
    end;

    procedure IWrite(E: Integer; V: Integer)
    begin
        GI.Write(E, V);
    end;

    procedure LWrite(E: Integer; V: Integer)
    var
        F: Interface "CLI Arr Face";
    begin
        F := GL.Get(1);
        F.Write(E, V);
    end;

    procedure DWrite(E: Integer; V: Integer)
    var
        F: Interface "CLI Arr Face";
    begin
        F := GD.Get(1);
        F.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLI Arr FStore";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLI Arr Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLI Arr Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLI Arr FStore")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI Arr FStore")
    begin
        G := NewG;
    end;

    procedure ViaByVal(O: Interface "CLJ ArrF Owner"; Y: Codeunit "CLI Arr FStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIface(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceRows(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLJ ArrF Owner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(O: Interface "CLJ ArrF Owner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLJ ArrF Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceNever(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ ArrF Owner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ ArrF Owner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ ArrF Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77883 "CLJ ArrF SI Fam SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLI Arr FStore";

    procedure Pull(O: Interface "CLJ ArrF Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77884 "CLJ SI ArrF 01" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77885 "CLJ SI ArrF 02" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77886 "CLJ SI ArrF 03" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77887 "CLJ SI ArrF 04" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77888 "CLJ SI ArrF 05" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77889 "CLJ SI ArrF 06" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77890 "CLJ SI ArrF 07" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77891 "CLJ SI ArrF 08" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77892 "CLJ SI ArrF 09" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77893 "CLJ SI ArrF 10" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77894 "CLJ SI ArrF 11" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77895 "CLJ SI ArrF 12" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77896 "CLJ SI ArrF 13" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77897 "CLJ SI ArrF 14" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77898 "CLJ SI ArrF 15" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77899 "CLJ SI ArrF 16" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77900 "CLJ SI ArrF 17" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77901 "CLJ SI ArrF 18" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77902 "CLJ SI ArrF 19" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77903 "CLJ SI ArrF 20" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77904 "CLJ SI ArrF 21" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77905 "CLJ SI ArrF 22" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77906 "CLJ SI ArrF 23" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77907 "CLJ SI ArrF 24" implements "CLJ ArrF Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77908 "CLJ ArrF SI Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArrF_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 01";
        A: array[2] of Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(1, 3);
        A[2].Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 02";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 03";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 04";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillIfaceRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 05";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 06";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillListRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 07";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 08";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillDictRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 09";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 10";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 11";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 12";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 13";
        A: array[2] of Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 14";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 15";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 16";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillIfaceNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 17";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 18";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillListNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 19";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 20";
        K: Codeunit "CLJ ArrF SI Fam Holder";
    begin
        K.FillDictNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 21";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 22";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 23";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIArrF_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI ArrF 24";
        K: Codeunit "CLJ ArrF SI Fam Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;
}

codeunit 77909 "CLJ ArrF TG Holder"
{
    var
        G: Codeunit "CLI Arr FStore";
        GV: Variant;
        GI: Interface "CLI Arr Face";
        GL: List of [Interface "CLI Arr Face"];
        GD: Dictionary of [Integer, Interface "CLI Arr Face"];

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure VWrite(E: Integer; V: Integer)
    var
        C: Codeunit "CLI Arr FStore";
    begin
        C := GV;
        C.Write(E, V);
    end;

    procedure IWrite(E: Integer; V: Integer)
    begin
        GI.Write(E, V);
    end;

    procedure LWrite(E: Integer; V: Integer)
    var
        F: Interface "CLI Arr Face";
    begin
        F := GL.Get(1);
        F.Write(E, V);
    end;

    procedure DWrite(E: Integer; V: Integer)
    var
        F: Interface "CLI Arr Face";
    begin
        F := GD.Get(1);
        F.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLI Arr FStore";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLI Arr Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLI Arr Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLI Arr FStore")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI Arr FStore")
    begin
        G := NewG;
    end;

    procedure ViaByVal(O: Interface "CLJ ArrF Owner"; Y: Codeunit "CLI Arr FStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIface(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceRows(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLJ ArrF Owner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(O: Interface "CLJ ArrF Owner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLJ ArrF Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLJ ArrF Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceNever(O: Interface "CLJ ArrF Owner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ ArrF Owner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ ArrF Owner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ ArrF Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ ArrF Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ ArrF Owner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77910 "CLJ TG ArrF 01" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLI Arr FStore";
    begin
        this.ShareAlias(A[2]);
        A[2].Write(1, 3);
        A[2].Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77911 "CLJ TG ArrF 02" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77912 "CLJ TG ArrF 03" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.KeepIfaceRows(this, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77913 "CLJ TG ArrF 04" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillIfaceRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77914 "CLJ TG ArrF 05" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListRows(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77915 "CLJ TG ArrF 06" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillListRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77916 "CLJ TG ArrF 07" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictRows(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77917 "CLJ TG ArrF 08" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillDictRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77918 "CLJ TG ArrF 09" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77919 "CLJ TG ArrF 10" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77920 "CLJ TG ArrF 11" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillRows(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77921 "CLJ TG ArrF 12" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77922 "CLJ TG ArrF 13" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLI Arr FStore";
    begin
        this.ShareAlias(A[2]);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77923 "CLJ TG ArrF 14" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77924 "CLJ TG ArrF 15" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.KeepIfaceNever(this, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77925 "CLJ TG ArrF 16" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillIfaceNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77926 "CLJ TG ArrF 17" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListNever(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77927 "CLJ TG ArrF 18" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillListNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77928 "CLJ TG ArrF 19" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictNever(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77929 "CLJ TG ArrF 20" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
    begin
        K.FillDictNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77930 "CLJ TG ArrF 21" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77931 "CLJ TG ArrF 22" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77932 "CLJ TG ArrF 23" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77933 "CLJ TG ArrF 24" implements "CLJ ArrF Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLI Arr FStore";
        Cnt: Integer;

    [Test]
    procedure TGArrF_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ ArrF TG Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    procedure WriteX(E: Integer; V: Integer)
    begin
        X.Write(E, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Arr FStore")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLI Arr FStore")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}
