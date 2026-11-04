// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: tables 73000, 73001 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Open, Close, IsTemporary, Name, Number, Caption, Count, IsEmpty, Get, GetBySystemId, Find directions, Next
// BC versions: 29 (27 and 28 by CI)

codeunit 73020 "LT RfT Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ScrubCaller(Value: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, ' from the object ');
        EndPos := StrPos(Value, '. An object with that ID');
        if (StartPos = 0) or (EndPos < StartPos) then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos - 1) + ' from the object <caller>' + CopyStr(Value, EndPos));
    end;

    [Test]
    procedure Open_Basics()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Observer.Observe('name', RecRef.Name());
        Observer.Observe('number', Format(RecRef.Number()));
        Observer.Observe('caption', RecRef.Caption());
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('isempty', Format(RecRef.IsEmpty()));
        Observer.Observe('istemp', Format(RecRef.IsTemporary()));
        Observer.Observe('currentcompany', Format(RecRef.CurrentCompany() = CompanyName()));
        Observer.Observe('fieldcount', Format(RecRef.FieldCount()));
        Observer.Observe('keycount', Format(RecRef.KeyCount()));
        Observer.Observe('currentkeyindex', Format(RecRef.CurrentKeyIndex()));
        RecRef.Close();
        Observer.Expect('name', 'LT RfT Data');
        Observer.Expect('number', '73001');
        Observer.Expect('caption', 'RfT Data Caption');
        Observer.Expect('count', '5');
        Observer.Expect('isempty', 'No');
        Observer.Expect('istemp', 'No');
        Observer.Expect('currentcompany', 'Yes');
        Observer.Expect('keycount', '4');
        Observer.Expect('currentkeyindex', '1');
        Observer.Ignore('fieldcount'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure Open_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001, true);
        Observer.Observe('istemp', Format(RecRef.IsTemporary()));
        Observer.Observe('count_empty', Format(RecRef.Count()));
        Observer.Observe('isempty', Format(RecRef.IsEmpty()));
        Fld := RecRef.Field(1);
        Fld.Value := 'T1';
        Observer.Observe('insert', Format(RecRef.Insert()));
        Observer.Observe('count_after', Format(RecRef.Count()));
        RecRef.Close();
        RecRef.Open(73001);
        Observer.Observe('real_count', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Expect('istemp', 'Yes');
        Observer.Expect('count_empty', '0');
        Observer.Expect('isempty', 'Yes');
        Observer.Expect('insert', 'Yes');
        Observer.Expect('count_after', '1');
        Observer.Expect('real_count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Open_TemporaryFalse_ExplicitCompany()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001, false);
        Observer.Observe('istemp_false', Format(RecRef.IsTemporary()));
        Observer.Observe('count_false', Format(RecRef.Count()));
        RecRef.Close();
        RecRef.Open(73001, false, CompanyName());
        Observer.Observe('count_company', Format(RecRef.Count()));
        Observer.Observe('istemp_company', Format(RecRef.IsTemporary()));
        RecRef.Close();
        RecRef.Open(73001, true, CompanyName());
        Observer.Observe('count_temp_company', Format(RecRef.Count()));
        Observer.Observe('istemp_temp_company', Format(RecRef.IsTemporary()));
        RecRef.Close();
        Observer.Expect('istemp_false', 'No');
        Observer.Expect('count_false', '5');
        Observer.Expect('count_company', '5');
        Observer.Expect('istemp_company', 'No');
        Observer.Expect('count_temp_company', '0');
        Observer.Expect('istemp_temp_company', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Open_OtherCompany_Unknown()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(73001, false, 'No Such Company XYZ');
        Observer.ObserveError('unknown_company');
        RecRef.Open(73001, false, '');
        Observer.Observe('blank_company', 'no error');
        Observer.Expect('unknown_company|text', 'The company "No Such Company XYZ" does not exist.');
        Observer.Expect('unknown_company|code', 'DB:RecordNotFound');
        Observer.Expect('blank_company', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Open_InvalidTableNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(0);
        Observer.Observe('zero', 'no error');
        asserterror RecRef.Open(-1);
        Observer.Observe('negative|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('negative|code', GetLastErrorCode());
        ClearLastError();
        asserterror RecRef.Open(73999);
        Observer.Observe('missing|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('missing|code', GetLastErrorCode());
        ClearLastError();
        asserterror RecRef.Open(2147483647);
        Observer.Observe('maxint|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('maxint|code', GetLastErrorCode());
        ClearLastError();
        asserterror RecRef.Open(Codeunit::"Probe Observer");
        Observer.Observe('codeunit_id|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('codeunit_id|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('zero', 'no error');
        Observer.Expect('negative|text', 'You tried to invoke the Table object with the ID -1 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('negative|code', 'AL:MetadataNotFound');
        Observer.Expect('missing|text', 'You tried to invoke the Table object with the ID 73999 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('missing|code', 'AL:MetadataNotFound');
        Observer.Expect('maxint|text', 'You tried to invoke the Table object with the ID 2147483647 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('maxint|code', 'AL:MetadataNotFound');
        Observer.Expect('codeunit_id|text', 'You tried to invoke the Table object with the ID 69160 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('codeunit_id|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Closed_Errors()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Dummy: Text;
        Num: Integer;
        B: Boolean;
    begin
        asserterror Dummy := RecRef.Name();
        Observer.ObserveError('name');
        Num := RecRef.Number();
        Observer.Observe('number', 'no error');
        asserterror Dummy := RecRef.Caption();
        Observer.ObserveError('caption');
        asserterror Num := RecRef.Count();
        Observer.ObserveError('count');
        asserterror B := RecRef.IsEmpty();
        Observer.ObserveError('isempty');
        asserterror B := RecRef.IsTemporary();
        Observer.ObserveError('istemporary');
        asserterror Num := RecRef.FieldCount();
        Observer.ObserveError('fieldcount');
        asserterror Fld := RecRef.Field(1);
        Observer.ObserveError('field');
        asserterror B := RecRef.Find('-');
        Observer.ObserveError('find');
        asserterror B := RecRef.Insert();
        Observer.ObserveError('insert');
        asserterror B := RecRef.Modify();
        Observer.ObserveError('modify');
        asserterror B := RecRef.Delete();
        Observer.ObserveError('delete');
        asserterror RecRef.DeleteAll();
        Observer.ObserveError('deleteall');
        asserterror Num := RecRef.KeyCount();
        Observer.ObserveError('keycount');
        asserterror Num := RecRef.CurrentKeyIndex();
        Observer.ObserveError('currentkeyindex');
        asserterror RecRef.Init();
        Observer.ObserveError('init');
        asserterror Dummy := RecRef.GetView();
        Observer.ObserveError('getview');
        asserterror RecRef.SetView('');
        Observer.ObserveError('setview');
        asserterror RecRef.Reset();
        Observer.ObserveError('reset');
        asserterror Dummy := Format(RecRef.RecordId());
        Observer.ObserveError('recordid');
        Observer.Expect('name|text', 'The record is not open.');
        Observer.Expect('name|code', 'RecordNotOpened');
        Observer.Expect('number', 'no error');
        Observer.Expect('caption|text', 'The record is not open.');
        Observer.Expect('caption|code', 'RecordNotOpened');
        Observer.Expect('count|text', 'The record is not open.');
        Observer.Expect('count|code', 'RecordNotOpened');
        Observer.Expect('isempty|text', 'The record is not open.');
        Observer.Expect('isempty|code', 'RecordNotOpened');
        Observer.Expect('istemporary|text', 'The record is not open.');
        Observer.Expect('istemporary|code', 'RecordNotOpened');
        Observer.Expect('field|text', 'The record is not open.');
        Observer.Expect('field|code', 'RecordNotOpened');
        Observer.Expect('find|text', 'The record is not open.');
        Observer.Expect('find|code', 'RecordNotOpened');
        Observer.Expect('insert|text', 'The record is not open.');
        Observer.Expect('insert|code', 'RecordNotOpened');
        Observer.Expect('modify|text', 'The record is not open.');
        Observer.Expect('modify|code', 'RecordNotOpened');
        Observer.Expect('delete|text', 'The record is not open.');
        Observer.Expect('delete|code', 'RecordNotOpened');
        Observer.Expect('deleteall|text', 'The record is not open.');
        Observer.Expect('deleteall|code', 'RecordNotOpened');
        Observer.Expect('keycount|text', 'The record is not open.');
        Observer.Expect('keycount|code', 'RecordNotOpened');
        Observer.Expect('currentkeyindex|text', 'The record is not open.');
        Observer.Expect('currentkeyindex|code', 'RecordNotOpened');
        Observer.Expect('init|text', 'The record is not open.');
        Observer.Expect('init|code', 'RecordNotOpened');
        Observer.Expect('getview|text', 'The record is not open.');
        Observer.Expect('getview|code', 'RecordNotOpened');
        Observer.Expect('setview|text', 'The record is not open.');
        Observer.Expect('setview|code', 'RecordNotOpened');
        Observer.Expect('reset|text', 'The record is not open.');
        Observer.Expect('reset|code', 'RecordNotOpened');
        Observer.Expect('recordid|text', 'The record is not open.');
        Observer.Expect('recordid|code', 'RecordNotOpened');
        Observer.Ignore('fieldcount|text'); // a dump or environment data: observed, not asserted
        Observer.Ignore('fieldcount|code'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure Get_ByRecordId_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Rec.Code := 'D2';
        Observer.Observe('get_existing', Format(RecRef.Get(Rec.RecordId())));
        Fld := RecRef.Field(2);
        Observer.Observe('txt', Format(Fld.Value));
        Rec.Code := 'NOPE';
        Observer.Observe('get_missing', Format(RecRef.Get(Rec.RecordId())));
        Rec.Code := '';
        Observer.Observe('get_blank', Format(RecRef.Get(Rec.RecordId())));
        Rec.Code := 'd2';
        Observer.Observe('get_case', Format(RecRef.Get(Rec.RecordId())));
        Observer.Expect('get_existing', 'Yes');
        Observer.Expect('txt', 'Text 2');
        Observer.Expect('get_missing', 'No');
        Observer.Expect('get_blank', 'No');
        Observer.Expect('get_case', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_ErrorPaths()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Parent";
        B: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Rec.Get('P1');
        B := RecRef.Get(Rec.RecordId());
        Observer.Observe('wrong_table_recordid', 'no error');
        Observer.Expect('wrong_table_recordid', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Get_ByRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        Rec: Record "LT RfT Data";
        RecId: RecordId;
        Fld: FieldRef;
    begin
        Helper.Seed();
        Rec.Get('D3');
        RecId := Rec.RecordId();
        Observer.Observe('recordid_format', Format(RecId));
        RecRef.Open(73001);
        Observer.Observe('get', Format(RecRef.Get(RecId)));
        Fld := RecRef.Field(2);
        Observer.Observe('txt', Format(Fld.Value));
        Observer.Observe('recordid_of_ref', Format(RecRef.RecordId()));
        Observer.Observe('same', Format(RecRef.RecordId() = RecId));
        RecRef2.Open(73000);
        RecRef2.Get(RecId);
        Observer.Observe('wrong_table', 'no error');
        Rec.Get('D3');
        Rec.Delete();
        Observer.Observe('get_deleted', Format(RecRef.Get(RecId)));
        Observer.Expect('recordid_format', 'LT RfT Data: D3');
        Observer.Expect('get', 'Yes');
        Observer.Expect('txt', 'Text 3');
        Observer.Expect('recordid_of_ref', 'LT RfT Data: D3');
        Observer.Expect('same', 'Yes');
        Observer.Expect('wrong_table', 'no error');
        Observer.Expect('get_deleted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
        Fld: FieldRef;
        EmptyGuid: Guid;
        SysId: Guid;
    begin
        Helper.Seed();
        Rec.Get('D4');
        SysId := Rec.SystemId;
        RecRef.Open(73001);
        Observer.Observe('found', Format(RecRef.GetBySystemId(SysId)));
        Fld := RecRef.Field(1);
        Observer.Observe('code', Format(Fld.Value));
        Observer.Observe('empty_guid', Format(RecRef.GetBySystemId(EmptyGuid)));
        Observer.Observe('random_guid', Format(RecRef.GetBySystemId(CreateGuid())));
        RecRef.Close();
        Observer.Expect('found', 'Yes');
        Observer.Expect('code', 'D4');
        Observer.Expect('empty_guid', 'No');
        Observer.Expect('random_guid', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Directions()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(1);
        Observer.Observe('first', Format(RecRef.FindFirst()) + Format(Fld.Value));
        Observer.Observe('last', Format(RecRef.FindLast()) + Format(Fld.Value));
        Observer.Observe('find_minus', Format(RecRef.Find('-')) + Format(Fld.Value));
        Observer.Observe('find_plus', Format(RecRef.Find('+')) + Format(Fld.Value));
        Observer.Observe('find_eq', Format(RecRef.Find('=')) + Format(Fld.Value));
        Observer.Observe('find_default', Format(RecRef.Find()) + Format(Fld.Value));
        Observer.Observe('find_ge', Format(RecRef.Find('>=')) + Format(Fld.Value));
        Observer.Observe('find_le', Format(RecRef.Find('<=')) + Format(Fld.Value));
        Observer.Observe('find_gt', Format(RecRef.Find('>')) + Format(Fld.Value));
        Observer.Observe('find_lt', Format(RecRef.Find('<')) + Format(Fld.Value));
        asserterror RecRef.Find('x');
        Observer.ObserveError('find_x');
        asserterror RecRef.Find('');
        Observer.ObserveError('find_empty');
        asserterror RecRef.Find('--');
        Observer.ObserveError('find_two');
        Observer.Expect('first', 'YesD1');
        Observer.Expect('last', 'YesD5');
        Observer.Expect('find_minus', 'YesD1');
        Observer.Expect('find_plus', 'YesD5');
        Observer.Expect('find_eq', 'YesD5');
        Observer.Expect('find_default', 'YesD5');
        Observer.Expect('find_ge', 'YesD5');
        Observer.Expect('find_le', 'YesD4');
        Observer.Expect('find_gt', 'YesD5');
        Observer.Expect('find_lt', 'YesD4');
        Observer.Expect('find_x|text', 'There is an invalid character in the Find expression ''x''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('find_x|code', 'DB:BadSearchMethod');
        Observer.Expect('find_empty|text', 'There is an invalid character in the Find expression ''''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('find_empty|code', 'DB:BadSearchMethod');
        Observer.Expect('find_two|text', 'There is an invalid character in the Find expression ''--''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('find_two|code', 'DB:BadSearchMethod');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Relative_ToCurrent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(1);
        Fld.Value := 'D3';
        Observer.Observe('eq', Format(RecRef.Find('=')) + Format(Fld.Value));
        Fld.Value := 'D3';
        Observer.Observe('gt', Format(RecRef.Find('>')) + Format(Fld.Value));
        Fld.Value := 'D3';
        Observer.Observe('lt', Format(RecRef.Find('<')) + Format(Fld.Value));
        Fld.Value := 'D3';
        Observer.Observe('ge', Format(RecRef.Find('>=')) + Format(Fld.Value));
        Fld.Value := 'D3';
        Observer.Observe('le', Format(RecRef.Find('<=')) + Format(Fld.Value));
        Fld.Value := 'D35';
        Observer.Observe('eq_missing', Format(RecRef.Find('=')));
        Fld.Value := 'D35';
        Observer.Observe('ge_missing', Format(RecRef.Find('>=')) + Format(Fld.Value));
        Fld.Value := 'D35';
        Observer.Observe('le_missing', Format(RecRef.Find('<=')) + Format(Fld.Value));
        Fld.Value := 'Z';
        Observer.Observe('gt_beyond', Format(RecRef.Find('>')));
        Fld.Value := 'A';
        Observer.Observe('lt_before', Format(RecRef.Find('<')));
        Observer.Expect('eq', 'YesD3');
        Observer.Expect('gt', 'YesD4');
        Observer.Expect('lt', 'YesD2');
        Observer.Expect('ge', 'YesD4');
        Observer.Expect('le', 'YesD2');
        Observer.Expect('eq_missing', 'No');
        Observer.Expect('ge_missing', 'YesD4');
        Observer.Expect('le_missing', 'YesD3');
        Observer.Expect('gt_beyond', 'No');
        Observer.Expect('lt_before', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Steps()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Seq: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(1);
        if RecRef.FindFirst() then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('forward', Seq);
        Observer.Observe('next_at_end', Format(RecRef.Next()));
        Observer.Observe('current_after_end', Format(Fld.Value));
        RecRef.FindLast();
        Seq := '';
        repeat
            Seq += Format(Fld.Value) + ';';
        until RecRef.Next(-1) = 0;
        Observer.Observe('backward', Seq);
        RecRef.FindFirst();
        Observer.Observe('next_2', Format(RecRef.Next(2)) + Format(Fld.Value));
        Observer.Observe('next_10', Format(RecRef.Next(10)) + Format(Fld.Value));
        RecRef.FindFirst();
        Observer.Observe('next_0', Format(RecRef.Next(0)) + Format(Fld.Value));
        Observer.Observe('next_minus_at_first', Format(RecRef.Next(-1)) + Format(Fld.Value));
        Observer.Expect('forward', 'D1;D2;D3;D4;D5;');
        Observer.Expect('next_at_end', '0');
        Observer.Expect('current_after_end', 'D5');
        Observer.Expect('backward', 'D5;D4;D3;D2;D1;');
        Observer.Expect('next_2', '2D3');
        Observer.Expect('next_10', '2D5');
        Observer.Expect('next_0', '0D1');
        Observer.Expect('next_minus_at_first', '0D1');
        Observer.Verify();
    end;

    [Test]
    procedure Find_EmptyTable_And_Filters()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(3);
        Fld.SetRange(20, 40);
        Observer.Observe('count_filtered', Format(RecRef.Count()));
        Observer.Observe('first', Format(RecRef.FindFirst()));
        Observer.Observe('last', Format(RecRef.FindLast()));
        Observer.Observe('findset', Format(RecRef.FindSet()));
        Fld.SetRange(9999);
        Observer.Observe('first_none', Format(RecRef.FindFirst()));
        Observer.Observe('last_none', Format(RecRef.FindLast()));
        Observer.Observe('findset_none', Format(RecRef.FindSet()));
        Observer.Observe('isempty_none', Format(RecRef.IsEmpty()));
        Observer.Observe('count_none', Format(RecRef.Count()));
        Observer.Expect('count_filtered', '3');
        Observer.Expect('first', 'Yes');
        Observer.Expect('last', 'Yes');
        Observer.Expect('findset', 'Yes');
        Observer.Expect('first_none', 'No');
        Observer.Expect('last_none', 'No');
        Observer.Expect('findset_none', 'No');
        Observer.Expect('isempty_none', 'Yes');
        Observer.Expect('count_none', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FindSet_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Seq: Text;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Fld := RecRef.Field(1);
        if RecRef.FindSet() then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('findset', Seq);
        Seq := '';
        if RecRef.FindSet(false) then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('findset_false', Seq);
        Seq := '';
        if RecRef.FindSet(true) then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('findset_true', Seq);
        Seq := '';
        if RecRef.FindSet(false, false) then
            repeat
                Seq += Format(Fld.Value) + ';';
            until RecRef.Next() = 0;
        Observer.Observe('findset_ff', Seq);
        Observer.Expect('findset', 'D1;D2;D3;D4;D5;');
        Observer.Expect('findset_false', 'D1;D2;D3;D4;D5;');
        Observer.Expect('findset_true', 'D1;D2;D3;D4;D5;');
        Observer.Expect('findset_ff', 'D1;D2;D3;D4;D5;');
        Observer.Verify();
    end;

    // Corpus issue 668 item 54 (writer br): what a RecordRef answers after Open(0), which raises no error.
    [TryFunction]
    local procedure BrTryOpenZeroMember(Which: Integer; var Result: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(0);
        case Which of
            1:
                Result := Format(RecRef.Number());
            2:
                Result := RecRef.Name();
            3:
                Result := Format(RecRef.FieldCount());
            4:
                Result := Format(RecRef.KeyCount());
            5:
                Result := Format(RecRef.IsEmpty());
            6:
                Result := Format(RecRef.IsTemporary());
            7:
                Result := Format(RecRef.Count());
        end;
    end;

    local procedure BrOpenZeroMember(Which: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if BrTryOpenZeroMember(Which, Result) then
            exit('ok:' + Result);
        exit('error:' + ScrubCaller(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Open_Zero_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('number', BrOpenZeroMember(1));
        Observer.Observe('name', BrOpenZeroMember(2));
        Observer.Observe('fieldcount', BrOpenZeroMember(3));
        Observer.Observe('keycount', BrOpenZeroMember(4));
        Observer.Observe('isempty', BrOpenZeroMember(5));
        Observer.Observe('istemporary', BrOpenZeroMember(6));
        Observer.Observe('count', BrOpenZeroMember(7));
        Observer.Expect('number', 'ok:0');
        Observer.Expect('name', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('fieldcount', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('keycount', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('isempty', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('istemporary', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('count', 'error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;
}
