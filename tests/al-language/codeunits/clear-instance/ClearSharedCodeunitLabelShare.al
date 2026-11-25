// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586) of ClearSharedCodeunitTempRef.al;
//   "CLL Store First", "CLL Store Mid" and "CLL Store Last" (codeunits 77155 to 77157) of
//   ClearSharedCodeunitLabelStore.al; self-contained objects 77215 to 77224
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: the store with one global Label (first, in the middle, last in the var list) shared by other holder kinds
//   than the var-parameter alias of ClearSharedCodeunitLabelStore.al. X is written once (3) before the clear.
//   - Iface: "CLL IStore First/Mid/Last" are the same stores that implement "CLL ILabelStore"; the holder hands X to
//     an interface variable I of the test, then runs ClearAll or Clear(X); the test reads I and X, writes 5 through
//     I and reads both again.
//   - ValueParam: the holder passes X by value to the routine that runs ClearAll or Clear(X) and reads the
//     parameter P and X there. ValueParamOuter: P is a by-value parameter of the caller of the clearing routine.
//     Result text: p: <P> <label of P> | x: <X> <label of X> || p: <P after P.Write(5)> | x: <X after it>.
//   Measured on BC 29.0 (Linux), the same for the three Label positions:
//   - ClearAll: the interface variable and the by-value parameter (of the clearing routine or of its caller) stay on
//     X's instance. It is reset in place as in ClearSharedCodeunitLabelStore.al (rows=1 kept, RecordRef [1,1] closed,
//     Integers 0), and a write through the sharer shows through X (rows=2).
//   - Clear(X): X gets a fresh instance (rows=0). The interface variable and the by-value parameter keep the old one
//     with its values (rows=1, int1=3); a later write through them does not show through X.
//   - The Label keeps its text on both sides in every cell.
// BC versions: 27, 28, 29

interface "CLL ILabelStore"
{
    procedure Write(V: Integer);
    procedure State(): Text;
    procedure LabelText(): Text;
}

codeunit 77215 "CLL IStore First" implements "CLL ILabelStore"
{
    var
        Lbl: Label 'kept label text';
        Rows: Record "CLB Row" temporary;
        Refs: array[2, 3] of RecordRef;
        Ints: array[3] of Integer;

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
        exit(StrSubstNo('rows=%1 ref11=%2 refrows=%3 ref23=%4 int1=%5 int3=%6',
            Rows.Count(), Refs[1, 1].Number, RefRows, Refs[2, 3].Number, Ints[1], Ints[3]));
    end;

    procedure LabelText(): Text
    begin
        exit(Lbl);
    end;
}

codeunit 77216 "CLL IStore Mid" implements "CLL ILabelStore"
{
    var
        Rows: Record "CLB Row" temporary;
        Lbl: Label 'kept label text';
        Refs: array[2, 3] of RecordRef;
        Ints: array[3] of Integer;

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
        exit(StrSubstNo('rows=%1 ref11=%2 refrows=%3 ref23=%4 int1=%5 int3=%6',
            Rows.Count(), Refs[1, 1].Number, RefRows, Refs[2, 3].Number, Ints[1], Ints[3]));
    end;

    procedure LabelText(): Text
    begin
        exit(Lbl);
    end;
}

codeunit 77217 "CLL IStore Last" implements "CLL ILabelStore"
{
    var
        Rows: Record "CLB Row" temporary;
        Refs: array[2, 3] of RecordRef;
        Ints: array[3] of Integer;
        Lbl: Label 'kept label text';

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
        exit(StrSubstNo('rows=%1 ref11=%2 refrows=%3 ref23=%4 int1=%5 int3=%6',
            Rows.Count(), Refs[1, 1].Number, RefRows, Refs[2, 3].Number, Ints[1], Ints[3]));
    end;

    procedure LabelText(): Text
    begin
        exit(Lbl);
    end;
}

codeunit 77218 "CLL IHolder First"
{
    var
        X: Codeunit "CLL IStore First";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ShareIface(var I: Interface "CLL ILabelStore")
    begin
        I := X;
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

codeunit 77219 "CLL IHolder Mid"
{
    var
        X: Codeunit "CLL IStore Mid";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ShareIface(var I: Interface "CLL ILabelStore")
    begin
        I := X;
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

codeunit 77220 "CLL IHolder Last"
{
    var
        X: Codeunit "CLL IStore Last";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ShareIface(var I: Interface "CLL ILabelStore")
    begin
        I := X;
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

codeunit 77221 "CLL VP Holder First"
{
    var
        X: Codeunit "CLL Store First";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenRead(X, UseClearAll));
    end;

    procedure ValueParamOuter(UseClearAll: Boolean): Text
    begin
        exit(OuterRead(X, UseClearAll));
    end;

    local procedure ClearThenRead(P: Codeunit "CLL Store First"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure OuterRead(P: Codeunit "CLL Store First"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        DoClear(UseClearAll);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure DoClear(UseClearAll: Boolean)
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
    end;
}

codeunit 77222 "CLL VP Holder Mid"
{
    var
        X: Codeunit "CLL Store Mid";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenRead(X, UseClearAll));
    end;

    procedure ValueParamOuter(UseClearAll: Boolean): Text
    begin
        exit(OuterRead(X, UseClearAll));
    end;

    local procedure ClearThenRead(P: Codeunit "CLL Store Mid"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure OuterRead(P: Codeunit "CLL Store Mid"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        DoClear(UseClearAll);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure DoClear(UseClearAll: Boolean)
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
    end;
}

codeunit 77223 "CLL VP Holder Last"
{
    var
        X: Codeunit "CLL Store Last";
        Cnt: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenRead(X, UseClearAll));
    end;

    procedure ValueParamOuter(UseClearAll: Boolean): Text
    begin
        exit(OuterRead(X, UseClearAll));
    end;

    local procedure ClearThenRead(P: Codeunit "CLL Store Last"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure OuterRead(P: Codeunit "CLL Store Last"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        DoClear(UseClearAll);
        Before := 'p: ' + P.State() + ' ' + P.LabelText() + ' | x: ' + X.State() + ' ' + X.LabelText();
        P.Write(5);
        exit(Before + ' || p: ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure DoClear(UseClearAll: Boolean)
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
    end;
}

codeunit 77224 "CLL Label Share Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LabelFirst_Iface_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder First";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_Iface_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder First";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ValueParam_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder First";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ValueParamOuter_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder First";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ValueParam_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder First";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ValueParamOuter_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder First";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_Iface_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder Mid";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_Iface_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder Mid";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ValueParam_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Mid";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ValueParamOuter_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Mid";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ValueParam_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Mid";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ValueParamOuter_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Mid";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_Iface_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder Last";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_Iface_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL IHolder Last";
        I: Interface "CLL ILabelStore";
    begin
        H.WriteX(3);
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('iface', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through iface', I.LabelText());
        Observer.Observe('label through x', H.LabelX());
        I.Write(5);
        Observer.Observe('iface after write', I.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Expect('iface', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through iface', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('iface after write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ValueParam_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Last";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ValueParamOuter_ClearAll_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Last";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(true));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text | x: rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ValueParam_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Last";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParam(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ValueParamOuter_ClearX_Written()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL VP Holder Last";
    begin
        H.WriteX(3);
        Observer.Observe('result', H.ValueParamOuter(false));
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('result', 'p: rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0 kept label text | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 kept label text || p: rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;
}
