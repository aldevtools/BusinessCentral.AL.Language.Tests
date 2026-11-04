// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), own table 71245
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: array[N] of Record X temporary: do the elements share one temporary table (Insert in element 1, Count in element 2),
//   do they keep their own filters, current key and current record, DeleteAll / Copy / TransferFields between elements,
//   an array passed to a procedure, and the contrast with two separate temporary variables and a non-temporary array.
// BC versions: 29 (27 and 28 by CI)

table 71245 "LT TAE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(ByName; Name) { }
        key(ByQty; Qty) { }
    }
}

codeunit 71246 "LT Rec Temp Array Elements"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(var Row: Record "LT TAE Row"; NewCode: Code[10]; NewName: Text[30]; NewQty: Integer)
    begin
        Row.Init();
        Row.Code := NewCode;
        Row.Name := NewName;
        Row.Qty := NewQty;
        Row.Insert();
    end;

    local procedure ClearDb()
    var
        Db: Record "LT TAE Row";
    begin
        Db.DeleteAll();
    end;

    local procedure Names(var Row: Record "LT TAE Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Code + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure InsertInto(var Row: Record "LT TAE Row")
    begin
        Add(Row, 'P', 'passed', 7);
    end;

    [Test]
    procedure P174_Array_InsertInFirst_CountInSecond()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Observe('isEmpty2', Format(R[2].IsEmpty()));
        Observer.Observe('get2_A', Format(R[2].Get('A')));
        Observer.Observe('findfirst2', Format(R[2].FindFirst()));
        Observer.Observe('is_temp_1', Format(R[1].IsTemporary()));
        Observer.Observe('is_temp_2', Format(R[2].IsTemporary()));
        Observer.Expect('count1', '2');
        Observer.Expect('count2', '2');
        Observer.Expect('isEmpty2', 'No');
        Observer.Expect('get2_A', 'Yes');
        Observer.Expect('findfirst2', 'Yes');
        Observer.Expect('is_temp_1', 'Yes');
        Observer.Expect('is_temp_2', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_InsertSameKeyInBoth()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        R[2].Init();
        R[2].Code := 'A';
        R[2].Name := 'dup';
        Observer.Observe('insert2_ok', Format(R[2].Insert()));
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('insert2_ok', 'No');
        Observer.Expect('count1', '1');
        Observer.Expect('count2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_InsertSameKeyInBoth_Error()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        R[2].Init();
        R[2].Code := 'A';
        asserterror R[2].Insert(true);
        Observer.ObserveError('dup_insert');
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('dup_insert|text', 'The record in table LT TAE Row already exists. Identification fields and values: Code=''A''');
        Observer.Expect('dup_insert|code', 'DB:RecordExists');
        Observer.Expect('count1', '1');
        Observer.Expect('count2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_ModifyInSecond_SeenInFirst()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        R[2].Get('A');
        R[2].Name := 'changed';
        R[2].Modify();
        R[1].Get('A');
        Observer.Observe('name1', R[1].Name);
        Observer.Observe('name2', R[2].Name);
        Observer.Expect('name1', 'changed');
        Observer.Expect('name2', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_DeleteAllInSecond_EmptiesFirst()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        R[2].DeleteAll();
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('count1', '0');
        Observer.Expect('count2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_OwnFilters()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        Add(R[1], 'C', 'charlie', 3);
        R[1].SetRange(Qty, 1, 2);
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Observe('filters1', R[1].GetFilters());
        Observer.Observe('filters2', R[2].GetFilters());
        R[2].SetFilter(Code, '>=B');
        Observer.Observe('count1b', Format(R[1].Count()));
        Observer.Observe('count2b', Format(R[2].Count()));
        Observer.Observe('names1', Names(R[1]));
        Observer.Observe('names2', Names(R[2]));
        R[1].Reset();
        Observer.Observe('filters1_afterreset', R[1].GetFilters());
        Observer.Observe('filters2_afterreset1', R[2].GetFilters());
        Observer.Expect('count1', '2');
        Observer.Expect('count2', '3');
        Observer.Expect('filters1', 'Qty: 1..2');
        Observer.Expect('filters2', '');
        Observer.Expect('count1b', '2');
        Observer.Expect('count2b', '2');
        Observer.Expect('names1', 'A,B,');
        Observer.Expect('names2', 'B,C,');
        Observer.Expect('filters1_afterreset', '');
        Observer.Expect('filters2_afterreset1', 'Code: >=B');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_OwnFilters_DeleteAllRespectsOwnFilter()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        Add(R[1], 'C', 'charlie', 3);
        R[2].SetRange(Code, 'B');
        R[2].DeleteAll();
        R[2].Reset();
        Observer.Observe('left', Names(R[1]));
        Observer.Expect('left', 'A,C,');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_OwnCurrentKey()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'zulu', 1);
        Add(R[1], 'B', 'alpha', 3);
        Add(R[1], 'C', 'mike', 2);
        R[1].SetCurrentKey(Name);
        Observer.Observe('order1_byname', Names(R[1]));
        Observer.Observe('order2_default', Names(R[2]));
        R[2].SetCurrentKey(Qty);
        Observer.Observe('order1_after', Names(R[1]));
        Observer.Observe('order2_byqty', Names(R[2]));
        R[1].SetCurrentKey(Code);
        Observer.Observe('order1_bycode', Names(R[1]));
        Observer.Observe('order2_still_byqty', Names(R[2]));
        Observer.Expect('order1_byname', 'B,C,A,');
        Observer.Expect('order2_default', 'A,B,C,');
        Observer.Expect('order1_after', 'B,C,A,');
        Observer.Expect('order2_byqty', 'A,C,B,');
        Observer.Expect('order1_bycode', 'A,B,C,');
        Observer.Expect('order2_still_byqty', 'A,C,B,');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_OwnCurrentRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        Add(R[1], 'C', 'charlie', 3);
        R[1].Get('A');
        R[2].Get('C');
        Observer.Observe('cur1', R[1].Code);
        Observer.Observe('cur2', R[2].Code);
        Observer.Observe('next1', Format(R[1].Next()) + R[1].Code);
        Observer.Observe('cur2_after', R[2].Code);
        R[2].Init();
        Observer.Observe('cur1_after_init2', R[1].Code);
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Expect('cur1', 'A');
        Observer.Expect('cur2', 'C');
        Observer.Expect('next1', '1B');
        Observer.Expect('cur2_after', 'C');
        Observer.Expect('cur1_after_init2', 'B');
        Observer.Expect('count1', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_ThirdElement_SharesToo()
    var
        Observer: Codeunit "Probe Observer";
        R: array[3] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[3], 'A', 'alpha', 1);
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Observe('count3', Format(R[3].Count()));
        Add(R[2], 'B', 'bravo', 2);
        Observer.Observe('count1b', Format(R[1].Count()));
        Observer.Observe('count3b', Format(R[3].Count()));
        Observer.Expect('count1', '1');
        Observer.Expect('count2', '1');
        Observer.Expect('count3', '1');
        Observer.Expect('count1b', '2');
        Observer.Expect('count3b', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_PassedToProcedure_ElementByVar()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        InsertInto(R[2]);
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('count1', '1');
        Observer.Expect('count2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_CopyBetweenElements()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Add(R[1], 'B', 'bravo', 2);
        R[1].SetRange(Code, 'B');
        R[2].Copy(R[1]);
        Observer.Observe('filters2', R[2].GetFilters());
        Observer.Observe('count2', Format(R[2].Count()));
        R[2].Reset();
        Observer.Observe('count2_reset', Format(R[2].Count()));
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Expect('filters2', 'Code: B');
        Observer.Expect('count2', '1');
        Observer.Expect('count2_reset', '2');
        Observer.Expect('count1', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_CopyShareTempTrue()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
        Other: Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Other.Copy(R[1], true);
        Add(Other, 'Z', 'zulu', 9);
        Observer.Observe('count_other', Format(Other.Count()));
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('count_other', '2');
        Observer.Expect('count1', '2');
        Observer.Expect('count2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_TransferFieldsFromElement()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 5);
        R[2].TransferFields(R[1]);
        Observer.Observe('code2', R[2].Code);
        Observer.Observe('name2', R[2].Name);
        Observer.Observe('count2', Format(R[2].Count()));
        Observer.Expect('code2', 'A');
        Observer.Expect('name2', 'alpha');
        Observer.Expect('count2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P174_TwoSeparateTempVars_DoNotShare()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT TAE Row" temporary;
        B: Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(A, 'A', 'alpha', 1);
        Observer.Observe('countA', Format(A.Count()));
        Observer.Observe('countB', Format(B.Count()));
        Observer.Expect('countA', '1');
        Observer.Expect('countB', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P174_NonTempArray_SharesDatabaseTable()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row";
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Observer.Observe('is_temp', Format(R[1].IsTemporary()));
        Observer.Observe('count1', Format(R[1].Count()));
        Observer.Observe('count2', Format(R[2].Count()));
        R[2].SetRange(Code, 'X');
        Observer.Observe('count1_own_filter', Format(R[1].Count()));
        Observer.Observe('count2_own_filter', Format(R[2].Count()));
        R[1].DeleteAll();
        Observer.Expect('is_temp', 'No');
        Observer.Expect('count1', '1');
        Observer.Expect('count2', '1');
        Observer.Expect('count1_own_filter', '1');
        Observer.Expect('count2_own_filter', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P174_Array_ClearOneElement()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2] of Record "LT TAE Row" temporary;
    begin
        ClearDb();
        Add(R[1], 'A', 'alpha', 1);
        Clear(R[2]);
        Observer.Observe('count1_after_clear2', Format(R[1].Count()));
        Clear(R[1]);
        Observer.Observe('count2_after_clear1', Format(R[2].Count()));
        Observer.Observe('count1_after_clear1', Format(R[1].Count()));
        Observer.Expect('count1_after_clear2', '1');
        Observer.Expect('count2_after_clear1', '1');
        Observer.Expect('count1_after_clear1', '1');
        Observer.Verify();
    end;
}
