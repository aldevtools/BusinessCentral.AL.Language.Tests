// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLX Store" (codeunit 75580) and interface "CLX IStore" of
//   ClearSharedCodeunit.al; self-contained objects 78482 to 78595
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
//   Store: "CLX Store" (one Integer; implements "CLX IStore"); states Written (the holder set 3) and Never.
//   Owners: Plain, SI and TG. Owner StateX = Format of the Integer.
//   Measured on BC 29.0 (Linux): every SI, TG, Normal, TableNo and Report cell reads the same values as
//   the Plain cells of the same slot and state in this file:
//   ClearAll resets the store's instance in place and the holder stays on it. Temporary rows stay, RecordRefs
//   close, the Integers and the owner's Cnt go to 0. The next write through the holder shows through the owner and
//   the reverse. Caller variables read the same instance after return. A fresh by-value caller argument (ByValFill,
//   IfaceByValFill) stays its own, unwritten instance.
// BC versions: 27, 28, 29

interface "CLJ CLX Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLX Store");
    procedure SetStore(var NewS: Codeunit "CLX Store");
    procedure SetStoreByVal(NewS: Codeunit "CLX Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

codeunit 78482 "CLJ CLX Plain Owner"
{
    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78483 "CLJ CLX Typed Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        GI: Interface "CLX IStore";
        GL: List of [Interface "CLX IStore"];
        GD: Dictionary of [Integer, Interface "CLX IStore"];

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure VSet(V: Integer)
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        C.Set(V);
    end;

    procedure ISet(V: Integer)
    begin
        GI.Set(V);
    end;

    procedure LSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        F.Set(V);
    end;

    procedure DSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        F.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;

    procedure VGet(): Integer
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        exit(C.Get());
    end;

    procedure IGet(): Integer
    begin
        exit(GI.Get());
    end;

    procedure LGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        exit(F.Get());
    end;

    procedure DGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        exit(F.Get());
    end;

    procedure SetStore(var NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure PullPlain(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLJ CLX Plain Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure HandPlain(var O: Codeunit "CLJ CLX Plain Owner"; var Hd: Codeunit "CLJ CLX Typed Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValPlain(var O: Codeunit "CLJ CLX Plain Owner"; var Hd: Codeunit "CLJ CLX Typed Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValPlain(var O: Codeunit "CLJ CLX Plain Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure DoClearPlain(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterPlain(var O: Codeunit "CLJ CLX Plain Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClearPlain(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaIfacePlain(var O: Codeunit "CLJ CLX Plain Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValPlain(var O: Codeunit "CLJ CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainWritten(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadVarPlainWritten(O, GV);
    end;

    procedure KeepVarPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarPlainWritten(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfacePlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainWritten(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadIfacePlainWritten(O, GI);
    end;

    procedure FillListPlainWritten(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadListPlainWritten(O, GL);
    end;

    procedure FillDictPlainWritten(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadDictPlainWritten(O, GD);
    end;

    procedure KeepIfacePlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfacePlainWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillPlainWritten(var O: Codeunit "CLJ CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfacePlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLJ CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLJ CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;
}

codeunit 78484 "CLJ CLX Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";

    procedure PullPlain(var O: Codeunit "CLJ CLX Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 78485 "CLJ CLX Plain Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLX_VarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_OtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.PullPlain(O);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Plain SI Holder";
    begin
        K.PullPlain(O);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_CallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepLocalPlainWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ArrayElement_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        A: array[2] of Codeunit "CLX Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Hander: Codeunit "CLJ CLX Typed Holder";
    begin
        Hander.HandPlain(O, K);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
    begin
        O.SetStore(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillPlainWritten(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValDeep_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValSetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Hander: Codeunit "CLJ CLX Typed Holder";
    begin
        Hander.HandByValPlain(O, K);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValSetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
    begin
        O.SetStoreByVal(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarPlainWritten(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepVarPlainWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillVarPlainWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepIfacePlainWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillIfacePlainWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ListLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListPlainWritten(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillListPlainWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_DictLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictPlainWritten(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_DictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillDictPlainWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainWritten(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainWritten(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillPlainWritten(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValFromCodeunit_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Plain SI Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepLocalPlainNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        A: array[2] of Codeunit "CLX Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Hander: Codeunit "CLJ CLX Typed Holder";
    begin
        Hander.HandPlain(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Hander: Codeunit "CLJ CLX Typed Holder";
    begin
        Hander.HandByValPlain(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        Y: Codeunit "CLX Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepVarPlainNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillVarPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.KeepIfacePlainNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillIfacePlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListPlainNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillListPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictPlainNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
    begin
        K.FillDictPlainNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ CLX Plain Owner";
        K: Codeunit "CLJ CLX Typed Holder";
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;
}

codeunit 78486 "CLJ CLX SI Fam Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        GI: Interface "CLX IStore";
        GL: List of [Interface "CLX IStore"];
        GD: Dictionary of [Integer, Interface "CLX IStore"];

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure VSet(V: Integer)
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        C.Set(V);
    end;

    procedure ISet(V: Integer)
    begin
        GI.Set(V);
    end;

    procedure LSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        F.Set(V);
    end;

    procedure DSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        F.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;

    procedure VGet(): Integer
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        exit(C.Get());
    end;

    procedure IGet(): Integer
    begin
        exit(GI.Get());
    end;

    procedure LGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        exit(F.Get());
    end;

    procedure DGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        exit(F.Get());
    end;

    procedure SetStore(var NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ CLX Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure Hand(O: Interface "CLJ CLX Owner"; var Hd: Codeunit "CLJ CLX SI Fam Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ CLX Owner"; var Hd: Codeunit "CLJ CLX SI Fam Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure DoClear(O: Interface "CLJ CLX Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaIface(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillWritten(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarWritten(O: Interface "CLJ CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarWritten(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfaceWritten(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLJ CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictWritten(O: Interface "CLJ CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillWritten(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillNever(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarNever(O: Interface "CLJ CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfaceNever(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;
}

codeunit 78487 "CLJ CLX SI Fam SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";

    procedure Pull(O: Interface "CLJ CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 78488 "CLJ SI CLX 01" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78489 "CLJ SI CLX 02" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78490 "CLJ SI CLX 03" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78491 "CLJ SI CLX 04" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78492 "CLJ SI CLX 05" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78493 "CLJ SI CLX 06" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78494 "CLJ SI CLX 07" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78495 "CLJ SI CLX 08" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78496 "CLJ SI CLX 09" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78497 "CLJ SI CLX 10" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78498 "CLJ SI CLX 11" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78499 "CLJ SI CLX 12" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78500 "CLJ SI CLX 13" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78501 "CLJ SI CLX 14" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78502 "CLJ SI CLX 15" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78503 "CLJ SI CLX 16" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78504 "CLJ SI CLX 17" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78505 "CLJ SI CLX 18" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78506 "CLJ SI CLX 19" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78507 "CLJ SI CLX 20" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78508 "CLJ SI CLX 21" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78509 "CLJ SI CLX 22" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78510 "CLJ SI CLX 23" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78511 "CLJ SI CLX 24" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78512 "CLJ SI CLX 25" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78513 "CLJ SI CLX 26" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78514 "CLJ SI CLX 27" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78515 "CLJ SI CLX 28" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78516 "CLJ SI CLX 29" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78517 "CLJ SI CLX 30" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78518 "CLJ SI CLX 31" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78519 "CLJ SI CLX 32" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78520 "CLJ SI CLX 33" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78521 "CLJ SI CLX 34" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78522 "CLJ SI CLX 35" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78523 "CLJ SI CLX 36" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78524 "CLJ SI CLX 37" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78525 "CLJ SI CLX 38" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78526 "CLJ SI CLX 39" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78527 "CLJ SI CLX 40" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78528 "CLJ SI CLX 41" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78529 "CLJ SI CLX 42" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78530 "CLJ SI CLX 43" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78531 "CLJ SI CLX 44" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78532 "CLJ SI CLX 45" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78533 "CLJ SI CLX 46" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78534 "CLJ SI CLX 47" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78535 "CLJ SI CLX 48" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78536 "CLJ SI CLX 49" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78537 "CLJ SI CLX 50" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78538 "CLJ SI CLX 51" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78539 "CLJ SI CLX 52" implements "CLJ CLX Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78540 "CLJ CLX SI Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLX_VarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 01";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_OtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 02";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.Pull(O);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 03";
        K: Codeunit "CLJ CLX SI Fam SI Holder";
    begin
        K.Pull(O);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_CallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 04";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepLocalWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ArrayElement_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 05";
        A: array[2] of Codeunit "CLX Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 06";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Hander: Codeunit "CLJ CLX SI Fam Holder";
    begin
        Hander.Hand(O, K);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 07";
        Y: Codeunit "CLX Store";
    begin
        O.SetStore(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 08";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillWritten(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 09";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValDeep_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 10";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValSetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 11";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Hander: Codeunit "CLJ CLX SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        K.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValSetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 12";
        Y: Codeunit "CLX Store";
    begin
        O.SetStoreByVal(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 13";
        K: Codeunit "CLJ CLX SI Fam Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarWritten(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 14";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepVarWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 15";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillVarWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 16";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 17";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepIfaceWritten(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 18";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillIfaceWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ListLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 19";
        K: Codeunit "CLJ CLX SI Fam Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListWritten(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 20";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillListWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_DictLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 21";
        K: Codeunit "CLJ CLX SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictWritten(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_DictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 22";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillDictWritten(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 23";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 24";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 25";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillWritten(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValFromCodeunit_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 26";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 27";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 28";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 29";
        K: Codeunit "CLJ CLX SI Fam SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 30";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 31";
        A: array[2] of Codeunit "CLX Store";
    begin
        O.ShareAlias(A[2]);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 32";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Hander: Codeunit "CLJ CLX SI Fam Holder";
    begin
        Hander.Hand(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 33";
        Y: Codeunit "CLX Store";
    begin
        O.SetStore(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 34";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 35";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 36";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 37";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Hander: Codeunit "CLJ CLX SI Fam Holder";
    begin
        Hander.HandByVal(O, K);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 38";
        Y: Codeunit "CLX Store";
    begin
        O.SetStoreByVal(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 39";
        K: Codeunit "CLJ CLX SI Fam Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 40";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 41";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillVarNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 42";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 43";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 44";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillIfaceNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 45";
        K: Codeunit "CLJ CLX SI Fam Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 46";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillListNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 47";
        K: Codeunit "CLJ CLX SI Fam Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 48";
        K: Codeunit "CLJ CLX SI Fam Holder";
    begin
        K.FillDictNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 49";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 50";
        K: Codeunit "CLJ CLX SI Fam Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 51";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLJ SI CLX 52";
        K: Codeunit "CLJ CLX SI Fam Holder";
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;
}

codeunit 78541 "CLJ CLX TG Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        GI: Interface "CLX IStore";
        GL: List of [Interface "CLX IStore"];
        GD: Dictionary of [Integer, Interface "CLX IStore"];

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure VSet(V: Integer)
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        C.Set(V);
    end;

    procedure ISet(V: Integer)
    begin
        GI.Set(V);
    end;

    procedure LSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        F.Set(V);
    end;

    procedure DSet(V: Integer)
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        F.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;

    procedure VGet(): Integer
    var
        C: Codeunit "CLX Store";
    begin
        C := GV;
        exit(C.Get());
    end;

    procedure IGet(): Integer
    begin
        exit(GI.Get());
    end;

    procedure LGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GL.Get(1);
        exit(F.Get());
    end;

    procedure DGet(): Integer
    var
        F: Interface "CLX IStore";
    begin
        F := GD.Get(1);
        exit(F.Get());
    end;

    procedure SetStore(var NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLX Store")
    begin
        G := NewG;
    end;

    procedure Pull(O: Interface "CLJ CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLJ CLX Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure Hand(O: Interface "CLJ CLX Owner"; var Hd: Codeunit "CLJ CLX TG Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLJ CLX Owner"; var Hd: Codeunit "CLJ CLX TG Holder")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure DoClear(O: Interface "CLJ CLX Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaIface(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByVal(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillWritten(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarWritten(O: Interface "CLJ CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarWritten(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfaceWritten(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLJ CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictWritten(O: Interface "CLJ CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLJ CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillWritten(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure KeepLocalNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure ViaByValFillNever(O: Interface "CLJ CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
    end;

    procedure LoadVarNever(O: Interface "CLJ CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLJ CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
    end;

    procedure LoadIfaceNever(O: Interface "CLJ CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLJ CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLJ CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLJ CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLJ CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLJ CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLJ CLX Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLX IStore";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;

    procedure ViaIfaceByValFillNever(O: Interface "CLJ CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
    end;
}

codeunit 78542 "CLJ TG CLX 01" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78543 "CLJ TG CLX 02" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_OtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.Pull(this);
        K.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78544 "CLJ CLX TG SI Holder 03"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";

    procedure Pull(O: Interface "CLJ CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 78545 "CLJ TG CLX 03" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG SI Holder 03";
    begin
        K.Pull(this);
        K.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78546 "CLJ TG CLX 04" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_CallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepLocalWritten(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78547 "CLJ TG CLX 05" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ArrayElement_Written()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLX Store";
    begin
        this.ShareAlias(A[2]);
        A[2].Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78548 "CLJ TG CLX 06" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Hander: Codeunit "CLJ CLX TG Holder";
    begin
        Hander.Hand(this, K);
        K.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78549 "CLJ TG CLX 07" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        this.SetStore(Y);
        Y.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78550 "CLJ TG CLX 08" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillWritten(this, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78551 "CLJ TG CLX 09" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78552 "CLJ TG CLX 10" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValDeep_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78553 "CLJ TG CLX 11" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValSetterOut_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Hander: Codeunit "CLJ CLX TG Holder";
    begin
        Hander.HandByVal(this, K);
        K.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78554 "CLJ TG CLX 12" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValSetterIn_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        this.SetStoreByVal(Y);
        Y.Set(3);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78555 "CLJ TG CLX 13" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarWritten(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78556 "CLJ TG CLX 14" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepVarWritten(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78557 "CLJ TG CLX 15" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillVarWritten(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78558 "CLJ TG CLX 16" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78559 "CLJ TG CLX 17" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceCallerLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepIfaceWritten(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78560 "CLJ TG CLX 18" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillIfaceWritten(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78561 "CLJ TG CLX 19" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ListLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListWritten(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78562 "CLJ TG CLX 20" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillListWritten(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78563 "CLJ TG CLX 21" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_DictLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictWritten(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78564 "CLJ TG CLX 22" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_DictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillDictWritten(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78565 "CLJ TG CLX 23" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78566 "CLJ TG CLX 24" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceWritten(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78567 "CLJ TG CLX 25" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValFill_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillWritten(this, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78568 "CLJ TG CLX 26" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValFromCodeunit_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Y: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78569 "CLJ TG CLX 27" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78570 "CLJ TG CLX 28" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78571 "CLJ CLX TG SI Holder 29"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";

    procedure Pull(O: Interface "CLJ CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 78572 "CLJ TG CLX 29" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG SI Holder 29";
    begin
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        K.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78573 "CLJ TG CLX 30" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepLocalNever(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78574 "CLJ TG CLX 31" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLX Store";
    begin
        this.ShareAlias(A[2]);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(A[2].Get()));
        A[2].Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(A[2].Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78575 "CLJ TG CLX 32" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Hander: Codeunit "CLJ CLX TG Holder";
    begin
        Hander.Hand(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78576 "CLJ TG CLX 33" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        this.SetStore(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78577 "CLJ TG CLX 34" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78578 "CLJ TG CLX 35" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78579 "CLJ TG CLX 36" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78580 "CLJ TG CLX 37" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Hander: Codeunit "CLJ CLX TG Holder";
    begin
        Hander.HandByVal(this, K);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78581 "CLJ TG CLX 38" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
    begin
        this.SetStoreByVal(Y);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(Y.Get()));
        Y.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78582 "CLJ TG CLX 39" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        V: Variant;
        C: Codeunit "CLX Store";
    begin
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', Format(C.Get()));
        C := V;
        C.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', Format(C.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78583 "CLJ TG CLX 40" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepVarNever(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78584 "CLJ TG CLX 41" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillVarNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.VGet()));
        K.VSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.VGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78585 "CLJ TG CLX 42" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78586 "CLJ TG CLX 43" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.KeepIfaceNever(this, Observer);
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78587 "CLJ TG CLX 44" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillIfaceNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.IGet()));
        K.ISet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.IGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78588 "CLJ TG CLX 45" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        L: List of [Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadListNever(this, L);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := L.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78589 "CLJ TG CLX 46" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillListNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.LGet()));
        K.LSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.LGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78590 "CLJ TG CLX 47" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        D: Dictionary of [Integer, Interface "CLX IStore"];
        F: Interface "CLX IStore";
    begin
        K.LoadDictNever(this, D);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', Format(F.Get()));
        F := D.Get(1);
        F.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', Format(F.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78591 "CLJ TG CLX 48" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
    begin
        K.FillDictNever(this);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.DGet()));
        K.DSet(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.DGet()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78592 "CLJ TG CLX 49" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIface(this, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78593 "CLJ TG CLX 50" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        I: Interface "CLX IStore";
    begin
        K.LoadIfaceNever(this, I);
        K.ViaIfaceByVal(this, I, Observer);
        Observer.Observe('caller holder after return', Format(I.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78594 "CLJ TG CLX 51" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Z: Codeunit "CLX Store";
    begin
        K.ViaIfaceByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Format(Z.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller argument after return', '0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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

codeunit 78595 "CLJ TG CLX 52" implements "CLJ CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLJ CLX TG Holder";
        Y: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaIfaceByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure StateX(): Text
    begin
        exit(Format(X.Get()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLX Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLX Store")
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
