// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects 75586 to 75591
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: Clear and ClearAll of a non-SingleInstance codeunit variable X whose codeunit holds a temporary record
//   global, a two-dimensional array of RecordRef and an array of Integer, while an interface, a second codeunit
//   variable (Y := X) or a value parameter shares X's instance. X is unused, used once by a call that reads an
//   Integer element, or used once by a call that counts the temporary rows. Nothing is written before the share.
//   Each test reads the state through X and through the alias after the clear, then writes through the alias
//   (one temporary row, RecordRef element [1,1] opened on a temporary table with one row, Integer element 1) and
//   reads both again. State text: rows = temporary rows, ref11 / ref23 = Number of RecordRef elements [1,1] and
//   [2,3] (refrows = rows of [1,1] when it is open), int1 / int3 = Integer elements 1 and 3.
//   Also: Number, IsEmpty and Count of a RecordRef that was never opened, and `B := A` of temporary records.
//   Measured on BC 29.0 (Linux). The three X states (unused, used by a read of an Integer element, used by a
//   count of the temporary rows) gave the same values in every cell:
//   - Clear(X) gives X a fresh instance: X reads rows=0, ref11=0, int1=0 afterwards, also when X wrote before.
//     The interface, the codeunit alias or the value parameter keeps the old instance: a write through it after
//     the clear shows only there (rows=1 ref11=75586 refrows=1 int1=5), and what the alias wrote before the clear
//     (3) stays visible through the alias. The same when X is cleared through a var parameter.
//   - Without a clear, an unused X shares its instance on assignment: after I := X or Y := X a write through
//     either side shows through the other.
//   - ClearAll in the codeunit that owns X does not detach X: it resets X's instance in place, seen through X and
//     through the alias. The Integer array goes back to 0 and RecordRef element [1,1] is closed (Number 0), but the
//     temporary record keeps its rows (rows=1). A write after the ClearAll adds to them (rows=2).
//     ClearAll inside the store's own codeunit does the same; Clear(Rows) of the temporary record keeps its rows.
//   - A RecordRef that was never opened, or was cleared or closed, has Number 0. IsEmpty, Count and IsTemporary on a
//     never-opened RecordRef raise "The record is not open." (RecordNotOpened).
//   - B := A of two temporary record variables copies the field values only: B keeps its own table (a row
//     inserted into B is not in A, B.Find('=') does not find A's row). Clear(A) and A.Reset() keep A's rows.
// BC versions: 27, 28, 29

table 75586 "CLB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

interface "CLB IStore"
{
    procedure Write(V: Integer);
    procedure State(): Text;
    procedure IntAt(I: Integer): Integer;
    procedure RowCount(): Integer;
}

codeunit 75587 "CLB Store" implements "CLB IStore"
{
    var
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

    procedure IntAt(I: Integer): Integer
    begin
        exit(Ints[I]);
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows.Count());
    end;

    procedure RefNumber(I: Integer; J: Integer): Integer
    begin
        exit(Refs[I, J].Number);
    end;

    procedure RefIsEmpty(I: Integer; J: Integer): Boolean
    begin
        exit(Refs[I, J].IsEmpty());
    end;

    procedure RefCount(I: Integer; J: Integer): Integer
    begin
        exit(Refs[I, J].Count());
    end;

    procedure ClearRows()
    begin
        Clear(Rows);
    end;

    procedure ClearAllSelf()
    begin
        ClearAll();
    end;
}

codeunit 75588 "CLB Holder"
{
    var
        X: Codeunit "CLB Store";
        Count: Integer;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure SetCount(V: Integer)
    begin
        Count := V;
    end;

    procedure GetCount(): Integer
    begin
        exit(Count);
    end;

    procedure UseInt()
    begin
        X.IntAt(1);
    end;

    procedure UseRows()
    begin
        X.RowCount();
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
    begin
        I := X;
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
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

    procedure ClearXViaVar()
    begin
        ClearVar(X);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ValueParam(UseClearAll: Boolean): Text
    begin
        exit(ClearThenWrite(X, UseClearAll));
    end;

    local procedure ClearThenWrite(P: Codeunit "CLB Store"; UseClearAll: Boolean): Text
    var
        Before: Text;
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        Before := P.State() + ' | x: ' + X.State();
        P.Write(5);
        exit(Before + ' || ' + P.State() + ' | x: ' + X.State());
    end;

    local procedure ClearVar(var P: Codeunit "CLB Store")
    begin
        Clear(P);
    end;
}

codeunit 75589 "CLB Clear Temp RecRef Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_LocalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        I := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        Y := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        Y := X;
        ClearVar(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        A: Text;
    begin
        A := ClearThenWrite(X, X);
        Observer.Observe('param', A);
        Observer.Observe('x', X.State());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        A := H.ValueParam(false);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.ShareIface(I);
        I.Write(3);
        H.ClearX();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        A := H.ValueParam(true);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.ShareIface(I);
        I.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        H.ClearXViaVar();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        Y := X;
        Y.Write(3);
        Clear(X);
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', X.State());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        I := X;
        I.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedAlias_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        Y := X;
        X.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_GlobalUnusedAlias_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(5);
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Second_LocalUnusedX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Z: Codeunit "CLB Store";
    begin
        Z.Write(7);
        Observer.Observe('x', X.State());
        Observer.Observe('z', Z.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('z', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIntIface()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        X.IntAt(1);
        I := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIntAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.IntAt(1);
        Y := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIntAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.IntAt(1);
        Y := X;
        ClearVar(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIntValueParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        A: Text;
    begin
        X.IntAt(1);
        A := ClearThenWrite(X, X);
        Observer.Observe('param', A);
        Observer.Observe('x', X.State());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseInt();
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        H.UseInt();
        A := H.ValueParam(false);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseInt();
        H.ShareIface(I);
        I.Write(3);
        H.ClearX();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIntIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseInt();
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIntAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIntValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        H.UseInt();
        A := H.ValueParam(true);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIntIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseInt();
        H.ShareIface(I);
        I.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIntAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIntAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        H.ClearXViaVar();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIntAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.IntAt(1);
        Y := X;
        Y.Write(3);
        Clear(X);
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', X.State());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedIntIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        X.IntAt(1);
        I := X;
        I.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedIntAlias_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.IntAt(1);
        Y := X;
        X.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_GlobalUsedIntAlias_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseInt();
        H.ShareAlias(Y);
        Y.Write(5);
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Second_LocalUsedIntX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Z: Codeunit "CLB Store";
    begin
        X.IntAt(1);
        Z.Write(7);
        Observer.Observe('x', X.State());
        Observer.Observe('z', Z.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('z', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedRowsIface()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        X.RowCount();
        I := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedRowsAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.RowCount();
        Y := X;
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedRowsAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.RowCount();
        Y := X;
        ClearVar(X);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', X.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedRowsValueParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        A: Text;
    begin
        X.RowCount();
        A := ClearThenWrite(X, X);
        Observer.Observe('param', A);
        Observer.Observe('x', X.State());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseRows();
        H.ShareIface(I);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        H.UseRows();
        A := H.ValueParam(false);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseRows();
        H.ShareIface(I);
        I.Write(3);
        H.ClearX();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedRowsIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseRows();
        H.ShareIface(I);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedRowsAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedRowsValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        A: Text;
    begin
        H.UseRows();
        A := H.ValueParam(true);
        Observer.Observe('param', A);
        Observer.Observe('x', H.StateX());
        Observer.Expect('param', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 | x: rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0 || rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0 | x: rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedRowsIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        I: Interface "CLB IStore";
    begin
        H.UseRows();
        H.ShareIface(I);
        I.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', I.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedRowsAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedRowsAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        H.ClearXViaVar();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedRowsAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.RowCount();
        Y := X;
        Y.Write(3);
        Clear(X);
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', X.State());
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedRowsIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        I: Interface "CLB IStore";
    begin
        X.RowCount();
        I := X;
        I.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', I.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedRowsAlias_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Y: Codeunit "CLB Store";
    begin
        X.RowCount();
        Y := X;
        X.Write(5);
        Observer.Observe('x', X.State());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Share_GlobalUsedRowsAlias_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.UseRows();
        H.ShareAlias(Y);
        Y.Write(5);
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Second_LocalUsedRowsX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
        Z: Codeunit "CLB Store";
    begin
        X.RowCount();
        Z.Write(7);
        Observer.Observe('x', X.State());
        Observer.Observe('z', Z.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('z', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        X.Write(3);
        Clear(X);
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
    begin
        H.WriteX(3);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
    begin
        H.WriteX(3);
        H.SetCount(4);
        H.ClearAllGlobals();
        Observer.Observe('x', H.StateX());
        Observer.Observe('count', Format(H.GetCount()));
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalAlias_AliasWroteBefore_ThenWrites()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLB Holder";
        Y: Codeunit "CLB Store";
    begin
        H.ShareAlias(Y);
        Y.Write(3);
        H.ClearAllGlobals();
        Y.Write(5);
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearRows_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        X.Write(3);
        X.ClearRows();
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        X.Write(3);
        X.ClearAllSelf();
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_InsideStore_ThenWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        X.Write(3);
        X.ClearAllSelf();
        X.Write(5);
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    local procedure ClearVar(var P: Codeunit "CLB Store")
    begin
        Clear(P);
    end;

    local procedure ClearThenWrite(var P: Codeunit "CLB Store"; Q: Codeunit "CLB Store"): Text
    var
        Before: Text;
    begin
        Clear(P);
        Before := Q.State() + ' | x: ' + P.State();
        Q.Write(5);
        exit(Before + ' || ' + Q.State() + ' | x: ' + P.State());
    end;
}

codeunit 75590 "CLB RecRef Unopened Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Unopened_Local_Number()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        Observer.Observe('number', Format(R.Number));
        Observer.Expect('number', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Local_IsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        asserterror if R.IsEmpty() then;
        Observer.ObserveError('isempty');
        Observer.Expect('isempty|text', 'The record is not open.');
        Observer.Expect('isempty|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Local_Count()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        asserterror if R.Count() = 0 then;
        Observer.ObserveError('count');
        Observer.Expect('count|text', 'The record is not open.');
        Observer.Expect('count|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Local_IsTemporary()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        asserterror if R.IsTemporary() then;
        Observer.ObserveError('istemporary');
        Observer.Expect('istemporary|text', 'The record is not open.');
        Observer.Expect('istemporary|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Store_Number()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        Observer.Observe('number', Format(X.RefNumber(2, 3)));
        Observer.Expect('number', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Store_IsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        asserterror X.RefIsEmpty(2, 3);
        Observer.ObserveError('isempty');
        Observer.Expect('isempty|text', 'The record is not open.');
        Observer.Expect('isempty|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Unopened_Store_Count()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLB Store";
    begin
        asserterror X.RefCount(2, 3);
        Observer.ObserveError('count');
        Observer.Expect('count|text', 'The record is not open.');
        Observer.Expect('count|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Cleared_Local_Number()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        R.Open(Database::"CLB Row", true);
        Clear(R);
        Observer.Observe('number', Format(R.Number));
        Observer.Expect('number', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Closed_Local_Number()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
    begin
        R.Open(Database::"CLB Row", true);
        R.Close();
        Observer.Observe('number', Format(R.Number));
        Observer.Expect('number', '0');
        Observer.Verify();
    end;
}

codeunit 75591 "CLB Temp Assign Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Assign_EmptyA_ThenBInserts()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
        B: Record "CLB Row" temporary;
    begin
        B := A;
        B.Init();
        B."No." := 1;
        B.Insert();
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b', Format(B.Count()));
        Observer.Expect('a', '0');
        Observer.Expect('b', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_AWithRow_BCount()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
        B: Record "CLB Row" temporary;
    begin
        A.Init();
        A."No." := 1;
        A.Insert();
        B := A;
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b', Format(B.Count()));
        B.Init();
        B."No." := 2;
        B.Insert();
        Observer.Observe('a after b insert', Format(A.Count()));
        Observer.Observe('b after b insert', Format(B.Count()));
        Observer.Expect('a', '1');
        Observer.Expect('b', '0');
        Observer.Expect('a after b insert', '1');
        Observer.Expect('b after b insert', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_AWithRow_ThenAInserts()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
        B: Record "CLB Row" temporary;
    begin
        A.Init();
        A."No." := 1;
        A.Insert();
        B := A;
        A.Init();
        A."No." := 2;
        A.Insert();
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b', Format(B.Count()));
        Observer.Expect('a', '2');
        Observer.Expect('b', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_AWithRow_BFieldValue()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
        B: Record "CLB Row" temporary;
    begin
        A.Init();
        A."No." := 1;
        A.Insert();
        B := A;
        Observer.Observe('b no', Format(B."No."));
        Observer.Observe('b find', Format(B.Find('=')));
        Observer.Expect('b no', '1');
        Observer.Expect('b find', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LocalTemp_Clear_Count()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
    begin
        A.Init();
        A."No." := 1;
        A.Insert();
        Clear(A);
        Observer.Observe('a', Format(A.Count()));
        Observer.Expect('a', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LocalTemp_Reset_Count()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "CLB Row" temporary;
    begin
        A.Init();
        A."No." := 1;
        A.Insert();
        A.Reset();
        Observer.Observe('a', Format(A.Count()));
        Observer.Expect('a', '1');
        Observer.Verify();
    end;
}
