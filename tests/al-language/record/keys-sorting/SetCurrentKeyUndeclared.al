// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Known pin: recordref/TestRecordRefRuntimeContracts.al:RecordRef_GetTableAndSetTable_... (CurrentKey answers the fields on a RecordRef)

table 73237 "LT P163 SK"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; A; Integer) { }
        field(3; B; Text[20]) { }
        field(4; C; Decimal) { }
        field(5; Blobby; Blob) { }
        field(6; Counted; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P163 SK");
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(K1; A) { }
        key(K2; B, A) { }
    }
}

codeunit 73238 "LT P163 SetCurrentKey"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var R: Record "LT P163 SK")
    begin
        R.DeleteAll(false);
        Add(R, 'A', 3, 'm', 30);
        Add(R, 'B', 1, 'z', 10);
        Add(R, 'C', 2, 'a', 20);
        Add(R, 'D', 2, 'y', 20);
        Add(R, 'E', 1, 'b', 10);
        R.Reset();
    end;

    local procedure Add(var R: Record "LT P163 SK"; NewCode: Code[10]; NewA: Integer; NewB: Text; NewC: Decimal)
    begin
        R.Init();
        R.Code := NewCode;
        R.A := NewA;
        R.B := CopyStr(NewB, 1, MaxStrLen(R.B));
        R.C := NewC;
        R.Insert(false);
    end;

    local procedure Codes(var R: Record "LT P163 SK"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += R.Code;
            until R.Next() = 0;
        exit(Result);
    end;

    local procedure CodesBackwards(var R: Record "LT P163 SK"): Text
    var
        Result: Text;
    begin
        if R.FindLast() then
            repeat
                Result += R.Code;
            until R.Next(-1) = 0;
        exit(Result);
    end;

    [Test]
    procedure P163_SetCurrentKey_UndeclaredFields_Order()
    var
        R: Record "LT P163 SK";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        Observer.Observe('primary', Codes(R));
        R.SetCurrentKey(A);
        Observer.Observe('declared_K1_A', Codes(R));
        R.SetCurrentKey(B, A);
        Observer.Observe('declared_K2_B_A', Codes(R));
        R.SetCurrentKey(C);
        Observer.Observe('undeclared_C', Codes(R));
        Observer.Observe('undeclared_C_backwards', CodesBackwards(R));
        R.SetCurrentKey(A, C);
        Observer.Observe('undeclared_A_C', Codes(R));
        R.SetCurrentKey(C, A);
        Observer.Observe('undeclared_C_A', Codes(R));
        R.SetCurrentKey(B);
        Observer.Observe('prefix_of_K2_B', Codes(R));
        R.SetCurrentKey(C, B, A);
        Observer.Observe('undeclared_C_B_A', Codes(R));
        R.SetCurrentKey(Code);
        Observer.Observe('back_to_primary_field', Codes(R));
        Observer.Expect('primary', 'ABCDE');
        Observer.Expect('declared_K1_A', 'BECDA');
        Observer.Expect('declared_K2_B_A', 'CEADB');
        Observer.Expect('undeclared_C', 'BECDA');
        Observer.Expect('undeclared_C_backwards', 'ADCEB');
        Observer.Expect('undeclared_A_C', 'BECDA');
        Observer.Expect('undeclared_C_A', 'BECDA');
        Observer.Expect('prefix_of_K2_B', 'CEADB');
        Observer.Expect('undeclared_C_B_A', 'EBCDA');
        Observer.Expect('back_to_primary_field', 'ABCDE');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetCurrentKey_UndeclaredFields_FindFirstLastNext()
    var
        R: Record "LT P163 SK";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.SetCurrentKey(C);
        R.FindFirst();
        Observer.Observe('first', R.Code);
        R.FindLast();
        Observer.Observe('last', R.Code);
        R.FindFirst();
        Observer.Observe('next_1', Format(R.Next()) + R.Code);
        Observer.Observe('next_2', Format(R.Next()) + R.Code);
        Observer.Observe('next_minus_1', Format(R.Next(-1)) + R.Code);
        R.Get('C');
        Observer.Observe('find_greater_from_C', Format(R.Find('>')) + R.Code);
        R.Get('C');
        Observer.Observe('find_less_from_C', Format(R.Find('<')) + R.Code);
        R.Get('C');
        Observer.Observe('find_equal_from_C', Format(R.Find('=')) + R.Code);
        R.Get('A');
        Observer.Observe('find_greater_from_A_last', Format(R.Find('>')) + R.Code);
        Observer.Expect('first', 'B');
        Observer.Expect('last', 'A');
        Observer.Expect('next_1', '1E');
        Observer.Expect('next_2', '1C');
        Observer.Expect('next_minus_1', '-1E');
        Observer.Expect('find_greater_from_C', 'YesD');
        Observer.Expect('find_less_from_C', 'YesE');
        Observer.Expect('find_equal_from_C', 'YesC');
        Observer.Expect('find_greater_from_A_last', 'NoA');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetCurrentKey_UndeclaredFields_CurrentKeyViewAscending()
    var
        R: Record "LT P163 SK";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.SetCurrentKey(C);
        Observer.Observe('current_key', R.CurrentKey());
        Observer.Observe('view', R.GetView());
        Observer.Observe('view_without_names', R.GetView(false));
        R.SetCurrentKey(C, A);
        Observer.Observe('current_key_two', R.CurrentKey());
        R.SetAscending(C, false);
        Observer.Observe('ascending_false', Format(R.Ascending()));
        Observer.Observe('codes_descending', Codes(R));
        Observer.Observe('view_descending', R.GetView());
        R.SetAscending(C, true);
        R.SetCurrentKey(A);
        Observer.Observe('current_key_declared', R.CurrentKey());
        Observer.Expect('current_key', 'C');
        Observer.Expect('view', 'VERSION(1) SORTING(C)');
        Observer.Expect('view_without_names', 'VERSION(1) SORTING(Field4)');
        Observer.Expect('current_key_two', 'C,A');
        Observer.Expect('ascending_false', 'No');
        Observer.Expect('codes_descending', 'ACDBE');
        Observer.Expect('view_descending', 'VERSION(1) SORTING(C,A) ORDER(Descending,Ascending)');
        Observer.Expect('current_key_declared', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetCurrentKey_UndeclaredFields_WithFiltersAndCopy()
    var
        R: Record "LT P163 SK";
        Dup: Record "LT P163 SK";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.SetCurrentKey(C);
        R.SetRange(A, 1, 2);
        Observer.Observe('filtered_range_A', Codes(R));
        R.SetRange(A);
        R.SetFilter(C, '>=20');
        Observer.Observe('filtered_C', Codes(R));
        Observer.Observe('count_filtered', Format(R.Count()));
        R.Reset();
        R.SetCurrentKey(C);
        Dup.Copy(R);
        Observer.Observe('copy_current_key', Dup.CurrentKey());
        Observer.Observe('copy_codes', Codes(Dup));
        R.Reset();
        Observer.Observe('after_reset_codes', Codes(R));
        Observer.Observe('after_reset_current_key', R.CurrentKey());
        Observer.Expect('filtered_range_A', 'BECD');
        Observer.Expect('filtered_C', 'CDA');
        Observer.Expect('count_filtered', '3');
        Observer.Expect('copy_current_key', 'C');
        Observer.Expect('copy_codes', 'BECDA');
        Observer.Expect('after_reset_codes', 'ABCDE');
        Observer.Expect('after_reset_current_key', 'Code');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetCurrentKey_UndeclaredFields_TemporaryRecord()
    var
        TmpRec: Record "LT P163 SK" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Add(TmpRec, 'A', 3, 'm', 30);
        Add(TmpRec, 'B', 1, 'z', 10);
        Add(TmpRec, 'C', 2, 'a', 20);
        Add(TmpRec, 'D', 2, 'y', 20);
        Add(TmpRec, 'E', 1, 'b', 10);
        TmpRec.Reset();
        Observer.Observe('primary', Codes(TmpRec));
        TmpRec.SetCurrentKey(C);
        Observer.Observe('undeclared_C', Codes(TmpRec));
        TmpRec.SetCurrentKey(B);
        Observer.Observe('declared_prefix_B', Codes(TmpRec));
        TmpRec.SetCurrentKey(C, B);
        Observer.Observe('undeclared_C_B', Codes(TmpRec));
        Observer.Expect('primary', 'ABCDE');
        Observer.Expect('undeclared_C', 'BECDA');
        Observer.Expect('declared_prefix_B', 'CEADB');
        Observer.Expect('undeclared_C_B', 'EBCDA');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetCurrentKey_FlowFieldAndBlob()
    var
        R: Record "LT P163 SK";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.SetCurrentKey(Counted);
        Observer.Observe('flowfield', 'no error');
        asserterror R.SetCurrentKey(Blobby);
        Observer.ObserveError('blob');
        R.SetCurrentKey(A, Counted);
        Observer.Observe('declared_then_flowfield', 'no error');
        Observer.Expect('flowfield', 'no error');
        Observer.Expect('blob|text', 'Sorting cannot be done based on the Blobby field(s) in the LT P163 SK table.');
        Observer.Expect('blob|code', 'DB:Ok');
        Observer.Expect('declared_then_flowfield', 'no error');
        Observer.Verify();
    end;

    // Corpus issue 668 item 16 (writer BQ): which key SetCurrentKey picks when several keys fit. LT BQ Key Pick (record/lt-bq-odd-leads/
    // BqObjects.al) has K1 (A, B), K2 (A, C), K3 (C), K5 (D) with IncludedFields E, and K6 (F) with Enabled = false. Rows 1..4 all have A = 1
    // and D = 0; B 2 1 4 3; C 3 4 1 2; E 4 3 2 1; F 1 4 3 2: the order of the ids shows which fields sort.
    local procedure BqSeedKeyPick()
    var
        R: Record "LT BQ Key Pick";
    begin
        R.DeleteAll();
        BqAddKeyPick(1, 2, 3, 4, 1);
        BqAddKeyPick(2, 1, 4, 3, 4);
        BqAddKeyPick(3, 4, 1, 2, 3);
        BqAddKeyPick(4, 3, 2, 1, 2);
    end;

    local procedure BqAddKeyPick(Id: Integer; B: Integer; C: Integer; E: Integer; F: Integer)
    var
        R: Record "LT BQ Key Pick";
    begin
        R.Init();
        R.Id := Id;
        R.A := 1;
        R.B := B;
        R.C := C;
        R.E := E;
        R.F := F;
        R.Insert();
    end;

    local procedure BqKeyPickIds(var R: Record "LT BQ Key Pick"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id);
            until R.Next() = 0;
        exit(R.CurrentKey() + '|' + Result);
    end;

    [Test]
    procedure P163_SetCurrentKey_WhichKeyIsPicked_BQ()
    var
        R: Record "LT BQ Key Pick";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedKeyPick();
        R.SetCurrentKey(A);
        Observer.Observe('a', BqKeyPickIds(R));
        Observer.Observe('a_view', R.GetView());
        R.SetCurrentKey(C);
        Observer.Observe('c', BqKeyPickIds(R));
        R.SetCurrentKey(A, C);
        Observer.Observe('a_c', BqKeyPickIds(R));
        R.SetCurrentKey(B);
        Observer.Observe('b', BqKeyPickIds(R));
        R.SetCurrentKey(D);
        Observer.Observe('d', BqKeyPickIds(R));
        R.SetCurrentKey(E);
        Observer.Observe('e_included_only', BqKeyPickIds(R));
        R.SetCurrentKey(F);
        Observer.Observe('f_disabled_key', BqKeyPickIds(R));
        R.SetCurrentKey(D, E);
        Observer.Observe('d_e', BqKeyPickIds(R));
        Observer.Expect('a', 'A,B|2143');
        Observer.Expect('a_view', 'VERSION(1) SORTING(A,B)');
        Observer.Expect('c', 'C|3412');
        Observer.Expect('a_c', 'A,C|3412');
        Observer.Expect('b', 'B|2143');
        Observer.Expect('d', 'D|1234');
        Observer.Expect('e_included_only', 'E|4321');
        Observer.Expect('f_disabled_key', 'F|1432');
        Observer.Expect('d_e', 'D,E|4321');
        Observer.Verify();
    end;
}
