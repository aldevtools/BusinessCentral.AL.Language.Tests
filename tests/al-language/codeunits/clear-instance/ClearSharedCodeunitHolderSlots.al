// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) and "CLB Store" (codeunit 75587) of
//   ClearSharedCodeunitTempRef.al; "CLR Nested" of ClearSharedCodeunitSetterOwner.al; the stores and owners of
//   ClearSharedCodeunitHolderKinds.al (unchanged, see its header); self-contained objects 77330 to 77367
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: ClearAll in an owner codeunit whose store global one more variable shares, for the six stores of
//   ClearSharedCodeunitHolderKinds.al and the holder slots that file does not measure:
//   - ByValFill: a by-value Codeunit parameter of a routine that is still running; the routine puts the parameter on
//     the owner's store (getter; for the register the owner's setter takes the parameter, so the caller's argument
//     shares too), then calls the owner's ClearAll and reads through the parameter.
//   - ByValPassed: a test local on the store passed by value to a routine that calls ClearAll and reads through the
//     parameter; the test then reads through its own variable.
//   - ByValDeep: the same, but ClearAll runs two calls below the routine that holds the parameter.
//   - ByValSetterOut: a routine with a local takes the owner's instance and hands it to a by-value setter of a holder
//     codeunit (G := NewG); the setter and the routine have returned when ClearAll runs.
//   - ByValSetterIn: a test local handed into a by-value setter of the owner (the register owners' SetRegisterByValue;
//     for the other stores "CLI <store> BOwner", a copy of the owner with the same globals plus SetStoreByVal).
//   - VariantLocal / VariantCallerLocal / VariantGlobal: a Variant filled from a Codeunit local that then ends: a test
//     local, a local of a routine of another codeunit, a global of another codeunit. Reads assign the Variant back to
//     a Codeunit variable after ClearAll.
//   - IfaceLocal / IfaceCallerLocal / IfaceGlobal: the same with an Interface variable.
//   - ListLocal / ListGlobal / DictLocal / DictGlobal: a List of [Interface] and a Dictionary of [Integer, Interface]
//     that hold the instance as their only element; reads take the element out after ClearAll.
//   - IfaceVarParam / IfaceByValPassed: a test local Interface passed (var / by value) to a routine that calls
//     ClearAll and reads through the parameter; the test then reads through its own variable.
//   - IfaceByValFill: a by-value Interface parameter (the caller passes a fresh store instance) that the running
//     routine fills from the owner's store through a routine whose local then ends.
//   - IfaceByValFromCodeunit: a test local Codeunit on the store passed to a by-value Interface parameter.
//   Only "CLV Price Store" implements an interface ("CLV Store Face": State, SetInt). For the other five stores the
//   Interface cells use "CLI <store> FStore", a copy of the store with the same globals in the same order (and the
//   register's TableNo) that implements "CLI <store> Face", held by "CLI <owner> FOwner", a copy of the owner. Each
//   copy also has an ArrayElement cell (a holder kind of ClearSharedCodeunitHolderKinds.al) that ties it to the
//   original.
//   Each cell in two states: Rows (the store's temporary table holds rows when ClearAll runs) and Never. Before
//   ClearAll the owner writes a scalar and the test reads it through the holder ("pre holder after owner write"; not
//   for the array store, whose writes all add rows). After ClearAll the reads and writes are those of
//   ClearSharedCodeunitHolderKinds.al.
//   Measured on BC 29.0 (Linux):
//   - Every slot gives the same answer, for every store, owner and state, as the holder kinds of
//     ClearSharedCodeunitHolderKinds.al: ClearAll in the owner resets the store in place, and the owner and the slot
//     stay on the one instance (a write through either side shows through the other). Temporary tables keep the rows
//     they hold now; scalars go to their defaults; the Label keeps its text; RecordRefs are closed; the register's
//     nested codeunit reads 0; the wrapper's inner "CLB Store" stays one instance.
//   - Before ClearAll every slot already reads the owner's scalar write (one instance from the moment it is filled).
//   - A Variant, an Interface variable, and a List or Dictionary element give the instance back unchanged after
//     ClearAll: assigning the Variant to a Codeunit variable, or taking the element out, reaches the owner's store.
//   - Parameters: the caller's variable reads the same instance after the routine returns (writes made through the
//     parameter show). A fresh caller argument stays its own instance when the routine puts its by-value parameter
//     on the owner's store (0 rows, defaults), except for the register, whose owner's setter takes the parameter, so
//     the caller's argument is the shared instance.
//   - The store copies ("CLI <store> FStore") read exactly as the stores they copy, in every cell.
// BC versions: 27, 28, 29

interface "CLI Reg Face"
{
    procedure Mark();
    procedure WriteRow(V: Integer);
    procedure State(): Text;
}

interface "CLI Arr Face"
{
    procedure Write(E: Integer; V: Integer);
    procedure State(): Text;
}

interface "CLI Plus Face"
{
    procedure Write(V: Integer);
    procedure SetN(V: Integer);
    procedure State(): Text;
}

interface "CLI Wrap Face"
{
    procedure WriteX(V: Integer);
    procedure SetWCnt(V: Integer);
    procedure GetWCnt(): Integer;
    procedure StateX(): Text;
}

interface "CLI TwoDim Face"
{
    procedure Write(I: Integer; J: Integer; V: Integer);
    procedure SetInt(V: Integer);
    procedure State(): Text;
}

codeunit 77330 "CLI Reg FStore" implements "CLI Reg Face"
{
    TableNo = "CLB Row";

    var
        Rows: Record "CLB Row" temporary;
        Rec: Record "CLB Row";
        Dec: Decimal;
        Flag: Boolean;
        Cd: Code[20];
        Nested: Codeunit "CLR Nested";

    trigger OnRun()
    begin
        Cd := 'RUN';
    end;

    procedure Mark()
    begin
        Dec := 1.5;
        Flag := true;
        Cd := 'MARK';
        Rec.SetRange("No.", 7);
        Rec."No." := 9;
        Nested.Set(4);
    end;

    procedure WriteRow(V: Integer)
    begin
        Rows.Init();
        Rows."No." := V;
        Rows.Insert();
    end;

    procedure EmptyRows()
    begin
        Rows.DeleteAll();
    end;

    procedure ShareRows(var R: Record "CLB Row" temporary)
    begin
        R.Copy(Rows, true);
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('rows=%1 dec=%2 flag=%3 code=%4 recfilter=%5 recno=%6 nested=%7',
            Rows.Count(), Format(Dec, 0, 9), Flag, Cd, Rec.GetFilters(), Rec."No.", Nested.Get()));
    end;
}

codeunit 77331 "CLI Arr FStore" implements "CLI Arr Face"
{
    var
        Rows: array[2] of Record "CLB Row" temporary;
        Refs: array[2] of RecordRef;
        Ints: array[3] of Integer;

    procedure Write(E: Integer; V: Integer)
    begin
        Rows[E].Init();
        Rows[E]."No." := V;
        Rows[E].Insert();
        if Refs[1].Number = 0 then
            Refs[1].Open(Database::"CLB Row", true);
        Refs[1].Init();
        Refs[1].Field(1).Value := V;
        Refs[1].Insert();
        Ints[1] := V;
    end;

    procedure State(): Text
    var
        RefRows: Text;
    begin
        RefRows := '-';
        if Refs[1].Number <> 0 then
            RefRows := Format(Refs[1].Count());
        exit(StrSubstNo('rows1=%1 rows2=%2 ref1=%3 refrows=%4 int1=%5',
            Rows[1].Count(), Rows[2].Count(), Refs[1].Number, RefRows, Ints[1]));
    end;

    procedure ClearElem(E: Integer)
    begin
        Clear(Rows[E]);
    end;

    procedure ClearArr()
    begin
        Clear(Rows);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;

    procedure AssignFirstToSecond()
    begin
        Rows[2] := Rows[1];
    end;

    procedure SecondNo(): Integer
    begin
        exit(Rows[2]."No.");
    end;
}

codeunit 77332 "CLI Plus FStore" implements "CLI Plus Face"
{
    var
        Rows: Record "CLB Row" temporary;
        Refs: array[2, 3] of RecordRef;
        Ints: array[3] of Integer;
        N: Integer;

    procedure Write(V: Integer)
    begin
        Rows.Init();
        Rows."No." := V;
        Rows.Insert();
        if Refs[1, 1].Number = 0 then
            Refs[1, 1].Open(Database::"CLB Row", true);
        Refs[1, 1].Init();
        Refs[1, 1].Field(1).Value := V;
        Refs[1, 1].Insert();
        Ints[1] := V;
    end;

    procedure State(): Text
    var
        RefRows: Text;
    begin
        RefRows := '-';
        if Refs[1, 1].Number <> 0 then
            RefRows := Format(Refs[1, 1].Count());
        exit(StrSubstNo('rows=%1 ref11=%2 refrows=%3 ref23=%4 int1=%5 int3=%6 n=%7',
            Rows.Count(), Refs[1, 1].Number, RefRows, Refs[2, 3].Number, Ints[1], Ints[3], N));
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;
}

codeunit 77333 "CLI Wrap FStore" implements "CLI Wrap Face"
{
    var
        X: Codeunit "CLB Store";
        WCnt: Integer;

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

    procedure SetWCnt(V: Integer)
    begin
        WCnt := V;
    end;

    procedure GetWCnt(): Integer
    begin
        exit(WCnt);
    end;
}

codeunit 77334 "CLI TwoDim FStore" implements "CLI TwoDim Face"
{
    var
        B: array[2, 2] of Record "CLB Row" temporary;
        Ints: array[2] of Integer;

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        B[I, J].Init();
        B[I, J]."No." := V;
        B[I, J].Insert();
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('b11=%1 b12=%2 b21=%3 b22=%4 int1=%5', B[1, 1].Count(), B[1, 2].Count(), B[2, 1].Count(), B[2, 2].Count(), Ints[1]));
    end;

    procedure SetInt(V: Integer)
    begin
        Ints[1] := V;
    end;
}

codeunit 77335 "CLI RegPlain FOwner"
{
    var
        Reg: Codeunit "CLI Reg FStore";
        Cnt: Integer;

    trigger OnRun()
    begin
        ClearAll();
    end;

    procedure SetRegister(var NewReg: Codeunit "CLI Reg FStore")
    begin
        Reg := NewReg;
    end;

    procedure SetRegisterByValue(NewReg: Codeunit "CLI Reg FStore")
    begin
        Reg := NewReg;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure StateReg(): Text
    begin
        exit(Reg.State());
    end;

    procedure WriteReg(V: Integer)
    begin
        Reg.WriteRow(V);
    end;

    procedure EmptyReg()
    begin
        Reg.EmptyRows();
    end;

    procedure MarkReg()
    begin
        Reg.Mark();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77336 "CLI RegTableNo FOwner"
{
    TableNo = "CLB Row";

    var
        Reg: Codeunit "CLI Reg FStore";
        Cnt: Integer;

    trigger OnRun()
    begin
        ClearAll();
    end;

    procedure SetRegister(var NewReg: Codeunit "CLI Reg FStore")
    begin
        Reg := NewReg;
    end;

    procedure SetRegisterByValue(NewReg: Codeunit "CLI Reg FStore")
    begin
        Reg := NewReg;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure StateReg(): Text
    begin
        exit(Reg.State());
    end;

    procedure WriteReg(V: Integer)
    begin
        Reg.WriteRow(V);
    end;

    procedure EmptyReg()
    begin
        Reg.EmptyRows();
    end;

    procedure MarkReg()
    begin
        Reg.Mark();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 77337 "CLI Arr FOwner"
{
    var
        X: Codeunit "CLI Arr FStore";

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

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77338 "CLI Plus FOwner"
{
    var
        X: Codeunit "CLI Plus FStore";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLI Plus FStore")
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
}

codeunit 77339 "CLI Wrap FOwner"
{
    var
        W: Codeunit "CLI Wrap FStore";
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

    procedure ShareWrapper(var V: Codeunit "CLI Wrap FStore")
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
}

codeunit 77340 "CLI TwoDim FOwner"
{
    var
        X: Codeunit "CLI TwoDim FStore";
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

    procedure ShareAlias(var Y: Codeunit "CLI TwoDim FStore")
    begin
        Y := X;
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;
}

codeunit 77341 "CLI Price BOwner" implements "CLV Line"
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

    procedure SetStoreByVal(NewS: Codeunit "CLV Price Store")
    begin
        S := NewS;
    end;
}

codeunit 77342 "CLI Arr BOwner"
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

    procedure SetStoreByVal(NewS: Codeunit "CLS Arr Store")
    begin
        X := NewS;
    end;
}

codeunit 77343 "CLI Plus BOwner"
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

    procedure SetStoreByVal(NewS: Codeunit "CLQ Store Plus")
    begin
        X := NewS;
    end;
}

codeunit 77344 "CLI Wrap BOwner"
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

    procedure SetStoreByVal(NewS: Codeunit "CLQ Wrapper")
    begin
        W := NewS;
    end;
}

codeunit 77345 "CLI TwoDim BOwner"
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

    procedure SetStoreByVal(NewS: Codeunit "CLT B2 Store")
    begin
        X := NewS;
    end;
}

codeunit 77346 "CLI Price Holder"
{
    var
        G: Codeunit "CLV Price Store";
        GV: Variant;
        GI: Interface "CLV Store Face";
        GL: List of [Interface "CLV Store Face"];
        GD: Dictionary of [Integer, Interface "CLV Store Face"];

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

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLV Store Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLV Store Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure ISetInt(V: Integer)
    begin
        GI.SetInt(V);
    end;

    procedure LSetInt(V: Integer)
    var
        F: Interface "CLV Store Face";
    begin
        F := GL.Get(1);
        F.SetInt(V);
    end;

    procedure DSetInt(V: Integer)
    var
        F: Interface "CLV Store Face";
    begin
        F := GD.Get(1);
        F.SetInt(V);
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLV Price Store")
    begin
        G := NewG;
    end;

    procedure HandByVal(var O: Codeunit "CLV Line Owner"; var H: Codeunit "CLI Price Holder")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByVal(var O: Codeunit "CLV Line Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
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

    procedure DoClear(var O: Codeunit "CLV Line Owner")
    begin
        O.SetLine();
    end;

    procedure ViaByValOuter(var O: Codeunit "CLV Line Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
        DoClear(O);
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure ViaIface(var O: Codeunit "CLV Line Owner"; var I: Interface "CLV Store Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;

    procedure ViaIfaceByVal(var O: Codeunit "CLV Line Owner"; I: Interface "CLV Store Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;

    procedure ViaByValFillRows(var O: Codeunit "CLV Line Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.GetStore(Y);
        O.Prepare();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
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

    procedure LoadVarRows(var O: Codeunit "CLV Line Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        O.Prepare();
        V := Y;
    end;

    procedure FillVarRows(var O: Codeunit "CLV Line Owner")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarRows(O, V);
        O.SetInt(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        C := V;
        C.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure LoadIfaceRows(var O: Codeunit "CLV Line Owner"; var I: Interface "CLV Store Face")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        O.Prepare();
        I := Y;
    end;

    procedure LoadListRows(var O: Codeunit "CLV Line Owner"; var L: List of [Interface "CLV Store Face"])
    var
        Y: Codeunit "CLV Price Store";
        I: Interface "CLV Store Face";
    begin
        O.GetStore(Y);
        O.Prepare();
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(var O: Codeunit "CLV Line Owner"; var D: Dictionary of [Integer, Interface "CLV Store Face"])
    var
        Y: Codeunit "CLV Price Store";
        I: Interface "CLV Store Face";
    begin
        O.GetStore(Y);
        O.Prepare();
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(var O: Codeunit "CLV Line Owner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(var O: Codeunit "CLV Line Owner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(var O: Codeunit "CLV Line Owner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLV Store Face";
    begin
        LoadIfaceRows(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;

    procedure ViaIfaceByValFillRows(var O: Codeunit "CLV Line Owner"; I: Interface "CLV Store Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;

    procedure ViaByValFillNever(var O: Codeunit "CLV Line Owner"; Y: Codeunit "CLV Price Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.GetStore(Y);
        Y.Mark();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
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

    procedure LoadVarNever(var O: Codeunit "CLV Line Owner"; var V: Variant)
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        Y.Mark();
        V := Y;
    end;

    procedure FillVarNever(var O: Codeunit "CLV Line Owner")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        LoadVarNever(O, V);
        O.SetInt(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        C := V;
        C.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
    end;

    procedure LoadIfaceNever(var O: Codeunit "CLV Line Owner"; var I: Interface "CLV Store Face")
    var
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        Y.Mark();
        I := Y;
    end;

    procedure LoadListNever(var O: Codeunit "CLV Line Owner"; var L: List of [Interface "CLV Store Face"])
    var
        Y: Codeunit "CLV Price Store";
        I: Interface "CLV Store Face";
    begin
        O.GetStore(Y);
        Y.Mark();
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(var O: Codeunit "CLV Line Owner"; var D: Dictionary of [Integer, Interface "CLV Store Face"])
    var
        Y: Codeunit "CLV Price Store";
        I: Interface "CLV Store Face";
    begin
        O.GetStore(Y);
        Y.Mark();
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(var O: Codeunit "CLV Line Owner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(var O: Codeunit "CLV Line Owner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(var O: Codeunit "CLV Line Owner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(var O: Codeunit "CLV Line Owner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLV Store Face";
    begin
        LoadIfaceNever(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;

    procedure ViaIfaceByValFillNever(var O: Codeunit "CLV Line Owner"; I: Interface "CLV Store Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
    end;
}

codeunit 77347 "CLI Reg Holder"
{
    var
        G: Codeunit "CLR Register";
        GV: Variant;

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

    procedure SetStoreByVal(NewG: Codeunit "CLR Register")
    begin
        G := NewG;
    end;

    procedure HandByValPlain(var O: Codeunit "CLR Plain Owner"; var H: Codeunit "CLI Reg Holder")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByValPlain(var O: Codeunit "CLR Plain Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearPlain(var O: Codeunit "CLR Plain Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterPlain(var O: Codeunit "CLR Plain Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        DoClearPlain(O);
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillPlainRows(var O: Codeunit "CLR Plain Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainRows(var O: Codeunit "CLR Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        V := Y;
    end;

    procedure FillVarPlainRows(var O: Codeunit "CLR Plain Owner")
    begin
        LoadVarPlainRows(O, GV);
    end;

    procedure KeepVarPlainRows(var O: Codeunit "CLR Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarPlainRows(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure ViaByValFillPlainNever(var O: Codeunit "CLR Plain Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarPlainNever(var O: Codeunit "CLR Plain Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        V := Y;
    end;

    procedure FillVarPlainNever(var O: Codeunit "CLR Plain Owner")
    begin
        LoadVarPlainNever(O, GV);
    end;

    procedure KeepVarPlainNever(var O: Codeunit "CLR Plain Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarPlainNever(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure HandByValTableNo(var O: Codeunit "CLR TableNo Owner"; var H: Codeunit "CLI Reg Holder")
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByValTableNo(var O: Codeunit "CLR TableNo Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClearTableNo(var O: Codeunit "CLR TableNo Owner")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuterTableNo(var O: Codeunit "CLR TableNo Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        DoClearTableNo(O);
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillTableNoRows(var O: Codeunit "CLR TableNo Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarTableNoRows(var O: Codeunit "CLR TableNo Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        V := Y;
    end;

    procedure FillVarTableNoRows(var O: Codeunit "CLR TableNo Owner")
    begin
        LoadVarTableNoRows(O, GV);
    end;

    procedure KeepVarTableNoRows(var O: Codeunit "CLR TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarTableNoRows(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure ViaByValFillTableNoNever(var O: Codeunit "CLR TableNo Owner"; Y: Codeunit "CLR Register"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarTableNoNever(var O: Codeunit "CLR TableNo Owner"; var V: Variant)
    var
        Y: Codeunit "CLR Register";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        V := Y;
    end;

    procedure FillVarTableNoNever(var O: Codeunit "CLR TableNo Owner")
    begin
        LoadVarTableNoNever(O, GV);
    end;

    procedure KeepVarTableNoNever(var O: Codeunit "CLR TableNo Owner"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        LoadVarTableNoNever(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 77348 "CLI RegFace Holder"
{
    var
        G: Codeunit "CLI Reg FStore";
        GV: Variant;
        GI: Interface "CLI Reg Face";
        GL: List of [Interface "CLI Reg Face"];
        GD: Dictionary of [Integer, Interface "CLI Reg Face"];

    procedure Mark()
    begin
        G.Mark();
    end;

    procedure VMark()
    var
        C: Codeunit "CLI Reg FStore";
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
        C: Codeunit "CLI Reg FStore";
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
        C: Codeunit "CLI Reg FStore";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure IMark()
    begin
        GI.Mark();
    end;

    procedure LMark()
    var
        F: Interface "CLI Reg Face";
    begin
        F := GL.Get(1);
        F.Mark();
    end;

    procedure DMark()
    var
        F: Interface "CLI Reg Face";
    begin
        F := GD.Get(1);
        F.Mark();
    end;

    procedure IWriteRow(V: Integer)
    begin
        GI.WriteRow(V);
    end;

    procedure LWriteRow(V: Integer)
    var
        F: Interface "CLI Reg Face";
    begin
        F := GL.Get(1);
        F.WriteRow(V);
    end;

    procedure DWriteRow(V: Integer)
    var
        F: Interface "CLI Reg Face";
    begin
        F := GD.Get(1);
        F.WriteRow(V);
    end;

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLI Reg Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLI Reg Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI Reg FStore")
    begin
        G := NewG;
    end;

    procedure ViaIfacePlain(var O: Codeunit "CLI RegPlain FOwner"; var I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValPlain(var O: Codeunit "CLI RegPlain FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfacePlainRows(var O: Codeunit "CLI RegPlain FOwner"; var I: Interface "CLI Reg Face")
    var
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
    end;

    procedure LoadListPlainRows(var O: Codeunit "CLI RegPlain FOwner"; var L: List of [Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainRows(var O: Codeunit "CLI RegPlain FOwner"; var D: Dictionary of [Integer, Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainRows(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadIfacePlainRows(O, GI);
    end;

    procedure FillListPlainRows(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadListPlainRows(O, GL);
    end;

    procedure FillDictPlainRows(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadDictPlainRows(O, GD);
    end;

    procedure KeepIfacePlainRows(var O: Codeunit "CLI RegPlain FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Reg Face";
    begin
        LoadIfacePlainRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillPlainRows(var O: Codeunit "CLI RegPlain FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfacePlainNever(var O: Codeunit "CLI RegPlain FOwner"; var I: Interface "CLI Reg Face")
    var
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
    end;

    procedure LoadListPlainNever(var O: Codeunit "CLI RegPlain FOwner"; var L: List of [Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictPlainNever(var O: Codeunit "CLI RegPlain FOwner"; var D: Dictionary of [Integer, Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfacePlainNever(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadIfacePlainNever(O, GI);
    end;

    procedure FillListPlainNever(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadListPlainNever(O, GL);
    end;

    procedure FillDictPlainNever(var O: Codeunit "CLI RegPlain FOwner")
    begin
        LoadDictPlainNever(O, GD);
    end;

    procedure KeepIfacePlainNever(var O: Codeunit "CLI RegPlain FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Reg Face";
    begin
        LoadIfacePlainNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillPlainNever(var O: Codeunit "CLI RegPlain FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfacePlainNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceTableNo(var O: Codeunit "CLI RegTableNo FOwner"; var I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValTableNo(var O: Codeunit "CLI RegTableNo FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceTableNoRows(var O: Codeunit "CLI RegTableNo FOwner"; var I: Interface "CLI Reg Face")
    var
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
    end;

    procedure LoadListTableNoRows(var O: Codeunit "CLI RegTableNo FOwner"; var L: List of [Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictTableNoRows(var O: Codeunit "CLI RegTableNo FOwner"; var D: Dictionary of [Integer, Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceTableNoRows(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadIfaceTableNoRows(O, GI);
    end;

    procedure FillListTableNoRows(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadListTableNoRows(O, GL);
    end;

    procedure FillDictTableNoRows(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadDictTableNoRows(O, GD);
    end;

    procedure KeepIfaceTableNoRows(var O: Codeunit "CLI RegTableNo FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Reg Face";
    begin
        LoadIfaceTableNoRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillTableNoRows(var O: Codeunit "CLI RegTableNo FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceTableNoRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceTableNoNever(var O: Codeunit "CLI RegTableNo FOwner"; var I: Interface "CLI Reg Face")
    var
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
    end;

    procedure LoadListTableNoNever(var O: Codeunit "CLI RegTableNo FOwner"; var L: List of [Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictTableNoNever(var O: Codeunit "CLI RegTableNo FOwner"; var D: Dictionary of [Integer, Interface "CLI Reg Face"])
    var
        Y: Codeunit "CLI Reg FStore";
        I: Interface "CLI Reg Face";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceTableNoNever(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadIfaceTableNoNever(O, GI);
    end;

    procedure FillListTableNoNever(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadListTableNoNever(O, GL);
    end;

    procedure FillDictTableNoNever(var O: Codeunit "CLI RegTableNo FOwner")
    begin
        LoadDictTableNoNever(O, GD);
    end;

    procedure KeepIfaceTableNoNever(var O: Codeunit "CLI RegTableNo FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Reg Face";
    begin
        LoadIfaceTableNoNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillTableNoNever(var O: Codeunit "CLI RegTableNo FOwner"; I: Interface "CLI Reg Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceTableNoNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77349 "CLI Arr Holder"
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

    procedure SetStoreByVal(NewG: Codeunit "CLS Arr Store")
    begin
        G := NewG;
    end;

    procedure HandByVal(var O: Codeunit "CLS Arr Holder"; var H: Codeunit "CLI Arr Holder")
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByVal(var O: Codeunit "CLS Arr Holder"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(var O: Codeunit "CLS Arr Holder")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(var O: Codeunit "CLS Arr Holder"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
    begin
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(var O: Codeunit "CLS Arr Holder"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarRows(var O: Codeunit "CLS Arr Holder"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        V := Y;
    end;

    procedure FillVarRows(var O: Codeunit "CLS Arr Holder")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(var O: Codeunit "CLS Arr Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure ViaByValFillNever(var O: Codeunit "CLS Arr Holder"; Y: Codeunit "CLS Arr Store"; var Observer: Codeunit "Probe Observer")
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

    procedure LoadVarNever(var O: Codeunit "CLS Arr Holder"; var V: Variant)
    var
        Y: Codeunit "CLS Arr Store";
    begin
        O.ShareAlias(Y);
        V := Y;
    end;

    procedure FillVarNever(var O: Codeunit "CLS Arr Holder")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(var O: Codeunit "CLS Arr Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
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

codeunit 77350 "CLI ArrFace Holder"
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

    procedure SetStoreByVal(NewG: Codeunit "CLI Arr FStore")
    begin
        G := NewG;
    end;

    procedure ViaIface(var O: Codeunit "CLI Arr FOwner"; var I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(var O: Codeunit "CLI Arr FOwner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceRows(var O: Codeunit "CLI Arr FOwner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        I := Y;
    end;

    procedure LoadListRows(var O: Codeunit "CLI Arr FOwner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(var O: Codeunit "CLI Arr FOwner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(var O: Codeunit "CLI Arr FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(var O: Codeunit "CLI Arr FOwner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceNever(var O: Codeunit "CLI Arr FOwner"; var I: Interface "CLI Arr Face")
    var
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        I := Y;
    end;

    procedure LoadListNever(var O: Codeunit "CLI Arr FOwner"; var L: List of [Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(var O: Codeunit "CLI Arr FOwner"; var D: Dictionary of [Integer, Interface "CLI Arr Face"])
    var
        Y: Codeunit "CLI Arr FStore";
        I: Interface "CLI Arr Face";
    begin
        O.ShareAlias(Y);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(var O: Codeunit "CLI Arr FOwner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(var O: Codeunit "CLI Arr FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Arr Face";
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(var O: Codeunit "CLI Arr FOwner"; I: Interface "CLI Arr Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77351 "CLI Plus Holder"
{
    var
        G: Codeunit "CLQ Store Plus";
        GV: Variant;

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

    procedure SetStoreByVal(NewG: Codeunit "CLQ Store Plus")
    begin
        G := NewG;
    end;

    procedure HandByVal(var O: Codeunit "CLQ Plus Holder"; var H: Codeunit "CLI Plus Holder")
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByVal(var O: Codeunit "CLQ Plus Holder"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(var O: Codeunit "CLQ Plus Holder")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(var O: Codeunit "CLQ Plus Holder"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(var O: Codeunit "CLQ Plus Holder"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(var O: Codeunit "CLQ Plus Holder"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(var O: Codeunit "CLQ Plus Holder")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(var O: Codeunit "CLQ Plus Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
    begin
        LoadVarRows(O, V);
        O.SetXN(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
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

    procedure ViaByValFillNever(var O: Codeunit "CLQ Plus Holder"; Y: Codeunit "CLQ Store Plus"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(var O: Codeunit "CLQ Plus Holder"; var V: Variant)
    var
        Y: Codeunit "CLQ Store Plus";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(var O: Codeunit "CLQ Plus Holder")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(var O: Codeunit "CLQ Plus Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Store Plus";
    begin
        LoadVarNever(O, V);
        O.SetXN(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
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

codeunit 77352 "CLI PlusFace Holder"
{
    var
        G: Codeunit "CLI Plus FStore";
        GV: Variant;
        GI: Interface "CLI Plus Face";
        GL: List of [Interface "CLI Plus Face"];
        GD: Dictionary of [Integer, Interface "CLI Plus Face"];

    procedure Write(V: Integer)
    begin
        G.Write(V);
    end;

    procedure VWrite(V: Integer)
    var
        C: Codeunit "CLI Plus FStore";
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
        C: Codeunit "CLI Plus FStore";
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
        C: Codeunit "CLI Plus FStore";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure IWrite(V: Integer)
    begin
        GI.Write(V);
    end;

    procedure LWrite(V: Integer)
    var
        F: Interface "CLI Plus Face";
    begin
        F := GL.Get(1);
        F.Write(V);
    end;

    procedure DWrite(V: Integer)
    var
        F: Interface "CLI Plus Face";
    begin
        F := GD.Get(1);
        F.Write(V);
    end;

    procedure ISetN(V: Integer)
    begin
        GI.SetN(V);
    end;

    procedure LSetN(V: Integer)
    var
        F: Interface "CLI Plus Face";
    begin
        F := GL.Get(1);
        F.SetN(V);
    end;

    procedure DSetN(V: Integer)
    var
        F: Interface "CLI Plus Face";
    begin
        F := GD.Get(1);
        F.SetN(V);
    end;

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLI Plus Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLI Plus Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI Plus FStore")
    begin
        G := NewG;
    end;

    procedure ViaIface(var O: Codeunit "CLI Plus FOwner"; var I: Interface "CLI Plus Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(var O: Codeunit "CLI Plus FOwner"; I: Interface "CLI Plus Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceRows(var O: Codeunit "CLI Plus FOwner"; var I: Interface "CLI Plus Face")
    var
        Y: Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(var O: Codeunit "CLI Plus FOwner"; var L: List of [Interface "CLI Plus Face"])
    var
        Y: Codeunit "CLI Plus FStore";
        I: Interface "CLI Plus Face";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(var O: Codeunit "CLI Plus FOwner"; var D: Dictionary of [Integer, Interface "CLI Plus Face"])
    var
        Y: Codeunit "CLI Plus FStore";
        I: Interface "CLI Plus Face";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(var O: Codeunit "CLI Plus FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Plus Face";
    begin
        LoadIfaceRows(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(var O: Codeunit "CLI Plus FOwner"; I: Interface "CLI Plus Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceNever(var O: Codeunit "CLI Plus FOwner"; var I: Interface "CLI Plus Face")
    var
        Y: Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(var O: Codeunit "CLI Plus FOwner"; var L: List of [Interface "CLI Plus Face"])
    var
        Y: Codeunit "CLI Plus FStore";
        I: Interface "CLI Plus Face";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(var O: Codeunit "CLI Plus FOwner"; var D: Dictionary of [Integer, Interface "CLI Plus Face"])
    var
        Y: Codeunit "CLI Plus FStore";
        I: Interface "CLI Plus Face";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(var O: Codeunit "CLI Plus FOwner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(var O: Codeunit "CLI Plus FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Plus Face";
    begin
        LoadIfaceNever(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(var O: Codeunit "CLI Plus FOwner"; I: Interface "CLI Plus Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
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

codeunit 77353 "CLI Wrap Holder"
{
    var
        G: Codeunit "CLQ Wrapper";
        GV: Variant;

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

    procedure SetStoreByVal(NewG: Codeunit "CLQ Wrapper")
    begin
        G := NewG;
    end;

    procedure HandByVal(var O: Codeunit "CLQ Deep Holder"; var H: Codeunit "CLI Wrap Holder")
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareWrapper(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByVal(var O: Codeunit "CLQ Deep Holder"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
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

    procedure DoClear(var O: Codeunit "CLQ Deep Holder")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(var O: Codeunit "CLQ Deep Holder"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
        DoClear(O);
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

    procedure ViaByValFillRows(var O: Codeunit "CLQ Deep Holder"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
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

    procedure LoadVarRows(var O: Codeunit "CLQ Deep Holder"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarRows(var O: Codeunit "CLQ Deep Holder")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(var O: Codeunit "CLQ Deep Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        LoadVarRows(O, V);
        O.SetWCnt(3);
        C := V;
        Observer.Observe('pre holder after owner write', Format(C.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX());
        C := V;
        Observer.Observe('holder wrapper cnt', Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX());
        C := V;
        C.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        C := V;
        Observer.Observe('holder after write through the inner store of the owner', C.StateX());
    end;

    procedure ViaByValFillNever(var O: Codeunit "CLQ Deep Holder"; Y: Codeunit "CLQ Wrapper"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
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

    procedure LoadVarNever(var O: Codeunit "CLQ Deep Holder"; var V: Variant)
    var
        Y: Codeunit "CLQ Wrapper";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        V := Y;
    end;

    procedure FillVarNever(var O: Codeunit "CLQ Deep Holder")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(var O: Codeunit "CLQ Deep Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        LoadVarNever(O, V);
        O.SetWCnt(3);
        C := V;
        Observer.Observe('pre holder after owner write', Format(C.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX());
        C := V;
        Observer.Observe('holder wrapper cnt', Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX());
        C := V;
        C.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        C := V;
        Observer.Observe('holder after write through the inner store of the owner', C.StateX());
    end;
}

codeunit 77354 "CLI WrapFace Holder"
{
    var
        G: Codeunit "CLI Wrap FStore";
        GV: Variant;
        GI: Interface "CLI Wrap Face";
        GL: List of [Interface "CLI Wrap Face"];
        GD: Dictionary of [Integer, Interface "CLI Wrap Face"];

    procedure WriteX(V: Integer)
    begin
        G.WriteX(V);
    end;

    procedure VWriteX(V: Integer)
    var
        C: Codeunit "CLI Wrap FStore";
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
        C: Codeunit "CLI Wrap FStore";
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
        C: Codeunit "CLI Wrap FStore";
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
        C: Codeunit "CLI Wrap FStore";
    begin
        C := GV;
        exit(C.StateX());
    end;

    procedure IWriteX(V: Integer)
    begin
        GI.WriteX(V);
    end;

    procedure LWriteX(V: Integer)
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GL.Get(1);
        F.WriteX(V);
    end;

    procedure DWriteX(V: Integer)
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GD.Get(1);
        F.WriteX(V);
    end;

    procedure ISetWCnt(V: Integer)
    begin
        GI.SetWCnt(V);
    end;

    procedure LSetWCnt(V: Integer)
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GL.Get(1);
        F.SetWCnt(V);
    end;

    procedure DSetWCnt(V: Integer)
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GD.Get(1);
        F.SetWCnt(V);
    end;

    procedure IGetWCnt(): Integer
    begin
        exit(GI.GetWCnt());
    end;

    procedure LGetWCnt(): Integer
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GL.Get(1);
        exit(F.GetWCnt());
    end;

    procedure DGetWCnt(): Integer
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GD.Get(1);
        exit(F.GetWCnt());
    end;

    procedure IStateX(): Text
    begin
        exit(GI.StateX());
    end;

    procedure LStateX(): Text
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GL.Get(1);
        exit(F.StateX());
    end;

    procedure DStateX(): Text
    var
        F: Interface "CLI Wrap Face";
    begin
        F := GD.Get(1);
        exit(F.StateX());
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI Wrap FStore")
    begin
        G := NewG;
    end;

    procedure ViaIface(var O: Codeunit "CLI Wrap FOwner"; var I: Interface "CLI Wrap Face"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;

    procedure ViaIfaceByVal(var O: Codeunit "CLI Wrap FOwner"; I: Interface "CLI Wrap Face"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;

    procedure LoadIfaceRows(var O: Codeunit "CLI Wrap FOwner"; var I: Interface "CLI Wrap Face")
    var
        Y: Codeunit "CLI Wrap FStore";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListRows(var O: Codeunit "CLI Wrap FOwner"; var L: List of [Interface "CLI Wrap Face"])
    var
        Y: Codeunit "CLI Wrap FStore";
        I: Interface "CLI Wrap Face";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(var O: Codeunit "CLI Wrap FOwner"; var D: Dictionary of [Integer, Interface "CLI Wrap Face"])
    var
        Y: Codeunit "CLI Wrap FStore";
        I: Interface "CLI Wrap Face";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(var O: Codeunit "CLI Wrap FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        LoadIfaceRows(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;

    procedure ViaIfaceByValFillRows(var O: Codeunit "CLI Wrap FOwner"; I: Interface "CLI Wrap Face"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        LoadIfaceRows(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;

    procedure LoadIfaceNever(var O: Codeunit "CLI Wrap FOwner"; var I: Interface "CLI Wrap Face")
    var
        Y: Codeunit "CLI Wrap FStore";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
    end;

    procedure LoadListNever(var O: Codeunit "CLI Wrap FOwner"; var L: List of [Interface "CLI Wrap Face"])
    var
        Y: Codeunit "CLI Wrap FStore";
        I: Interface "CLI Wrap Face";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(var O: Codeunit "CLI Wrap FOwner"; var D: Dictionary of [Integer, Interface "CLI Wrap Face"])
    var
        Y: Codeunit "CLI Wrap FStore";
        I: Interface "CLI Wrap Face";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(var O: Codeunit "CLI Wrap FOwner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(var O: Codeunit "CLI Wrap FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        LoadIfaceNever(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;

    procedure ViaIfaceByValFillNever(var O: Codeunit "CLI Wrap FOwner"; I: Interface "CLI Wrap Face"; var Observer: Codeunit "Probe Observer")
    var
        Inner: Codeunit "CLB Store";
    begin
        LoadIfaceNever(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
    end;
}

codeunit 77355 "CLI TwoDim Holder"
{
    var
        G: Codeunit "CLT B2 Store";
        GV: Variant;

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

    procedure SetStoreByVal(NewG: Codeunit "CLT B2 Store")
    begin
        G := NewG;
    end;

    procedure HandByVal(var O: Codeunit "CLT B2 Holder"; var H: Codeunit "CLI TwoDim Holder")
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        H.SetStoreByVal(Y);
    end;

    procedure ViaByVal(var O: Codeunit "CLT B2 Holder"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure DoClear(var O: Codeunit "CLT B2 Holder")
    begin
        O.ClearAllGlobals();
    end;

    procedure ViaByValOuter(var O: Codeunit "CLT B2 Holder"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        DoClear(O);
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure ViaByValFillRows(var O: Codeunit "CLT B2 Holder"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarRows(var O: Codeunit "CLT B2 Holder"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        V := Y;
    end;

    procedure FillVarRows(var O: Codeunit "CLT B2 Holder")
    begin
        LoadVarRows(O, GV);
    end;

    procedure KeepVarRows(var O: Codeunit "CLT B2 Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarRows(O, V);
        O.SetIntX(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;

    procedure ViaByValFillNever(var O: Codeunit "CLT B2 Holder"; Y: Codeunit "CLT B2 Store"; var Observer: Codeunit "Probe Observer")
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
    end;

    procedure LoadVarNever(var O: Codeunit "CLT B2 Holder"; var V: Variant)
    var
        Y: Codeunit "CLT B2 Store";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        V := Y;
    end;

    procedure FillVarNever(var O: Codeunit "CLT B2 Holder")
    begin
        LoadVarNever(O, GV);
    end;

    procedure KeepVarNever(var O: Codeunit "CLT B2 Holder"; var Observer: Codeunit "Probe Observer")
    var
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        LoadVarNever(O, V);
        O.SetIntX(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
    end;
}

codeunit 77356 "CLI TwoDimFace Holder"
{
    var
        G: Codeunit "CLI TwoDim FStore";
        GV: Variant;
        GI: Interface "CLI TwoDim Face";
        GL: List of [Interface "CLI TwoDim Face"];
        GD: Dictionary of [Integer, Interface "CLI TwoDim Face"];

    procedure Write(I: Integer; J: Integer; V: Integer)
    begin
        G.Write(I, J, V);
    end;

    procedure VWrite(I: Integer; J: Integer; V: Integer)
    var
        C: Codeunit "CLI TwoDim FStore";
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
        C: Codeunit "CLI TwoDim FStore";
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
        C: Codeunit "CLI TwoDim FStore";
    begin
        C := GV;
        exit(C.State());
    end;

    procedure IWrite(I: Integer; J: Integer; V: Integer)
    begin
        GI.Write(I, J, V);
    end;

    procedure LWrite(I: Integer; J: Integer; V: Integer)
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GL.Get(1);
        F.Write(I, J, V);
    end;

    procedure DWrite(I: Integer; J: Integer; V: Integer)
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GD.Get(1);
        F.Write(I, J, V);
    end;

    procedure ISetInt(V: Integer)
    begin
        GI.SetInt(V);
    end;

    procedure LSetInt(V: Integer)
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GL.Get(1);
        F.SetInt(V);
    end;

    procedure DSetInt(V: Integer)
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GD.Get(1);
        F.SetInt(V);
    end;

    procedure IState(): Text
    begin
        exit(GI.State());
    end;

    procedure LState(): Text
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GL.Get(1);
        exit(F.State());
    end;

    procedure DState(): Text
    var
        F: Interface "CLI TwoDim Face";
    begin
        F := GD.Get(1);
        exit(F.State());
    end;

    procedure SetStoreByVal(NewG: Codeunit "CLI TwoDim FStore")
    begin
        G := NewG;
    end;

    procedure ViaIface(var O: Codeunit "CLI TwoDim FOwner"; var I: Interface "CLI TwoDim Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByVal(var O: Codeunit "CLI TwoDim FOwner"; I: Interface "CLI TwoDim Face"; var Observer: Codeunit "Probe Observer")
    begin
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceRows(var O: Codeunit "CLI TwoDim FOwner"; var I: Interface "CLI TwoDim Face")
    var
        Y: Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        I := Y;
    end;

    procedure LoadListRows(var O: Codeunit "CLI TwoDim FOwner"; var L: List of [Interface "CLI TwoDim Face"])
    var
        Y: Codeunit "CLI TwoDim FStore";
        I: Interface "CLI TwoDim Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictRows(var O: Codeunit "CLI TwoDim FOwner"; var D: Dictionary of [Integer, Interface "CLI TwoDim Face"])
    var
        Y: Codeunit "CLI TwoDim FStore";
        I: Interface "CLI TwoDim Face";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceRows(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadIfaceRows(O, GI);
    end;

    procedure FillListRows(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadListRows(O, GL);
    end;

    procedure FillDictRows(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadDictRows(O, GD);
    end;

    procedure KeepIfaceRows(var O: Codeunit "CLI TwoDim FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI TwoDim Face";
    begin
        LoadIfaceRows(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillRows(var O: Codeunit "CLI TwoDim FOwner"; I: Interface "CLI TwoDim Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceRows(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure LoadIfaceNever(var O: Codeunit "CLI TwoDim FOwner"; var I: Interface "CLI TwoDim Face")
    var
        Y: Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        I := Y;
    end;

    procedure LoadListNever(var O: Codeunit "CLI TwoDim FOwner"; var L: List of [Interface "CLI TwoDim Face"])
    var
        Y: Codeunit "CLI TwoDim FStore";
        I: Interface "CLI TwoDim Face";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        I := Y;
        L.Add(I);
    end;

    procedure LoadDictNever(var O: Codeunit "CLI TwoDim FOwner"; var D: Dictionary of [Integer, Interface "CLI TwoDim Face"])
    var
        Y: Codeunit "CLI TwoDim FStore";
        I: Interface "CLI TwoDim Face";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        I := Y;
        D.Add(1, I);
    end;

    procedure FillIfaceNever(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadIfaceNever(O, GI);
    end;

    procedure FillListNever(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadListNever(O, GL);
    end;

    procedure FillDictNever(var O: Codeunit "CLI TwoDim FOwner")
    begin
        LoadDictNever(O, GD);
    end;

    procedure KeepIfaceNever(var O: Codeunit "CLI TwoDim FOwner"; var Observer: Codeunit "Probe Observer")
    var
        I: Interface "CLI TwoDim Face";
    begin
        LoadIfaceNever(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;

    procedure ViaIfaceByValFillNever(var O: Codeunit "CLI TwoDim FOwner"; I: Interface "CLI TwoDim Face"; var Observer: Codeunit "Probe Observer")
    begin
        LoadIfaceNever(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
    end;
}

codeunit 77357 "CLI Price Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Price_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        K.ViaByValFillRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller argument after return', 't1=0 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        O.GetStore(Y);
        O.Prepare();
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        O.GetStore(Y);
        O.Prepare();
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Hd: Codeunit "CLI Price Holder";
        Hander: Codeunit "CLI Price Holder";
    begin
        Hander.HandByVal(O, Hd);
        O.Prepare();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Hd.State());
        Hd.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Hd.State());
        Hd.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Price BOwner";
        Y: Codeunit "CLV Price Store";
    begin
        O.SetStoreByVal(Y);
        O.Prepare();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        K.LoadVarRows(O, V);
        O.SetInt(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        C := V;
        C.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillVarRows(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.VState());
        K.VSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.VState());
        K.VWriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=3 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceRows(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillIfaceRows(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.IState());
        K.ISetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.IState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.IState());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        L: List of [Interface "CLV Store Face"];
        F: Interface "CLV Store Face";
    begin
        K.LoadListRows(O, L);
        O.SetInt(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        O.WriteT1(4);
        F := L.Get(1);
        Observer.Observe('holder after owner row', F.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillListRows(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.LState());
        K.LSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.LState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.LState());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        D: Dictionary of [Integer, Interface "CLV Store Face"];
        F: Interface "CLV Store Face";
    begin
        K.LoadDictRows(O, D);
        O.SetInt(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        O.WriteT1(4);
        F := D.Get(1);
        Observer.Observe('holder after owner row', F.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillDictRows(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.DState());
        K.DSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.DState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.DState());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        Z: Codeunit "CLV Price Store";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Expect('caller argument after return', 't1=0 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        O.Prepare();
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=2 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=2 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=2 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=2 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=2 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=3 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=3 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        K.ViaByValFillNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller argument after return', 't1=0 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        O.GetStore(Y);
        Y.Mark();
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller holder after return', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Y: Codeunit "CLV Price Store";
        K: Codeunit "CLI Price Holder";
    begin
        O.GetStore(Y);
        Y.Mark();
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Expect('caller holder after return', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        Hd: Codeunit "CLI Price Holder";
        Hander: Codeunit "CLI Price Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.Mark();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Hd.State());
        Hd.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Hd.State());
        Hd.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Price BOwner";
        Y: Codeunit "CLV Price Store";
    begin
        O.SetStoreByVal(Y);
        Y.Mark();
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', Y.State());
        Y.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', Y.State());
        Y.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        V: Variant;
        C: Codeunit "CLV Price Store";
    begin
        K.LoadVarNever(O, V);
        O.SetInt(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        C := V;
        C.WriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillVarNever(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.VState());
        K.VSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.VState());
        K.VWriteT1(4);
        Observer.Observe('owner after holder row', O.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('owner after holder row', 't1=1 kind=None int=11 lc=store label cnt=0 line=1');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceNever(O, I);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', I.State());
        I.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', I.State());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', I.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillIfaceNever(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.IState());
        K.ISetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.IState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.IState());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        L: List of [Interface "CLV Store Face"];
        F: Interface "CLV Store Face";
    begin
        K.LoadListNever(O, L);
        O.SetInt(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        O.WriteT1(4);
        F := L.Get(1);
        Observer.Observe('holder after owner row', F.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillListNever(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.LState());
        K.LSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.LState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.LState());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        D: Dictionary of [Integer, Interface "CLV Store Face"];
        F: Interface "CLV Store Face";
    begin
        K.LoadDictNever(O, D);
        O.SetInt(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.SetLine();
        Observer.Observe('owner', O.State());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.SetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        O.WriteT1(4);
        F := D.Get(1);
        Observer.Observe('holder after owner row', F.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
    begin
        K.FillDictNever(O);
        O.SetInt(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.SetLine();
        Observer.Observe('owner', O.State());
        Observer.Observe('holder', K.DState());
        K.DSetInt(10);
        Observer.Observe('owner after holder write', O.State());
        O.SetInt(11);
        Observer.Observe('holder after owner write', K.DState());
        O.WriteT1(4);
        Observer.Observe('holder after owner row', K.DState());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        I: Interface "CLV Store Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        Z: Codeunit "CLV Price Store";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Expect('caller argument after return', 't1=0 kind=None int=0 lc=store label');
        Observer.Verify();
    end;

    [Test]
    procedure Price_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLV Line Owner";
        K: Codeunit "CLI Price Holder";
        Y: Codeunit "CLV Price Store";
    begin
        O.GetStore(Y);
        Y.Mark();
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 't1=0 kind=Beta int=3 lc=store label');
        Observer.Expect('owner', 't1=0 kind=None int=0 lc=store label cnt=0 line=1');
        Observer.Expect('holder', 't1=0 kind=None int=0 lc=store label');
        Observer.Expect('owner after holder write', 't1=0 kind=None int=10 lc=store label cnt=0 line=1');
        Observer.Expect('holder after owner write', 't1=0 kind=None int=11 lc=store label');
        Observer.Expect('holder after owner row', 't1=1 kind=None int=11 lc=store label');
        Observer.Expect('caller holder after return', 't1=1 kind=None int=11 lc=store label');
        Observer.Verify();
    end;
}

codeunit 77358 "CLI Reg Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RegPlain_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        K.ViaByValFillPlainRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Hd: Codeunit "CLI Reg Holder";
        Hander: Codeunit "CLI Reg Holder";
    begin
        Hander.HandByValPlain(O, Hd);
        Hd.Mark();
        Hd.WriteRow(1);
        Hd.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
    begin
        O.SetRegisterByValue(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        K.LoadVarPlainRows(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.KeepVarPlainRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.FillVarPlainRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        K.ViaByValFillPlainNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaByValOuterPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Hd: Codeunit "CLI Reg Holder";
        Hander: Codeunit "CLI Reg Holder";
    begin
        Hander.HandByValPlain(O, Hd);
        Hd.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        Y: Codeunit "CLR Register";
    begin
        O.SetRegisterByValue(Y);
        Y.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        K.LoadVarPlainNever(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.KeepVarPlainNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR Plain Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.FillVarPlainNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        K.ViaByValFillTableNoRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaByValOuterTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Hd: Codeunit "CLI Reg Holder";
        Hander: Codeunit "CLI Reg Holder";
    begin
        Hander.HandByValTableNo(O, Hd);
        Hd.Mark();
        Hd.WriteRow(1);
        Hd.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
    begin
        O.SetRegisterByValue(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        K.LoadVarTableNoRows(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.KeepVarTableNoRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.FillVarTableNoRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        K.ViaByValFillTableNoNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
        K: Codeunit "CLI Reg Holder";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaByValOuterTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Hd: Codeunit "CLI Reg Holder";
        Hander: Codeunit "CLI Reg Holder";
    begin
        Hander.HandByValTableNo(O, Hd);
        Hd.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        Y: Codeunit "CLR Register";
    begin
        O.SetRegisterByValue(Y);
        Y.Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
        V: Variant;
        C: Codeunit "CLR Register";
    begin
        K.LoadVarTableNoNever(O, V);
        O.MarkReg();
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.KeepVarTableNoNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLR TableNo Owner";
        K: Codeunit "CLI Reg Holder";
    begin
        K.FillVarTableNoNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 77359 "CLI RegFace Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RegPlain_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        A: array[2] of Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        A[2].WriteRow(1);
        A[2].WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.KeepIfacePlainRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillIfacePlainRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        L: List of [Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadListPlainRows(O, L);
        O.MarkReg();
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillListPlainRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        D: Dictionary of [Integer, Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadDictPlainRows(O, D);
        O.MarkReg();
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillDictPlainRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainRows(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainRows(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        Z: Codeunit "CLI Reg FStore";
    begin
        K.ViaIfaceByValFillPlainRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        A: array[2] of Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.KeepIfacePlainNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillIfacePlainNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        L: List of [Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadListPlainNever(O, L);
        O.MarkReg();
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillListPlainNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        D: Dictionary of [Integer, Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadDictPlainNever(O, D);
        O.MarkReg();
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillDictPlainNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfacePlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfacePlainNever(O, I);
        K.ViaIfaceByValPlain(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        Z: Codeunit "CLI Reg FStore";
    begin
        K.ViaIfaceByValFillPlainNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegPlain_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegPlain FOwner";
        K: Codeunit "CLI RegFace Holder";
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaIfaceByValPlain(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        A: array[2] of Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        A[2].WriteRow(1);
        A[2].WriteRow(2);
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoRows(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.KeepIfaceTableNoRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillIfaceTableNoRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        L: List of [Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadListTableNoRows(O, L);
        O.MarkReg();
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillListTableNoRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        D: Dictionary of [Integer, Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadDictTableNoRows(O, D);
        O.MarkReg();
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillDictTableNoRows(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoRows(O, I);
        K.ViaIfaceTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoRows(O, I);
        K.ViaIfaceByValTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        Z: Codeunit "CLI Reg FStore";
    begin
        K.ViaIfaceByValFillTableNoRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        Y.WriteRow(1);
        Y.WriteRow(2);
        O.SetCnt(5);
        K.ViaIfaceByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=2 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=3 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=4 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        A: array[2] of Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(A[2]);
        A[2].Mark();
        O.SetCnt(5);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoNever(O, I);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.KeepIfaceTableNoNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillIfaceTableNoNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        L: List of [Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadListTableNoNever(O, L);
        O.MarkReg();
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillListTableNoNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        D: Dictionary of [Integer, Interface "CLI Reg Face"];
        F: Interface "CLI Reg Face";
    begin
        K.LoadDictTableNoNever(O, D);
        O.MarkReg();
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.WriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
    begin
        K.FillDictTableNoNever(O);
        O.MarkReg();
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateReg());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWriteRow(11);
        Observer.Observe('owner after holder write', O.StateReg());
        O.WriteReg(12);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoNever(O, I);
        K.ViaIfaceTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        I: Interface "CLI Reg Face";
    begin
        K.LoadIfaceTableNoNever(O, I);
        K.ViaIfaceByValTableNo(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        Z: Codeunit "CLI Reg FStore";
    begin
        K.ViaIfaceByValFillTableNoNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller argument after return', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;

    [Test]
    procedure RegTableNo_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI RegTableNo FOwner";
        K: Codeunit "CLI RegFace Holder";
        Y: Codeunit "CLI Reg FStore";
    begin
        O.SetRegister(Y);
        Y.Mark();
        O.SetCnt(5);
        K.ViaIfaceByValTableNo(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 dec=1.5 flag=Yes code=MARK recfilter=No.: 7 recno=9 nested=4');
        Observer.Expect('owner', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('owner after holder write', 'rows=1 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('holder after owner write', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Expect('caller holder after return', 'rows=2 dec=0 flag=No code= recfilter= recno=0 nested=0');
        Observer.Verify();
    end;
}

codeunit 77360 "CLI Arr Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Arr_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        K.ViaByValFillRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Hd: Codeunit "CLI Arr Holder";
        Hander: Codeunit "CLI Arr Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.Write(1, 3);
        Hd.Write(2, 4);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Hd.State());
        Hd.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr BOwner";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStoreByVal(Y);
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
    procedure Arr_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarRows(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
    begin
        K.FillVarRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        K.ViaByValFillNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        O.ShareAlias(Y);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
        K: Codeunit "CLI Arr Holder";
    begin
        O.ShareAlias(Y);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        Hd: Codeunit "CLI Arr Holder";
        Hander: Codeunit "CLI Arr Holder";
    begin
        Hander.HandByVal(O, Hd);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Hd.State());
        Hd.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr BOwner";
        Y: Codeunit "CLS Arr Store";
    begin
        O.SetStoreByVal(Y);
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

    [Test]
    procedure Arr_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
        V: Variant;
        C: Codeunit "CLS Arr Store";
    begin
        K.LoadVarNever(O, V);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLS Arr Holder";
        K: Codeunit "CLI Arr Holder";
    begin
        K.FillVarNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;
}

codeunit 77361 "CLI ArrFace Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Arr_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        A: array[2] of Codeunit "CLI Arr FStore";
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
    procedure Arr_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillIfaceRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListRows(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillListRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictRows(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillDictRows(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=4 rows2=4 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        A: array[2] of Codeunit "CLI Arr FStore";
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
    procedure Arr_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillIfaceNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        L: List of [Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadListNever(O, L);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillListNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        D: Dictionary of [Integer, Interface "CLI Arr Face"];
        F: Interface "CLI Arr Face";
    begin
        K.LoadDictNever(O, D);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
    begin
        K.FillDictNever(O);
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 6);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        I: Interface "CLI Arr Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        Z: Codeunit "CLI Arr FStore";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller argument after return', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure Arr_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Arr FOwner";
        K: Codeunit "CLI ArrFace Holder";
        Y: Codeunit "CLI Arr FStore";
    begin
        O.ShareAlias(Y);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('owner', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('holder', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('owner after holder write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Expect('holder after owner write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Expect('caller holder after return', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;
}

codeunit 77362 "CLI Plus Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Plus_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        K.ViaByValFillRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Hd: Codeunit "CLI Plus Holder";
        Hander: Codeunit "CLI Plus Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.Write(3);
        Hd.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus BOwner";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStoreByVal(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
    begin
        K.LoadVarRows(O, V);
        O.SetXN(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
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
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
    begin
        K.FillVarRows(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        K.ViaByValFillNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Y: Codeunit "CLQ Store Plus";
        K: Codeunit "CLI Plus Holder";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        Hd: Codeunit "CLI Plus Holder";
        Hander: Codeunit "CLI Plus Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.State());
        Hd.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus BOwner";
        Y: Codeunit "CLQ Store Plus";
    begin
        O.SetStoreByVal(Y);
        Y.SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Y.State());
        Y.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
        V: Variant;
        C: Codeunit "CLQ Store Plus";
    begin
        K.LoadVarNever(O, V);
        O.SetXN(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
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
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Plus Holder";
        K: Codeunit "CLI Plus Holder";
    begin
        K.FillVarNever(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VState());
        K.VWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 77363 "CLI PlusFace Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Plus_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        A: array[2] of Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(3);
        A[2].SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceRows(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillIfaceRows(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        L: List of [Interface "CLI Plus Face"];
        F: Interface "CLI Plus Face";
    begin
        K.LoadListRows(O, L);
        O.SetXN(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
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
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillListRows(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        D: Dictionary of [Integer, Interface "CLI Plus Face"];
        F: Interface "CLI Plus Face";
    begin
        K.LoadDictRows(O, D);
        O.SetXN(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
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
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillDictRows(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        Z: Codeunit "CLI Plus FStore";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        Y: Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(3);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 n=3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        A: array[2] of Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(A[2]);
        A[2].SetN(6);
        O.SetCnt(4);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', A[2].State());
        A[2].Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceNever(O, I);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.State());
        I.Write(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillIfaceNever(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IState());
        K.IWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        L: List of [Interface "CLI Plus Face"];
        F: Interface "CLI Plus Face";
    begin
        K.LoadListNever(O, L);
        O.SetXN(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
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
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillListNever(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LState());
        K.LWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        D: Dictionary of [Integer, Interface "CLI Plus Face"];
        F: Interface "CLI Plus Face";
    begin
        K.LoadDictNever(O, D);
        O.SetXN(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
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
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
    begin
        K.FillDictNever(O);
        O.SetXN(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DState());
        K.DWrite(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        I: Interface "CLI Plus Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        Z: Codeunit "CLI Plus FStore";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Plus FOwner";
        K: Codeunit "CLI PlusFace Holder";
        Y: Codeunit "CLI Plus FStore";
    begin
        O.ShareAlias(Y);
        Y.SetN(6);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 n=0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 n=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Expect('caller holder after return', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0 n=0');
        Observer.Verify();
    end;
}

codeunit 77364 "CLI Wrap Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Wrap_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        K.ViaByValFillRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.StateX());
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Hd: Codeunit "CLI Wrap Holder";
        Hander: Codeunit "CLI Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        Hander.HandByVal(O, Hd);
        Hd.WriteX(3);
        Hd.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Hd.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.StateX());
        Observer.Observe('holder wrapper cnt', Format(Hd.GetWCnt()));
        Hd.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Hd.StateX());
        Hd.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Hd.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap BOwner";
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
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
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadVarRows(O, V);
        O.SetWCnt(3);
        C := V;
        Observer.Observe('pre holder after owner write', Format(C.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX());
        C := V;
        Observer.Observe('holder wrapper cnt', Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX());
        C := V;
        C.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        C := V;
        Observer.Observe('holder after write through the inner store of the owner', C.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillVarRows(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.VGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VStateX());
        Observer.Observe('holder wrapper cnt', Format(K.VGetWCnt()));
        K.VWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VStateX());
        K.VSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.VStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        K.ViaByValFillNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.StateX());
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Y: Codeunit "CLQ Wrapper";
        K: Codeunit "CLI Wrap Holder";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        Hd: Codeunit "CLI Wrap Holder";
        Hander: Codeunit "CLI Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        Hander.HandByVal(O, Hd);
        Hd.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Hd.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', Hd.StateX());
        Observer.Observe('holder wrapper cnt', Format(Hd.GetWCnt()));
        Hd.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', Hd.StateX());
        Hd.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', Hd.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap BOwner";
        Y: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        O.SetStoreByVal(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(Y.GetWCnt()));
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
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
        V: Variant;
        C: Codeunit "CLQ Wrapper";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadVarNever(O, V);
        O.SetWCnt(3);
        C := V;
        Observer.Observe('pre holder after owner write', Format(C.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        C := V;
        Observer.Observe('holder', C.StateX());
        C := V;
        Observer.Observe('holder wrapper cnt', Format(C.GetWCnt()));
        C := V;
        C.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        C := V;
        Observer.Observe('holder after owner write', C.StateX());
        C := V;
        C.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        C := V;
        Observer.Observe('holder after write through the inner store of the owner', C.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLQ Deep Holder";
        K: Codeunit "CLI Wrap Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillVarNever(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.VGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.VStateX());
        Observer.Observe('holder wrapper cnt', Format(K.VGetWCnt()));
        K.VWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.VStateX());
        K.VSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.VStateX());
        Observer.Expect('pre holder after owner write', '3');
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

codeunit 77365 "CLI WrapFace Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Wrap_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        A: array[2] of Codeunit "CLI Wrap FStore";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(A[2]);
        A[2].WriteX(3);
        A[2].SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(A[2].GetWCnt()));
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
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadIfaceRows(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillIfaceRows(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.IGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IStateX());
        Observer.Observe('holder wrapper cnt', Format(K.IGetWCnt()));
        K.IWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IStateX());
        K.ISetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.IStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        L: List of [Interface "CLI Wrap Face"];
        F: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadListRows(O, L);
        O.SetWCnt(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', Format(F.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.StateX());
        F := L.Get(1);
        Observer.Observe('holder wrapper cnt', Format(F.GetWCnt()));
        F := L.Get(1);
        F.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.StateX());
        F := L.Get(1);
        F.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        F := L.Get(1);
        Observer.Observe('holder after write through the inner store of the owner', F.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillListRows(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.LGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LStateX());
        Observer.Observe('holder wrapper cnt', Format(K.LGetWCnt()));
        K.LWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LStateX());
        K.LSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.LStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        D: Dictionary of [Integer, Interface "CLI Wrap Face"];
        F: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadDictRows(O, D);
        O.SetWCnt(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', Format(F.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.StateX());
        F := D.Get(1);
        Observer.Observe('holder wrapper cnt', Format(F.GetWCnt()));
        F := D.Get(1);
        F.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.StateX());
        F := D.Get(1);
        F.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        F := D.Get(1);
        Observer.Observe('holder after write through the inner store of the owner', F.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillDictRows(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.DGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DStateX());
        Observer.Observe('holder wrapper cnt', Format(K.DGetWCnt()));
        K.DWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DStateX());
        K.DSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.DStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(I.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(I.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Z: Codeunit "CLI Wrap FStore";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.StateX());
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Y: Codeunit "CLI Wrap FStore";
    begin
        O.ShareWrapper(Y);
        Y.WriteX(3);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=3 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=4 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        A: array[2] of Codeunit "CLI Wrap FStore";
        Inner: Codeunit "CLB Store";
    begin
        O.ShareWrapper(A[2]);
        A[2].SetWCnt(2);
        O.SetCnt(4);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(A[2].GetWCnt()));
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
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadIfaceNever(O, I);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(I.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', I.StateX());
        Observer.Observe('holder wrapper cnt', Format(I.GetWCnt()));
        I.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', I.StateX());
        I.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', I.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillIfaceNever(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.IGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.IStateX());
        Observer.Observe('holder wrapper cnt', Format(K.IGetWCnt()));
        K.IWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.IStateX());
        K.ISetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.IStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        L: List of [Interface "CLI Wrap Face"];
        F: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadListNever(O, L);
        O.SetWCnt(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', Format(F.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := L.Get(1);
        Observer.Observe('holder', F.StateX());
        F := L.Get(1);
        Observer.Observe('holder wrapper cnt', Format(F.GetWCnt()));
        F := L.Get(1);
        F.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.StateX());
        F := L.Get(1);
        F.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        F := L.Get(1);
        Observer.Observe('holder after write through the inner store of the owner', F.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillListNever(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.LGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.LStateX());
        Observer.Observe('holder wrapper cnt', Format(K.LGetWCnt()));
        K.LWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.LStateX());
        K.LSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.LStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        D: Dictionary of [Integer, Interface "CLI Wrap Face"];
        F: Interface "CLI Wrap Face";
        Inner: Codeunit "CLB Store";
    begin
        K.LoadDictNever(O, D);
        O.SetWCnt(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', Format(F.GetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        F := D.Get(1);
        Observer.Observe('holder', F.StateX());
        F := D.Get(1);
        Observer.Observe('holder wrapper cnt', Format(F.GetWCnt()));
        F := D.Get(1);
        F.WriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.StateX());
        F := D.Get(1);
        F.SetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        F := D.Get(1);
        Observer.Observe('holder after write through the inner store of the owner', F.StateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Inner: Codeunit "CLB Store";
    begin
        K.FillDictNever(O);
        O.SetWCnt(3);
        Observer.Observe('pre holder after owner write', Format(K.DGetWCnt()));
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('owner wrapper cnt', Format(O.GetWCnt()));
        Observer.Observe('owner cnt', Format(O.GetCnt()));
        Observer.Observe('holder', K.DStateX());
        Observer.Observe('holder wrapper cnt', Format(K.DGetWCnt()));
        K.DWriteX(5);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(7);
        Observer.Observe('holder after owner write', K.DStateX());
        K.DSetWCnt(8);
        Observer.Observe('owner wrapper cnt after holder write', Format(O.GetWCnt()));
        O.ShareAlias(Inner);
        Inner.Write(9);
        Observer.Observe('holder after write through the inner store of the owner', K.DStateX());
        Observer.Expect('pre holder after owner write', '3');
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
    procedure Wrap_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(I.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        I: Interface "CLI Wrap Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(I.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Z: Codeunit "CLI Wrap FStore";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.StateX());
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller argument after return', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Wrap_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI Wrap FOwner";
        K: Codeunit "CLI WrapFace Holder";
        Y: Codeunit "CLI Wrap FStore";
    begin
        O.ShareWrapper(Y);
        Y.SetWCnt(2);
        O.SetCnt(4);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.StateX());
        Observer.Observe('caller holder wrapper cnt after return', Format(Y.GetWCnt()));
        Observer.Expect('pre holder after owner write', '3');
        Observer.Expect('owner', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('owner wrapper cnt', '0');
        Observer.Expect('owner cnt', '0');
        Observer.Expect('holder', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('holder wrapper cnt', '0');
        Observer.Expect('owner after holder write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('holder after owner write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=7 int3=0');
        Observer.Expect('owner wrapper cnt after holder write', '8');
        Observer.Expect('holder after write through the inner store of the owner', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder after return', 'rows=3 ref11=75586 refrows=3 ref23=0 int1=9 int3=0');
        Observer.Expect('caller holder wrapper cnt after return', '8');
        Observer.Verify();
    end;
}

codeunit 77366 "CLI TwoDim Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TwoDim_ByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.ViaByValFillRows(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller argument after return', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValDeep_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValSetterOut_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Hd: Codeunit "CLI TwoDim Holder";
        Hander: Codeunit "CLI TwoDim Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.Write(1, 1, 1);
        Hd.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Hd.State());
        Hd.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValSetterIn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim BOwner";
        Y: Codeunit "CLT B2 Store";
    begin
        O.SetStoreByVal(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        K.LoadVarRows(O, V);
        O.SetIntX(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.KeepVarRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.FillVarRows(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.ViaByValFillNever(O, Y, Observer);
        Observer.Observe('caller argument after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller argument after return', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        K.ViaByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValDeep_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Y: Codeunit "CLT B2 Store";
        K: Codeunit "CLI TwoDim Holder";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        K.ViaByValOuter(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValSetterOut_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        Hd: Codeunit "CLI TwoDim Holder";
        Hander: Codeunit "CLI TwoDim Holder";
    begin
        Hander.HandByVal(O, Hd);
        Hd.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Hd.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Hd.State());
        Hd.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Hd.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ByValSetterIn_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim BOwner";
        Y: Codeunit "CLT B2 Store";
    begin
        O.SetStoreByVal(Y);
        Y.SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', Y.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', Y.State());
        Y.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
        V: Variant;
        C: Codeunit "CLT B2 Store";
    begin
        K.LoadVarNever(O, V);
        O.SetIntX(3);
        C := V;
        Observer.Observe('pre holder after owner write', C.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        C := V;
        Observer.Observe('holder', C.State());
        C := V;
        C.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        C := V;
        Observer.Observe('holder after owner write', C.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.KeepVarNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_VariantGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLT B2 Holder";
        K: Codeunit "CLI TwoDim Holder";
    begin
        K.FillVarNever(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.VState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.VState());
        K.VWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.VState());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;
}

codeunit 77367 "CLI TwoDimFace Slot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TwoDim_ArrayElement_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        A: array[2] of Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(A[2]);
        A[2].Write(1, 1, 1);
        A[2].SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceRows(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceCallerLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.KeepIfaceRows(O, Observer);
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillIfaceRows(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ListLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        L: List of [Interface "CLI TwoDim Face"];
        F: Interface "CLI TwoDim Face";
    begin
        K.LoadListRows(O, L);
        O.SetIntX(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ListGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillListRows(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_DictLocal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        D: Dictionary of [Integer, Interface "CLI TwoDim Face"];
        F: Interface "CLI TwoDim Face";
    begin
        K.LoadDictRows(O, D);
        O.SetIntX(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_DictGlobal_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillDictRows(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceVarParam_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValPassed_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceRows(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValFill_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        Z: Codeunit "CLI TwoDim FStore";
    begin
        K.ViaIfaceByValFillRows(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller argument after return', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValFromCodeunit_Rows()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        Y: Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(Y);
        Y.Write(1, 1, 1);
        Y.SetInt(7);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=1 b12=1 b21=1 b22=1 int1=3');
        Observer.Expect('owner', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('owner after holder write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('holder after owner write', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Expect('caller holder after return', 'b11=3 b12=3 b21=3 b22=3 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ArrayElement_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        A: array[2] of Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(A[2]);
        A[2].SetInt(7);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', A[2].State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', A[2].State());
        A[2].Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', A[2].State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceNever(O, I);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', I.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', I.State());
        I.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', I.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceCallerLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.KeepIfaceNever(O, Observer);
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillIfaceNever(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.IState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.IState());
        K.IWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.IState());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ListLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        L: List of [Interface "CLI TwoDim Face"];
        F: Interface "CLI TwoDim Face";
    begin
        K.LoadListNever(O, L);
        O.SetIntX(3);
        F := L.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := L.Get(1);
        Observer.Observe('holder', F.State());
        F := L.Get(1);
        F.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        F := L.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_ListGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillListNever(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.LState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.LState());
        K.LWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.LState());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_DictLocal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        D: Dictionary of [Integer, Interface "CLI TwoDim Face"];
        F: Interface "CLI TwoDim Face";
    begin
        K.LoadDictNever(O, D);
        O.SetIntX(3);
        F := D.Get(1);
        Observer.Observe('pre holder after owner write', F.State());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        F := D.Get(1);
        Observer.Observe('holder', F.State());
        F := D.Get(1);
        F.Write(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        F := D.Get(1);
        Observer.Observe('holder after owner write', F.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_DictGlobal_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
    begin
        K.FillDictNever(O);
        O.SetIntX(3);
        Observer.Observe('pre holder after owner write', K.DState());
        O.ClearAllGlobals();
        Observer.Observe('owner', O.StateX());
        Observer.Observe('holder', K.DState());
        K.DWrite(2, 2, 2);
        Observer.Observe('owner after holder write', O.StateX());
        O.WriteX(1, 2, 3);
        Observer.Observe('holder after owner write', K.DState());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceVarParam_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIface(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValPassed_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        I: Interface "CLI TwoDim Face";
    begin
        K.LoadIfaceNever(O, I);
        K.ViaIfaceByVal(O, I, Observer);
        Observer.Observe('caller holder after return', I.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValFill_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        Z: Codeunit "CLI TwoDim FStore";
    begin
        K.ViaIfaceByValFillNever(O, Z, Observer);
        Observer.Observe('caller argument after return', Z.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller argument after return', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_IfaceByValFromCodeunit_Never()
    var
        Observer: Codeunit "Probe Observer";
        O: Codeunit "CLI TwoDim FOwner";
        K: Codeunit "CLI TwoDimFace Holder";
        Y: Codeunit "CLI TwoDim FStore";
    begin
        O.ShareAlias(Y);
        Y.SetInt(7);
        K.ViaIfaceByVal(O, Y, Observer);
        Observer.Observe('caller holder after return', Y.State());
        Observer.Expect('pre holder after owner write', 'b11=0 b12=0 b21=0 b22=0 int1=3');
        Observer.Expect('owner', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('holder', 'b11=0 b12=0 b21=0 b22=0 int1=0');
        Observer.Expect('owner after holder write', 'b11=1 b12=1 b21=1 b22=1 int1=0');
        Observer.Expect('holder after owner write', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Expect('caller holder after return', 'b11=2 b12=2 b21=2 b22=2 int1=0');
        Observer.Verify();
    end;
}
