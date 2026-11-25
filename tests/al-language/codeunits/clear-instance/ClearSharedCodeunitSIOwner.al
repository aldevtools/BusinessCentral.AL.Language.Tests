// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Row" (table 75586), "CLB IStore" and "CLB Store" (codeunit 75587)
//   of ClearSharedCodeunitTempRef.al; self-contained objects 75592 to 75599 and 75760 to 75778
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: Clear and ClearAll around a SingleInstance codeunit S that holds a global X of the non-SingleInstance
//   store "CLB Store" (a temporary record, a two-dimensional array of RecordRef, an array of Integer).
//   - "CLS SI Lifetime Tests": the state S's X shows across test methods of one test codeunit. Each sequence has
//     its own S, and its steps are test methods that run in the order they are declared (A1 = X never made before
//     the first read, A2 = X made by calls that write nothing, A3 = X written, then ClearAll and Clear(X) inside S).
//   - "CLS SI Owner Clear Tests": Clear(X) and ClearAll inside S while a codeunit variable or an interface shares
//     X's instance, X unused or made by a call that writes nothing. Each test has its own S.
//   - "CLS Temp Array Tests": a store whose temporary record global is an array of two elements.
//   - "CLS Test Globals ClearAll": ClearAll() in a test codeunit whose globals are stores shared elsewhere.
//   State text: rows = temporary rows, ref11 / ref23 = Number of RecordRef elements [1,1] and [2,3] (refrows = rows
//   of [1,1] when it is open), int1 / int3 = Integer elements 1 and 3.
//   Measured on BC 29.0 (Linux). X unused, or made by calls that write nothing (S.Touch reads an Integer element and
//   counts the temporary rows), gave the same values in every cell; no difference between a made and a never-made X
//   is observable through S.
//   - S and its X live for the whole session: the marker set in step 1 is still there in step 2, and what X held at
//     the end of one test method (temporary rows, RecordRef [1,1] open on a temporary table, Integer elements) is
//     still there in the next one, also after a write from a codeunit run with Codeunit.Run.
//   - ClearAll inside S resets X in place: Integer elements go to 0, RecordRef [1,1] is closed (Number 0), the
//     temporary rows stay (rows=1), S's own Integer goes to 0, and the next write adds to the rows (rows=2). The
//     kept rows are still there in the next test method. Clear(X) inside S gives X a fresh instance (rows=0).
//   - With a share (S.ShareAlias / S.ShareIface): Clear(X) inside S leaves the alias with the old instance (a write
//     through the alias shows only there; what it wrote before stays with it); ClearAll inside S keeps X and the
//     alias on one instance (reset in place as above, then a write through the alias shows through X too).
//   - Clear of a variable of S itself changes nothing: S1 and S2 still read X's rows, RecordRef and Integer.
//   - An array of temporary records in a codeunit global or a local is ONE temporary table for all elements: a row
//     inserted through element 1 is counted, found (Get) and deleted (DeleteAll) through element 2, an insert of the
//     same key through element 2 returns false, and both elements count every row. Filters stay per element (a
//     SetRange on element 1 does not filter element 2). Clear of the array or of one element keeps the rows;
//     element 2 := element 1 copies the field values. Clear and ClearAll of the store behave as with one temporary
//     record: Clear(X) gives the holder a fresh instance, ClearAll keeps the rows and closes the RecordRef.
//   - ClearAll() in a test codeunit treats its own globals like ClearAll in any codeunit: a store global shared with a
//     local alias, an interface global or another codeunit's global (CLS Keeper) stays shared and is reset in place
//     (rows kept, RecordRef closed, Integer 0); an Integer global goes to 0. A global of a SingleInstance owner keeps
//     everything (rows, RecordRef, Integer, S's own Integer).
// BC versions: 27, 28, 29

codeunit 75596 "CLS Arr Store"
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

codeunit 75597 "CLS Arr Holder"
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
}

codeunit 75598 "CLS Keeper"
{
    var
        K: Codeunit "CLB Store";

    procedure Adopt(P: Codeunit "CLB Store")
    begin
        K := P;
    end;

    procedure StateK(): Text
    begin
        exit(K.State());
    end;

    procedure WriteK(V: Integer)
    begin
        K.Write(V);
    end;
}

codeunit 75760 "CLS SI Owner A1"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75761 "CLS SI Owner A2"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75762 "CLS SI Owner A3"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75599 "CLS Run Write"
{
    trigger OnRun()
    var
        S: Codeunit "CLS SI Owner A2";
    begin
        S.WriteX(7);
    end;
}

codeunit 75592 "CLS SI Lifetime Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure A1_Step1_OwnerOnly_XNeverMade()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A1";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(4);
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure A1_Step2_FirstReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure A1_Step3_SecondReadOfX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A1";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A2_Step1_MadeByCallsThatWriteNothing()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A2";
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
    procedure A2_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A2_Step3_WriteFromRunCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A2";
    begin
        Codeunit.Run(Codeunit::"CLS Run Write");
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A2_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A2";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=7 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step1_Write()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
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
    procedure A3_Step2_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step3_ClearAllInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step4_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step5_WriteAgain()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        S.WriteX(6);
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=6 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step6_ClearXInOwner()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure A3_Step7_ReadX()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner A3";
    begin
        Observer.Observe('x', S.StateX());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;
}

codeunit 75763 "CLS SI Owner B01"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75764 "CLS SI Owner B02"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75765 "CLS SI Owner B03"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75766 "CLS SI Owner B04"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75767 "CLS SI Owner B05"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75768 "CLS SI Owner B06"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75769 "CLS SI Owner B07"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75770 "CLS SI Owner B08"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75771 "CLS SI Owner B09"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75772 "CLS SI Owner B10"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75773 "CLS SI Owner B11"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75774 "CLS SI Owner B12"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75775 "CLS SI Owner B13"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75776 "CLS SI Owner B14"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75777 "CLS SI Owner B15"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75593 "CLS SI Owner Clear Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_SIOwnerUnused_Alias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B01";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareAlias(Y);
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerUnused_Iface()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B02";
        I: Interface "CLB IStore";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareIface(I);
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerUnused_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B03";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareAlias(Y);
        Y.Write(3);
        S.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', S.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerUnused_Alias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B04";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareAlias(Y);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerUnused_Iface()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B05";
        I: Interface "CLB IStore";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareIface(I);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerUnused_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B06";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.ShareAlias(Y);
        Y.Write(3);
        S.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', S.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerTouched_Alias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B07";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareAlias(Y);
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerTouched_Iface()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B08";
        I: Interface "CLB IStore";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareIface(I);
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerTouched_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B09";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareAlias(Y);
        Y.Write(3);
        S.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', S.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('alias', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=2 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerTouched_Alias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B10";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareAlias(Y);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerTouched_Iface()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B11";
        I: Interface "CLB IStore";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareIface(I);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('alias', I.State());
        I.Write(5);
        Observer.Observe('x after write', S.StateX());
        Observer.Observe('alias after write', I.State());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerTouched_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B12";
        Y: Codeunit "CLB Store";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.Touch();
        S.ShareAlias(Y);
        Y.Write(3);
        S.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', S.StateX());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_SIOwnerWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B13";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.WriteX(3);
        S.SetCnt(4);
        S.ClearAllGlobals();
        Observer.Observe('x', S.StateX());
        Observer.Observe('cnt', Format(S.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner B14";
    begin
        Observer.Observe('start cnt', Format(S.GetCnt()));
        S.SetCnt(1);
        S.WriteX(3);
        S.ClearX();
        Observer.Observe('x', S.StateX());
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SIOwnerVariable_XKeeps()
    var
        Observer: Codeunit "Probe Observer";
        S1: Codeunit "CLS SI Owner B15";
        S2: Codeunit "CLS SI Owner B15";
    begin
        S1.WriteX(3);
        S1.SetCnt(4);
        Clear(S1);
        Observer.Observe('s1', S1.StateX());
        Observer.Observe('s2', S2.StateX());
        Observer.Observe('cnt', Format(S1.GetCnt()));
        Observer.Expect('s1', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('s2', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;
}

codeunit 75594 "CLS Temp Array Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ArrStore_WriteFirstElement()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 5);
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_WriteBothElements()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 5);
        X.Write(2, 6);
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=6');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_Clear_Alias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
    begin
        H.ShareAlias(Y);
        H.ClearX();
        Observer.Observe('x', H.StateX());
        Observer.Observe('alias', Y.State());
        Y.Write(1, 5);
        Observer.Observe('x after write', H.StateX());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('alias', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('x after write', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Expect('alias after write', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_Clear_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
    begin
        H.ShareAlias(Y);
        Y.Write(1, 3);
        H.ClearX();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Observer.Expect('alias', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=3');
        Observer.Expect('x', 'rows1=0 rows2=0 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearAll_Alias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLS Arr Holder";
        Y: Codeunit "CLS Arr Store";
    begin
        H.ShareAlias(Y);
        Y.Write(1, 3);
        Y.Write(2, 4);
        H.ClearAllGlobals();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', H.StateX());
        Y.Write(2, 5);
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('alias', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Expect('alias after write', 'rows1=3 rows2=3 ref1=75586 refrows=1 int1=5');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearElement_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 3);
        X.Write(2, 4);
        X.ClearElem(1);
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearArray_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 3);
        X.Write(2, 4);
        X.ClearArr();
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_ClearAll_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 3);
        X.Write(2, 4);
        X.ClearAllSelf();
        Observer.Observe('x', X.State());
        Observer.Expect('x', 'rows1=2 rows2=2 ref1=0 refrows=- int1=0');
        Observer.Verify();
    end;

    [Test]
    procedure ArrStore_AssignElement_InsideStore()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLS Arr Store";
    begin
        X.Write(1, 3);
        X.AssignFirstToSecond();
        Observer.Observe('x', X.State());
        Observer.Observe('second no', Format(X.SecondNo()));
        X.Write(2, 4);
        Observer.Observe('x after write', X.State());
        Observer.Expect('x', 'rows1=1 rows2=1 ref1=75586 refrows=1 int1=3');
        Observer.Expect('second no', '3');
        Observer.Expect('x after write', 'rows1=2 rows2=2 ref1=75586 refrows=2 int1=4');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_InsertFirst_Counts()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('a1', '1');
        Observer.Expect('a2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_ClearArray_Counts()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2].Init();
        A[2]."No." := 2;
        A[2].Insert();
        Clear(A);
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('a1', '2');
        Observer.Expect('a2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_ClearElement_Counts()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2].Init();
        A[2]."No." := 2;
        A[2].Insert();
        Clear(A[1]);
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('a1', '2');
        Observer.Expect('a2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_AssignElement_Counts()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2] := A[1];
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Observe('a2 no', Format(A[2]."No."));
        A[2].Init();
        A[2]."No." := 2;
        A[2].Insert();
        Observer.Observe('after insert a1', Format(A[1].Count()));
        Observer.Observe('after insert a2', Format(A[2].Count()));
        Observer.Expect('a1', '1');
        Observer.Expect('a2', '1');
        Observer.Expect('a2 no', '1');
        Observer.Expect('after insert a1', '2');
        Observer.Expect('after insert a2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_SameKeyInSecond_InsertResult()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2].Init();
        A[2]."No." := 1;
        Observer.Observe('insert a2 same key', Format(A[2].Insert()));
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('insert a2 same key', 'No');
        Observer.Expect('a1', '1');
        Observer.Expect('a2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_GetThroughSecond()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        Observer.Observe('a2 get 1', Format(A[2].Get(1)));
        Observer.Expect('a2 get 1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_FilterOnFirstOnly()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2].Init();
        A[2]."No." := 2;
        A[2].Insert();
        A[1].SetRange("No.", 1);
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('a1', '1');
        Observer.Expect('a2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LocalArray_DeleteAllThroughSecond()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2] of Record "CLB Row" temporary;
    begin
        A[1].Init();
        A[1]."No." := 1;
        A[1].Insert();
        A[2].DeleteAll();
        Observer.Observe('a1', Format(A[1].Count()));
        Observer.Observe('a2', Format(A[2].Count()));
        Observer.Expect('a1', '0');
        Observer.Expect('a2', '0');
        Observer.Verify();
    end;
}

codeunit 75778 "CLS SI Owner D"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
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

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
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

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75595 "CLS TG ClearAll 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";
        GCnt: Integer;

    [Test]
    procedure ClearAll_TestGlobalUnused_LocalAlias()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        Y := GX;
        GCnt := 4;
        ClearAll();
        Observer.Observe('cnt', Format(GCnt));
        Observer.Observe('x', GX.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', GX.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('cnt', '0');
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;
}

codeunit 75716 "CLS TG ClearAll 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure ClearAll_TestGlobalUnused_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        Y := GX;
        Y.Write(3);
        ClearAll();
        Observer.Observe('alias', Y.State());
        Observer.Observe('x', GX.State());
        Y.Write(5);
        Observer.Observe('alias after write', Y.State());
        Observer.Observe('x after write', GX.State());
        Observer.Expect('alias', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;
}

codeunit 75717 "CLS TG ClearAll 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure ClearAll_TestGlobalWritten_Keeper()
    var
        Observer: Codeunit "Probe Observer";
        K: Codeunit "CLS Keeper";
    begin
        GX.Write(3);
        K.Adopt(GX);
        ClearAll();
        Observer.Observe('keeper', K.StateK());
        Observer.Observe('x', GX.State());
        K.WriteK(5);
        Observer.Observe('keeper after write', K.StateK());
        Observer.Observe('x after write', GX.State());
        Observer.Expect('keeper', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('keeper after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;
}

codeunit 75718 "CLS TG ClearAll 4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure ClearAll_TestGlobalTouched_LocalAlias()
    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "CLB Store";
    begin
        GX.IntAt(1);
        GX.RowCount();
        Y := GX;
        ClearAll();
        Observer.Observe('x', GX.State());
        Observer.Observe('alias', Y.State());
        Y.Write(5);
        Observer.Observe('x after write', GX.State());
        Observer.Observe('alias after write', Y.State());
        Observer.Expect('x', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('alias', 'rows=0 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Expect('alias after write', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;
}

codeunit 75719 "CLS TG ClearAll 5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";
        GI: Interface "CLB IStore";

    [Test]
    procedure ClearAll_TestGlobalIface_StoreReads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GI := GX;
        GI.Write(3);
        ClearAll();
        Observer.Observe('x', GX.State());
        GX.Write(5);
        Observer.Observe('x after write', GX.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Expect('x after write', 'rows=2 ref11=75586 refrows=1 ref23=0 int1=5 int3=0');
        Observer.Verify();
    end;
}

codeunit 75720 "CLS TG ClearAll 6"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GX: Codeunit "CLB Store";

    [Test]
    procedure ClearAll_TestGlobalWritten_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GX.Write(3);
        ClearAll();
        Observer.Observe('x', GX.State());
        Observer.Expect('x', 'rows=1 ref11=0 refrows=- ref23=0 int1=0 int3=0');
        Observer.Verify();
    end;
}

codeunit 75721 "CLS TG ClearAll 7"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GS: Codeunit "CLS SI Owner D";

    [Test]
    procedure ClearAll_TestGlobalSIOwner()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('start cnt', Format(GS.GetCnt()));
        GS.WriteX(3);
        GS.SetCnt(4);
        ClearAll();
        Observer.Observe('x', GS.StateX());
        Observer.Observe('cnt', Format(GS.GetCnt()));
        Observer.Expect('start cnt', '0');
        Observer.Expect('x', 'rows=1 ref11=75586 refrows=1 ref23=0 int1=3 int3=0');
        Observer.Expect('cnt', '4');
        Observer.Verify();
    end;
}
