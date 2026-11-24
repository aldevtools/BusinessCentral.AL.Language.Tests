// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) and "CLB Store" (codeunit 75587) of
//   ClearSharedCodeunitTempRef.al; "CLV Price Store", "CLV Line Owner" of ClearSharedCodeunitStoreShapes.al;
//   "CLR Register", "CLR Plain Owner", "CLR TableNo Owner" of ClearSharedCodeunitSetterOwner.al; "CLS Arr Store",
//   "CLS Arr Holder" of ClearSharedCodeunitSIOwner.al; "CLQ Store Plus", "CLQ Plus Holder", "CLQ Wrapper",
//   "CLQ Deep Holder" of ClearSharedCodeunitOwnerKinds.al; "CLT B2 Store", "CLT B2 Holder" of
//   ClearSharedCodeunitTempArrayShare.al; self-contained objects 77266 to 77288
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in an owner codeunit whose store global another variable shares, for six stores and seven kinds
//   of holder. Stores and owners (unchanged, from the files above): the price store under "CLV Line Owner" (ClearAll
//   in SetLine), "CLR Register" under "CLR Plain Owner" and "CLR TableNo Owner", "CLS Arr Store" (one-dimension
//   arrays), "CLQ Store Plus" (one more Integer), "CLQ Wrapper" (a "CLB Store" global and an Integer) under
//   "CLQ Deep Holder", "CLT B2 Store" (a two-dimension array of temporary records).
//   Holder kinds (the holder is the only other variable on the store's instance):
//   - VarParam: a test local shared by the owner's getter (or put into the register owner's setter), then passed as a
//     var parameter to a routine of another codeunit that calls the owner's ClearAll and reads through it.
//   - OtherGlobal: a global of another codeunit (not SingleInstance) that takes the instance from the owner's getter.
//   - SIGlobal: the same in a SingleInstance codeunit (each test assigns it first and clears it at the end).
//   - CallerLocal: a local of a routine of another codeunit (not the test) that shares, writes, calls the owner's
//     ClearAll and reads, all inside that routine.
//   - ArrayElement: element 2 of a test local array of the store codeunit.
//   - SetterOut: a routine with a local takes the owner's instance and hands it to the holder's setter (G := NewG);
//     the local then ends.
//   - SetterIn: a test local handed into a setter of the owner (a copy of the owner with the same globals and
//     procedures plus SetStore). For the register this is how every holder above shares it (its owners have only a
//     setter), so the register has no SetterIn cell of its own.
//   Each kind in two states: Rows (the store's temporary table holds rows when ClearAll runs) and Never (only scalars
//   written, no row). After ClearAll the test reads the owner and the holder, writes through the holder and reads the
//   owner, then the reverse; the wrapper cells also write through the owner's inner "CLB Store" and read the holder.
//   Writes and reads mirror the one holder kind measured before (ClearSharedCodeunitStoreShapes.al
//   Price_StoreAlias_SetLine, ClearSharedCodeunitSetterOwner.al PlainProc_VarSetter_Rows, ClearSharedCodeunitSIOwner.al
//   ArrStore_ClearAll_Alias_AliasWroteBefore, ClearSharedCodeunitOwnerKinds.al StorePlus_AliasWroteBefore and
//   Deep_WrapperAliasWroteBefore, ClearSharedCodeunitTempArrayShare.al TwoDimWritten_InStore_ClearAll_AliasWroteBefore).
//   Measured on BC 29.0 (Linux):
//   - Every holder kind gives the same answer, for every store, owner and state, and it is the answer of the one
//     holder kind measured before: ClearAll in the owner resets the store in place, and the owner and the holder
//     stay on the one instance (a write through either side shows through the other).
//   - Temporary tables keep the rows they hold now (price t1=2, register rows=2, array rows1=2 rows2=2, store plus
//     rows=1, wrapper rows=1, two-dimension b11=b12=b21=b22=1); Never reads 0 rows. Integers, the Enum, the Decimal,
//     the Boolean, the Code and the record filter and field go to their defaults; the Label keeps its text; RecordRefs
//     are closed (Number 0); the register's nested codeunit reads 0; the owner's own Integer reads 0.
//   - Wrapper: the wrapper's Integer reads 0 on both sides, and a write through the owner's inner "CLB Store" shows
//     through the holder's wrapper (one inner instance).
// BC versions: 27, 28, 29

codeunit 77284 "CLH Price Twin" implements "CLV Line"
{
    var
        S: Codeunit "CLV Price Store";
        Cnt: Integer;
        LineNo: Integer;

    procedure SetLine()
    begin
        ClearAll();
        LineNo := 1;
    end;

    procedure Prepare()
    begin
        S.Mark();
        S.Fill();
        Cnt := 5;
    end;

    procedure State(): Text
    begin
        exit(S.State() + ' cnt=' + Format(Cnt) + ' line=' + Format(LineNo));
    end;

    procedure SetInt(V: Integer)
    begin
        S.SetInt(V);
    end;

    procedure GetStore(var X: Codeunit "CLV Price Store")
    begin
        X := S;
    end;

    procedure WriteT1(V: Integer)
    begin
        S.WriteT1(V);
    end;

    procedure EmptyT1()
    begin
        S.EmptyT1();
    end;

    procedure ShareT1(var R: Record "CLB Row" temporary)
    begin
        S.ShareT1(R);
    end;

    procedure SetStore(var NewS: Codeunit "CLV Price Store")
    begin
        S := NewS;
    end;
}

codeunit 77285 "CLH Arr Twin"
{
    var
        X: Codeunit "CLS Arr Store";

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

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetStore(var NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;
}

codeunit 77286 "CLH Plus Twin"
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

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure SetXN(V: Integer)
    begin
        X.SetN(V);
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;
}

codeunit 77287 "CLH Wrap Twin"
{
    var
        W: Codeunit "CLQ Wrapper";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        W.WriteX(V);
    end;

    procedure StateX(): Text
    begin
        exit(W.StateX());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        W.ShareAlias(Y);
    end;

    procedure ShareWrapper(var V: Codeunit "CLQ Wrapper")
    begin
        V := W;
    end;

    procedure SetWCnt(V: Integer)
    begin
        W.SetWCnt(V);
    end;

    procedure GetWCnt(): Integer
    begin
        exit(W.GetWCnt());
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure SetStore(var NewS: Codeunit "CLQ Wrapper")
    begin
        W := NewS;
    end;
}

codeunit 77288 "CLH TwoDim Twin"
{
    var
        X: Codeunit "CLT B2 Store";
        Cnt: Integer;

    procedure WriteX(I: Integer; J: Integer; V: Integer)
    begin
        X.Write(I, J, V);
    end;

    procedure SetIntX(V: Integer)
    begin
        X.SetInt(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLT B2 Store")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetStore(var NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;
}

codeunit 77272 "CLH Price Holder"
{
    var
        G: Codeunit "CLV Price Store";

    procedure Pull(var O: Codeunit "CLV Line Owner")
    begin
        O.GetStore(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

    procedure ViaVar(var O: Codeunit "CLV Line Owner"; var Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure KeepLocalRows(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure KeepLocalNever(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        Y.Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure Hand(var O: Codeunit "CLV Line Owner"; var H: Codeunit "CLH Price Holder")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        H.SetStore(Y);
    end;
}

codeunit 77273 "CLH Reg Holder"
{
    var
        G: Codeunit "CLR Register";

    procedure PullPlain(var O: Codeunit "CLR Plain Owner")
    begin
        O.SetRegister(G);
    end;

    procedure PullTableNo(var O: Codeunit "CLR TableNo Owner")
    begin
        O.SetRegister(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

    procedure ViaVarPlain(var O: Codeunit "CLR Plain Owner"; var Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalPlainRows(var O: Codeunit "CLR Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalPlainNever(var O: Codeunit "CLR Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandPlain(var O: Codeunit "CLR Plain Owner"; var H: Codeunit "CLH Reg Holder")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        H.SetStore(Y);
    end;

    procedure ViaVarTableNo(var O: Codeunit "CLR TableNo Owner"; var Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalTableNoRows(var O: Codeunit "CLR TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalTableNoNever(var O: Codeunit "CLR TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure HandTableNo(var O: Codeunit "CLR TableNo Owner"; var H: Codeunit "CLH Reg Holder")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        H.SetStore(Y);
    end;
}

codeunit 77274 "CLH Arr Holder"
{
    var
        G: Codeunit "CLS Arr Store";

    procedure Pull(var O: Codeunit "CLS Arr Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
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

    procedure ViaVar(var O: Codeunit "CLS Arr Holder"; var Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalRows(var O: Codeunit "CLS Arr Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalNever(var O: Codeunit "CLS Arr Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(var O: Codeunit "CLS Arr Holder"; var H: Codeunit "CLH Arr Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        H.SetStore(Y);
    end;
}

codeunit 77275 "CLH Plus Holder"
{
    var
        G: Codeunit "CLQ Store Plus";

    procedure Pull(var O: Codeunit "CLQ Plus Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

    procedure ViaVar(var O: Codeunit "CLQ Plus Holder"; var Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
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

    procedure KeepLocalRows(var O: Codeunit "CLQ Plus Holder"; var Observer: Codeunit "Probe Observer")
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

    procedure KeepLocalNever(var O: Codeunit "CLQ Plus Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
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

    procedure Hand(var O: Codeunit "CLQ Plus Holder"; var H: Codeunit "CLH Plus Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        H.SetStore(Y);
    end;
}

codeunit 77276 "CLH Wrap Holder"
{
    var
        G: Codeunit "CLQ Wrapper";

    procedure Pull(var O: Codeunit "CLQ Deep Holder")
    begin
        O.ShareWrapper(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

    procedure ViaVar(var O: Codeunit "CLQ Deep Holder"; var Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX());
        Observer.Observe('holder wrapper cnt', Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX());
        Y.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Y.StateX());
    end;

    procedure KeepLocalRows(var O: Codeunit "CLQ Deep Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX());
        Observer.Observe('holder wrapper cnt', Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX());
        Y.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Y.StateX());
    end;

    procedure KeepLocalNever(var O: Codeunit "CLQ Deep Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX());
        Observer.Observe('holder wrapper cnt', Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX());
        Y.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Y.StateX());
    end;

    procedure Hand(var O: Codeunit "CLQ Deep Holder"; var H: Codeunit "CLH Wrap Holder")
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareWrapper(Y);
        H.SetStore(Y);
    end;
}

codeunit 77277 "CLH TwoDim Holder"
{
    var
        G: Codeunit "CLT B2 Store";

    procedure Pull(var O: Codeunit "CLT B2 Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

    procedure ViaVar(var O: Codeunit "CLT B2 Holder"; var Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalRows(var O: Codeunit "CLT B2 Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure KeepLocalNever(var O: Codeunit "CLT B2 Holder"; var Observer: Codeunit "Probe Observer")
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure Hand(var O: Codeunit "CLT B2 Holder"; var H: Codeunit "CLH TwoDim Holder")
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        H.SetStore(Y);
    end;
}

codeunit 77278 "CLH Price SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLV Price Store";

    procedure Pull(var O: Codeunit "CLV Line Owner")
    begin
        O.GetStore(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

codeunit 77279 "CLH Reg SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLR Register";

    procedure PullPlain(var O: Codeunit "CLR Plain Owner")
    begin
        O.SetRegister(G);
    end;

    procedure PullTableNo(var O: Codeunit "CLR TableNo Owner")
    begin
        O.SetRegister(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

codeunit 77280 "CLH Arr SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLS Arr Store";

    procedure Pull(var O: Codeunit "CLS Arr Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
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

codeunit 77281 "CLH Plus SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Store Plus";

    procedure Pull(var O: Codeunit "CLQ Plus Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

codeunit 77282 "CLH Wrap SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLQ Wrapper";

    procedure Pull(var O: Codeunit "CLQ Deep Holder")
    begin
        O.ShareWrapper(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

codeunit 77283 "CLH TwoDim SI Holder"
{
    SingleInstance = true;

    var
        G: Codeunit "CLT B2 Store";

    procedure Pull(var O: Codeunit "CLT B2 Holder")
    begin
        O.ShareAlias(G);
    end;

    procedure SetStore(var NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure Release()
    begin
        Clear(G);
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

codeunit 77266 "CLH Price Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Price_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLH Price Holder";
    begin
        O.GetStore(Y);
        O.Prepare();
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price Holder";
    begin
        H.Pull(O);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price SI Holder";
    begin
        H.Pull(O);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        H.Release();
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLH Price Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        A: array[2] of Codeunit "CLV Price Store";
    begin
        O.GetStore(A[2]);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', A[2].State());
        A[2].SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', A[2].State());
        A[2].WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price Holder";
        Hander: Codeunit "CLH Price Holder";
    begin
        Hander.Hand(O, H);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Price Twin";
        Y: Codeunit "CLV Price Store";
    begin
        O.SetStore(Y);
        O.Prepare();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLH Price Holder";
    begin
        O.GetStore(Y);
        Y.Mark();
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price Holder";
    begin
        H.Pull(O);
        H.Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price SI Holder";
    begin
        H.Pull(O);
        H.Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        H.Release();
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLH Price Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        A: array[2] of Codeunit "CLV Price Store";
    begin
        O.GetStore(A[2]);
        A[2].Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', A[2].State());
        A[2].SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', A[2].State());
        A[2].WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        H: Codeunit "CLH Price Holder";
        Hander: Codeunit "CLH Price Holder";
    begin
        Hander.Hand(O, H);
        H.Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', H.State());
        H.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', H.State());
        H.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Price Twin";
        Y: Codeunit "CLV Price Store";
    begin
        O.SetStore(Y);
        Y.Mark();
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;
}

codeunit 77267 "CLH Reg Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RegPlain_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLH Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg Holder";
    begin
        H.PullPlain(O);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg SI Holder";
    begin
        H.PullPlain(O);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLH Reg Holder";
    begin
        K.KeepLocalPlainRows(O, Observer);
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        A: array[2] of Codeunit "CLR Register";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        A[2].WriteRow(1);
        A[2].WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg Holder";
        Hander: Codeunit "CLH Reg Holder";
    begin
        Hander.HandPlain(O, H);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLH Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaVarPlain(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg Holder";
    begin
        H.PullPlain(O);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg SI Holder";
    begin
        H.PullPlain(O);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLH Reg Holder";
    begin
        K.KeepLocalPlainNever(O, Observer);
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        A: array[2] of Codeunit "CLR Register";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        H: Codeunit "CLH Reg Holder";
        Hander: Codeunit "CLH Reg Holder";
    begin
        Hander.HandPlain(O, H);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLH Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaVarTableNo(O, Y, Observer);
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg Holder";
    begin
        H.PullTableNo(O);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg SI Holder";
    begin
        H.PullTableNo(O);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLH Reg Holder";
    begin
        K.KeepLocalTableNoRows(O, Observer);
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        A: array[2] of Codeunit "CLR Register";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        A[2].WriteRow(1);
        A[2].WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg Holder";
        Hander: Codeunit "CLH Reg Holder";
    begin
        Hander.HandTableNo(O, H);
        H.Mark();
        H.WriteRow(1);
        H.WriteRow(2);
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLH Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaVarTableNo(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg Holder";
    begin
        H.PullTableNo(O);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg SI Holder";
    begin
        H.PullTableNo(O);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLH Reg Holder";
    begin
        K.KeepLocalTableNoNever(O, Observer);
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        A: array[2] of Codeunit "CLR Register";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        H: Codeunit "CLH Reg Holder";
        Hander: Codeunit "CLH Reg Holder";
    begin
        Hander.HandTableNo(O, H);
        H.Mark();
        O.SetCnt(5);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 77268 "CLH Arr Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Arr_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLH Arr Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr Holder";
    begin
        H.Pull(O);
        H.Write(1, 3);
        H.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr SI Holder";
    begin
        H.Pull(O);
        H.Write(1, 3);
        H.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLH Arr Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(1, 3);
        A[2].Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr Holder";
        Hander: Codeunit "CLH Arr Holder";
    begin
        Hander.Hand(O, H);
        H.Write(1, 3);
        H.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Arr Twin";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStore(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLH Arr Holder";
    begin
        O.ShareAlias(Y);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr Holder";
    begin
        H.Pull(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr SI Holder";
    begin
        H.Pull(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLH Arr Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        A: array[2] of Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(A[2]);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        H: Codeunit "CLH Arr Holder";
        Hander: Codeunit "CLH Arr Holder";
    begin
        Hander.Hand(O, H);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Arr Twin";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStore(Y);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;
}

codeunit 77269 "CLH Plus Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Plus_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLH Plus Holder";
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
    procedure Plus_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus Holder";
    begin
        H.Pull(O);
        H.Write(3);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus SI Holder";
    begin
        H.Pull(O);
        H.Write(3);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLH Plus Holder";
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
    procedure Plus_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
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
    procedure Plus_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus Holder";
        Hander: Codeunit "CLH Plus Holder";
    begin
        Hander.Hand(O, H);
        H.Write(3);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Plus Twin";
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
    procedure Plus_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLH Plus Holder";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
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
    procedure Plus_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus Holder";
    begin
        H.Pull(O);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus SI Holder";
    begin
        H.Pull(O);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLH Plus Holder";
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
    procedure Plus_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        A: array[2] of Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(A[2]);
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        H: Codeunit "CLH Plus Holder";
        Hander: Codeunit "CLH Plus Holder";
    begin
        Hander.Hand(O, H);
        H.SetN(6);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.State());
        H.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Plus Twin";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStore(Y);
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
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 77270 "CLH Wrap Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Wrap_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLH Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        H.Pull(O);
        H.WriteX(3);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap SI Holder";
        Inner: Codeunit "CLB Store";
    begin
        H.Pull(O);
        H.WriteX(3);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        H.Release();
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLH Wrap Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        A: array[2] of Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(A[2]);
        A[2].WriteX(3);
        A[2].SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].StateX());
        Observer.Observe('holder wrapper cnt', Format(A[2].GetWCnt()));
        A[2].WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].StateX());
        A[2].SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', A[2].StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap Holder";
        Hander: Codeunit "CLH Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        Hander.Hand(O, H);
        H.WriteX(3);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Wrap Twin";
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX());
        Observer.Observe('holder wrapper cnt', Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX());
        Y.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Y.StateX());
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLH Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        H.Pull(O);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap SI Holder";
        Inner: Codeunit "CLB Store";
    begin
        H.Pull(O);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        H.Release();
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLH Wrap Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        A: array[2] of Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(A[2]);
        A[2].SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].StateX());
        Observer.Observe('holder wrapper cnt', Format(A[2].GetWCnt()));
        A[2].WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].StateX());
        A[2].SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', A[2].StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        H: Codeunit "CLH Wrap Holder";
        Hander: Codeunit "CLH Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        Hander.Hand(O, H);
        H.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', H.StateX());
        Observer.Observe('holder wrapper cnt', Format(H.GetWCnt()));
        H.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', H.StateX());
        H.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', H.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH Wrap Twin";
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.SetStore(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.StateX());
        Observer.Observe('holder wrapper cnt', Format(Y.GetWCnt()));
        Y.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.StateX());
        Y.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Y.StateX());
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Verify();
    end;
}

codeunit 77271 "CLH TwoDim Kind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TwoDim_VarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLH TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_OtherGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim Holder";
    begin
        H.Pull(O);
        H.Write(1, 1, 1);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SIGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim SI Holder";
    begin
        H.Pull(O);
        H.Write(1, 1, 1);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_CallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLH TwoDim Holder";
    begin
        K.KeepLocalRows(O, Observer);
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        A: array[2] of Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(1, 1, 1);
        A[2].SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim Holder";
        Hander: Codeunit "CLH TwoDim Holder";
    begin
        Hander.Hand(O, H);
        H.Write(1, 1, 1);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH TwoDim Twin";
        Y: Codeunit "CLT B2 Store";
    begin
        O.SetStore(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLH TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        K.ViaVar(O, Y, Observer);
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_OtherGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim Holder";
    begin
        H.Pull(O);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SIGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim SI Holder";
    begin
        H.Pull(O);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        H.Release();
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_CallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLH TwoDim Holder";
    begin
        K.KeepLocalNever(O, Observer);
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        A: array[2] of Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(A[2]);
        A[2].SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        H: Codeunit "CLH TwoDim Holder";
        Hander: Codeunit "CLH TwoDim Holder";
    begin
        Hander.Hand(O, H);
        H.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', H.State());
        H.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', H.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_SetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLH TwoDim Twin";
        Y: Codeunit "CLT B2 Store";
    begin
        O.SetStore(Y);
        Y.SetInt(7);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;
}
