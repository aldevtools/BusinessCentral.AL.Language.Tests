// Probe (observe only): SetAscending per field and ties, RecordRef.Ascending / SetRecFilter, SetCurrentKey on fields no declared key starts with.
// Settles docs/probes-needed.md rows 235, 373, 390, 401 (batch 4). Object ids 68043 - 68048.

table 68043 "W4 Sort Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Integer) { }
        field(4; Txt; Text[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KA; A, B) { }
        key(KT; Txt) { }
    }
}

// A table whose declared keys are the primary key and one key on F1 only.
table 68044 "W4 Key Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Integer) { }
        field(3; F2; Text[10]) { }
        field(4; Amt; Decimal) { }
        field(5; Cnt; Integer) { FieldClass = FlowField; CalcFormula = count("W4 Key Row"); Editable = false; }
        field(6; Flow; Code[10]) { FieldClass = FlowFilter; }
        field(7; Bl; Blob) { }
        field(8; Md; Media) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K1; F1) { }
    }
}

codeunit 68045 "W4 Sort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "W4 Sort Row";
    begin
        R.DeleteAll();
        Add(1, 1, 2, 'a');
        Add(2, 1, 1, 'b');
        Add(3, 2, 2, 'b');
        Add(4, 2, 1, 'c');
        Add(5, 3, 1, 'a');
    end;

    local procedure Add(Id: Integer; A: Integer; B: Integer; Txt: Text[10])
    var
        R: Record "W4 Sort Row";
    begin
        R.Id := Id;
        R.A := A;
        R.B := B;
        R.Txt := Txt;
        R.Insert();
    end;

    local procedure Ids(var R: Record "W4 Sort Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    // Rows: id 1 (A1 B2 a), id 2 (A1 B1 b), id 3 (A2 B2 b), id 4 (A2 B1 c), id 5 (A3 B1 a). Keys: PK(Id), KA(A,B), KT(Txt).
    [Test]
    procedure SetAscending_SingleFieldKey()
    var
        R: Record "W4 Sort Row";
        R2: Record "W4 Sort Row";
        R3: Record "W4 Sort Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(Txt);
        Observer.Observe('ids_ascending', Ids(R));
        R.SetAscending(Txt, false);
        Observer.Observe('ids_after_setascending_false', Ids(R));
        Observer.Observe('ascending_after', Format(R.Ascending()));
        Observer.Observe('getview', R.GetView());
        R2.Copy(R);
        Observer.Observe('copy_ids', Ids(R2));
        Observer.Observe('copy_ascending', Format(R2.Ascending()));
        R3.SetView(R.GetView());
        Observer.Observe('setview_ids', Ids(R3));
        Observer.Observe('setview_ascending', Format(R3.Ascending()));
        R.SetAscending(Txt, true);
        Observer.Observe('ids_after_setascending_true', Ids(R));
        Observer.Observe('ascending_after_true', Format(R.Ascending()));
        Observer.Expect('ids_ascending', '1,5,2,3,4,');
        Observer.Expect('ids_after_setascending_false', '4,2,3,1,5,');
        Observer.Expect('ascending_after', 'No');
        Observer.Expect('getview', 'VERSION(1) SORTING(Txt) ORDER(Descending)');
        Observer.Expect('copy_ids', '4,2,3,1,5,');
        Observer.Expect('copy_ascending', 'No');
        Observer.Expect('setview_ids', '4,3,2,5,1,');
        Observer.Expect('setview_ascending', 'No');
        Observer.Expect('ids_after_setascending_true', '1,5,2,3,4,');
        Observer.Expect('ascending_after_true', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetAscending_TwoFieldKey_OneFieldAtATime()
    var
        R: Record "W4 Sort Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(A, B);
        Observer.Observe('ids_ascending', Ids(R));
        Observer.Observe('currentkey', R.CurrentKey());
        R.SetAscending(A, false);
        Observer.Observe('ids_a_false', Ids(R));
        Observer.Observe('ascending_a_false', Format(R.Ascending()));
        Observer.Observe('getview_a_false', R.GetView());
        R.SetAscending(A, true);
        R.SetAscending(B, false);
        Observer.Observe('ids_b_false', Ids(R));
        Observer.Observe('ascending_b_false', Format(R.Ascending()));
        Observer.Observe('getview_b_false', R.GetView());
        R.SetAscending(A, false);
        Observer.Observe('ids_both_false', Ids(R));
        Observer.Observe('ascending_both_false', Format(R.Ascending()));
        Observer.Expect('ids_ascending', '2,1,4,3,5,');
        Observer.Expect('currentkey', 'A,B');
        Observer.Expect('ids_a_false', '5,4,3,2,1,');
        Observer.Expect('ascending_a_false', 'No');
        Observer.Expect('getview_a_false', 'VERSION(1) SORTING(A,B) ORDER(Descending,Ascending)');
        Observer.Expect('ids_b_false', '1,2,3,4,5,');
        Observer.Expect('ascending_b_false', 'No');
        Observer.Expect('getview_b_false', 'VERSION(1) SORTING(A,B) ORDER(Ascending,Descending)');
        Observer.Expect('ids_both_false', '5,3,4,1,2,');
        Observer.Expect('ascending_both_false', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Ascending_WholeKey_Ties()
    var
        R: Record "W4 Sort Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        // Ties on A (ids 1 and 2, then 3 and 4): by B of the key or by the primary key.
        R.SetCurrentKey(A);
        Observer.Observe('key_a_ascending', Ids(R));
        R.Ascending(false);
        Observer.Observe('key_a_descending', Ids(R));
        Observer.Observe('ascending_answer', Format(R.Ascending()));
        // Ties on Txt: ids 1 and 5, then 2 and 3.
        R.Reset();
        R.SetCurrentKey(Txt);
        Observer.Observe('key_txt_ascending', Ids(R));
        R.Ascending(false);
        Observer.Observe('key_txt_descending', Ids(R));
        R.Reset();
        Observer.Observe('ascending_after_reset', Format(R.Ascending()));
        Observer.Observe('currentkey_after_reset', R.CurrentKey());
        Observer.Expect('key_a_ascending', '2,1,4,3,5,');
        Observer.Expect('key_a_descending', '5,3,4,1,2,');
        Observer.Expect('ascending_answer', 'No');
        Observer.Expect('key_txt_ascending', '1,5,2,3,4,');
        Observer.Expect('key_txt_descending', '4,3,2,5,1,');
        Observer.Expect('ascending_after_reset', 'Yes');
        Observer.Expect('currentkey_after_reset', 'Id');
        Observer.Verify();
    end;
}

codeunit 68046 "W4 RecRef Sort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "W4 Sort Row";
    begin
        R.DeleteAll();
        Add(1, 1, 2, 'a');
        Add(2, 1, 1, 'b');
        Add(3, 2, 2, 'b');
        Add(4, 2, 1, 'c');
        Add(5, 3, 1, 'a');
    end;

    local procedure Add(Id: Integer; A: Integer; B: Integer; Txt: Text[10])
    var
        R: Record "W4 Sort Row";
    begin
        R.Id := Id;
        R.A := A;
        R.B := B;
        R.Txt := Txt;
        R.Insert();
    end;

    local procedure Ids(var RR: RecordRef): Text
    var
        Result: Text;
    begin
        if RR.FindSet() then
            repeat
                Result += Format(RR.Field(1).Value()) + ',';
            until RR.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure RecordRef_Ascending()
    var
        RR: RecordRef;
        RR2: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"W4 Sort Row");
        RR.CurrentKeyIndex(3);
        Observer.Observe('currentkeyindex', Format(RR.CurrentKeyIndex()));
        Observer.Observe('ascending_default', Format(RR.Ascending()));
        Observer.Observe('ids_ascending', Ids(RR));
        RR.Ascending(false);
        Observer.Observe('ascending_after_false', Format(RR.Ascending()));
        Observer.Observe('ids_descending', Ids(RR));
        Observer.Observe('getview', RR.GetView());
        RR2.Open(Database::"W4 Sort Row");
        RR2.Copy(RR);
        Observer.Observe('copy_ascending', Format(RR2.Ascending()));
        Observer.Observe('copy_ids', Ids(RR2));
        RR.Reset();
        Observer.Observe('ascending_after_reset', Format(RR.Ascending()));
        Observer.Expect('currentkeyindex', '3');
        Observer.Expect('ascending_default', 'Yes');
        Observer.Expect('ids_ascending', '1,5,2,3,4,');
        Observer.Expect('ascending_after_false', 'No');
        Observer.Expect('ids_descending', '4,3,2,5,1,');
        Observer.Expect('getview', 'VERSION(1) SORTING(Txt) ORDER(Descending)');
        Observer.Expect('copy_ascending', 'No');
        Observer.Expect('copy_ids', '4,3,2,5,1,');
        Observer.Expect('ascending_after_reset', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_SetRecFilter_AndRecordSetRecFilter()
    var
        R: Record "W4 Sort Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        // The record form, for comparison.
        R.Get(3);
        R.SetRecFilter();
        Observer.Observe('record_filters', R.GetFilters());
        Observer.Observe('record_count', Format(R.Count()));
        R.Reset();
        R.SetCurrentKey(Txt);
        R.Get(3);
        R.SetRecFilter();
        Observer.Observe('record_key_txt_filters', R.GetFilters());
        Observer.Observe('record_key_txt_count', Format(R.Count()));
        // The RecordRef form.
        RR.Open(Database::"W4 Sort Row");
        RR.Get(RecId(3));
        RR.SetRecFilter();
        Observer.Observe('recref_filters', RR.GetFilters());
        Observer.Observe('recref_count', Format(RR.Count()));
        RR.Reset();
        RR.CurrentKeyIndex(3);
        RR.Get(RecId(3));
        RR.SetRecFilter();
        Observer.Observe('recref_key_txt_filters', RR.GetFilters());
        Observer.Observe('recref_key_txt_count', Format(RR.Count()));
        Observer.Expect('record_filters', 'Id: 3');
        Observer.Expect('record_count', '1');
        Observer.Expect('record_key_txt_filters', 'Id: 3, Txt: b');
        Observer.Expect('record_key_txt_count', '1');
        Observer.Expect('recref_filters', 'Id: 3');
        Observer.Expect('recref_count', '1');
        Observer.Expect('recref_key_txt_filters', 'Id: 3, Txt: b');
        Observer.Expect('recref_key_txt_count', '1');
        Observer.Verify();
    end;

    local procedure RecId(Id: Integer): RecordId
    var
        R: Record "W4 Sort Row";
    begin
        R.Get(Id);
        exit(R.RecordId());
    end;
}

codeunit 68047 "W4 Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "W4 Key Row";
    begin
        R.DeleteAll();
        Add(1, 2, 'b', 3);
        Add(2, 1, 'b', 1);
        Add(3, 1, 'a', 2);
        Add(4, 2, 'a', 1);
    end;

    local procedure Add(Id: Integer; F1: Integer; F2: Text[10]; Amt: Decimal)
    var
        R: Record "W4 Key Row";
    begin
        R.Id := Id;
        R.F1 := F1;
        R.F2 := F2;
        R.Amt := Amt;
        R.Insert();
    end;

    local procedure Ids(var R: Record "W4 Key Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    // Rows: id 1 (F1 2, F2 b, Amt 3), id 2 (1, b, 1), id 3 (1, a, 2), id 4 (2, a, 1). Declared keys: PK(Id), K1(F1). F2 and Amt start no key.
    [Test]
    procedure SetCurrentKey_FieldNoKeyStartsWith()
    var
        R: Record "W4 Key Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(F2);
        Observer.Observe('currentkey_f2', R.CurrentKey());
        Observer.Observe('ids_f2', Ids(R));
        R.Ascending(false);
        Observer.Observe('ids_f2_descending', Ids(R));
        Observer.Observe('ascending_answer', Format(R.Ascending()));
        R.Reset();
        R.SetCurrentKey(F2, F1);
        Observer.Observe('currentkey_f2_f1', R.CurrentKey());
        Observer.Observe('ids_f2_f1', Ids(R));
        R.Reset();
        R.SetCurrentKey(Amt);
        Observer.Observe('currentkey_amt', R.CurrentKey());
        Observer.Observe('ids_amt', Ids(R));
        R.Reset();
        R.SetCurrentKey(F1, F2);
        Observer.Observe('currentkey_f1_f2', R.CurrentKey());
        Observer.Observe('ids_f1_f2', Ids(R));
        R.Reset();
        R.SetCurrentKey(F2);
        R.SetFilter(Amt, '>=2');
        Observer.Observe('ids_f2_filtered', Ids(R));
        Observer.Observe('getview_f2_filtered', R.GetView());
        Observer.Expect('currentkey_f2', 'F2');
        Observer.Expect('ids_f2', '3,4,1,2,');
        Observer.Expect('ids_f2_descending', '2,1,4,3,');
        Observer.Expect('ascending_answer', 'No');
        Observer.Expect('currentkey_f2_f1', 'F2,F1');
        Observer.Expect('ids_f2_f1', '3,4,2,1,');
        Observer.Expect('currentkey_amt', 'Amt');
        Observer.Expect('ids_amt', '2,4,3,1,');
        Observer.Expect('currentkey_f1_f2', 'F1,F2');
        Observer.Expect('ids_f1_f2', '3,2,4,1,');
        Observer.Expect('ids_f2_filtered', '3,1,');
        Observer.Expect('getview_f2_filtered', 'VERSION(1) SORTING(F2) WHERE(Amt=FILTER(>=2))');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_SurvivesCopyAndRecordRef()
    var
        R: Record "W4 Key Row";
        R2: Record "W4 Key Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetCurrentKey(F2);
        R2.Copy(R);
        Observer.Observe('copy_currentkey', R2.CurrentKey());
        Observer.Observe('copy_ids', Ids(R2));
        RR.GetTable(R);
        Observer.Observe('recref_currentkeyindex', Format(RR.CurrentKeyIndex()));
        Observer.Observe('recref_getview', RR.GetView());
        Observer.Expect('copy_currentkey', 'F2');
        Observer.Expect('copy_ids', '3,4,1,2,');
        Observer.Expect('recref_currentkeyindex', '-1');
        Observer.Expect('recref_getview', 'VERSION(1) SORTING(F2)');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryKeyFlowField(var R: Record "W4 Key Row")
    begin
        R.SetCurrentKey(Cnt);
    end;

    [TryFunction]
    local procedure TryKeyFlowFilter(var R: Record "W4 Key Row")
    begin
        R.SetCurrentKey(Flow);
    end;

    [TryFunction]
    local procedure TryKeyBlob(var R: Record "W4 Key Row")
    begin
        R.SetCurrentKey(Bl);
    end;

    [TryFunction]
    local procedure TryKeyMedia(var R: Record "W4 Key Row")
    begin
        R.SetCurrentKey(Md);
    end;

    local procedure Outcome(Ok: Boolean; R: Record "W4 Key Row"): Text
    begin
        if Ok then
            exit('ok:[' + R.CurrentKey() + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SetCurrentKey_NotStoredFields()
    var
        R: Record "W4 Key Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('flowfield', Outcome(TryKeyFlowField(R), R));
        ClearLastError();
        Clear(R);
        Observer.Observe('flowfilter', Outcome(TryKeyFlowFilter(R), R));
        ClearLastError();
        Clear(R);
        Observer.Observe('blob', Outcome(TryKeyBlob(R), R));
        ClearLastError();
        Clear(R);
        Observer.Observe('media', Outcome(TryKeyMedia(R), R));
        ClearLastError();
        Observer.Expect('flowfield', 'ok:[Id]');
        Observer.Expect('flowfilter', 'error:Sorting cannot be done based on the Flow field(s) in the W4 Key Row table.|DB:Ok');
        Observer.Expect('blob', 'error:Sorting cannot be done based on the Bl field(s) in the W4 Key Row table.|DB:Ok');
        Observer.Expect('media', 'ok:[Id]');
        Observer.Verify();
    end;
}
