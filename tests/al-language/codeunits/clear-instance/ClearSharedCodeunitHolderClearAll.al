// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the stores "CLX Store" / "CLX IStore" (ClearSharedCodeunit.al),
//   "CLB Store" / "CLB IStore" (ClearSharedCodeunitTempRef.al), "CLS Arr Store" (ClearSharedCodeunitSIOwner.al),
//   "CLQ Store Plus" and "CLQ Wrapper" (ClearSharedCodeunitOwnerKinds.al), "CLR Register"
//   (ClearSharedCodeunitSetterOwner.al), "CLT B2 Store" (ClearSharedCodeunitTempArrayShare.al) and "CLV Price Store"
//   (ClearSharedCodeunitStoreShapes.al); self-contained objects 82438 to 82654.
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Owners (as ClearSharedCodeunitOwnerSlotsCLB.al): globals X (the store) and Cnt; procedures WriteX, StateX,
//   ShareAlias (var getter), SetStore, SetStoreByVal, ClearAllGlobals (ClearAll), SetCnt, GetCnt.
//   Plain: one owner object per store, a fresh local per test. SI: a SingleInstance owner of its own per test.
//   TG: the test codeunit itself is the owner, one test each. Test names are <Owner><Store>_<Cell>_<State>.
// States: Rows / Written (the holder wrote the store before ClearAll) and Never (no call on the store at all
//   before ClearAll; only the owner's Cnt was set).
// Facts: ClearAll() runs in the HOLDER codeunit (procedure ClearAllSelf), not in the owner. The holder keeps the
//   owner's store in a global: Codeunit (HcaGlobal: plain holder, HcaSIGlobal: SingleInstance holder), Variant,
//   Interface, List of [Interface] or Dictionary of [Integer, Interface]. The holder's own Integer HCnt (9) shows
//   the ClearAll ran. Then: read the owner and its Cnt; for the Codeunit globals also read the holder, write through
//   it and read the owner, write through the owner and read the holder; else write through the owner and read it.
// Result (BC 29.0): ClearAll in the holder clears its Codeunit global (plain or SingleInstance) and its
//   Interface global the way ClearAll in the owner does: the shared instance is reset in place (temporary rows
//   kept), the owner reads the reset store and writes cross. A Variant, List of [Interface] or Dictionary of
//   [Integer, Interface] global is only dropped: the owner keeps every value it had. The owner's Cnt stays 4.
//   A List of [Variant] holder does not compile (AL0408; must-not-compile cases 1747 and 2770).
// BC versions: 27, 28, 29

interface "CLKH CLX Owner"
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

interface "CLKH CLB Owner"
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

interface "CLKH Arr Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLS Arr Store");
    procedure SetStore(var NewS: Codeunit "CLS Arr Store");
    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

interface "CLKH Plus Owner"
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

interface "CLKH Wrap Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper");
    procedure SetStore(var NewS: Codeunit "CLQ Wrapper");
    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

interface "CLKH B2 Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLT B2 Store");
    procedure SetStore(var NewS: Codeunit "CLT B2 Store");
    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

interface "CLKH Reg Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLR Register");
    procedure SetStore(var NewS: Codeunit "CLR Register");
    procedure SetStoreByVal(NewS: Codeunit "CLR Register");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

interface "CLKH Price Owner"
{
    procedure WriteX(V: Integer);
    procedure StateX(): Text;
    procedure ShareAlias(var Y: Codeunit "CLV Price Store");
    procedure SetStore(var NewS: Codeunit "CLV Price Store");
    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store");
    procedure ClearAllGlobals();
    procedure SetCnt(V: Integer);
    procedure GetCnt(): Integer;
}

codeunit 82438 "CLKH CLX Plain Owner"
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

codeunit 82439 "CLKH CLX Plain Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure PullPlain(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIfacePlain(var O: Codeunit "CLKH CLX Plain Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValPlain(var O: Codeunit "CLKH CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainWritten(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadVarPlainWritten(O, GV);
    end;

    procedure KeepVarPlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictPlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfacePlainWritten(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadIfacePlainWritten(O, GI);
    end;

    procedure FillListPlainWritten(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadListPlainWritten(O, GL);
    end;

    procedure FillDictPlainWritten(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadDictPlainWritten(O, GD);
    end;

    procedure KeepIfacePlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainWritten(var O: Codeunit "CLKH CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLKH CLX Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLKH CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLKH CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82440 "CLKH CLX Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH CLX Plain Owner")
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

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 82441 "CLKH CLX Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLX_HcaGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.PullPlain(O);
        K.Set(3);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaSIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        KS: Codeunit "CLKH CLX Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Set(3);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaVariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillVarPlainWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaIfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillIfacePlainWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillListPlainWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaDictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillDictPlainWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        KS: Codeunit "CLKH CLX Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillIfacePlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillListPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLX Plain Owner";
        K: Codeunit "CLKH CLX Plain Holder";
    begin
        K.FillDictPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;
}

codeunit 82442 "CLKH CLX SI Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure Pull(O: Interface "CLKH CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIface(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarWritten(O: Interface "CLKH CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceWritten(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLKH CLX Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictWritten(O: Interface "CLKH CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfaceWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillWritten(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKH CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKH CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKH CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKH CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKH CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82443 "CLKH CLX SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLX Owner")
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

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 82444 "CLKH SI CLX 01" implements "CLKH CLX Owner"
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

codeunit 82445 "CLKH SI CLX 02" implements "CLKH CLX Owner"
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

codeunit 82446 "CLKH SI CLX 03" implements "CLKH CLX Owner"
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

codeunit 82447 "CLKH SI CLX 04" implements "CLKH CLX Owner"
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

codeunit 82448 "CLKH SI CLX 05" implements "CLKH CLX Owner"
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

codeunit 82449 "CLKH SI CLX 06" implements "CLKH CLX Owner"
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

codeunit 82450 "CLKH SI CLX 07" implements "CLKH CLX Owner"
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

codeunit 82451 "CLKH SI CLX 08" implements "CLKH CLX Owner"
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

codeunit 82452 "CLKH SI CLX 09" implements "CLKH CLX Owner"
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

codeunit 82453 "CLKH SI CLX 10" implements "CLKH CLX Owner"
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

codeunit 82454 "CLKH SI CLX 11" implements "CLKH CLX Owner"
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

codeunit 82455 "CLKH SI CLX 12" implements "CLKH CLX Owner"
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

codeunit 82456 "CLKH CLX SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLX_HcaGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 01";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.Pull(O);
        K.Set(3);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaSIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 02";
        KS: Codeunit "CLKH CLX SI SI Holder";
    begin
        KS.Pull(O);
        KS.Set(3);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaVariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 03";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillVarWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaIfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 04";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillIfaceWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 05";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillListWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaDictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 06";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillDictWritten(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 07";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 08";
        KS: Codeunit "CLKH CLX SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 09";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 10";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillIfaceNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 11";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillListNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLX 12";
        K: Codeunit "CLKH CLX SI Holder";
    begin
        K.FillDictNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
        Observer.Verify();
    end;
}

codeunit 82457 "CLKH CLX TG Holder"
{
    var
        G: Codeunit "CLX Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure Pull(O: Interface "CLKH CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIface(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarWritten(O: Interface "CLKH CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceWritten(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLKH CLX Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictWritten(O: Interface "CLKH CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfaceWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLKH CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillWritten(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKH CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKH CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKH CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKH CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKH CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKH CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKH CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKH CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82458 "CLKH TG CLX 01" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.Pull(this);
        K.Set(3);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
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

codeunit 82459 "CLKH CLX TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLX Owner")
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

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 82460 "CLKH TG CLX 02" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaSIGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH CLX TG SI 02";
    begin
        KS.Pull(this);
        KS.Set(3);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
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

codeunit 82461 "CLKH TG CLX 03" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaVariantGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillVarWritten(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82462 "CLKH TG CLX 04" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaIfaceGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillIfaceWritten(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82463 "CLKH TG CLX 05" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaListGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillListWritten(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82464 "CLKH TG CLX 06" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaDictGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillDictWritten(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '3');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82465 "CLKH TG CLX 07" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
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

codeunit 82466 "CLKH CLX TG SI 08"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLX Owner")
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

    procedure Set(V: Integer)
    begin
        G.Set(V);
    end;

    procedure Get(): Integer
    begin
        exit(G.Get());
    end;
}

codeunit 82467 "CLKH TG CLX 08" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH CLX TG SI 08";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', Format(KS.Get()));
        KS.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', Format(KS.Get()));
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '8');
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

codeunit 82468 "CLKH TG CLX 09" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82469 "CLKH TG CLX 10" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillIfaceNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82470 "CLKH TG CLX 11" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillListNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82471 "CLKH TG CLX 12" implements "CLKH CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLX TG Holder";
    begin
        K.FillDictNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', '8');
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

codeunit 82472 "CLKH CLB Plain Owner"
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

codeunit 82473 "CLKH CLB Plain Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure PullPlain(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIfacePlain(var O: Codeunit "CLKH CLB Plain Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValPlain(var O: Codeunit "CLKH CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictPlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfacePlainRows(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadIfacePlainRows(O, GI);
    end;

    procedure FillListPlainRows(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadListPlainRows(O, GL);
    end;

    procedure FillDictPlainRows(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadDictPlainRows(O, GD);
    end;

    procedure KeepIfacePlainRows(var O: Codeunit "CLKH CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainRows(var O: Codeunit "CLKH CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLKH CLB Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLKH CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLKH CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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
}

codeunit 82474 "CLKH CLB Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH CLB Plain Owner")
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

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82475 "CLKH CLB Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLB_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        KS: Codeunit "CLKH CLB Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Write(3);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaIfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillIfacePlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillListPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaDictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillDictPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        KS: Codeunit "CLKH CLB Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillIfacePlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillListPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH CLB Plain Owner";
        K: Codeunit "CLKH CLB Plain Holder";
    begin
        K.FillDictPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;
}

codeunit 82476 "CLKH CLB SI Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure Pull(O: Interface "CLKH CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIface(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKH CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceRows(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLKH CLB Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictRows(O: Interface "CLKH CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfaceRows(O: Interface "CLKH CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLKH CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLKH CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillRows(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKH CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKH CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKH CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKH CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKH CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82477 "CLKH CLB SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLB Owner")
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

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82478 "CLKH SI CLB 01" implements "CLKH CLB Owner"
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

codeunit 82479 "CLKH SI CLB 02" implements "CLKH CLB Owner"
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

codeunit 82480 "CLKH SI CLB 03" implements "CLKH CLB Owner"
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

codeunit 82481 "CLKH SI CLB 04" implements "CLKH CLB Owner"
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

codeunit 82482 "CLKH SI CLB 05" implements "CLKH CLB Owner"
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

codeunit 82483 "CLKH SI CLB 06" implements "CLKH CLB Owner"
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

codeunit 82484 "CLKH SI CLB 07" implements "CLKH CLB Owner"
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

codeunit 82485 "CLKH SI CLB 08" implements "CLKH CLB Owner"
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

codeunit 82486 "CLKH SI CLB 09" implements "CLKH CLB Owner"
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

codeunit 82487 "CLKH SI CLB 10" implements "CLKH CLB Owner"
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

codeunit 82488 "CLKH SI CLB 11" implements "CLKH CLB Owner"
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

codeunit 82489 "CLKH SI CLB 12" implements "CLKH CLB Owner"
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

codeunit 82490 "CLKH CLB SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLB_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 01";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.Pull(O);
        K.Write(3);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 02";
        KS: Codeunit "CLKH CLB SI SI Holder";
    begin
        KS.Pull(O);
        KS.Write(3);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 03";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaIfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 04";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillIfaceRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 05";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillListRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaDictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 06";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillDictRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 07";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 08";
        KS: Codeunit "CLKH CLB SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 09";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 10";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillIfaceNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 11";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillListNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI CLB 12";
        K: Codeunit "CLKH CLB SI Holder";
    begin
        K.FillDictNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
        Observer.Verify();
    end;
}

codeunit 82491 "CLKH CLB TG Holder"
{
    var
        G: Codeunit "CLB Store";
        GV: Variant;
        HCnt: Integer;
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

    procedure Pull(O: Interface "CLKH CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaIface(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKH CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceRows(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLKH CLB Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictRows(O: Interface "CLKH CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfaceRows(O: Interface "CLKH CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLKH CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLKH CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillRows(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKH CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKH CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKH CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKH CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKH CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKH CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKH CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKH CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82492 "CLKH TG CLB 01" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.Pull(this);
        K.Write(3);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82493 "CLKH CLB TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLB Owner")
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

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82494 "CLKH TG CLB 02" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH CLB TG SI 02";
    begin
        KS.Pull(this);
        KS.Write(3);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82495 "CLKH TG CLB 03" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82496 "CLKH TG CLB 04" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaIfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillIfaceRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
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

codeunit 82497 "CLKH TG CLB 05" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillListRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82498 "CLKH TG CLB 06" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaDictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillDictRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82499 "CLKH TG CLB 07" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82500 "CLKH CLB TG SI 08"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH CLB Owner")
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

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82501 "CLKH TG CLB 08" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH CLB TG SI 08";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0');
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

codeunit 82502 "CLKH TG CLB 09" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
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

codeunit 82503 "CLKH TG CLB 10" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaIfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillIfaceNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
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

codeunit 82504 "CLKH TG CLB 11" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillListNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
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

codeunit 82505 "CLKH TG CLB 12" implements "CLKH CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_HcaDictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH CLB TG Holder";
    begin
        K.FillDictNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0');
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

codeunit 82506 "CLKH Arr Plain Owner"
{
    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82507 "CLKH Arr Plain Holder"
{
    var
        G: Codeunit "CLS Arr Store";
        GV: Variant;
        HCnt: Integer;

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

    procedure PullPlain(var O: Codeunit "CLKH Arr Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH Arr Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH Arr Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH Arr Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLKH Arr Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH Arr Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH Arr Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82508 "CLKH Arr Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH Arr Plain Owner")
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

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82509 "CLKH Arr Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainArr_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        K: Codeunit "CLKH Arr Plain Holder";
    begin
        K.PullPlain(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        KS: Codeunit "CLKH Arr Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Write(1, 3);
        KS.Write(2, 4);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        K: Codeunit "CLKH Arr Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        K: Codeunit "CLKH Arr Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        KS: Codeunit "CLKH Arr Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Arr Plain Owner";
        K: Codeunit "CLKH Arr Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=8');
        Observer.Verify();
    end;
}

codeunit 82510 "CLKH Arr SI Holder"
{
    var
        G: Codeunit "CLS Arr Store";
        GV: Variant;
        HCnt: Integer;

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

    procedure Pull(O: Interface "CLKH Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Arr Owner"; var Observer: Codeunit "Probe Observer")
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
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Arr Owner"; var Observer: Codeunit "Probe Observer")
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
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82511 "CLKH Arr SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Arr Owner")
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

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82512 "CLKH SI Arr 01" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82513 "CLKH SI Arr 02" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82514 "CLKH SI Arr 03" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82515 "CLKH SI Arr 04" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82516 "CLKH SI Arr 05" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82517 "CLKH SI Arr 06" implements "CLKH Arr Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82518 "CLKH Arr SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArr_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 01";
        K: Codeunit "CLKH Arr SI Holder";
    begin
        K.Pull(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 02";
        KS: Codeunit "CLKH Arr SI SI Holder";
    begin
        KS.Pull(O);
        KS.Write(1, 3);
        KS.Write(2, 4);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 03";
        K: Codeunit "CLKH Arr SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 04";
        K: Codeunit "CLKH Arr SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 05";
        KS: Codeunit "CLKH Arr SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Arr 06";
        K: Codeunit "CLKH Arr SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=8');
        Observer.Verify();
    end;
}

codeunit 82519 "CLKH Arr TG Holder"
{
    var
        G: Codeunit "CLS Arr Store";
        GV: Variant;
        HCnt: Integer;

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

    procedure Pull(O: Interface "CLKH Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Arr Owner"; var Observer: Codeunit "Probe Observer")
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
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Arr Owner"; var Observer: Codeunit "Probe Observer")
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
        O.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82520 "CLKH TG Arr 01" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Arr TG Holder";
    begin
        K.Pull(this);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82521 "CLKH Arr TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Arr Owner")
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

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82522 "CLKH TG Arr 02" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Arr TG SI 02";
    begin
        KS.Pull(this);
        KS.Write(1, 3);
        KS.Write(2, 4);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82523 "CLKH TG Arr 03" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Arr TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82524 "CLKH TG Arr 04" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Arr TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82525 "CLKH Arr TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Arr Owner")
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

    procedure Write(E: Integer; V: Integer)
    begin
        G.Write(E, V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82526 "CLKH TG Arr 05" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Arr TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82527 "CLKH TG Arr 06" implements "CLKH Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Arr TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=8');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, V);
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

codeunit 82528 "CLKH Plus Plain Owner"
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

codeunit 82529 "CLKH Plus Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKH Plus Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH Plus Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKH Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH Plus Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82530 "CLKH Plus Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH Plus Plain Owner")
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

codeunit 82531 "CLKH Plus Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainPlus_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        K: Codeunit "CLKH Plus Plain Holder";
    begin
        K.PullPlain(O);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        KS: Codeunit "CLKH Plus Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Write(3);
        KS.SetN(6);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        K: Codeunit "CLKH Plus Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=6');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=6');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        K: Codeunit "CLKH Plus Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        KS: Codeunit "CLKH Plus Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Plus Plain Owner";
        K: Codeunit "CLKH Plus Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82532 "CLKH Plus SI Holder"
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

    procedure Pull(O: Interface "CLKH Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Plus Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Plus Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82533 "CLKH Plus SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Plus Owner")
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

codeunit 82534 "CLKH SI Plus 01" implements "CLKH Plus Owner"
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

codeunit 82535 "CLKH SI Plus 02" implements "CLKH Plus Owner"
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

codeunit 82536 "CLKH SI Plus 03" implements "CLKH Plus Owner"
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

codeunit 82537 "CLKH SI Plus 04" implements "CLKH Plus Owner"
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

codeunit 82538 "CLKH SI Plus 05" implements "CLKH Plus Owner"
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

codeunit 82539 "CLKH SI Plus 06" implements "CLKH Plus Owner"
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

codeunit 82540 "CLKH Plus SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIPlus_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 01";
        K: Codeunit "CLKH Plus SI Holder";
    begin
        K.Pull(O);
        K.Write(3);
        K.SetN(6);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 02";
        KS: Codeunit "CLKH Plus SI SI Holder";
    begin
        KS.Pull(O);
        KS.Write(3);
        KS.SetN(6);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 03";
        K: Codeunit "CLKH Plus SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=6');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=6');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 04";
        K: Codeunit "CLKH Plus SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 05";
        KS: Codeunit "CLKH Plus SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Plus 06";
        K: Codeunit "CLKH Plus SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82541 "CLKH Plus TG Holder"
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

    procedure Pull(O: Interface "CLKH Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Plus Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKH Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Plus Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82542 "CLKH TG Plus 01" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Plus TG Holder";
    begin
        K.Pull(this);
        K.Write(3);
        K.SetN(6);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
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

codeunit 82543 "CLKH Plus TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Plus Owner")
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

codeunit 82544 "CLKH TG Plus 02" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Plus TG SI 02";
    begin
        KS.Pull(this);
        KS.Write(3);
        KS.SetN(6);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
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

codeunit 82545 "CLKH TG Plus 03" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Plus TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=6');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=6');
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

codeunit 82546 "CLKH TG Plus 04" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Plus TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
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

codeunit 82547 "CLKH Plus TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Plus Owner")
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

codeunit 82548 "CLKH TG Plus 05" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Plus TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 n=0');
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

codeunit 82549 "CLKH TG Plus 06" implements "CLKH Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Plus TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 n=0');
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

codeunit 82567 "CLKH Wrap Plain Owner"
{
    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82568 "CLKH Wrap Plain Holder"
{
    var
        G: Codeunit "CLQ Wrapper";
        GV: Variant;
        HCnt: Integer;

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure VWriteX(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure VSetWCnt(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure VGetWCnt(): Integer
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;

    procedure VStateX(): Text
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.StateX());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Wrapper")
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

    procedure PullPlain(var O: Codeunit "CLKH Wrap Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH Wrap Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH Wrap Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH Wrap Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLKH Wrap Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH Wrap Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH Wrap Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;
}

codeunit 82569 "CLKH Wrap Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH Wrap Plain Owner")
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

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;
}

codeunit 82570 "CLKH Wrap Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainWrap_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        K: Codeunit "CLKH Wrap Plain Holder";
    begin
        K.PullPlain(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        KS: Codeunit "CLKH Wrap Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.WriteX(3);
        KS.SetWCnt(2);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        K: Codeunit "CLKH Wrap Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 w=2');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=2');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        K: Codeunit "CLKH Wrap Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        KS: Codeunit "CLKH Wrap Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Wrap Plain Owner";
        K: Codeunit "CLKH Wrap Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;
}

codeunit 82571 "CLKH Wrap SI Holder"
{
    var
        G: Codeunit "CLQ Wrapper";
        GV: Variant;
        HCnt: Integer;

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure VWriteX(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure VSetWCnt(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure VGetWCnt(): Integer
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;

    procedure VStateX(): Text
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.StateX());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Wrapper")
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

    procedure Pull(O: Interface "CLKH Wrap Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Wrap Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Wrap Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;

    procedure LoadVarNever(O: Interface "CLKH Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Wrap Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Wrap Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;
}

codeunit 82572 "CLKH Wrap SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Wrap Owner")
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

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;
}

codeunit 82573 "CLKH SI Wrap 01" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82574 "CLKH SI Wrap 02" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82575 "CLKH SI Wrap 03" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82576 "CLKH SI Wrap 04" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82577 "CLKH SI Wrap 05" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82578 "CLKH SI Wrap 06" implements "CLKH Wrap Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82579 "CLKH Wrap SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIWrap_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 01";
        K: Codeunit "CLKH Wrap SI Holder";
    begin
        K.Pull(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 02";
        KS: Codeunit "CLKH Wrap SI SI Holder";
    begin
        KS.Pull(O);
        KS.WriteX(3);
        KS.SetWCnt(2);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 03";
        K: Codeunit "CLKH Wrap SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 w=2');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=2');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 04";
        K: Codeunit "CLKH Wrap SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 05";
        KS: Codeunit "CLKH Wrap SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Wrap 06";
        K: Codeunit "CLKH Wrap SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;
}

codeunit 82580 "CLKH Wrap TG Holder"
{
    var
        G: Codeunit "CLQ Wrapper";
        GV: Variant;
        HCnt: Integer;

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure VWriteX(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure VSetWCnt(V: Integer)
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        C.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure VGetWCnt(): Integer
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;

    procedure VStateX(): Text
    var
        C: Codeunit "CLQ Wrapper";
    begin
        C := GV;
        exit(C.StateX());
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLQ Wrapper")
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

    procedure Pull(O: Interface "CLKH Wrap Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Wrap Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Wrap Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;

    procedure LoadVarNever(O: Interface "CLKH Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Wrap Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Wrap Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
    end;
}

codeunit 82581 "CLKH TG Wrap 01" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Wrap TG Holder";
    begin
        K.Pull(this);
        K.WriteX(3);
        K.SetWCnt(2);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82582 "CLKH Wrap TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Wrap Owner")
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

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;
}

codeunit 82583 "CLKH TG Wrap 02" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Wrap TG SI 02";
    begin
        KS.Pull(this);
        KS.WriteX(3);
        KS.SetWCnt(2);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82584 "CLKH TG Wrap 03" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Wrap TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 w=2');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=2');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82585 "CLKH TG Wrap 04" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Wrap TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82586 "CLKH Wrap TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Wrap Owner")
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

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure SetWCnt(V: Integer)
    begin
        G.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(G.GetWCnt());
    end;

    procedure StateX(): Text
    begin
        exit(G.StateX());
    end;
}

codeunit 82587 "CLKH TG Wrap 05" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Wrap TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82588 "CLKH TG Wrap 06" implements "CLKH Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Wrap TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=8 int3=0 w=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.StateX() + ' w=' + Format(X.GetWCnt()));
    end;

    procedure ShareAlias(var Y: Codeunit "CLQ Wrapper")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82589 "CLKH B2 Plain Owner"
{
    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82590 "CLKH B2 Plain Holder"
{
    var
        G: Codeunit "CLT B2 Store";
        GV: Variant;
        HCnt: Integer;

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure VWrite(I: Integer; J: Integer; V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLT B2 Store")
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

    procedure PullPlain(var O: Codeunit "CLKH B2 Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH B2 Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH B2 Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH B2 Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLKH B2 Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH B2 Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH B2 Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82591 "CLKH B2 Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH B2 Plain Owner")
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

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82592 "CLKH B2 Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainB2_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        K: Codeunit "CLKH B2 Plain Holder";
    begin
        K.PullPlain(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        KS: Codeunit "CLKH B2 Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Write(1, 1, 1);
        KS.SetInt(7);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        K: Codeunit "CLKH B2 Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=7');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=7');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        K: Codeunit "CLKH B2 Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        KS: Codeunit "CLKH B2 Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH B2 Plain Owner";
        K: Codeunit "CLKH B2 Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Verify();
    end;
}

codeunit 82593 "CLKH B2 SI Holder"
{
    var
        G: Codeunit "CLT B2 Store";
        GV: Variant;
        HCnt: Integer;

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure VWrite(I: Integer; J: Integer; V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLT B2 Store")
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

    procedure Pull(O: Interface "CLKH B2 Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH B2 Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH B2 Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH B2 Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH B2 Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82594 "CLKH B2 SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH B2 Owner")
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

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82595 "CLKH SI B2 01" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82596 "CLKH SI B2 02" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82597 "CLKH SI B2 03" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82598 "CLKH SI B2 04" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82599 "CLKH SI B2 05" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82600 "CLKH SI B2 06" implements "CLKH B2 Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82601 "CLKH B2 SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIB2_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 01";
        K: Codeunit "CLKH B2 SI Holder";
    begin
        K.Pull(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 02";
        KS: Codeunit "CLKH B2 SI SI Holder";
    begin
        KS.Pull(O);
        KS.Write(1, 1, 1);
        KS.SetInt(7);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 03";
        K: Codeunit "CLKH B2 SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=7');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=7');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 04";
        K: Codeunit "CLKH B2 SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 05";
        KS: Codeunit "CLKH B2 SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI B2 06";
        K: Codeunit "CLKH B2 SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Verify();
    end;
}

codeunit 82602 "CLKH B2 TG Holder"
{
    var
        G: Codeunit "CLT B2 Store";
        GV: Variant;
        HCnt: Integer;

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure VWrite(I: Integer; J: Integer; V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLT B2 Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLT B2 Store")
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

    procedure Pull(O: Interface "CLKH B2 Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH B2 Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH B2 Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH B2 Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH B2 Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82603 "CLKH TG B2 01" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH B2 TG Holder";
    begin
        K.Pull(this);
        K.Write(1, 1, 1);
        K.SetInt(7);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82604 "CLKH B2 TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH B2 Owner")
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

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82605 "CLKH TG B2 02" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH B2 TG SI 02";
    begin
        KS.Pull(this);
        KS.Write(1, 1, 1);
        KS.SetInt(7);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82606 "CLKH TG B2 03" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH B2 TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=7');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=7');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82607 "CLKH TG B2 04" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH B2 TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82608 "CLKH B2 TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH B2 Owner")
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

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82609 "CLKH TG B2 05" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH B2 TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82610 "CLKH TG B2 06" implements "CLKH B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH B2 TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(1, 2, V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82611 "CLKH Reg Plain Owner"
{
    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82612 "CLKH Reg Plain Holder"
{
    var
        G: Codeunit "CLR Register";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure VWriteRow(V: Integer)
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLR Register")
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

    procedure PullPlain(var O: Codeunit "CLKH Reg Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH Reg Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH Reg Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH Reg Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLKH Reg Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH Reg Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH Reg Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82613 "CLKH Reg Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH Reg Plain Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82614 "CLKH Reg Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainReg_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        K: Codeunit "CLKH Reg Plain Holder";
    begin
        K.PullPlain(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        KS: Codeunit "CLKH Reg Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Mark();
        KS.WriteRow(1);
        KS.WriteRow(2);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        K: Codeunit "CLKH Reg Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=3 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        K: Codeunit "CLKH Reg Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        KS: Codeunit "CLKH Reg Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Reg Plain Owner";
        K: Codeunit "CLKH Reg Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 82615 "CLKH Reg SI Holder"
{
    var
        G: Codeunit "CLR Register";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure VWriteRow(V: Integer)
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLR Register")
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

    procedure Pull(O: Interface "CLKH Reg Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Reg Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Reg Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Reg Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Reg Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82616 "CLKH Reg SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Reg Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82617 "CLKH SI Reg 01" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82618 "CLKH SI Reg 02" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82619 "CLKH SI Reg 03" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82620 "CLKH SI Reg 04" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82621 "CLKH SI Reg 05" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82622 "CLKH SI Reg 06" implements "CLKH Reg Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82623 "CLKH Reg SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIReg_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 01";
        K: Codeunit "CLKH Reg SI Holder";
    begin
        K.Pull(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 02";
        KS: Codeunit "CLKH Reg SI SI Holder";
    begin
        KS.Pull(O);
        KS.Mark();
        KS.WriteRow(1);
        KS.WriteRow(2);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 03";
        K: Codeunit "CLKH Reg SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=3 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 04";
        K: Codeunit "CLKH Reg SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 05";
        KS: Codeunit "CLKH Reg SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Reg 06";
        K: Codeunit "CLKH Reg SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 82624 "CLKH Reg TG Holder"
{
    var
        G: Codeunit "CLR Register";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure VWriteRow(V: Integer)
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        C.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLR Register";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLR Register")
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

    procedure Pull(O: Interface "CLKH Reg Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Reg Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Reg Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Reg Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Reg Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82625 "CLKH TG Reg 01" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Reg TG Holder";
    begin
        K.Pull(this);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82626 "CLKH Reg TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Reg Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82627 "CLKH TG Reg 02" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Reg TG SI 02";
    begin
        KS.Pull(this);
        KS.Mark();
        KS.WriteRow(1);
        KS.WriteRow(2);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82628 "CLKH TG Reg 03" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Reg TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=3 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82629 "CLKH TG Reg 04" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Reg TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82630 "CLKH Reg TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Reg Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteRow(V: Integer)
    begin
        G.WriteRow(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82631 "CLKH TG Reg 05" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Reg TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82632 "CLKH TG Reg 06" implements "CLKH Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Reg TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteRow(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLR Register")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLR Register")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82633 "CLKH Price Plain Owner"
{
    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82634 "CLKH Price Plain Holder"
{
    var
        G: Codeunit "CLV Price Store";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure VWriteT1(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLV Price Store")
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

    procedure PullPlain(var O: Codeunit "CLKH Price Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKH Price Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKH Price Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKH Price Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarPlainRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLKH Price Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKH Price Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKH Price Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarPlainNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82635 "CLKH Price Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKH Price Plain Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82636 "CLKH Price Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainPrice_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        K: Codeunit "CLKH Price Plain Holder";
    begin
        K.PullPlain(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        KS: Codeunit "CLKH Price Plain SI Holder";
    begin
        KS.PullPlain(O);
        KS.Mark();
        KS.WriteT1(3);
        KS.SetInt(6);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        K: Codeunit "CLKH Price Plain Holder";
    begin
        K.FillVarPlainRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=Beta int=6 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=2 kind=Beta int=6 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        K: Codeunit "CLKH Price Plain Holder";
    begin
        K.PullPlain(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        KS: Codeunit "CLKH Price Plain SI Holder";
    begin
        KS.PullPlain(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH Price Plain Owner";
        K: Codeunit "CLKH Price Plain Holder";
    begin
        K.FillVarPlainNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=1 kind=None int=0 lc=store label');
        Observer.Verify();
    end;
}

codeunit 82637 "CLKH Price SI Holder"
{
    var
        G: Codeunit "CLV Price Store";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure VWriteT1(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLV Price Store")
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

    procedure Pull(O: Interface "CLKH Price Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Price Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Price Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Price Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Price Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82638 "CLKH Price SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Price Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82639 "CLKH SI Price 01" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82640 "CLKH SI Price 02" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82641 "CLKH SI Price 03" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82642 "CLKH SI Price 04" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82643 "CLKH SI Price 05" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82644 "CLKH SI Price 06" implements "CLKH Price Owner"
{
    SingleInstance = true;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82645 "CLKH Price SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIPrice_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 01";
        K: Codeunit "CLKH Price SI Holder";
    begin
        K.Pull(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 02";
        KS: Codeunit "CLKH Price SI SI Holder";
    begin
        KS.Pull(O);
        KS.Mark();
        KS.WriteT1(3);
        KS.SetInt(6);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 03";
        K: Codeunit "CLKH Price SI Holder";
    begin
        K.FillVarRows(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=Beta int=6 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=2 kind=Beta int=6 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 04";
        K: Codeunit "CLKH Price SI Holder";
    begin
        K.Pull(O);
        O.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 05";
        KS: Codeunit "CLKH Price SI SI Holder";
    begin
        KS.Pull(O);
        O.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKH SI Price 06";
        K: Codeunit "CLKH Price SI Holder";
    begin
        K.FillVarNever(O);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        O.WriteX(8);
        Observer.Observe('owner after owner write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=1 kind=None int=0 lc=store label');
        Observer.Verify();
    end;
}

codeunit 82646 "CLKH Price TG Holder"
{
    var
        G: Codeunit "CLV Price Store";
        GV: Variant;
        HCnt: Integer;

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure VWriteT1(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure VSetInt(V: Integer)
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        C.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;

    procedure VState(): Text
    var
        C: Codeunit "CLV Price Store";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure SetStore(var NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLV Price Store")
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

    procedure Pull(O: Interface "CLKH Price Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure LoadVarRows(O: Interface "CLKH Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKH Price Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKH Price Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure LoadVarNever(O: Interface "CLKH Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKH Price Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKH Price Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 82647 "CLKH TG Price 01" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Price TG Holder";
    begin
        K.Pull(this);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82648 "CLKH Price TG SI 02"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Price Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82649 "CLKH TG Price 02" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaSIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Price TG SI 02";
    begin
        KS.Pull(this);
        KS.Mark();
        KS.WriteT1(3);
        KS.SetInt(6);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82650 "CLKH TG Price 03" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaVariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Price TG Holder";
    begin
        K.FillVarRows(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 't1=1 kind=Beta int=6 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=2 kind=Beta int=6 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82651 "CLKH TG Price 04" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Price TG Holder";
    begin
        K.Pull(this);
        this.SetCnt(4);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', K.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82652 "CLKH Price TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKH Price Owner")
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

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure WriteT1(V: Integer)
    begin
        G.WriteT1(V);
    end;

    procedure SetInt(V: Integer)
    begin
        G.SetInt(V);
    end;

    procedure State(): Text
    begin
        exit(G.State());
    end;
}

codeunit 82653 "CLKH TG Price 05" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaSIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        KS: Codeunit "CLKH Price TG SI 05";
    begin
        KS.Pull(this);
        this.SetCnt(4);
        KS.SetHCnt(9);
        KS.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(KS.GetHCnt()));
        Observer.Observe('holder', KS.State());
        KS.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(8);
        Observer.Observe('holder after owner write', KS.State());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 82654 "CLKH TG Price 06" implements "CLKH Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_HcaVariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKH Price TG Holder";
    begin
        K.FillVarNever(this);
        K.SetHCnt(9);
        K.ClearAllSelf();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder cnt', Format(K.GetHCnt()));
        this.WriteX(8);
        Observer.Observe('owner after owner write', this.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '4');
        Observer.Expect('holder cnt', '0');
        Observer.Expect('owner after owner write', 't1=1 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    procedure WriteX(V: Integer)
    begin
        X.WriteT1(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLV Price Store")
    begin
        Y := X;
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        X := NewS;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}
