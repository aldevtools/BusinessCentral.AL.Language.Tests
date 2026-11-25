// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586), "CLB Store" (codeunit 75587) and
//   "CLB Holder" (codeunit 75588) of ClearSharedCodeunitTempRef.al; self-contained objects 77155 to 77171
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: a store codeunit with the globals of "CLB Store" (a temporary record, a two-dimensional array of RecordRef,
//   an array of Integer) plus one global Label, the Label first, in the middle or last in the var list
//   ("CLL Store First", "CLL Store Mid", "CLL Store Last"). State() gives the same text as "CLB Store"; LabelText()
//   returns the Label. Where a test compares with "CLB Store", the reference ran the same calls.
//   - "CLL Label Store Tests": ClearAll in a plain holder (X written, nothing shares; an alias that wrote before;
//     an alias that wrote nothing), ClearAll inside the store, Clear(X) in the holder with an alias.
//   - "CLL SI Lifetime Tests": a SingleInstance codeunit S whose global X is the Label store, the steps of the
//     sequences A1 to A3 of "CLS SI Lifetime Tests" (75592): L1 = X never made before the first read in a later test
//     method, L2 = X made by calls that write nothing (S.Touch), L3 = X written, then ClearAll and Clear(X) inside S.
//     Each sequence has its own S; its steps are test methods that run in the order they are declared.
//   Measured on BC 29.0 (Linux). The three Label positions gave the same values in every cell, and every state equals
//   the state of "CLB Store" after the same calls:
//   - ClearAll in the holder resets X in place as for "CLB Store": the temporary rows stay (rows=1), RecordRef [1,1]
//     is closed, the Integer elements and the holder's Integer go to 0. An alias that wrote before sees the same
//     reset and a later write through it shows through X too (rows=2). An alias that wrote nothing stays on X's
//     instance. ClearAll inside the store does the same. The Label keeps its text in every cell (also after
//     Clear(X) gives X a fresh instance, and through the alias that keeps the old one).
//   - SingleInstance owner S (login shape): X never made before the first read (L1) and X made by calls that write
//     nothing (L2) read the same in a later test method: a fresh store (rows=0, RecordRefs closed, Integers 0) and
//     the Label text, equal to a fresh "CLB Store". A write in one test method is still there in the next. L3 gives
//     the values of A3 in 75592: ClearAll inside S keeps the rows, closes the RecordRef, sets the Integers and S's
//     Integer to 0, and the kept rows are still there in the next test method; Clear(X) inside S gives rows=0.
// BC versions: 27, 28, 29

codeunit 77155 "CLL Store First"
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

    procedure IntAt(I: Integer): Integer
    begin
        exit(Ints[I]);
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;
}

codeunit 77156 "CLL Store Mid"
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

    procedure IntAt(I: Integer): Integer
    begin
        exit(Ints[I]);
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;
}

codeunit 77157 "CLL Store Last"
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

    procedure IntAt(I: Integer): Integer
    begin
        exit(Ints[I]);
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;
}

codeunit 77158 "CLL Holder First"
{
    var
        X: Codeunit "CLL Store First";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store First")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77159 "CLL Holder Mid"
{
    var
        X: Codeunit "CLL Store Mid";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Mid")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77160 "CLL Holder Last"
{
    var
        X: Codeunit "CLL Store Last";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Last")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77161 "CLL Label Store Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LabelFirst_ClearAllInHolder_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder First";
        R: Codeunit "CLB Holder";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        R.WriteX(3);
        R.SetCount(4);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        Observer.Observe('x equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label', H.LabelX());
        H.WriteX(5);
        R.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label after write', H.LabelX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x equals the store without a label', 'Yes');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Expect('label after write', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ClearAllInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder First";
        R: Codeunit "CLB Holder";
        Y: Codeunit "CLL Store First";
        RY: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        R.ShareAlias(RY);
        Y.Write(3);
        RY.Write(3);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias equals the store without a label', Format(Y.State() = RY.State()));
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Y.Write(5);
        RY.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias equals the store without a label', 'Yes');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ClearAllInHolder_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder First";
        Y: Codeunit "CLL Store First";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ClearAllInStore_Written()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store First";
    begin
        X.Write(3);
        X.ClearAllSelf();
        Observer.Observe('x', X.State());
        Observer.Observe('label', X.LabelText());
        X.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_ClearXInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder First";
        Y: Codeunit "CLL Store First";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelFirst_NeverUsed_LabelAndState()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store First";
    begin
        Observer.Observe('label', X.LabelText());
        Observer.Observe('x', X.State());
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ClearAllInHolder_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Mid";
        R: Codeunit "CLB Holder";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        R.WriteX(3);
        R.SetCount(4);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        Observer.Observe('x equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label', H.LabelX());
        H.WriteX(5);
        R.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label after write', H.LabelX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x equals the store without a label', 'Yes');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Expect('label after write', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ClearAllInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Mid";
        R: Codeunit "CLB Holder";
        Y: Codeunit "CLL Store Mid";
        RY: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        R.ShareAlias(RY);
        Y.Write(3);
        RY.Write(3);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias equals the store without a label', Format(Y.State() = RY.State()));
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Y.Write(5);
        RY.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias equals the store without a label', 'Yes');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ClearAllInHolder_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Mid";
        Y: Codeunit "CLL Store Mid";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ClearAllInStore_Written()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store Mid";
    begin
        X.Write(3);
        X.ClearAllSelf();
        Observer.Observe('x', X.State());
        Observer.Observe('label', X.LabelText());
        X.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_ClearXInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Mid";
        Y: Codeunit "CLL Store Mid";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelMid_NeverUsed_LabelAndState()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store Mid";
    begin
        Observer.Observe('label', X.LabelText());
        Observer.Observe('x', X.State());
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ClearAllInHolder_Written_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Last";
        R: Codeunit "CLB Holder";
    begin
        H.WriteX(3);
        H.SetCnt(4);
        R.WriteX(3);
        R.SetCount(4);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('cnt', Format(H.GetCnt()));
        Observer.Observe('x', H.StateX());
        Observer.Observe('x equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label', H.LabelX());
        H.WriteX(5);
        R.WriteX(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Observe('label after write', H.LabelX());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x equals the store without a label', 'Yes');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Expect('label after write', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ClearAllInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Last";
        R: Codeunit "CLB Holder";
        Y: Codeunit "CLL Store Last";
        RY: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        R.ShareAlias(RY);
        Y.Write(3);
        RY.Write(3);
        H.ClearAllGlobals();
        R.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias equals the store without a label', Format(Y.State() = RY.State()));
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Y.Write(5);
        RY.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('x after write equals the store without a label', Format(H.StateX() = R.StateX()));
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias equals the store without a label', 'Yes');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write equals the store without a label', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ClearAllInHolder_UnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Last";
        Y: Codeunit "CLL Store Last";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ClearAllInStore_Written()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store Last";
    begin
        X.Write(3);
        X.ClearAllSelf();
        Observer.Observe('x', X.State());
        Observer.Observe('label', X.LabelText());
        X.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_ClearXInHolder_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLL Holder Last";
        Y: Codeunit "CLL Store Last";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Observe('label through alias', Y.LabelText());
        Observer.Observe('label through x', H.LabelX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label through alias', 'kept label text');
        Observer.Expect('label through x', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure LabelLast_NeverUsed_LabelAndState()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLL Store Last";
    begin
        Observer.Observe('label', X.LabelText());
        Observer.Observe('x', X.State());
        Observer.Expect('label', 'kept label text');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;
}

codeunit 77162 "CLL SI First L1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store First";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store First")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77163 "CLL SI First L2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store First";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store First")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77164 "CLL SI First L3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store First";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store First")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77165 "CLL SI Mid L1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Mid";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Mid")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77166 "CLL SI Mid L2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Mid";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Mid")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77167 "CLL SI Mid L3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Mid";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Mid")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77168 "CLL SI Last L1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Last";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Last")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77169 "CLL SI Last L2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Last";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Last")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77170 "CLL SI Last L3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLL Store Last";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLL Store Last")
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

    procedure LabelX(): Text
    begin
        exit(X.LabelText());
    end;
}

codeunit 77171 "CLL SI Lifetime Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure First_L1_Step1_OwnerOnly_XNeverMade()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L1";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(4);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure First_L1_Step2_FirstReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L1";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '4');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure First_L1_Step3_SecondReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure First_L2_Step1_MadeByCallsThatWriteNothing()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L2";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.Touch();
        S.SetCnt(2);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure First_L2_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L2";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '2');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure First_L2_Step3_WriteThenRead()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L2";
    begin
        S.WriteX(7);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure First_L2_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step1_Write()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.WriteX(5);
        S.SetCnt(4);
        Observer.Observe('x', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step3_ClearAllInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step5_WriteAgain()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        S.WriteX(6);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=6 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step6_ClearXInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure First_L3_Step7_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI First L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L1_Step1_OwnerOnly_XNeverMade()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L1";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(4);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L1_Step2_FirstReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L1";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '4');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L1_Step3_SecondReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L2_Step1_MadeByCallsThatWriteNothing()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L2";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.Touch();
        S.SetCnt(2);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L2_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L2";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '2');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L2_Step3_WriteThenRead()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L2";
    begin
        S.WriteX(7);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L2_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step1_Write()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.WriteX(5);
        S.SetCnt(4);
        Observer.Observe('x', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step3_ClearAllInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step5_WriteAgain()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        S.WriteX(6);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=6 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step6_ClearXInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Mid_L3_Step7_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Mid L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L1_Step1_OwnerOnly_XNeverMade()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L1";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(4);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L1_Step2_FirstReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L1";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '4');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L1_Step3_SecondReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L2_Step1_MadeByCallsThatWriteNothing()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L2";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.Touch();
        S.SetCnt(2);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L2_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L2";
        Ref: Codeunit "CLB Store";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('x equals a fresh store', Format(S.StateX() = Ref.State()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Expect('cnt', '2');
        Observer.Expect('x equals a fresh store', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L2_Step3_WriteThenRead()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L2";
    begin
        S.WriteX(7);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L2_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step1_Write()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.WriteX(5);
        S.SetCnt(4);
        Observer.Observe('x', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step3_ClearAllInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step5_WriteAgain()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        S.WriteX(6);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=6 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step6_ClearXInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('label', S.LabelX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('label', 'kept label text');
        Observer.Verify();
    end;

    [Test]
    procedure Last_L3_Step7_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLL SI Last L3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;
}
