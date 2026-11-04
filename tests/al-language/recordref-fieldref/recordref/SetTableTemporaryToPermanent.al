// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73748 and codeunit 73749
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a temporary record with rows into a RecordRef by GetTable, then SetTable into a record variable that is not temporary (IsTemporary, Count, Get, Insert, Modify, Delete and what the permanent table holds afterwards);
//   the other direction (permanent record into RecordRef, SetTable into a temporary variable); a second SetTable into the same variable.
//   Pinned already: RecordRef.Open(id, true) then SetTable into a permanent / permanent RecordRef into temporary variable (record/lt-loadfields-pagesource-validate/P81RecordRefTables.al
//   TempRecordRef_SetTable_IntoNonTemporaryRecord, NonTempRecordRef_SetTable_IntoTemporaryRecord; recordref/lt-recordref-fieldref-members/P92SetTable.al SetTable_TemporaryVariants).
// BC versions: 29 (27 and 28 by CI)

table 73748 "LT SetTblTmp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 73749 "LT SetTblTmp Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT SetTblTmp Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'perm-a';
        Row.Insert();
        Row.Code := 'B';
        Row.Name := 'perm-b';
        Row.Insert();
    end;

    local procedure SeedTemp(var Tmp: Record "LT SetTblTmp Row" temporary)
    begin
        Tmp.Init();
        Tmp.Code := 'T1';
        Tmp.Name := 'temp-1';
        Tmp.Insert();
        Tmp.Code := 'T2';
        Tmp.Name := 'temp-2';
        Tmp.Insert();
        Tmp.Code := 'T3';
        Tmp.Name := 'temp-3';
        Tmp.Insert();
    end;

    [Test]
    procedure SetTable_TempIntoPermanent_State()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Perm: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        SeedTemp(Tmp);
        RR.GetTable(Tmp);
        Observer.Observe('recref_temp', Format(RR.IsTemporary()));
        Observer.Observe('recref_count', Format(RR.Count()));
        RR.SetTable(Perm);
        Observer.Observe('perm_temp', Format(Perm.IsTemporary()));
        Observer.Observe('perm_count', Format(Perm.Count()));
        Observer.Observe('perm_get_t1', Format(Perm.Get('T1')));
        Observer.Observe('perm_get_a', Format(Perm.Get('A')));
        Observer.Observe('perm_isempty', Format(Perm.IsEmpty()));
        Observer.Expect('recref_temp', 'Yes');
        Observer.Expect('recref_count', '3');
        Observer.Expect('perm_temp', 'No');
        Observer.Expect('perm_count', '2');
        Observer.Expect('perm_get_t1', 'No');
        Observer.Expect('perm_get_a', 'Yes');
        Observer.Expect('perm_isempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TempIntoPermanent_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Perm: Record "LT SetTblTmp Row";
        Check: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        SeedTemp(Tmp);
        RR.GetTable(Tmp);
        RR.SetTable(Perm);
        Perm.Init();
        Perm.Code := 'N1';
        Perm.Name := 'new-1';
        Perm.Insert();
        Observer.Observe('perm_temp', Format(Perm.IsTemporary()));
        Observer.Observe('perm_count_after_insert', Format(Perm.Count()));
        Observer.Observe('check_count', Format(Check.Count()));
        Observer.Observe('check_get_n1', Format(Check.Get('N1')));
        Observer.Observe('tmp_count', Format(Tmp.Count()));
        Observer.Observe('tmp_get_n1', Format(Tmp.Get('N1')));
        Observer.Expect('perm_temp', 'No');
        Observer.Expect('perm_count_after_insert', '3');
        Observer.Expect('check_count', '3');
        Observer.Expect('check_get_n1', 'Yes');
        Observer.Expect('tmp_count', '3');
        Observer.Expect('tmp_get_n1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TempIntoPermanent_ModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Perm: Record "LT SetTblTmp Row";
        Check: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        SeedTemp(Tmp);
        RR.GetTable(Tmp);
        RR.SetTable(Perm);
        Perm.Code := 'T2';
        Observer.Observe('perm_get_t2', Format(Perm.Get('T2')));
        if Perm.Get('T2') then begin
            Perm.Name := 'changed';
            Observer.Observe('modify', Format(Perm.Modify()));
        end;
        if Perm.Get('T3') then
            Observer.Observe('delete', Format(Perm.Delete()));
        Observer.Observe('tmp_t2_name', Tmp.Name);
        Observer.Observe('tmp_count', Format(Tmp.Count()));
        Observer.Observe('check_count', Format(Check.Count()));
        Observer.Expect('perm_get_t2', 'No');
        Observer.Expect('tmp_t2_name', 'temp-3');
        Observer.Expect('tmp_count', '3');
        Observer.Expect('check_count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_PermanentIntoTemporary_State()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Perm: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Check: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        Perm.FindFirst();
        RR.GetTable(Perm);
        Observer.Observe('recref_temp', Format(RR.IsTemporary()));
        Observer.Observe('recref_count', Format(RR.Count()));
        RR.SetTable(Tmp);
        Observer.Observe('tmp_temp', Format(Tmp.IsTemporary()));
        Observer.Observe('tmp_count', Format(Tmp.Count()));
        Observer.Observe('tmp_get_a', Format(Tmp.Get('A')));
        Tmp.Init();
        Tmp.Code := 'N1';
        Tmp.Name := 'new-1';
        Tmp.Insert();
        Observer.Observe('tmp_count_after_insert', Format(Tmp.Count()));
        Observer.Observe('check_count', Format(Check.Count()));
        Observer.Observe('check_get_n1', Format(Check.Get('N1')));
        Observer.Expect('recref_temp', 'No');
        Observer.Expect('recref_count', '2');
        Observer.Expect('tmp_temp', 'Yes');
        Observer.Expect('tmp_count', '0');
        Observer.Expect('tmp_get_a', 'No');
        Observer.Expect('tmp_count_after_insert', '1');
        Observer.Expect('check_count', '2');
        Observer.Expect('check_get_n1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TempIntoPermanent_ThenIntoTemp()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Other: Record "LT SetTblTmp Row" temporary;
        Perm: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        SeedTemp(Tmp);
        RR.GetTable(Tmp);
        RR.SetTable(Perm);
        RR.SetTable(Other);
        Observer.Observe('perm_temp', Format(Perm.IsTemporary()));
        Observer.Observe('other_temp', Format(Other.IsTemporary()));
        Observer.Observe('other_count', Format(Other.Count()));
        Observer.Observe('other_get_t1', Format(Other.Get('T1')));
        Observer.Expect('perm_temp', 'No');
        Observer.Expect('other_temp', 'Yes');
        Observer.Expect('other_count', '0');
        Observer.Expect('other_get_t1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TempIntoPermanent_FilteredSource()
    var
        Observer: Codeunit "Probe Observer";
        Seeded: Record "LT SetTblTmp Row";
        Tmp: Record "LT SetTblTmp Row" temporary;
        Perm: Record "LT SetTblTmp Row";
        RR: RecordRef;
    begin
        Seed(Seeded);
        SeedTemp(Tmp);
        Tmp.SetRange(Code, 'T2', 'T3');
        Tmp.FindFirst();
        RR.GetTable(Tmp);
        Observer.Observe('recref_count', Format(RR.Count()));
        RR.SetTable(Perm);
        Observer.Observe('perm_temp', Format(Perm.IsTemporary()));
        Observer.Observe('perm_filters', Perm.GetFilters());
        Observer.Observe('perm_code', Perm.Code);
        Observer.Observe('perm_count', Format(Perm.Count()));
        Observer.Expect('recref_count', '2');
        Observer.Expect('perm_temp', 'No');
        Observer.Expect('perm_filters', 'Code: T2..T3');
        Observer.Expect('perm_code', 'T2');
        Observer.Expect('perm_count', '0');
        Observer.Verify();
    end;
}
