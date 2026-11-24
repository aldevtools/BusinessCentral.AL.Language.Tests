// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the stores "CLX Store" / "CLX IStore" (ClearSharedCodeunit.al),
//   "CLB Store" / "CLB IStore" (ClearSharedCodeunitTempRef.al), "CLS Arr Store" (ClearSharedCodeunitSIOwner.al),
//   "CLQ Store Plus" and "CLQ Wrapper" (ClearSharedCodeunitOwnerKinds.al), "CLR Register"
//   (ClearSharedCodeunitSetterOwner.al), "CLT B2 Store" (ClearSharedCodeunitTempArrayShare.al) and "CLV Price Store"
//   (ClearSharedCodeunitStoreShapes.al); self-contained objects 82655 to 82724.
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Owners (as ClearSharedCodeunitOwnerSlotsCLB.al): globals X (the store) and Cnt; procedures WriteX, StateX,
//   ShareAlias (var getter), SetStore, SetStoreByVal, ClearAllGlobals (ClearAll), SetCnt, GetCnt.
//   Plain: one owner object per store, a fresh local per test. SI: a SingleInstance owner of its own per test.
//   TG: the test codeunit itself is the owner, one test each. Test names are <Owner><Store>_<Cell>_<State>.
// States: Rows / Written (the holder wrote the store before ClearAll) and Never (no call on the store at all
//   before ClearAll; only the owner's Cnt was set).
// Facts: the store with one more Integer ("CLQ Store Plus") shared through every holder slot of
//   ClearSharedCodeunitOwnerSlots*.al that needs no interface, under the Plain, SI and test owners. State Never
//   means no call on the store before ClearAll in the owner (no Write, no SetN).
// Result (BC 29.0): every slot gives the answer of the plain by-value cell, with and without a call on the
//   store before ClearAll: the one instance is reset in place (temporary rows kept) and writes cross.
// BC versions: 27, 28, 29

interface "CLKP Plus Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus");
    procedure SetStore(var NewS: Codeunit "CLQ Store Plus");
    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

codeunit 82655 "CLKP Plus Plain Owner"
{
    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82656 "CLKP Plus Plain Holder"
{
    var
        G: Codeunit "CLQ Store Plus";
        GV: Variant;
        HCnt: Integer;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure VSetN(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure PullPlain(var O: Codeunit "CLKP Plus Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKP Plus Plain Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure HandPlain(var O: Codeunit "CLKP Plus Plain Owner"; var Hd: Codeunit "CLKP Plus Plain Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByValPlain(var O: Codeunit "CLKP Plus Plain Owner"; var Hd: Codeunit "CLKP Plus Plain Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKP Plus Plain Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure DoClearPlain(var O: Codeunit "CLKP Plus Plain Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterPlain(var O: Codeunit "CLKP Plus Plain Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure KeepLocalPlainRows(var O: Codeunit "CLKP Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure ViaByValFillPlainRows(var O: Codeunit "CLKP Plus Plain Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure LoadVarPlainRows(var O: Codeunit "CLKP Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKP Plus Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKP Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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

    procedure KeepLocalPlainNever(var O: Codeunit "CLKP Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
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

    procedure ViaByValFillPlainNever(var O: Codeunit "CLKP Plus Plain Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKP Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKP Plus Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKP Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
}

codeunit 82657 "CLKP Plus Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKP Plus Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82658 "CLKP Plus Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainPlus_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain SI Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        K.SetN(6);
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        K.KeepLocalPlainRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        A: array[2] of Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        A[2].SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Hander: Codeunit "CLKP Plus Plain Holder";
    begin
        Hander.HandPlain(O, K);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStore(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillPlainRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Hander: Codeunit "CLKP Plus Plain Holder";
    begin
        Hander.HandByValPlain(O, K);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        K.KeepVarPlainRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        K.KeepLocalPlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        A: array[2] of Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Hander: Codeunit "CLKP Plus Plain Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        Hander: Codeunit "CLKP Plus Plain Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
    begin
        K.KeepVarPlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP Plus Plain Owner";
        K: Codeunit "CLKP Plus Plain Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82659 "CLKP Plus SI Holder"
{
    var
        G: Codeunit "CLQ Store Plus";
        GV: Variant;
        HCnt: Integer;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure VSetN(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Pull(O: Interface "CLKP Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKP Plus Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure Hand(O: Interface "CLKP Plus Owner"; var Hd: Codeunit "CLKP Plus SI Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLKP Plus Owner"; var Hd: Codeunit "CLKP Plus SI Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure DoClear(O: Interface "CLKP Plus Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure KeepLocalRows(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure ViaByValFillRows(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure LoadVarRows(O: Interface "CLKP Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKP Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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

    procedure KeepLocalNever(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
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

    procedure ViaByValFillNever(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKP Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKP Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
}

codeunit 82660 "CLKP Plus SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKP Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82661 "CLKP SI Plus 01" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82662 "CLKP SI Plus 02" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82663 "CLKP SI Plus 03" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82664 "CLKP SI Plus 04" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82665 "CLKP SI Plus 05" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82666 "CLKP SI Plus 06" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82667 "CLKP SI Plus 07" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82668 "CLKP SI Plus 08" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82669 "CLKP SI Plus 09" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82670 "CLKP SI Plus 10" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82671 "CLKP SI Plus 11" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82672 "CLKP SI Plus 12" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82673 "CLKP SI Plus 13" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82674 "CLKP SI Plus 14" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82675 "CLKP SI Plus 15" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82676 "CLKP SI Plus 16" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82677 "CLKP SI Plus 17" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82678 "CLKP SI Plus 18" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82679 "CLKP SI Plus 19" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82680 "CLKP SI Plus 20" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82681 "CLKP SI Plus 21" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82682 "CLKP SI Plus 22" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82683 "CLKP SI Plus 23" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82684 "CLKP SI Plus 24" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82685 "CLKP SI Plus 25" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82686 "CLKP SI Plus 26" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82687 "CLKP SI Plus 27" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82688 "CLKP SI Plus 28" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82689 "CLKP SI Plus 29" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82690 "CLKP SI Plus 30" implements "CLKP Plus Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82691 "CLKP Plus SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIPlus_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 01";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 02";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        K.Pull(O);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 03";
        K: Codeunit "CLKP Plus SI SI Holder";
    begin
        K.Pull(O);
        K.Write(3);
        K.SetN(6);
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 04";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 05";
        A: array[2] of Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        A[2].SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 06";
        K: Codeunit "CLKP Plus SI Holder";
        Hander: Codeunit "CLKP Plus SI Holder";
    begin
        Hander.Hand(O, K);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 07";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStore(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 08";
        K: Codeunit "CLKP Plus SI Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 09";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 10";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 11";
        K: Codeunit "CLKP Plus SI Holder";
        Hander: Codeunit "CLKP Plus SI Holder";
    begin
        Hander.HandByVal(O, K);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 12";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 13";
        K: Codeunit "CLKP Plus SI Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 14";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 15";
        K: Codeunit "CLKP Plus SI Holder";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 16";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 17";
        K: Codeunit "CLKP Plus SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 18";
        K: Codeunit "CLKP Plus SI SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 19";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 20";
        A: array[2] of Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 21";
        K: Codeunit "CLKP Plus SI Holder";
        Hander: Codeunit "CLKP Plus SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 22";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 23";
        K: Codeunit "CLKP Plus SI Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 24";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 25";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 26";
        K: Codeunit "CLKP Plus SI Holder";
        Hander: Codeunit "CLKP Plus SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 27";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 28";
        K: Codeunit "CLKP Plus SI Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 29";
        K: Codeunit "CLKP Plus SI Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKP SI Plus 30";
        K: Codeunit "CLKP Plus SI Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82692 "CLKP Plus TG Holder"
{
    var
        G: Codeunit "CLQ Store Plus";
        GV: Variant;
        HCnt: Integer;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure VSetN(V: Integer)
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        C.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLQ Store Plus";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Pull(O: Interface "CLKP Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKP Plus Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure Hand(O: Interface "CLKP Plus Owner"; var Hd: Codeunit "CLKP Plus TG Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStore(Y);
    end;

    procedure HandByVal(O: Interface "CLKP Plus Owner"; var Hd: Codeunit "CLKP Plus TG Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Hd.SetStoreByVal(Y);
    end;

    procedure ViaByVal(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure DoClear(O: Interface "CLKP Plus Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure KeepLocalRows(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure ViaByValFillRows(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
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

    procedure LoadVarRows(O: Interface "CLKP Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKP Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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

    procedure KeepLocalNever(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
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

    procedure ViaByValFillNever(O: Interface "CLKP Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKP Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKP Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKP Plus Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
}

codeunit 82693 "CLKP TG Plus 01" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82694 "CLKP TG Plus 02" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        K.Pull(this);
        K.Write(3);
        K.SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82695 "CLKP Plus TG SI 03"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKP Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82696 "CLKP TG Plus 03" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG SI 03";
    begin
        K.Pull(this);
        K.Write(3);
        K.SetN(6);
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82697 "CLKP TG Plus 04" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        K.KeepLocalRows(this, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82698 "CLKP TG Plus 05" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(A[2]);
        A[2].Write(3);
        A[2].SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82699 "CLKP TG Plus 06" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Hander: Codeunit "CLKP Plus TG Holder";
    begin
        Hander.Hand(this, K);
        K.Write(3);
        K.SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82700 "CLKP TG Plus 07" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
    begin
        this.SetStore(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82701 "CLKP TG Plus 08" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillRows(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82702 "CLKP TG Plus 09" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82703 "CLKP TG Plus 10" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82704 "CLKP TG Plus 11" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Hander: Codeunit "CLKP Plus TG Holder";
    begin
        Hander.HandByVal(this, K);
        K.Write(3);
        K.SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82705 "CLKP TG Plus 12" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
    begin
        this.SetStoreByVal(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82706 "CLKP TG Plus 13" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82707 "CLKP TG Plus 14" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        K.KeepVarRows(this, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82708 "CLKP TG Plus 15" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
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
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82709 "CLKP TG Plus 16" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82710 "CLKP TG Plus 17" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82711 "CLKP Plus TG SI 18"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKP Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure Release()
    begin
        Clear(G);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure SetHCnt(V: Integer)
    begin
        HCnt := V;
    end;

    procedure GetHCnt(): Integer
    begin
        exit(HCnt);
    end;

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure SetN(V: Integer)
    begin
        G.SetN(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82712 "CLKP TG Plus 18" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG SI 18";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82713 "CLKP TG Plus 19" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        K.KeepLocalNever(this, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82714 "CLKP TG Plus 20" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82715 "CLKP TG Plus 21" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Hander: Codeunit "CLKP Plus TG Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82716 "CLKP TG Plus 22" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82717 "CLKP TG Plus 23" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Z: Codeunit "CLQ Store Plus";
    begin
        K.ViaByValFillNever(this, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82718 "CLKP TG Plus 24" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82719 "CLKP TG Plus 25" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByValOuter(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82720 "CLKP TG Plus 26" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        Hander: Codeunit "CLKP Plus TG Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82721 "CLKP TG Plus 27" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82722 "CLKP TG Plus 28" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82723 "CLKP TG Plus 29" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
    begin
        K.KeepVarNever(this, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82724 "CLKP TG Plus 30" implements "CLKP Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKP Plus TG Holder";
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
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

    procedure ShareAlias(var Y: Codeunit "CLQ Store Plus")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}
