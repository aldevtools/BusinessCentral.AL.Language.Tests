// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the stores "CLX Store" / "CLX IStore" (ClearSharedCodeunit.al),
//   "CLB Store" / "CLB IStore" (ClearSharedCodeunitTempRef.al), "CLS Arr Store" (ClearSharedCodeunitSIOwner.al),
//   "CLQ Store Plus" and "CLQ Wrapper" (ClearSharedCodeunitOwnerKinds.al), "CLR Register"
//   (ClearSharedCodeunitSetterOwner.al), "CLT B2 Store" (ClearSharedCodeunitTempArrayShare.al) and "CLV Price Store"
//   (ClearSharedCodeunitStoreShapes.al); self-contained objects 82157 to 82437.
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Owners (as ClearSharedCodeunitOwnerSlotsCLB.al): globals X (the store) and Cnt; procedures WriteX, StateX,
//   ShareAlias (var getter), SetStore, SetStoreByVal, ClearAllGlobals (ClearAll), SetCnt, GetCnt.
//   Plain: one owner object per store, a fresh local per test. SI: a SingleInstance owner of its own per test.
//   TG: the test codeunit itself is the owner, one test each. Test names are <Owner><Store>_<Cell>_<State>.
// States: Rows / Written (the holder wrote the store before ClearAll) and Never (no call on the store at all
//   before ClearAll; only the owner's Cnt was set).
// Facts: ClearAll in the owner while TWO more variables share the store's instance. The first holder is the slot
//   of ClearSharedCodeunitOwnerSlots*.al (OtherGlobal, VarParam, ByValPassed, VariantLocal, IfaceLocal) and the
//   second a test-local alias Y2 taken by the owner's var getter before the first; TwoGlobalPair holds the store in
//   the global of a plain codeunit and of a SingleInstance codeunit at once. After the reads of the one-holder cell,
//   the test reads Y2, writes through Y2 and reads the owner. ByValPassed is the one-holder reference cell.
// Result (BC 29.0): every cell gives the answer of the one-holder by-value cell: ClearAll resets the one
//   instance in place; the owner, the first holder and Y2 read the reset store (temporary rows kept), and a write
//   through any of the three shows in the others. Same for every store, owner and state.
// BC versions: 27, 28, 29

interface "CLKT CLX Owner"
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

interface "CLKT CLB Owner"
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

interface "CLKT Arr Owner"
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

interface "CLKT Plus Owner"
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

interface "CLKT Wrap Owner"
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

interface "CLKT B2 Owner"
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

interface "CLKT Reg Owner"
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

interface "CLKT Price Owner"
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

codeunit 82157 "CLKT CLX Plain Owner"
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

codeunit 82158 "CLKT CLX Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT CLX Plain Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByValPlain(var O: Codeunit "CLKT CLX Plain Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfacePlain(var O: Codeunit "CLKT CLX Plain Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValPlain(var O: Codeunit "CLKT CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainWritten(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadVarPlainWritten(O, GV);
    end;

    procedure KeepVarPlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictPlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfacePlainWritten(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadIfacePlainWritten(O, GI);
    end;

    procedure FillListPlainWritten(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadListPlainWritten(O, GL);
    end;

    procedure FillDictPlainWritten(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadDictPlainWritten(O, GD);
    end;

    procedure KeepIfacePlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainWritten(var O: Codeunit "CLKT CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLKT CLX Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLKT CLX Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLKT CLX Plain Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82159 "CLKT CLX Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT CLX Plain Owner")
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

codeunit 82160 "CLKT CLX Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLX_TwoOtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoVariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoIfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfacePlainWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoGlobalPair_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        KS: Codeunit "CLKT CLX Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
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
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX Plain Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLX_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLX Plain Owner";
        K: Codeunit "CLKT CLX Plain Holder";
        KS: Codeunit "CLKT CLX Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;
}

codeunit 82161 "CLKT CLX SI Holder"
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

    procedure Pull(O: Interface "CLKT CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT CLX Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIface(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarWritten(O: Interface "CLKT CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceWritten(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLKT CLX Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictWritten(O: Interface "CLKT CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfaceWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillWritten(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKT CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKT CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKT CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKT CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKT CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82162 "CLKT CLX SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLX Owner")
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

codeunit 82163 "CLKT SI CLX 01" implements "CLKT CLX Owner"
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

codeunit 82164 "CLKT SI CLX 02" implements "CLKT CLX Owner"
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

codeunit 82165 "CLKT SI CLX 03" implements "CLKT CLX Owner"
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

codeunit 82166 "CLKT SI CLX 04" implements "CLKT CLX Owner"
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

codeunit 82167 "CLKT SI CLX 05" implements "CLKT CLX Owner"
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

codeunit 82168 "CLKT SI CLX 06" implements "CLKT CLX Owner"
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

codeunit 82169 "CLKT SI CLX 07" implements "CLKT CLX Owner"
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

codeunit 82170 "CLKT SI CLX 08" implements "CLKT CLX Owner"
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

codeunit 82171 "CLKT SI CLX 09" implements "CLKT CLX Owner"
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

codeunit 82172 "CLKT SI CLX 10" implements "CLKT CLX Owner"
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

codeunit 82173 "CLKT SI CLX 11" implements "CLKT CLX Owner"
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

codeunit 82174 "CLKT SI CLX 12" implements "CLKT CLX Owner"
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

codeunit 82175 "CLKT CLX SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLX_TwoOtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 01";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 02";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 03";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoVariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 04";
        K: Codeunit "CLKT CLX SI Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoIfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 05";
        K: Codeunit "CLKT CLX SI Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfaceWritten(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoGlobalPair_Written()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 06";
        K: Codeunit "CLKT CLX SI Holder";
        KS: Codeunit "CLKT CLX SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
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
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 07";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 08";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 09";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX SI Holder";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 10";
        K: Codeunit "CLKT CLX SI Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 11";
        K: Codeunit "CLKT CLX SI Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SICLX_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLX 12";
        K: Codeunit "CLKT CLX SI Holder";
        KS: Codeunit "CLKT CLX SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
        Observer.Verify();
    end;
}

codeunit 82176 "CLKT CLX TG Holder"
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

    procedure Pull(O: Interface "CLKT CLX Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT CLX Owner"; var Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT CLX Owner"; Y: Codeunit "CLX Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIface(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarWritten(O: Interface "CLKT CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadVarWritten(O, GV);
    end;

    procedure KeepVarWritten(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceWritten(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        Y.Set(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListWritten(O: Interface "CLKT CLX Owner"; var L: List of [Interface "CLX IStore"])
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

    procedure LoadDictWritten(O: Interface "CLKT CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
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

    procedure FillIfaceWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadIfaceWritten(O, GI);
    end;

    procedure FillListWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadListWritten(O, GL);
    end;

    procedure FillDictWritten(O: Interface "CLKT CLX Owner")
    begin
        LoadDictWritten(O, GD);
    end;

    procedure KeepIfaceWritten(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillWritten(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT CLX Owner"; var V: Variant)
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT CLX Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKT CLX Owner"; var I: Interface "CLX IStore")
    var
        Y: Codeunit "CLX Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKT CLX Owner"; var L: List of [Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKT CLX Owner"; var D: Dictionary of [Integer, Interface "CLX IStore"])
    var
        Y: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKT CLX Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKT CLX Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKT CLX Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKT CLX Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKT CLX Owner"; I: Interface "CLX IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82177 "CLKT TG CLX 01" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoOtherGlobal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82178 "CLKT TG CLX 02" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoVarParam_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82179 "CLKT TG CLX 03" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoByValPassed_Written()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Set(3);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82180 "CLKT TG CLX 04" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoVariantLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82181 "CLKT TG CLX 05" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoIfaceLocal_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        K.LoadIfaceWritten(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82182 "CLKT CLX TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLX Owner")
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

codeunit 82183 "CLKT TG CLX 06" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoGlobalPair_Written()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        KS: Codeunit "CLKT CLX TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
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
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82184 "CLKT TG CLX 07" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82185 "CLKT TG CLX 08" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82186 "CLKT TG CLX 09" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLX Store";
        K: Codeunit "CLKT CLX TG Holder";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Format(Y.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('caller holder after return', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82187 "CLKT TG CLX 10" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        V: Variant;
        C: Codeunit "CLX Store";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82188 "CLKT TG CLX 11" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        I: Interface "CLX IStore";
        Y2: Codeunit "CLX Store";
    begin
        this.ShareAlias(Y2);
        K.LoadIfaceNever(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(I.Get()));
        I.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(I.Get()));
        Observer.Observe('second holder', Format(Y2.Get()));
        Y2.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82189 "CLKT CLX TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLX Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLX Owner")
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

codeunit 82190 "CLKT TG CLX 12" implements "CLKT CLX Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLX Store";
        Cnt: Integer;

    [Test]
    procedure TGCLX_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLX TG Holder";
        KS: Codeunit "CLKT CLX TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', Format(K.Get()));
        K.Set(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', Format(K.Get()));
        Observer.Observe('second holder', Format(KS.Get()));
        KS.Set(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', '0');
        Observer.Expect('owner after holder write', '5');
        Observer.Expect('holder after owner write', '7');
        Observer.Expect('second holder', '7');
        Observer.Expect('owner after second holder write', '9');
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

codeunit 82191 "CLKT CLB Plain Owner"
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

codeunit 82192 "CLKT CLB Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT CLB Plain Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByValPlain(var O: Codeunit "CLKT CLB Plain Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfacePlain(var O: Codeunit "CLKT CLB Plain Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValPlain(var O: Codeunit "CLKT CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictPlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfacePlainRows(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadIfacePlainRows(O, GI);
    end;

    procedure FillListPlainRows(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadListPlainRows(O, GL);
    end;

    procedure FillDictPlainRows(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadDictPlainRows(O, GD);
    end;

    procedure KeepIfacePlainRows(var O: Codeunit "CLKT CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainRows(var O: Codeunit "CLKT CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfacePlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLKT CLB Plain Owner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLKT CLB Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLKT CLB Plain Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82193 "CLKT CLB Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT CLB Plain Owner")
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

codeunit 82194 "CLKT CLB Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainCLB_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoIfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfacePlainRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        KS: Codeunit "CLKT CLB Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB Plain Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfacePlainNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCLB_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT CLB Plain Owner";
        K: Codeunit "CLKT CLB Plain Holder";
        KS: Codeunit "CLKT CLB Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;
}

codeunit 82195 "CLKT CLB SI Holder"
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

    procedure Pull(O: Interface "CLKT CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT CLB Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIface(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKT CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceRows(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLKT CLB Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictRows(O: Interface "CLKT CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfaceRows(O: Interface "CLKT CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLKT CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLKT CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillRows(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKT CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKT CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKT CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKT CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKT CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82196 "CLKT CLB SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLB Owner")
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

codeunit 82197 "CLKT SI CLB 01" implements "CLKT CLB Owner"
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

codeunit 82198 "CLKT SI CLB 02" implements "CLKT CLB Owner"
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

codeunit 82199 "CLKT SI CLB 03" implements "CLKT CLB Owner"
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

codeunit 82200 "CLKT SI CLB 04" implements "CLKT CLB Owner"
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

codeunit 82201 "CLKT SI CLB 05" implements "CLKT CLB Owner"
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

codeunit 82202 "CLKT SI CLB 06" implements "CLKT CLB Owner"
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

codeunit 82203 "CLKT SI CLB 07" implements "CLKT CLB Owner"
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

codeunit 82204 "CLKT SI CLB 08" implements "CLKT CLB Owner"
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

codeunit 82205 "CLKT SI CLB 09" implements "CLKT CLB Owner"
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

codeunit 82206 "CLKT SI CLB 10" implements "CLKT CLB Owner"
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

codeunit 82207 "CLKT SI CLB 11" implements "CLKT CLB Owner"
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

codeunit 82208 "CLKT SI CLB 12" implements "CLKT CLB Owner"
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

codeunit 82209 "CLKT CLB SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SICLB_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 01";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 02";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 03";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 04";
        K: Codeunit "CLKT CLB SI Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoIfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 05";
        K: Codeunit "CLKT CLB SI Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 06";
        K: Codeunit "CLKT CLB SI Holder";
        KS: Codeunit "CLKT CLB SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 07";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 08";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 09";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB SI Holder";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 10";
        K: Codeunit "CLKT CLB SI Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 11";
        K: Codeunit "CLKT CLB SI Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y2);
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure SICLB_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI CLB 12";
        K: Codeunit "CLKT CLB SI Holder";
        KS: Codeunit "CLKT CLB SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;
}

codeunit 82210 "CLKT CLB TG Holder"
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

    procedure Pull(O: Interface "CLKT CLB Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT CLB Owner"; var Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT CLB Owner"; Y: Codeunit "CLB Store"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIface(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByVal(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKT CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT CLB Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceRows(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(O: Interface "CLKT CLB Owner"; var L: List of [Interface "CLB IStore"])
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

    procedure LoadDictRows(O: Interface "CLKT CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
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

    procedure FillIfaceRows(O: Interface "CLKT CLB Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(O: Interface "CLKT CLB Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(O: Interface "CLKT CLB Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillRows(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT CLB Owner"; var V: Variant)
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT CLB Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadIfaceNever(O: Interface "CLKT CLB Owner"; var I: Interface "CLB IStore")
    var
        Y: Codeunit "CLB Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(O: Interface "CLKT CLB Owner"; var L: List of [Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(O: Interface "CLKT CLB Owner"; var D: Dictionary of [Integer, Interface "CLB IStore"])
    var
        Y: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(O: Interface "CLKT CLB Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(O: Interface "CLKT CLB Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(O: Interface "CLKT CLB Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(O: Interface "CLKT CLB Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaIfaceByValFillNever(O: Interface "CLKT CLB Owner"; I: Interface "CLB IStore"; var Observer: Codeunit "Probe Observer")
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

codeunit 82211 "CLKT TG CLB 01" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82212 "CLKT TG CLB 02" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82213 "CLKT TG CLB 03" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(3);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82214 "CLKT TG CLB 04" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82215 "CLKT TG CLB 05" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoIfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        K.LoadIfaceRows(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82216 "CLKT CLB TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLB Owner")
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

codeunit 82217 "CLKT TG CLB 06" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        KS: Codeunit "CLKT CLB TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82218 "CLKT TG CLB 07" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82219 "CLKT TG CLB 08" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82220 "CLKT TG CLB 09" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
        K: Codeunit "CLKT CLB TG Holder";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82221 "CLKT TG CLB 10" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        V: Variant;
        C: Codeunit "CLB Store";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82222 "CLKT TG CLB 11" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoIfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        I: Interface "CLB IStore";
        Y2: Codeunit "CLB Store";
    begin
        this.ShareAlias(Y2);
        K.LoadIfaceNever(this, I);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82223 "CLKT CLB TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLB Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT CLB Owner")
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

codeunit 82224 "CLKT TG CLB 12" implements "CLKT CLB Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    [Test]
    procedure TGCLB_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT CLB TG Holder";
        KS: Codeunit "CLKT CLB TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
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

codeunit 82225 "CLKT Arr Plain Owner"
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

codeunit 82226 "CLKT Arr Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT Arr Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT Arr Plain Owner"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKT Arr Plain Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKT Arr Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKT Arr Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT Arr Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT Arr Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT Arr Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT Arr Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82227 "CLKT Arr Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT Arr Plain Owner")
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

codeunit 82228 "CLKT Arr Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainArr_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
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
    procedure PlainArr_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        KS: Codeunit "CLKT Arr Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
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
    procedure PlainArr_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr Plain Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure PlainArr_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Arr Plain Owner";
        K: Codeunit "CLKT Arr Plain Holder";
        KS: Codeunit "CLKT Arr Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;
}

codeunit 82229 "CLKT Arr SI Holder"
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

    procedure Pull(O: Interface "CLKT Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Arr Owner"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Arr Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Arr Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82230 "CLKT Arr SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Arr Owner")
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

codeunit 82231 "CLKT SI Arr 01" implements "CLKT Arr Owner"
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

codeunit 82232 "CLKT SI Arr 02" implements "CLKT Arr Owner"
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

codeunit 82233 "CLKT SI Arr 03" implements "CLKT Arr Owner"
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

codeunit 82234 "CLKT SI Arr 04" implements "CLKT Arr Owner"
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

codeunit 82235 "CLKT SI Arr 05" implements "CLKT Arr Owner"
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

codeunit 82236 "CLKT SI Arr 06" implements "CLKT Arr Owner"
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

codeunit 82237 "CLKT SI Arr 07" implements "CLKT Arr Owner"
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

codeunit 82238 "CLKT SI Arr 08" implements "CLKT Arr Owner"
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

codeunit 82239 "CLKT SI Arr 09" implements "CLKT Arr Owner"
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

codeunit 82240 "CLKT SI Arr 10" implements "CLKT Arr Owner"
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

codeunit 82241 "CLKT SI Arr 11" implements "CLKT Arr Owner"
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

codeunit 82242 "CLKT SI Arr 12" implements "CLKT Arr Owner"
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

codeunit 82243 "CLKT Arr SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIArr_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 01";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
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
    procedure SIArr_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 02";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
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
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 03";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 04";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 05";
        K: Codeunit "CLKT Arr SI Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 06";
        K: Codeunit "CLKT Arr SI Holder";
        KS: Codeunit "CLKT Arr SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        K.Write(1, 3);
        K.Write(2, 4);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 07";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
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
    procedure SIArr_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 08";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 09";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 10";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr SI Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 11";
        K: Codeunit "CLKT Arr SI Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;

    [Test]
    procedure SIArr_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Arr 12";
        K: Codeunit "CLKT Arr SI Holder";
        KS: Codeunit "CLKT Arr SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
        Observer.Verify();
    end;
}

codeunit 82244 "CLKT Arr TG Holder"
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

    procedure Pull(O: Interface "CLKT Arr Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Arr Owner"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Arr Owner"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Arr Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Arr Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Arr Owner"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Arr Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Arr Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82245 "CLKT TG Arr 01" implements "CLKT Arr Owner"
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
        K: Codeunit "CLKT Arr TG Holder";
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

codeunit 82246 "CLKT TG Arr 02" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
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
        this.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
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

codeunit 82247 "CLKT TG Arr 03" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
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

codeunit 82248 "CLKT TG Arr 04" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
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

codeunit 82249 "CLKT TG Arr 05" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
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

codeunit 82250 "CLKT Arr TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Arr Owner")
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

codeunit 82251 "CLKT TG Arr 06" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        KS: Codeunit "CLKT Arr TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
        K.Write(1, 3);
        K.Write(2, 4);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=5 rows2=5 ref1=75586 refrows=3 int1=9');
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

codeunit 82252 "CLKT TG Arr 07" implements "CLKT Arr Owner"
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
        K: Codeunit "CLKT Arr TG Holder";
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

codeunit 82253 "CLKT TG Arr 08" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
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

codeunit 82254 "CLKT TG Arr 09" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
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

codeunit 82255 "CLKT TG Arr 10" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLKT Arr TG Holder";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
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

codeunit 82256 "CLKT TG Arr 11" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
        Y2: Codeunit "CLS Arr Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
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

codeunit 82257 "CLKT Arr TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Arr Owner")
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

codeunit 82258 "CLKT TG Arr 12" implements "CLKT Arr Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLS Arr Store";
        Cnt: Integer;

    [Test]
    procedure TGArr_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Arr TG Holder";
        KS: Codeunit "CLKT Arr TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(6);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('second holder', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('owner after second holder write', 'rows1=3 rows2=3 ref1=75586 refrows=3 int1=9');
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

codeunit 82259 "CLKT Plus Plain Owner"
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

codeunit 82260 "CLKT Plus Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT Plus Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT Plus Plain Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByValPlain(var O: Codeunit "CLKT Plus Plain Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainRows(var O: Codeunit "CLKT Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKT Plus Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT Plus Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT Plus Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT Plus Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82261 "CLKT Plus Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT Plus Plain Owner")
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

codeunit 82262 "CLKT Plus Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainPlus_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        KS: Codeunit "CLKT Plus Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus Plain Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPlus_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Plus Plain Owner";
        K: Codeunit "CLKT Plus Plain Holder";
        KS: Codeunit "CLKT Plus Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82263 "CLKT Plus SI Holder"
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

    procedure Pull(O: Interface "CLKT Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Plus Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKT Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Plus Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Plus Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82264 "CLKT Plus SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Plus Owner")
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

codeunit 82265 "CLKT SI Plus 01" implements "CLKT Plus Owner"
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

codeunit 82266 "CLKT SI Plus 02" implements "CLKT Plus Owner"
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

codeunit 82267 "CLKT SI Plus 03" implements "CLKT Plus Owner"
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

codeunit 82268 "CLKT SI Plus 04" implements "CLKT Plus Owner"
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

codeunit 82269 "CLKT SI Plus 05" implements "CLKT Plus Owner"
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

codeunit 82270 "CLKT SI Plus 06" implements "CLKT Plus Owner"
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

codeunit 82271 "CLKT SI Plus 07" implements "CLKT Plus Owner"
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

codeunit 82272 "CLKT SI Plus 08" implements "CLKT Plus Owner"
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

codeunit 82273 "CLKT SI Plus 09" implements "CLKT Plus Owner"
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

codeunit 82274 "CLKT SI Plus 10" implements "CLKT Plus Owner"
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

codeunit 82275 "CLKT Plus SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIPlus_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 01";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 02";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 03";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 04";
        K: Codeunit "CLKT Plus SI Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 05";
        K: Codeunit "CLKT Plus SI Holder";
        KS: Codeunit "CLKT Plus SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 06";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 07";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 08";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus SI Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 09";
        K: Codeunit "CLKT Plus SI Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIPlus_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Plus 10";
        K: Codeunit "CLKT Plus SI Holder";
        KS: Codeunit "CLKT Plus SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 82276 "CLKT Plus TG Holder"
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

    procedure Pull(O: Interface "CLKT Plus Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Plus Owner"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure ViaByVal(O: Interface "CLKT Plus Owner"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(O: Interface "CLKT Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Plus Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Plus Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Plus Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Plus Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Plus Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82277 "CLKT TG Plus 01" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82278 "CLKT TG Plus 02" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82279 "CLKT TG Plus 03" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82280 "CLKT TG Plus 04" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82281 "CLKT Plus TG SI 05"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Plus Owner")
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

codeunit 82282 "CLKT TG Plus 05" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        KS: Codeunit "CLKT Plus TG SI 05";
    begin
        K.Pull(this);
        KS.Pull(this);
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
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82283 "CLKT TG Plus 06" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82284 "CLKT TG Plus 07" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82285 "CLKT TG Plus 08" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLKT Plus TG Holder";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82286 "CLKT TG Plus 09" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
        Y2: Codeunit "CLQ Store Plus";
    begin
        this.ShareAlias(Y2);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82287 "CLKT Plus TG SI 10"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Plus Owner")
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

codeunit 82288 "CLKT TG Plus 10" implements "CLKT Plus Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Store Plus";
        Cnt: Integer;

    [Test]
    procedure TGPlus_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Plus TG Holder";
        KS: Codeunit "CLKT Plus TG SI 10";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 n=0');
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

codeunit 82289 "CLKT Wrap Plain Owner"
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

codeunit 82290 "CLKT Wrap Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT Wrap Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT Wrap Plain Owner"; var Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKT Wrap Plain Owner"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKT Wrap Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKT Wrap Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT Wrap Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT Wrap Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT Wrap Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT Wrap Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82291 "CLKT Wrap Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT Wrap Plain Owner")
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

codeunit 82292 "CLKT Wrap Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainWrap_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainRows(O, V);
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
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        KS: Codeunit "CLKT Wrap Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap Plain Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainNever(O, V);
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
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainWrap_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Wrap Plain Owner";
        K: Codeunit "CLKT Wrap Plain Holder";
        KS: Codeunit "CLKT Wrap Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;
}

codeunit 82293 "CLKT Wrap SI Holder"
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

    procedure Pull(O: Interface "CLKT Wrap Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Wrap Owner"; var Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure ViaByVal(O: Interface "CLKT Wrap Owner"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure LoadVarRows(O: Interface "CLKT Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Wrap Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Wrap Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Wrap Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Wrap Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82294 "CLKT Wrap SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Wrap Owner")
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

codeunit 82295 "CLKT SI Wrap 01" implements "CLKT Wrap Owner"
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

codeunit 82296 "CLKT SI Wrap 02" implements "CLKT Wrap Owner"
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

codeunit 82297 "CLKT SI Wrap 03" implements "CLKT Wrap Owner"
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

codeunit 82298 "CLKT SI Wrap 04" implements "CLKT Wrap Owner"
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

codeunit 82299 "CLKT SI Wrap 05" implements "CLKT Wrap Owner"
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

codeunit 82300 "CLKT SI Wrap 06" implements "CLKT Wrap Owner"
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

codeunit 82301 "CLKT SI Wrap 07" implements "CLKT Wrap Owner"
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

codeunit 82302 "CLKT SI Wrap 08" implements "CLKT Wrap Owner"
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

codeunit 82303 "CLKT SI Wrap 09" implements "CLKT Wrap Owner"
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

codeunit 82304 "CLKT SI Wrap 10" implements "CLKT Wrap Owner"
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

codeunit 82305 "CLKT SI Wrap 11" implements "CLKT Wrap Owner"
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

codeunit 82306 "CLKT SI Wrap 12" implements "CLKT Wrap Owner"
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

codeunit 82307 "CLKT Wrap SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIWrap_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 01";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 02";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 03";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 04";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 05";
        K: Codeunit "CLKT Wrap SI Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.LoadVarRows(O, V);
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
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 06";
        K: Codeunit "CLKT Wrap SI Holder";
        KS: Codeunit "CLKT Wrap SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        K.WriteX(3);
        K.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 07";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 08";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 09";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 10";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap SI Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 11";
        K: Codeunit "CLKT Wrap SI Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y2);
        K.LoadVarNever(O, V);
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
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIWrap_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Wrap 12";
        K: Codeunit "CLKT Wrap SI Holder";
        KS: Codeunit "CLKT Wrap SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
        Observer.Verify();
    end;
}

codeunit 82308 "CLKT Wrap TG Holder"
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

    procedure Pull(O: Interface "CLKT Wrap Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Wrap Owner"; var Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure ViaByVal(O: Interface "CLKT Wrap Owner"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
    end;

    procedure LoadVarRows(O: Interface "CLKT Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT Wrap Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Wrap Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Wrap Owner"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Wrap Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Wrap Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82309 "CLKT TG Wrap 01" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
    begin
        this.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
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

codeunit 82310 "CLKT TG Wrap 02" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        K.WriteX(3);
        K.SetWCnt(2);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82311 "CLKT TG Wrap 03" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82312 "CLKT TG Wrap 04" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82313 "CLKT TG Wrap 05" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82314 "CLKT Wrap TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Wrap Owner")
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

codeunit 82315 "CLKT TG Wrap 06" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        KS: Codeunit "CLKT Wrap TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
        K.WriteX(3);
        K.SetWCnt(2);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82316 "CLKT TG Wrap 07" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
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

codeunit 82317 "CLKT TG Wrap 08" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82318 "CLKT TG Wrap 09" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82319 "CLKT TG Wrap 10" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLKT Wrap TG Holder";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX() + ' w=' + Format(Y.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82320 "CLKT TG Wrap 11" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Y2: Codeunit "CLQ Wrapper";
    begin
        this.ShareAlias(Y2);
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX() + ' w=' + Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX() + ' w=' + Format(C.GetWCnt()));
        Observer.Observe('second holder', Y2.StateX() + ' w=' + Format(Y2.GetWCnt()));
        Y2.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82321 "CLKT Wrap TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Wrap Owner")
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

codeunit 82322 "CLKT TG Wrap 12" implements "CLKT Wrap Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    [Test]
    procedure TGWrap_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Wrap TG Holder";
        KS: Codeunit "CLKT Wrap TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.StateX() + ' w=' + Format(K.GetWCnt()));
        K.WriteX(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.StateX() + ' w=' + Format(K.GetWCnt()));
        Observer.Observe('second holder', KS.StateX() + ' w=' + Format(KS.GetWCnt()));
        KS.WriteX(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 w=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 w=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('second holder', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 w=0');
        Observer.Expect('owner after second holder write', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0 w=0');
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

codeunit 82323 "CLKT B2 Plain Owner"
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

codeunit 82324 "CLKT B2 Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT B2 Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT B2 Plain Owner"; var Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKT B2 Plain Owner"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKT B2 Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLKT B2 Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT B2 Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT B2 Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT B2 Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT B2 Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82325 "CLKT B2 Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT B2 Plain Owner")
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

codeunit 82326 "CLKT B2 Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainB2_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        KS: Codeunit "CLKT B2 Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 Plain Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainB2_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT B2 Plain Owner";
        K: Codeunit "CLKT B2 Plain Holder";
        KS: Codeunit "CLKT B2 Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;
}

codeunit 82327 "CLKT B2 SI Holder"
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

    procedure Pull(O: Interface "CLKT B2 Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT B2 Owner"; var Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT B2 Owner"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT B2 Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT B2 Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT B2 Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT B2 Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82328 "CLKT B2 SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT B2 Owner")
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

codeunit 82329 "CLKT SI B2 01" implements "CLKT B2 Owner"
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

codeunit 82330 "CLKT SI B2 02" implements "CLKT B2 Owner"
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

codeunit 82331 "CLKT SI B2 03" implements "CLKT B2 Owner"
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

codeunit 82332 "CLKT SI B2 04" implements "CLKT B2 Owner"
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

codeunit 82333 "CLKT SI B2 05" implements "CLKT B2 Owner"
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

codeunit 82334 "CLKT SI B2 06" implements "CLKT B2 Owner"
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

codeunit 82335 "CLKT SI B2 07" implements "CLKT B2 Owner"
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

codeunit 82336 "CLKT SI B2 08" implements "CLKT B2 Owner"
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

codeunit 82337 "CLKT SI B2 09" implements "CLKT B2 Owner"
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

codeunit 82338 "CLKT SI B2 10" implements "CLKT B2 Owner"
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

codeunit 82339 "CLKT SI B2 11" implements "CLKT B2 Owner"
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

codeunit 82340 "CLKT SI B2 12" implements "CLKT B2 Owner"
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

codeunit 82341 "CLKT B2 SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIB2_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 01";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 02";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 03";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 04";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 05";
        K: Codeunit "CLKT B2 SI Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 06";
        K: Codeunit "CLKT B2 SI Holder";
        KS: Codeunit "CLKT B2 SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        K.Write(1, 1, 1);
        K.SetInt(7);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 07";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 08";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 09";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 10";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 SI Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 11";
        K: Codeunit "CLKT B2 SI Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIB2_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI B2 12";
        K: Codeunit "CLKT B2 SI Holder";
        KS: Codeunit "CLKT B2 SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;
}

codeunit 82342 "CLKT B2 TG Holder"
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

    procedure Pull(O: Interface "CLKT B2 Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT B2 Owner"; var Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT B2 Owner"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(O: Interface "CLKT B2 Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT B2 Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT B2 Owner"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT B2 Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT B2 Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82343 "CLKT TG B2 01" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82344 "CLKT TG B2 02" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        K.Write(1, 1, 1);
        K.SetInt(7);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
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

codeunit 82345 "CLKT TG B2 03" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
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

codeunit 82346 "CLKT TG B2 04" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
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

codeunit 82347 "CLKT TG B2 05" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
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

codeunit 82348 "CLKT B2 TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT B2 Owner")
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

codeunit 82349 "CLKT TG B2 06" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        KS: Codeunit "CLKT B2 TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
        K.Write(1, 1, 1);
        K.SetInt(7);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('second holder', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('owner after second holder write', 'b11=4 b12=4 b21=4 b22=4 int1=0');
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

codeunit 82363 "CLKT TG B2 07" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
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

codeunit 82364 "CLKT TG B2 08" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82365 "CLKT TG B2 09" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82366 "CLKT TG B2 10" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLKT B2 TG Holder";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82367 "CLKT TG B2 11" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
        Y2: Codeunit "CLT B2 Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82368 "CLKT B2 TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT B2 Owner")
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

codeunit 82369 "CLKT TG B2 12" implements "CLKT B2 Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    [Test]
    procedure TGB2_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT B2 TG Holder";
        KS: Codeunit "CLKT B2 TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.Write(2, 2, 2);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(3);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.Write(2, 1, 9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('second holder', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('owner after second holder write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
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

codeunit 82370 "CLKT Reg Plain Owner"
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

codeunit 82371 "CLKT Reg Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT Reg Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT Reg Plain Owner"; var Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKT Reg Plain Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKT Reg Plain Owner"; var V: Variant)
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

    procedure FillVarPlainRows(var O: Codeunit "CLKT Reg Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT Reg Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT Reg Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT Reg Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT Reg Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82372 "CLKT Reg Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT Reg Plain Owner")
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

codeunit 82373 "CLKT Reg Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainReg_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        KS: Codeunit "CLKT Reg Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg Plain Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReg_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Reg Plain Owner";
        K: Codeunit "CLKT Reg Plain Holder";
        KS: Codeunit "CLKT Reg Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 82374 "CLKT Reg SI Holder"
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

    procedure Pull(O: Interface "CLKT Reg Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Reg Owner"; var Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Reg Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Reg Owner"; var V: Variant)
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

    procedure FillVarRows(O: Interface "CLKT Reg Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Reg Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Reg Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Reg Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82375 "CLKT Reg SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Reg Owner")
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

codeunit 82376 "CLKT SI Reg 01" implements "CLKT Reg Owner"
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

codeunit 82377 "CLKT SI Reg 02" implements "CLKT Reg Owner"
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

codeunit 82378 "CLKT SI Reg 03" implements "CLKT Reg Owner"
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

codeunit 82379 "CLKT SI Reg 04" implements "CLKT Reg Owner"
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

codeunit 82380 "CLKT SI Reg 05" implements "CLKT Reg Owner"
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

codeunit 82381 "CLKT SI Reg 06" implements "CLKT Reg Owner"
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

codeunit 82382 "CLKT SI Reg 07" implements "CLKT Reg Owner"
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

codeunit 82383 "CLKT SI Reg 08" implements "CLKT Reg Owner"
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

codeunit 82384 "CLKT SI Reg 09" implements "CLKT Reg Owner"
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

codeunit 82385 "CLKT SI Reg 10" implements "CLKT Reg Owner"
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

codeunit 82386 "CLKT SI Reg 11" implements "CLKT Reg Owner"
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

codeunit 82387 "CLKT SI Reg 12" implements "CLKT Reg Owner"
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

codeunit 82388 "CLKT Reg SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIReg_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 01";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 02";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 03";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 04";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 05";
        K: Codeunit "CLKT Reg SI Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.LoadVarRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 06";
        K: Codeunit "CLKT Reg SI Holder";
        KS: Codeunit "CLKT Reg SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 07";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 08";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 09";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 10";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg SI Holder";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 11";
        K: Codeunit "CLKT Reg SI Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y2);
        K.LoadVarNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure SIReg_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Reg 12";
        K: Codeunit "CLKT Reg SI Holder";
        KS: Codeunit "CLKT Reg SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 82389 "CLKT Reg TG Holder"
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

    procedure Pull(O: Interface "CLKT Reg Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Reg Owner"; var Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Reg Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Reg Owner"; var V: Variant)
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

    procedure FillVarRows(O: Interface "CLKT Reg Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Reg Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Reg Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Reg Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Reg Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82390 "CLKT TG Reg 01" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82391 "CLKT TG Reg 02" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82392 "CLKT TG Reg 03" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82393 "CLKT TG Reg 04" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82394 "CLKT TG Reg 05" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82395 "CLKT Reg TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Reg Owner")
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

codeunit 82396 "CLKT TG Reg 06" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        KS: Codeunit "CLKT Reg TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
        K.Mark();
        K.WriteRow(1);
        K.WriteRow(2);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=5 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82397 "CLKT TG Reg 07" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82398 "CLKT TG Reg 08" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82399 "CLKT TG Reg 09" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82400 "CLKT TG Reg 10" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLKT Reg TG Holder";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82401 "CLKT TG Reg 11" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        V: Variant;
        C: Codeunit "CLR Register";
        Y2: Codeunit "CLR Register";
    begin
        this.ShareAlias(Y2);
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82402 "CLKT Reg TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Reg Owner")
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

codeunit 82403 "CLKT TG Reg 12" implements "CLKT Reg Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLR Register";
        Cnt: Integer;

    [Test]
    procedure TGReg_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Reg TG Holder";
        KS: Codeunit "CLKT Reg TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteRow(11);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(12);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteRow(19);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('second holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after second holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
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

codeunit 82404 "CLKT Price Plain Owner"
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

codeunit 82405 "CLKT Price Plain Holder"
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

    procedure PullPlain(var O: Codeunit "CLKT Price Plain Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVarPlain(var O: Codeunit "CLKT Price Plain Owner"; var Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValPlain(var O: Codeunit "CLKT Price Plain Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLKT Price Plain Owner"; var V: Variant)
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

    procedure FillVarPlainRows(var O: Codeunit "CLKT Price Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLKT Price Plain Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarPlainNever(var O: Codeunit "CLKT Price Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLKT Price Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLKT Price Plain Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82406 "CLKT Price Plain SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure PullPlain(var O: Codeunit "CLKT Price Plain Owner")
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

codeunit 82407 "CLKT Price Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlainPrice_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        KS: Codeunit "CLKT Price Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price Plain Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarPlainNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure PlainPrice_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT Price Plain Owner";
        K: Codeunit "CLKT Price Plain Holder";
        KS: Codeunit "CLKT Price Plain SI Holder";
    begin
        K.PullPlain(O);
        KS.PullPlain(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;
}

codeunit 82408 "CLKT Price SI Holder"
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

    procedure Pull(O: Interface "CLKT Price Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Price Owner"; var Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Price Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Price Owner"; var V: Variant)
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

    procedure FillVarRows(O: Interface "CLKT Price Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Price Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Price Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Price Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82409 "CLKT Price SI SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Price Owner")
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

codeunit 82410 "CLKT SI Price 01" implements "CLKT Price Owner"
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

codeunit 82411 "CLKT SI Price 02" implements "CLKT Price Owner"
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

codeunit 82412 "CLKT SI Price 03" implements "CLKT Price Owner"
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

codeunit 82413 "CLKT SI Price 04" implements "CLKT Price Owner"
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

codeunit 82414 "CLKT SI Price 05" implements "CLKT Price Owner"
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

codeunit 82415 "CLKT SI Price 06" implements "CLKT Price Owner"
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

codeunit 82416 "CLKT SI Price 07" implements "CLKT Price Owner"
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

codeunit 82417 "CLKT SI Price 08" implements "CLKT Price Owner"
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

codeunit 82418 "CLKT SI Price 09" implements "CLKT Price Owner"
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

codeunit 82419 "CLKT SI Price 10" implements "CLKT Price Owner"
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

codeunit 82420 "CLKT SI Price 11" implements "CLKT Price Owner"
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

codeunit 82421 "CLKT SI Price 12" implements "CLKT Price Owner"
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

codeunit 82422 "CLKT Price SI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SIPrice_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 01";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
    begin
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 02";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 03";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 04";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 05";
        K: Codeunit "CLKT Price SI Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarRows(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 06";
        K: Codeunit "CLKT Price SI Holder";
        KS: Codeunit "CLKT Price SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 07";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 08";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 09";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 10";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price SI Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        O.ShareAlias(Y);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 11";
        K: Codeunit "CLKT Price SI Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y2);
        K.LoadVarNever(O, V);
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
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure SIPrice_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLKT SI Price 12";
        K: Codeunit "CLKT Price SI Holder";
        KS: Codeunit "CLKT Price SI SI Holder";
    begin
        K.Pull(O);
        KS.Pull(O);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', O.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
        Observer.Verify();
    end;
}

codeunit 82423 "CLKT Price TG Holder"
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

    procedure Pull(O: Interface "CLKT Price Owner")
    begin
        O.ShareAlias(G);
    end;

    procedure ViaVar(O: Interface "CLKT Price Owner"; var Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByVal(O: Interface "CLKT Price Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteT1(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(O: Interface "CLKT Price Owner"; var V: Variant)
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

    procedure FillVarRows(O: Interface "CLKT Price Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(O: Interface "CLKT Price Owner"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(O: Interface "CLKT Price Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.ShareAlias(Y);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(O: Interface "CLKT Price Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(O: Interface "CLKT Price Owner"; var Observer: Codeunit "Probe Observer")
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

codeunit 82424 "CLKT TG Price 01" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
    begin
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
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

codeunit 82425 "CLKT TG Price 02" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoOtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
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

codeunit 82426 "CLKT TG Price 03" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
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

codeunit 82427 "CLKT TG Price 04" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        Y.Mark();
        Y.WriteT1(3);
        Y.SetInt(6);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
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

codeunit 82428 "CLKT TG Price 05" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoVariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarRows(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
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

codeunit 82429 "CLKT Price TG SI 06"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Price Owner")
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

codeunit 82430 "CLKT TG Price 06" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoGlobalPair_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        KS: Codeunit "CLKT Price TG SI 06";
    begin
        K.Pull(this);
        KS.Pull(this);
        K.Mark();
        K.WriteT1(3);
        K.SetInt(6);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=3 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=4 kind=None int=0 lc=store label');
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

codeunit 82431 "CLKT TG Price 07" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
    begin
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
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

codeunit 82432 "CLKT TG Price 08" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoOtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        K.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
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

codeunit 82433 "CLKT TG Price 09" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaVar(this, Y, Observer);
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
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

codeunit 82434 "CLKT TG Price 10" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLKT Price TG Holder";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        this.ShareAlias(Y);
        this.SetCnt(4);
        K.ViaByVal(this, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('caller holder after return', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
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

codeunit 82435 "CLKT TG Price 11" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoVariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
        Y2: Codeunit "CLV Price Store";
    begin
        this.ShareAlias(Y2);
        K.LoadVarNever(this, V);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Observe('second holder', Y2.State());
        Y2.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
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

codeunit 82436 "CLKT Price TG SI 12"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";
        HCnt: Integer;

    procedure Pull(O: Interface "CLKT Price Owner")
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

codeunit 82437 "CLKT TG Price 12" implements "CLKT Price Owner"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        X: Codeunit "CLV Price Store";
        Cnt: Integer;

    [Test]
    procedure TGPrice_TwoGlobalPair_Never()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLKT Price TG Holder";
        KS: Codeunit "CLKT Price TG SI 12";
    begin
        K.Pull(this);
        KS.Pull(this);
        this.SetCnt(4);
        this.ClearAllGlobals();
        Observer.Observe('owner', this.StateX());
        Observer.Observe('owner cnt', Format(this.GetCnt()));
        Observer.Observe('holder', K.State());
        K.WriteT1(5);
        Observer.Observe('owner after holder write', this.StateX());
        this.WriteX(7);
        Observer.Observe('holder after owner write', K.State());
        Observer.Observe('second holder', KS.State());
        KS.WriteT1(9);
        Observer.Observe('owner after second holder write', this.StateX());
        KS.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=1 kind=None int=0 lc=store label');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('second holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after second holder write', 't1=3 kind=None int=0 lc=store label');
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
