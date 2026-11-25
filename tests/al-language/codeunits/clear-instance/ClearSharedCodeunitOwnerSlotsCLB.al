// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586), "CLB Store" (codeunit 75587) and
//   interface "CLB IStore" of ClearSharedCodeunitTempRef.al; self-contained objects 77934 to 77999 and 78425 to 78481
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
//   Store: "CLB Store" (a temporary record, an array[2, 3] of RecordRef, an array[3] of Integer; implements
//   "CLB IStore"). Owners: Plain, Normal, TableNo, Report, SI and TG. State text: rows = temporary rows, ref11 /
//   ref23 = Number of RecordRef elements [1,1] and [2,3], refrows = rows of [1,1], int1 / int3 = Integer elements.
//   Measured on BC 29.0 (Linux): every SI, TG, Normal, TableNo and Report cell reads the same values as
//   the Plain cells of the same slot and state in this file:
//   ClearAll resets the store's instance in place and the holder stays on it. Temporary rows stay, RecordRefs
//   close, the Integers and the owner's Cnt go to 0. The next write through the holder shows through the owner and
//   the reverse. Caller variables read the same instance after return. A fresh by-value caller argument (ByValFill,
//   IfaceByValFill) stays its own, unwritten instance.
// BC versions: 27, 28, 29

interface "CLJ CLB Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLB Store");
    procedure SetStore(var NewS: Codeunit "CLB Store");
    procedure SetStoreByVal(NewS: Codeunit "CLB Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

report 77937 "CLJ CLB Report Owner"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77934 "CLJ CLB Plain Owner"
{
    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77935 "CLJ CLB Normal Owner"
{
    Subtype = Normal;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77936 "CLJ CLB TableNo Owner"
{
    TableNo = "CLB Row";

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77938 "CLJ CLB Typed Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        GI: Interface "CLB IStore";
        GL: List of [Interface "CLB IStore"];
        GD: Dictionary of [Integer, Interface "CLB IStore"];

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLB Store";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure IWrite(V: Integer)
    begin
        GI.Write(V);
    end;

    procedure LWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        F.Write(V);
    end;

    procedure DWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        F.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLB Store";
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
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure PullPlain(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLJ CLB Plain Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandPlain(var O: Codeunit "CLJ CLB Plain Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValPlain(var O: Codeunit "CLJ CLB Plain Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValPlain(var O: Codeunit "CLJ CLB Plain Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearPlain(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterPlain(var O: Codeunit "CLJ CLB Plain Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClearPlain(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIfacePlain(var O: Codeunit "CLJ CLB Plain Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValPlain(var O: Codeunit "CLJ CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfacePlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainRows(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadIfacePlainRows(O, GI);
    end;

    procedure FillListPlainRows(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadListPlainRows(O, GL);
    end;

    procedure FillDictPlainRows(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadDictPlainRows(O, GD);
    end;

    procedure KeepIfacePlainRows(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfacePlainRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillPlainRows(var O: Codeunit "CLJ CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfacePlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLJ CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLJ CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure PullNormal(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarNormal(var O: Codeunit "CLJ CLB Normal Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandNormal(var O: Codeunit "CLJ CLB Normal Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValNormal(var O: Codeunit "CLJ CLB Normal Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValNormal(var O: Codeunit "CLJ CLB Normal Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearNormal(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterNormal(var O: Codeunit "CLJ CLB Normal Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClearNormal(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIfaceNormal(var O: Codeunit "CLJ CLB Normal Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValNormal(var O: Codeunit "CLJ CLB Normal Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNormalRows(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadVarNormalRows(O, GV);
    end;

    procedure KeepVarNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarNormalRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNormalRows(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadIfaceNormalRows(O, GI);
    end;

    procedure FillListNormalRows(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadListNormalRows(O, GL);
    end;

    procedure FillDictNormalRows(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadDictNormalRows(O, GD);
    end;

    procedure KeepIfaceNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceNormalRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNormalRows(var O: Codeunit "CLJ CLB Normal Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNormalRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNormalNever(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadVarNormalNever(O, GV);
    end;

    procedure KeepVarNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarNormalNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNormalNever(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadIfaceNormalNever(O, GI);
    end;

    procedure FillListNormalNever(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadListNormalNever(O, GL);
    end;

    procedure FillDictNormalNever(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        LoadDictNormalNever(O, GD);
    end;

    procedure KeepIfaceNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceNormalNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNormalNever(var O: Codeunit "CLJ CLB Normal Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNormalNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure PullTableNo(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearTableNo(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClearTableNo(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIfaceTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValTableNo(var O: Codeunit "CLJ CLB TableNo Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadVarTableNoRows(O, GV);
    end;

    procedure KeepVarTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarTableNoRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadIfaceTableNoRows(O, GI);
    end;

    procedure FillListTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadListTableNoRows(O, GL);
    end;

    procedure FillDictTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadDictTableNoRows(O, GD);
    end;

    procedure KeepIfaceTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceTableNoRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillTableNoRows(var O: Codeunit "CLJ CLB TableNo Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceTableNoRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadVarTableNoNever(O, GV);
    end;

    procedure KeepVarTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarTableNoNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadIfaceTableNoNever(O, GI);
    end;

    procedure FillListTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadListTableNoNever(O, GL);
    end;

    procedure FillDictTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        LoadDictTableNoNever(O, GD);
    end;

    procedure KeepIfaceTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceTableNoNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillTableNoNever(var O: Codeunit "CLJ CLB TableNo Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceTableNoNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure PullReport(var O: Report "CLJ CLB Report Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarReport(var O: Report "CLJ CLB Report Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandReport(var O: Report "CLJ CLB Report Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValReport(var O: Report "CLJ CLB Report Owner"; var Hd: Codeunit "CLJ CLB Typed Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValReport(var O: Report "CLJ CLB Report Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearReport(var O: Report "CLJ CLB Report Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterReport(var O: Report "CLJ CLB Report Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClearReport(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIfaceReport(var O: Report "CLJ CLB Report Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValReport(var O: Report "CLJ CLB Report Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalReportRows(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillReportRows(var O: Report "CLJ CLB Report Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarReportRows(var O: Report "CLJ CLB Report Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarReportRows(var O: Report "CLJ CLB Report Owner")
    begin
        LoadVarReportRows(O, GV);
    end;

    procedure KeepVarReportRows(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarReportRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceReportRows(var O: Report "CLJ CLB Report Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListReportRows(var O: Report "CLJ CLB Report Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictReportRows(var O: Report "CLJ CLB Report Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceReportRows(var O: Report "CLJ CLB Report Owner")
    begin
        LoadIfaceReportRows(O, GI);
    end;

    procedure FillListReportRows(var O: Report "CLJ CLB Report Owner")
    begin
        LoadListReportRows(O, GL);
    end;

    procedure FillDictReportRows(var O: Report "CLJ CLB Report Owner")
    begin
        LoadDictReportRows(O, GD);
    end;

    procedure KeepIfaceReportRows(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceReportRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillReportRows(var O: Report "CLJ CLB Report Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceReportRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalReportNever(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillReportNever(var O: Report "CLJ CLB Report Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarReportNever(var O: Report "CLJ CLB Report Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarReportNever(var O: Report "CLJ CLB Report Owner")
    begin
        LoadVarReportNever(O, GV);
    end;

    procedure KeepVarReportNever(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarReportNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceReportNever(var O: Report "CLJ CLB Report Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListReportNever(var O: Report "CLJ CLB Report Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictReportNever(var O: Report "CLJ CLB Report Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceReportNever(var O: Report "CLJ CLB Report Owner")
    begin
        LoadIfaceReportNever(O, GI);
    end;

    procedure FillListReportNever(var O: Report "CLJ CLB Report Owner")
    begin
        LoadListReportNever(O, GL);
    end;

    procedure FillDictReportNever(var O: Report "CLJ CLB Report Owner")
    begin
        LoadDictReportNever(O, GD);
    end;

    procedure KeepIfaceReportNever(var O: Report "CLJ CLB Report Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceReportNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillReportNever(var O: Report "CLJ CLB Report Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceReportNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77939 "CLJ CLB Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure PullPlain(var O: Codeunit "CLJ CLB Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77940 "CLJ CLB Plain Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Plain SI Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalPlainRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandPlain(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillPlainRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValPlain(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarPlainRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarPlainRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfacePlainRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfacePlainRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListPlainRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListPlainRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictPlainRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictPlainRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainRows(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainRows(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillPlainRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Plain SI Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalPlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandPlain(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValPlain(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarPlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfacePlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfacePlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListPlainNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictPlainNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Plain Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;
}

codeunit 77941 "CLJ CLB Normal SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure PullNormal(var O: Codeunit "CLJ CLB Normal Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77942 "CLJ CLB Normal Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NormalCLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVarNormal(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullNormal(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Normal SI Holder";
    begin
        K.PullNormal(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalNormalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandNormal(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillNormalRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValOuterNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValNormal(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarNormalRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarNormalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarNormalRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceNormalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceNormalRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListNormalRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListNormalRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictNormalRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictNormalRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalRows(O, I);
        K.ViaIfaceNormal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalRows(O, I);
        K.ViaIfaceByValNormal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillNormalRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaIfaceByValNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarNormal(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullNormal(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Normal SI Holder";
    begin
        K.PullNormal(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalNormalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandNormal(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillNormalNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValNormal(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarNormalNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarNormalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarNormalNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceNormalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceNormalNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListNormalNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListNormalNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictNormalNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictNormalNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalNever(O, I);
        K.ViaIfaceNormal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNormalNever(O, I);
        K.ViaIfaceByValNormal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillNormalNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure NormalCLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB Normal Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByValNormal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;
}

codeunit 77943 "CLJ CLB TableNo SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure PullTableNo(var O: Codeunit "CLJ CLB TableNo Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77944 "CLJ CLB TableNo Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableNoCLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVarTableNo(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullTableNo(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB TableNo SI Holder";
    begin
        K.PullTableNo(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalTableNoRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandTableNo(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillTableNoRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValOuterTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValTableNo(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarTableNoRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarTableNoRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarTableNoRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceTableNoRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceTableNoRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListTableNoRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListTableNoRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictTableNoRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictTableNoRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoRows(O, I);
        K.ViaIfaceTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoRows(O, I);
        K.ViaIfaceByValTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillTableNoRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaIfaceByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarTableNo(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullTableNo(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB TableNo SI Holder";
    begin
        K.PullTableNo(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalTableNoNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandTableNo(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillTableNoNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValTableNo(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarTableNoNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarTableNoNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarTableNoNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceTableNoNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceTableNoNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListTableNoNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListTableNoNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictTableNoNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictTableNoNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoNever(O, I);
        K.ViaIfaceTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceTableNoNever(O, I);
        K.ViaIfaceByValTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillTableNoNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableNoCLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLB TableNo Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;
}

codeunit 77945 "CLJ CLB Report SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure PullReport(var O: Report "CLJ CLB Report Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77946 "CLJ CLB Report Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReportCLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVarReport(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullReport(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Report SI Holder";
    begin
        K.PullReport(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalReportRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandReport(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillReportRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValOuterReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValReport(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarReportRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarReportRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarReportRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceReportRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceReportRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListReportRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListReportRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictReportRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictReportRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportRows(O, I);
        K.ViaIfaceReport(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportRows(O, I);
        K.ViaIfaceByValReport(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillReportRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaIfaceByValReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarReport(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.PullReport(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Report SI Holder";
    begin
        K.PullReport(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepLocalReportNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandReport(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillReportNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Hander: Codeunit "CLJ CLB Typed Holder";
    begin
        Hander.HandByValReport(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarReportNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepVarReportNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillVarReportNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.KeepIfaceReportNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillIfaceReportNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListReportNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillListReportNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictReportNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
    begin
        K.FillDictReportNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportNever(O, I);
        K.ViaIfaceReport(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceReportNever(O, I);
        K.ViaIfaceByValReport(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillReportNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportCLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Report "CLJ CLB Report Owner";
        K: Codeunit "CLJ CLB Typed Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByValReport(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;
}

codeunit 77947 "CLJ CLB SI Fam Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        GI: Interface "CLB IStore";
        GL: List of [Interface "CLB IStore"];
        GD: Dictionary of [Integer, Interface "CLB IStore"];

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLB Store";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure IWrite(V: Integer)
    begin
        GI.Write(V);
    end;

    procedure LWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        F.Write(V);
    end;

    procedure DWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        F.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLB Store";
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
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ CLB Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(O: Interface "CLJ CLB Owner"; var Hd: Codeunit "CLJ CLB SI Fam Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ CLB Owner"; var Hd: Codeunit "CLJ CLB SI Fam Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(O: Interface "CLJ CLB Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIface(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLJ CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLJ CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceRows(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLJ CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(O: Interface "CLJ CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(O: Interface "CLJ CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLJ CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLJ CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNever(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(O: Interface "CLJ CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceNever(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77948 "CLJ CLB SI Fam SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure Pull(O: Interface "CLJ CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 77949 "CLJ SI CLB 01" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77950 "CLJ SI CLB 02" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77951 "CLJ SI CLB 03" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77952 "CLJ SI CLB 04" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77953 "CLJ SI CLB 05" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77954 "CLJ SI CLB 06" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77955 "CLJ SI CLB 07" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77956 "CLJ SI CLB 08" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77957 "CLJ SI CLB 09" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77958 "CLJ SI CLB 10" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77959 "CLJ SI CLB 11" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77960 "CLJ SI CLB 12" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77961 "CLJ SI CLB 13" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77962 "CLJ SI CLB 14" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77963 "CLJ SI CLB 15" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77964 "CLJ SI CLB 16" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77965 "CLJ SI CLB 17" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77966 "CLJ SI CLB 18" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77967 "CLJ SI CLB 19" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77968 "CLJ SI CLB 20" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77969 "CLJ SI CLB 21" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77970 "CLJ SI CLB 22" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77971 "CLJ SI CLB 23" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77972 "CLJ SI CLB 24" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77973 "CLJ SI CLB 25" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77974 "CLJ SI CLB 26" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77975 "CLJ SI CLB 27" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77976 "CLJ SI CLB 28" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77977 "CLJ SI CLB 29" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77978 "CLJ SI CLB 30" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77979 "CLJ SI CLB 31" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77980 "CLJ SI CLB 32" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77981 "CLJ SI CLB 33" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77982 "CLJ SI CLB 34" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77983 "CLJ SI CLB 35" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77984 "CLJ SI CLB 36" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77985 "CLJ SI CLB 37" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77986 "CLJ SI CLB 38" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77987 "CLJ SI CLB 39" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77988 "CLJ SI CLB 40" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77989 "CLJ SI CLB 41" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77990 "CLJ SI CLB 42" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77991 "CLJ SI CLB 43" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77992 "CLJ SI CLB 44" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77993 "CLJ SI CLB 45" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77994 "CLJ SI CLB 46" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77995 "CLJ SI CLB 47" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77996 "CLJ SI CLB 48" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77997 "CLJ SI CLB 49" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77998 "CLJ SI CLB 50" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 77999 "CLJ SI CLB 51" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78425 "CLJ SI CLB 52" implements "CLJ CLB Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78426 "CLJ CLB SI Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 01";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 02";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.Pull(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 03";
        K: Codeunit "CLJ CLB SI Fam SI Holder";
    begin
        K.Pull(O);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 04";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 05";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 06";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Hander: Codeunit "CLJ CLB SI Fam Holder";
    begin
        Hander.Hand(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 07";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 08";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 09";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 10";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 11";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Hander: Codeunit "CLJ CLB SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        K.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 12";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 13";
        K: Codeunit "CLJ CLB SI Fam Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 14";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 15";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillVarRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 16";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 17";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 18";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillIfaceRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 19";
        K: Codeunit "CLJ CLB SI Fam Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 20";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillListRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 21";
        K: Codeunit "CLJ CLB SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 22";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillDictRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 23";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 24";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 25";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 26";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 27";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 28";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 29";
        K: Codeunit "CLJ CLB SI Fam SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 30";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 31";
        A: array[2] of Codeunit "CLB Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 32";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Hander: Codeunit "CLJ CLB SI Fam Holder";
    begin
        Hander.Hand(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 33";
        Y: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 34";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 35";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 36";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 37";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Hander: Codeunit "CLJ CLB SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 38";
        Y: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 39";
        K: Codeunit "CLJ CLB SI Fam Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 40";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 41";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillVarNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 42";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 43";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 44";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillIfaceNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 45";
        K: Codeunit "CLJ CLB SI Fam Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 46";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillListNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 47";
        K: Codeunit "CLJ CLB SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 48";
        K: Codeunit "CLJ CLB SI Fam Holder";
    begin
        K.FillDictNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 49";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 50";
        K: Codeunit "CLJ CLB SI Fam Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 51";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLB 52";
        K: Codeunit "CLJ CLB SI Fam Holder";
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;
}

codeunit 78427 "CLJ CLB TG Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        GI: Interface "CLB IStore";
        GL: List of [Interface "CLB IStore"];
        GD: Dictionary of [Integer, Interface "CLB IStore"];

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLB Store";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure IWrite(V: Integer)
    begin
        GI.Write(V);
    end;

    procedure LWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        F.Write(V);
    end;

    procedure DWrite(V: Integer)
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        F.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLB Store";
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
        F: Interface "CLB IStore";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLB IStore";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLB Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ CLB Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(O: Interface "CLJ CLB Owner"; var Hd: Codeunit "CLJ CLB TG Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ CLB Owner"; var Hd: Codeunit "CLJ CLB TG Holder")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(O: Interface "CLJ CLB Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaIface(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLJ CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLJ CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceRows(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLJ CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(O: Interface "CLJ CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(O: Interface "CLJ CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLJ CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLJ CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure KeepLocalNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillNever(O: Interface "CLJ CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(O: Interface "CLJ CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadIfaceNever(O: Interface "CLJ CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ CLB Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLB IStore";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 78428 "CLJ TG CLB 01" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78429 "CLJ TG CLB 02" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.Pull(this);
        K.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78430 "CLJ CLB TG SI Holder 03"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure Pull(O: Interface "CLJ CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 78431 "CLJ TG CLB 03" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG SI Holder 03";
    begin
        K.Pull(this);
        K.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78432 "CLJ TG CLB 04" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepLocalRows(this, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78433 "CLJ TG CLB 05" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLB Store";
    begin
        this.ShareAlias(A[2]);
        A[2].Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78434 "CLJ TG CLB 06" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Hander: Codeunit "CLJ CLB TG Holder";
    begin
        Hander.Hand(this, K);
        K.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78435 "CLJ TG CLB 07" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        this.SetStore(Y);
        Y.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78436 "CLJ TG CLB 08" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillRows(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78437 "CLJ TG CLB 09" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78438 "CLJ TG CLB 10" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78439 "CLJ TG CLB 11" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Hander: Codeunit "CLJ CLB TG Holder";
    begin
        Hander.HandByVal(this, K);
        K.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78440 "CLJ TG CLB 12" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        this.SetStoreByVal(Y);
        Y.Write(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78441 "CLJ TG CLB 13" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78442 "CLJ TG CLB 14" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepVarRows(this, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78443 "CLJ TG CLB 15" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillVarRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78444 "CLJ TG CLB 16" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78445 "CLJ TG CLB 17" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepIfaceRows(this, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78446 "CLJ TG CLB 18" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillIfaceRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78447 "CLJ TG CLB 19" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListRows(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78448 "CLJ TG CLB 20" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillListRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78449 "CLJ TG CLB 21" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictRows(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78450 "CLJ TG CLB 22" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillDictRows(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78451 "CLJ TG CLB 23" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78452 "CLJ TG CLB 24" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceRows(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78453 "CLJ TG CLB 25" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillRows(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78454 "CLJ TG CLB 26" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Y: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78455 "CLJ TG CLB 27" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78456 "CLJ TG CLB 28" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78457 "CLJ CLB TG SI Holder 29"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";

    procedure Pull(O: Interface "CLJ CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 78458 "CLJ TG CLB 29" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG SI Holder 29";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        K.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78459 "CLJ TG CLB 30" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepLocalNever(this, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78460 "CLJ TG CLB 31" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLB Store";
    begin
        this.ShareAlias(A[2]);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78461 "CLJ TG CLB 32" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Hander: Codeunit "CLJ CLB TG Holder";
    begin
        Hander.Hand(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78462 "CLJ TG CLB 33" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        this.SetStore(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78463 "CLJ TG CLB 34" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78464 "CLJ TG CLB 35" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78465 "CLJ TG CLB 36" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78466 "CLJ TG CLB 37" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Hander: Codeunit "CLJ CLB TG Holder";
    begin
        Hander.HandByVal(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78467 "CLJ TG CLB 38" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        this.SetStoreByVal(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78468 "CLJ TG CLB 39" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        V: Variant;
        C: Codeunit "CLB Store";
    begin
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78469 "CLJ TG CLB 40" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepVarNever(this, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78470 "CLJ TG CLB 41" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillVarNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78471 "CLJ TG CLB 42" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78472 "CLJ TG CLB 43" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.KeepIfaceNever(this, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78473 "CLJ TG CLB 44" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillIfaceNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78474 "CLJ TG CLB 45" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        L: List of [Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadListNever(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78475 "CLJ TG CLB 46" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillListNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78476 "CLJ TG CLB 47" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        D: Dictionary of [Integer, Interface "CLB IStore"];
        F: Interface "CLB IStore";
    begin
        K.LoadDictNever(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78477 "CLJ TG CLB 48" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
    begin
        K.FillDictNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78478 "CLJ TG CLB 49" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78479 "CLJ TG CLB 50" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        I: Interface "CLB IStore";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78480 "CLJ TG CLB 51" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Z: Codeunit "CLB Store";
    begin
        K.ViaIfaceByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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

codeunit 78481 "CLJ TG CLB 52" implements "CLJ CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLB TG Holder";
        Y: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLB Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLB Store")
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
