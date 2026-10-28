// Probe (observe only): platform tables without a provider (read only), a temporary record of a CRM table, a field declared ObsoleteState = Removed in a RecordRef,
// a TableFilter field, the hidden SystemId field and key in a RecordRef, SetPermissionFilter, partial records (AddLoadFields / SetBaseLoadFields without SetLoadFields).
// Settles docs/probes-needed.md rows 290, 391, 517 (partly), 619, 673 (partly), 808, 809 (batch 4). Object ids 68052 - 68059.
// Compile finding for row 517: Document Service, Tenant Profile Page Metadata, Web Service, MCP Configuration, Performance Profile Scheduler and Document Service Scenario
// have scope OnPrem (AL0296 in a Cloud app): they cannot be probed from this app.

table 68052 "W4 CRM Temp"
{
    TableType = CRM;
    ExternalName = 'w4crm';
    fields
    {
        field(1; Id; Guid) { ExternalName = 'w4crmid'; ExternalType = 'Uniqueidentifier'; ExternalAccess = Insert; }
        field(2; Name; Text[50]) { ExternalName = 'name'; ExternalType = 'String'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68053 "W4 Removed Field"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Old; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe of a removed field.'; ObsoleteTag = '1.0'; }
        field(3; Cur; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68054 "W4 TF Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Flt; TableFilter) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 68055 "W4 Partial Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Txt; Text[20]) { }
        field(4; Dec; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KC; Cd) { }
    }
}

table 89500 "SI TF Target"
{
    // Writer SI (al-runner issue 5998): the table a TableFilter text names in the Evaluate probes below. Caption, field captions and
    // option captions differ from the names, so the probes show which of them Evaluate accepts and which Format writes.
    Caption = 'SI Target Cap';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { Caption = 'Code Cap'; }
        field(2; Kind; Option) { Caption = 'Kind Cap'; OptionMembers = DIAM,LGDIAM; OptionCaption = 'Diam Cap,LgDiam Cap'; }
        field(3; Qty; Integer) { Caption = 'Qty Cap'; }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 89610 "SR TF Pair"
{
    // Writer SR (al-runner issue 6006): a table with two Code fields (like Bin's "Location Code" and Code), an Integer, an Option
    // and a Text field, for the multi-field and space-in-value TableFilter probes below. Captions differ from the names.
    Caption = 'SR Pair Cap';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Location Code"; Code[10]) { Caption = 'SR Loc Cap'; }
        field(2; Code; Code[20]) { Caption = 'SR Code Cap'; }
        field(3; Qty; Integer) { Caption = 'SR Qty Cap'; }
        field(4; Kind; Option) { Caption = 'SR Kind Cap'; OptionMembers = MAIN,SIDE; OptionCaption = 'Main Cap,Side Cap'; }
        field(5; Descr; Text[30]) { Caption = 'SR Descr Cap'; }
    }
    keys { key(PK; "Location Code", Code) { Clustered = true; } }
}

codeunit 68056 "W4 Platform Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:517: read only; tables with no provider, count of the rows a test tenant holds ----
    [TryFunction]
    local procedure TryCountTable(TableNo: Integer; var Result: Text)
    var
        RR: RecordRef;
    begin
        RR.Open(TableNo);
        Result := Format(RR.Count());
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:[' + Value + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure PlatformTablesWithoutProvider_ReadCounts()
    var
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tenant_report_layout_selection_count', Outcome(TryCountTable(Database::"Tenant Report Layout Selection", Result), Result));
        ClearLastError();
        Observer.Observe('media_resources_count', Outcome(TryCountTable(Database::"Media Resources", Result), Result));
        ClearLastError();
        Observer.Observe('signup_context_count', Outcome(TryCountTable(Database::"Signup Context", Result), Result));
        ClearLastError();
        Observer.Observe('tenant_web_service_count', Outcome(TryCountTable(Database::"Tenant Web Service", Result), Result));
        ClearLastError();
        Observer.Observe('tenant_web_service_odata_count', Outcome(TryCountTable(Database::"Tenant Web Service OData", Result), Result));
        ClearLastError();
        Observer.Expect('tenant_report_layout_selection_count', 'ok:[4]');
        Observer.Expect('media_resources_count', 'ok:[46]');
        Observer.Expect('signup_context_count', 'ok:[0]');
        Observer.Expect('tenant_web_service_count', 'ok:[64]');
        Observer.Expect('tenant_web_service_odata_count', 'ok:[29]');
        Observer.Verify();
    end;

    // ---- md:808: a temporary record of a CRM table, no connection registered ----
    [Test]
    procedure CrmTable_TemporaryRecord()
    var
        Crm: Record "W4 CRM Temp" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Crm.Init();
        Crm.Id := CreateGuid();
        Crm.Name := 'one';
        Crm.Insert();
        Observer.Observe('count_after_insert', Format(Crm.Count()));
        Crm.Reset();
        Observer.Observe('count_after_reset', Format(Crm.Count()));
        Observer.Observe('findfirst', Format(Crm.FindFirst()));
        Observer.Observe('name', Crm.Name);
        Crm.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Crm.Count()));
        Observer.Observe('isempty', Format(Crm.IsEmpty()));
        Observer.Expect('count_after_insert', '1');
        Observer.Expect('count_after_reset', '1');
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('name', 'one');
        Observer.Expect('count_after_deleteall', '0');
        Observer.Expect('isempty', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCrmCount(var Result: Text)
    var
        Crm: Record "W4 CRM Temp";
    begin
        Result := Format(Crm.Count());
    end;

    [Test]
    procedure CrmTable_NonTemporaryRecord_WithoutConnection()
    var
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('count', Outcome(TryCrmCount(Result), Result));
        ClearLastError();
        Observer.Expect('count', 'error:Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.|Argument');
        Observer.Verify();
    end;

    // ---- md:809: a field declared ObsoleteState = Removed, seen through a RecordRef ----
    [TryFunction]
    local procedure TryFieldName(var RR: RecordRef; FieldNo: Integer; var Result: Text)
    begin
        Result := RR.Field(FieldNo).Name();
    end;

    [Test]
    procedure RemovedField_InRecordRef()
    var
        RR: RecordRef;
        Result: Text;
        Names: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Removed Field");
        Observer.Observe('field_count', Format(RR.FieldCount()));
        Observer.Observe('field_exist_1', Format(RR.FieldExist(1)));
        Observer.Observe('field_exist_2', Format(RR.FieldExist(2)));
        Observer.Observe('field_exist_3', Format(RR.FieldExist(3)));
        for i := 1 to RR.FieldCount() do
            Names += Format(RR.FieldIndex(i).Number()) + ':' + RR.FieldIndex(i).Name() + ',';
        Observer.Observe('field_index_loop', Names);
        Observer.Observe('field_2_name', Outcome(TryFieldName(RR, 2, Result), Result));
        ClearLastError();
        Observer.Observe('field_3_name', Outcome(TryFieldName(RR, 3, Result), Result));
        ClearLastError();
        Observer.Expect('field_count', '2');
        Observer.Expect('field_exist_1', 'Yes');
        Observer.Expect('field_exist_2', 'No');
        Observer.Expect('field_exist_3', 'Yes');
        Observer.Expect('field_index_loop', '1:Id,3:Cur,');
        Observer.Expect('field_2_name', 'error:Field Old (2) of table W4 Removed Field (68053) is obsoleted, reason: Probe of a removed field.|MetadataObsolete');
        Observer.Expect('field_3_name', 'ok:[Cur]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedField_GeneralLedgerSetupField110()
    var
        RR: RecordRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"General Ledger Setup");
        Observer.Observe('field_exist_110', Format(RR.FieldExist(110)));
        Observer.Observe('field_110_name', Outcome(TryFieldName(RR, 110, Result), Result));
        ClearLastError();
        Observer.Expect('field_exist_110', 'No');
        Observer.Expect('field_110_name', 'error:Field Acc. Sched. for Balance Sheet (110) of table General Ledger Setup (98) is obsoleted, reason: Financial Reporting is replacing Account Schedules for financial statements|MetadataObsolete');
        Observer.Verify();
    end;

    // ---- md:391: a TableFilter field nobody set ----
    [TryFunction]
    local procedure TrySetTableFilter(var RR: RecordRef; Value: Text)
    begin
        RR.Field(2).Value := Value;
    end;

    [Test]
    procedure TableFilterField_Format()
    var
        Row: Record "W4 TF Row";
        Got: Record "W4 TF Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('unset_in_memory', '[' + Format(Row.Flt) + ']');
        Row.Id := 1;
        Row.Insert();
        Got.Get(1);
        Observer.Observe('unset_after_insert_and_get', '[' + Format(Got.Flt) + ']');
        RR.GetTable(Got);
        Observer.Observe('unset_via_fieldref_format', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('unset_via_fieldref_type', Format(RR.Field(2).Type()));
        Row.DeleteAll();
        Observer.Expect('unset_in_memory', '[]');
        Observer.Expect('unset_after_insert_and_get', '[]');
        Observer.Expect('unset_via_fieldref_format', '[]');
        Observer.Expect('unset_via_fieldref_type', 'TableFilter');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterField_SetFromText()
    var
        Row: Record "W4 TF Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 TF Row");
        Observer.Observe('set_where_const', Outcome(TrySetTableFilter(RR, 'WHERE(Id=CONST(1))'), ''));
        ClearLastError();
        Observer.Observe('after_where_const', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('set_plain_text', Outcome(TrySetTableFilter(RR, 'Id: 1'), ''));
        ClearLastError();
        Observer.Observe('after_plain_text', '[' + Format(RR.Field(2).Value()) + ']');
        Observer.Observe('set_empty', Outcome(TrySetTableFilter(RR, ''), ''));
        ClearLastError();
        Observer.Observe('after_empty', '[' + Format(RR.Field(2).Value()) + ']');
#if BC28PLUS
#if BC28PLUS
        Observer.Expect('set_where_const', 'error:The value "WHERE(Id=CONST(1))" can''t be evaluated into type TableFilter.|Evaluate:Argument');
#else
        Observer.Expect('set_where_const', 'error:The supplied value is not valid.|Argument');
#endif
#else
        Observer.Expect('set_where_const', 'error:The supplied value is not valid.|Argument');
#endif
        Observer.Expect('after_where_const', '[]');
#if BC28PLUS
        Observer.Expect('set_plain_text', 'error:The value "Id: 1" can''t be evaluated into type TableFilter.|Evaluate:Argument');
#else
        Observer.Expect('set_plain_text', 'error:The supplied value is not valid.|Argument');
#endif
        Observer.Expect('after_plain_text', '[]');
#if BC28PLUS
        Observer.Expect('set_empty', 'error:The value "" can''t be evaluated into type TableFilter.|Evaluate:Argument');
#else
        Observer.Expect('set_empty', 'error:The supplied value is not valid.|Argument');
#endif
        Observer.Expect('after_empty', '[]');
        Observer.Verify();
    end;

    // ---- md:619: the hidden SystemId field and key in a RecordRef ----
    [Test]
    procedure RecordRef_SystemIdFieldAndHiddenKey()
    var
        RR: RecordRef;
        KR: KeyRef;
        Names: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Sort Row");
        Observer.Observe('keycount', Format(RR.KeyCount()));
        Observer.Observe('systemid_exist', Format(RR.FieldExist(2000000000)));
        Observer.Observe('systemid_name', RR.Field(2000000000).Name());
        Observer.Observe('systemid_caption', RR.Field(2000000000).Caption());
        Observer.Observe('systemid_type', Format(RR.Field(2000000000).Type()));
        Observer.Observe('systemid_number', Format(RR.Field(2000000000).Number()));
        Observer.Observe('systemid_class', Format(RR.Field(2000000000).Class()));
        KR := RR.KeyIndex(RR.KeyCount());
        Observer.Observe('last_key_field_count', Format(KR.FieldCount()));
        for i := 1 to KR.FieldCount() do
            Names += KR.FieldIndex(i).Name() + ',';
        Observer.Observe('last_key_field_names', Names);
        RR.CurrentKeyIndex(RR.KeyCount());
        Observer.Observe('current_key_text_after_select_last', RR.CurrentKey());
        Observer.Expect('keycount', '4');
        Observer.Expect('systemid_exist', 'Yes');
        Observer.Expect('systemid_name', '$systemId');
        Observer.Expect('systemid_caption', 'System ID');
        Observer.Expect('systemid_type', 'GUID');
        Observer.Expect('systemid_number', '2000000000');
        Observer.Expect('systemid_class', 'Normal');
        Observer.Expect('last_key_field_count', '1');
        Observer.Expect('last_key_field_names', '$systemId,');
        Observer.Expect('current_key_text_after_select_last', 'System ID');
        Observer.Verify();
    end;

    // ---- md:673: SetPermissionFilter as a user who can read everything ----
    [Test]
    procedure SetPermissionFilter_RecordAndRecordRef()
    var
        R: Record "W4 Sort Row";
        RR: RecordRef;
        Before: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        R.Id := 2;
        R.Insert();
        Before := R.Count();
        R.SetPermissionFilter();
        Observer.Observe('record_filters', '[' + R.GetFilters() + ']');
        Observer.Observe('record_view', '[' + R.GetView() + ']');
        Observer.Observe('record_count_same', Format(R.Count() = Before));
        RR.Open(Database::"W4 Sort Row");
        RR.SetPermissionFilter();
        Observer.Observe('recref_filters', '[' + RR.GetFilters() + ']');
        Observer.Observe('recref_view', '[' + RR.GetView() + ']');
        Observer.Observe('recref_count_same', Format(RR.Count() = Before));
        R.Reset();
        R.DeleteAll();
        Observer.Expect('record_filters', '[]');
        Observer.Expect('record_view', '[VERSION(1) SORTING(Id)]');
        Observer.Expect('record_count_same', 'Yes');
        Observer.Expect('recref_filters', '[]');
        Observer.Expect('recref_view', '[VERSION(1) SORTING(Id)]');
        Observer.Expect('recref_count_same', 'Yes');
        Observer.Verify();
    end;

    // ---- md:290: partial records without a SetLoadFields ----
    [TryFunction]
    local procedure TryLoaded(var R: Record "W4 Partial Row"; FieldNo: Integer; var Result: Text)
    begin
        case FieldNo of
            1:
                Result := Format(R.AreFieldsLoaded(Id));
            2:
                Result := Format(R.AreFieldsLoaded(Cd));
            3:
                Result := Format(R.AreFieldsLoaded(Txt));
            4:
                Result := Format(R.AreFieldsLoaded(Dec));
        end;
    end;

    local procedure LoadedFlags(var R: Record "W4 Partial Row"): Text
    var
        Result: Text;
        Flags: Text;
        i: Integer;
    begin
        for i := 1 to 4 do begin
            if TryLoaded(R, i, Result) then
                Flags += Result + ','
            else begin
                Flags += 'error:' + GetLastErrorText() + ',';
                ClearLastError();
            end;
        end;
        exit(Flags);
    end;

    local procedure SeedPartial()
    var
        R: Record "W4 Partial Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Cd := 'C';
        R.Txt := 'T';
        R.Dec := 5;
        R.Insert();
    end;

    [Test]
    procedure PartialRecords_AddLoadFieldsWithoutSetLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.AddLoadFields(Txt);
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec_after_add_then_get', LoadedFlags(R));
        Observer.Observe('txt_value', R.Txt);
        Observer.Observe('dec_value', Format(R.Dec));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec_after_add_then_get', 'Yes,Yes,Yes,Yes,');
        Observer.Expect('txt_value', 'T');
        Observer.Expect('dec_value', '5');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_SetBaseLoadFieldsWithoutSetLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.SetBaseLoadFields();
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_SetBaseLoadFieldsOnAPartialRecord()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.SetLoadFields(Txt);
        R.SetBaseLoadFields();
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_RecordLoadFields()
    var
        R: Record "W4 Partial Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        R.LoadFields(Cd);
        R.Get(1);
        Observer.Observe('loaded_id_cd_txt_dec', LoadedFlags(R));
        R.DeleteAll();
        Observer.Expect('loaded_id_cd_txt_dec', 'Yes,Yes,Yes,Yes,');
        Observer.Verify();
    end;

    [Test]
    procedure PartialRecords_RecordRefLoadFields()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        SeedPartial();
        RR.Open(Database::"W4 Partial Row");
        RR.SetLoadFields(2);
        RR.AddLoadFields(4);
        RR.Get(RecordIdOfRow());
        Observer.Observe('recref_loaded_id', Format(RR.AreFieldsLoaded(1)));
        Observer.Observe('recref_loaded_cd', Format(RR.AreFieldsLoaded(2)));
        Observer.Observe('recref_loaded_txt', Format(RR.AreFieldsLoaded(3)));
        Observer.Observe('recref_loaded_dec', Format(RR.AreFieldsLoaded(4)));
        Observer.Expect('recref_loaded_id', 'Yes');
        Observer.Expect('recref_loaded_cd', 'Yes');
        Observer.Expect('recref_loaded_txt', 'Yes');
        Observer.Expect('recref_loaded_dec', 'Yes');
        Observer.Verify();
    end;

    local procedure RecordIdOfRow(): RecordId
    var
        R: Record "W4 Partial Row";
    begin
        R.Get(1);
        exit(R.RecordId());
    end;

    [TryFunction]
    local procedure TryAddUnknown(var RR: RecordRef)
    begin
        RR.AddLoadFields(9999);
    end;

    [TryFunction]
    local procedure TrySetUnknown(var RR: RecordRef)
    begin
        RR.SetLoadFields(9999);
    end;

    [Test]
    procedure PartialRecords_UnknownFieldNumber()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"W4 Partial Row");
        Observer.Observe('addloadfields_9999', Outcome(TryAddUnknown(RR), ''));
        ClearLastError();
        Observer.Observe('setloadfields_9999', Outcome(TrySetUnknown(RR), ''));
        ClearLastError();
        Observer.Expect('addloadfields_9999', 'error:The supplied field number ''9999'' cannot be found in the ''W4 Partial Row'' table.|FieldNotFound');
        Observer.Expect('setloadfields_9999', 'error:The supplied field number ''9999'' cannot be found in the ''W4 Partial Row'' table.|FieldNotFound');
        Observer.Verify();
    end;

    // ---- writer SI, al-runner issue 5998: Evaluate of a text into a TableFilter field ----
    [TryFunction]
    local procedure TryEvalTfReturn(var Row: Record "W4 TF Row"; Value: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(Row.Flt, Value);
    end;

    [TryFunction]
    local procedure TryEvalTfBare(var Row: Record "W4 TF Row"; Value: Text)
    begin
        Evaluate(Row.Flt, Value);
    end;

    // Evaluate as a function on a fresh row: 'throws:<text>|<code>' when it raises anyway, else '<return>|[<Format of the field>]|<last error>'.
    local procedure EvalTfForm(Value: Text): Text
    var
        Row: Record "W4 TF Row";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        if not TryEvalTfReturn(Row, Value, Ok) then
            Result := 'throws:' + GetLastErrorText() + '|' + GetLastErrorCode()
        else
            Result := Format(Ok) + '|[' + Format(Row.Flt) + ']|' + ErrorHead(GetLastErrorText());
        ClearLastError();
        exit(Result);
    end;

    // Evaluate as a statement on a fresh row: 'ok:[<Format of the field>]' or 'error:<text>|<code>'.
    local procedure EvalTfBare(Value: Text): Text
    var
        Row: Record "W4 TF Row";
        Result: Text;
    begin
        ClearLastError();
        if TryEvalTfBare(Row, Value) then
            Result := 'ok:[' + Format(Row.Flt) + ']'
        else
            Result := 'error:' + ErrorHead(GetLastErrorText()) + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // The error text up to its first backslash. The texts of an unknown table name go on with "The metadata object Table -1 was not
    // found. The application might be incompatible ..." on the Linux BC container (27.5, 28.5, 29.0); that tail is not pinned here
    // (a Linux suspect until the Windows check), only the sentence before it.
    local procedure ErrorHead(Value: Text): Text
    begin
        if StrPos(Value, '\') > 0 then
            Value := CopyStr(Value, 1, StrPos(Value, '\') - 1);
        exit(DelChr(Value, '>', ' '));
    end;

    [Test]
    procedure TableFilterEvaluate_AcceptedForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name_form', EvalTfForm('SI TF Target: Kind=LGDIAM'));
        Observer.Observe('caption_form', EvalTfForm('SI Target Cap: Kind Cap=LGDIAM'));
        Observer.Observe('name_table_caption_field', EvalTfForm('SI TF Target: Kind Cap=LGDIAM'));
        Observer.Observe('option_caption_value', EvalTfForm('SI TF Target: Kind=LgDiam Cap'));
        Observer.Observe('option_number_value', EvalTfForm('SI TF Target: Kind=1'));
        Observer.Observe('filter_wrapper', EvalTfForm('SI TF Target: Kind=FILTER(LGDIAM)'));
        Observer.Observe('const_wrapper', EvalTfForm('SI TF Target: Kind=CONST(LGDIAM)'));
        Observer.Observe('two_fields', EvalTfForm('SI TF Target: Code=A..B,Kind=DIAM'));
        Observer.Observe('two_fields_space', EvalTfForm('SI TF Target: Code=A..B, Kind=DIAM'));
        Observer.Observe('table_number', EvalTfForm('89500: Kind=LGDIAM'));
        Observer.Observe('quoted_table', EvalTfForm('"SI TF Target": Kind=LGDIAM'));
        Observer.Observe('lower_case', EvalTfForm('si tf target: kind=lgdiam'));
        Observer.Observe('no_space_after_colon', EvalTfForm('SI TF Target:Kind=LGDIAM'));
        Observer.Observe('integer_expression', EvalTfForm('SI TF Target: Qty=1..5|7'));
        Observer.Observe('integer_not_zero', EvalTfForm('SI TF Target: Qty=<>0'));
        Observer.Observe('code_wildcard', EvalTfForm('SI TF Target: Code=@a*'));
        Observer.Observe('base_app_table', EvalTfForm('Customer: No.=10000'));
        Observer.Observe('format_number_9', Format(EvalTf9('SI TF Target: Kind=LGDIAM')));
        Observer.Expect('name_form', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('caption_form', 'No|[]|The value "SI Target Cap: Kind Cap=LGDIAM" can''t be evaluated into type TableFilter.');
        Observer.Expect('name_table_caption_field', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('option_caption_value', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('option_number_value', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('filter_wrapper', 'No|[]|The value "SI TF Target: Kind=FILTER(LGDIAM)" can''t be evaluated into type TableFilter. An error occurred while interpreting the filter: Did not expect ''(''.');
        Observer.Expect('const_wrapper', 'No|[]|The value "SI TF Target: Kind=CONST(LGDIAM)" can''t be evaluated into type TableFilter. An error occurred while interpreting the filter: Did not expect ''(''.');
        Observer.Expect('two_fields', 'Yes|[SI TF Target: Code Cap=A..B,Kind Cap=Diam Cap]|');
        Observer.Expect('two_fields_space', 'Yes|[SI TF Target: Code Cap=A..B,Kind Cap=Diam Cap]|');
        Observer.Expect('table_number', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('quoted_table', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('lower_case', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('no_space_after_colon', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]|');
        Observer.Expect('integer_expression', 'Yes|[SI TF Target: Qty Cap=1..5|7]|');
        Observer.Expect('integer_not_zero', 'Yes|[SI TF Target: Qty Cap=<>0]|');
        Observer.Expect('code_wildcard', 'Yes|[SI TF Target: Code Cap=@A*]|');
        Observer.Expect('base_app_table', 'Yes|[Customer: No.=10000]|');
        Observer.Expect('format_number_9', 'Yes|[SI TF Target: Kind Cap=LgDiam Cap]');
        Observer.Verify();
    end;

    local procedure EvalTf9(Value: Text): Text
    var
        Row: Record "W4 TF Row";
        Ok: Boolean;
    begin
        Ok := Evaluate(Row.Flt, Value, 9);
        exit(Format(Ok) + '|[' + Format(Row.Flt) + ']');
    end;

    [Test]
    procedure TableFilterEvaluate_RejectedForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ret_bad_option', EvalTfForm('SI TF Target: Kind=FOO'));
        Observer.Observe('ret_unknown_field', EvalTfForm('SI TF Target: Nope=1'));
        Observer.Observe('ret_unknown_table', EvalTfForm('No Such Table: Kind=1'));
        Observer.Observe('ret_table_only', EvalTfForm('SI TF Target'));
        Observer.Observe('ret_table_colon_only', EvalTfForm('SI TF Target: '));
        Observer.Observe('ret_empty', EvalTfForm(''));
        Observer.Observe('ret_garbage', EvalTfForm('xyz'));
        Observer.Observe('ret_no_table', EvalTfForm('Kind=LGDIAM'));
        Observer.Observe('ret_where_form', EvalTfForm('WHERE(Kind=FILTER(LGDIAM))'));
        Observer.Observe('ret_bad_integer', EvalTfForm('SI TF Target: Qty=abc'));
        Observer.Expect('ret_bad_option', 'No|[]|The value "SI TF Target: Kind=FOO" can''t be evaluated into type TableFilter. ''FOO'' is not an option. The existing options are: Diam Cap,LgDiam Cap');
        Observer.Expect('ret_unknown_field', 'No|[]|The value "SI TF Target: Nope=1" can''t be evaluated into type TableFilter. The supplied field number ''Nope'' cannot be found in the ''SI Target Cap'' table.');
        Observer.Expect('ret_unknown_table', 'No|[]|The value "No Such Table: Kind=1" can''t be evaluated into type TableFilter.');
        Observer.Expect('ret_table_only', 'No|[]|The value "SI TF Target" can''t be evaluated into type TableFilter.');
        Observer.Expect('ret_table_colon_only', 'Yes|[SI TF Target: ]|');
        Observer.Expect('ret_empty', 'Yes|[]|');
        Observer.Expect('ret_garbage', 'No|[]|The value "xyz" can''t be evaluated into type TableFilter.');
        Observer.Expect('ret_no_table', 'No|[]|The value "Kind=LGDIAM" can''t be evaluated into type TableFilter.');
        Observer.Expect('ret_where_form', 'No|[]|The value "WHERE(Kind=FILTER(LGDIAM))" can''t be evaluated into type TableFilter.');
        Observer.Expect('ret_bad_integer', 'No|[]|The value "SI TF Target: Qty=abc" can''t be evaluated into type TableFilter. The value "abc" can''t be evaluated into type Integer.');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterEvaluate_ErrorsAsStatement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('bare_bad_option', EvalTfBare('SI TF Target: Kind=FOO'));
        Observer.Observe('bare_unknown_field', EvalTfBare('SI TF Target: Nope=1'));
        Observer.Observe('bare_unknown_table', EvalTfBare('No Such Table: Kind=1'));
        Observer.Observe('bare_table_only', EvalTfBare('SI TF Target'));
        Observer.Observe('bare_filter_wrapper', EvalTfBare('SI TF Target: Kind=FILTER(LGDIAM)'));
        Observer.Observe('bare_bad_integer', EvalTfBare('SI TF Target: Qty=abc'));
        Observer.Observe('bare_empty', EvalTfBare(''));
        Observer.Observe('bare_garbage', EvalTfBare('xyz'));
        Observer.Observe('bare_no_table', EvalTfBare('Kind=LGDIAM'));
        Observer.Observe('bare_valid', EvalTfBare('SI TF Target: Kind=LGDIAM'));
        Observer.Expect('bare_bad_option', 'error:The value "SI TF Target: Kind=FOO" can''t be evaluated into type TableFilter. ''FOO'' is not an option. The existing options are: Diam Cap,LgDiam Cap|Evaluate:InvalidFilterExpression');
        Observer.Expect('bare_unknown_field', 'error:The value "SI TF Target: Nope=1" can''t be evaluated into type TableFilter. The supplied field number ''Nope'' cannot be found in the ''SI Target Cap'' table.|Evaluate:FieldNotFound');
        Observer.Expect('bare_unknown_table', 'error:The value "No Such Table: Kind=1" can''t be evaluated into type TableFilter.|Evaluate:MetadataNotFound');
        Observer.Expect('bare_table_only', 'error:The value "SI TF Target" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('bare_filter_wrapper', 'error:The value "SI TF Target: Kind=FILTER(LGDIAM)" can''t be evaluated into type TableFilter. An error occurred while interpreting the filter: Did not expect ''(''.|Evaluate:InvalidFilterExpression');
        Observer.Expect('bare_bad_integer', 'error:The value "SI TF Target: Qty=abc" can''t be evaluated into type TableFilter. The value "abc" can''t be evaluated into type Integer.|Evaluate:InvalidFilterExpression');
        Observer.Expect('bare_empty', 'ok:[]');
        Observer.Expect('bare_garbage', 'error:The value "xyz" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('bare_no_table', 'error:The value "Kind=LGDIAM" can''t be evaluated into type TableFilter.|Evaluate');
        Observer.Expect('bare_valid', 'ok:[SI TF Target: Kind Cap=LgDiam Cap]');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilterEvaluate_StoredValue()
    var
        Row: Record "W4 TF Row";
        Got: Record "W4 TF Row";
        Copy: Record "W4 TF Row";
        Target: Record "SI TF Target";
        RR: RecordRef;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Ok := Evaluate(Row.Flt, 'SI TF Target: Code=A..B,Kind=LGDIAM');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('format_in_memory', '[' + Format(Row.Flt) + ']');
        Observer.Observe('format_len', Format(StrLen(Format(Row.Flt))));
        Row.Insert();
        Got.Get(1);
        Observer.Observe('format_after_get', '[' + Format(Got.Flt) + ']');
        RR.GetTable(Got);
        Observer.Observe('fieldref_value', '[' + Format(RR.Field(2).Value()) + ']');
        // Evaluate the text Format wrote back into another row.
        Observer.Observe('roundtrip_evaluate', Format(Evaluate(Copy.Flt, Format(Got.Flt))) + '|[' + Format(Copy.Flt) + ']');
        // Assign the text Format wrote through a FieldRef (the W4 probes above show other forms are refused there).
        Observer.Observe('roundtrip_fieldref', Outcome(TrySetTableFilter(RR, Format(Got.Flt)), Format(RR.Field(2).Value())));
        ClearLastError();
        // The text GetFilters gives for the same filters on the referenced table, for comparison.
        Target.SetFilter(Code, 'A..B');
        Target.SetRange(Kind, Target.Kind::LGDIAM);
        Observer.Observe('target_getfilters', Target.GetFilters());
        // A failed Evaluate as a function on a field that holds a value.
        Ok := Evaluate(Got.Flt, 'xyz');
        Observer.Observe('failed_eval_keeps', Format(Ok) + '|[' + Format(Got.Flt) + ']');
        // A second successful Evaluate replaces the value.
        Ok := Evaluate(Got.Flt, 'SI TF Target: Qty=5');
        Observer.Observe('second_eval', Format(Ok) + '|[' + Format(Got.Flt) + ']');
        Row.DeleteAll();
        Observer.Expect('ok', 'Yes');
        Observer.Expect('format_in_memory', '[SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap]');
        Observer.Expect('format_len', '47');
        Observer.Expect('format_after_get', '[SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap]');
        Observer.Expect('fieldref_value', '[SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap]');
        Observer.Expect('roundtrip_evaluate', 'Yes|[SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap]');
#if BC28PLUS
        Observer.Expect('roundtrip_fieldref', 'error:The value "SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap" can''t be evaluated into type TableFilter.|Evaluate:Argument');
#else
        Observer.Expect('roundtrip_fieldref', 'error:The supplied value is not valid.|Argument');
#endif
        Observer.Expect('target_getfilters', 'Code Cap: A..B, Kind Cap: LgDiam Cap');
        Observer.Expect('failed_eval_keeps', 'No|[SI TF Target: Code Cap=A..B,Kind Cap=LgDiam Cap]');
        Observer.Expect('second_eval', 'Yes|[SI TF Target: Qty Cap=5]');
        Observer.Verify();
    end;

    // ---- writer SR, al-runner issue 6006: TableFilter texts with several fields and values that hold spaces ----
    // Evaluate as a function on a fresh row: '<return>|[<Format>]|[<Format(..., 0, 9)>]|<last error text>|<last error code>',
    // or 'throws:<text>|<code>' when it raises anyway.
    local procedure SrEvalTf(Value: Text): Text
    var
        Row: Record "W4 TF Row";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        if not TryEvalTfReturn(Row, Value, Ok) then
            Result := 'throws:' + GetLastErrorText() + '|' + GetLastErrorCode()
        else
            Result := Format(Ok) + '|[' + Format(Row.Flt) + ']|[' + Format(Row.Flt, 0, 9) + ']|' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure TableFilterEvaluate_SrBinForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The forms of al-runner issue 6006 on the base app's Bin table (read only: only its metadata is used).
        Observer.Observe('bin_two_fields', SrEvalTf('Bin: Location Code=MAIN,Code=BIN01'));
        Observer.Observe('bin_space_value', SrEvalTf('Bin: Code=BIN WITH SPACE'));
        Observer.Observe('bin_two_fields_space', SrEvalTf('Bin: Location Code=MAIN,Code=BIN WITH SPACE'));
        Observer.Observe('bin_bare_two_fields', EvalTfBare('Bin: Location Code=MAIN,Code=BIN01'));
        Observer.Observe('bin_bare_space_value', EvalTfBare('Bin: Code=BIN WITH SPACE'));
        Observer.Observe('bin_bare_two_fields_space', EvalTfBare('Bin: Location Code=MAIN,Code=BIN WITH SPACE'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_SrMultiFieldForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two_codes', SrEvalTf('SR TF Pair: Location Code=MAIN,Code=BIN01'));
        Observer.Observe('space_value', SrEvalTf('SR TF Pair: Code=BIN WITH SPACE'));
        Observer.Observe('two_codes_space', SrEvalTf('SR TF Pair: Location Code=MAIN,Code=BIN WITH SPACE'));
        Observer.Observe('space_value_first', SrEvalTf('SR TF Pair: Code=BIN WITH SPACE,Location Code=MAIN'));
        Observer.Observe('space_after_comma', SrEvalTf('SR TF Pair: Location Code=MAIN, Code=BIN WITH SPACE'));
        Observer.Observe('space_before_comma', SrEvalTf('SR TF Pair: Code=BIN01 ,Location Code=MAIN'));
        Observer.Observe('trailing_space_value', SrEvalTf('SR TF Pair: Code=BIN01 '));
        Observer.Observe('leading_space_value', SrEvalTf('SR TF Pair: Code= BIN01'));
        Observer.Observe('lower_case_space_value', SrEvalTf('SR TF Pair: Code=bin with space'));
        Observer.Observe('text_space_value', SrEvalTf('SR TF Pair: Descr=Some text here'));
        Observer.Observe('caption_with_space', SrEvalTf('SR TF Pair: SR Loc Cap=MAIN'));
        Observer.Observe('quoted_field_name', SrEvalTf('SR TF Pair: "Location Code"=MAIN'));
        Observer.Observe('empty_value', SrEvalTf('SR TF Pair: Code='));
        Observer.Observe('value_too_long', SrEvalTf('SR TF Pair: Location Code=ABCDEFGHIJKL'));
        Observer.Observe('int_second', SrEvalTf('SR TF Pair: Code=BIN01,Qty=5'));
        Observer.Observe('int_second_range', SrEvalTf('SR TF Pair: Code=BIN01,Qty=1..5'));
        Observer.Observe('option_second', SrEvalTf('SR TF Pair: Code=BIN01,Kind=SIDE'));
        Observer.Observe('option_second_number', SrEvalTf('SR TF Pair: Code=BIN01,Kind=1'));
        Observer.Observe('three_fields', SrEvalTf('SR TF Pair: Location Code=MAIN,Code=BIN WITH SPACE,Qty=5'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_SrExpressionForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('range_second', SrEvalTf('SR TF Pair: Location Code=MAIN,Code=A..B'));
        Observer.Observe('or_value', SrEvalTf('SR TF Pair: Code=A|B'));
        Observer.Observe('or_second', SrEvalTf('SR TF Pair: Location Code=MAIN,Code=A|B'));
        Observer.Observe('or_space_values', SrEvalTf('SR TF Pair: Code=BIN ONE|BIN TWO'));
        Observer.Observe('range_space_values', SrEvalTf('SR TF Pair: Code=BIN A..BIN B'));
        Observer.Observe('not_equal_value', SrEvalTf('SR TF Pair: Code=<>BIN01'));
        Observer.Observe('single_quoted_space', SrEvalTf('SR TF Pair: Code=''BIN WITH SPACE'''));
        Observer.Observe('single_quoted_comma', SrEvalTf('SR TF Pair: Code=''A,B'''));
        Observer.Observe('single_quoted_pipe', SrEvalTf('SR TF Pair: Code=''A|B'''));
        Observer.Observe('double_quoted_value', SrEvalTf('SR TF Pair: Code="BIN01"'));
        Observer.Observe('quoted_then_second', SrEvalTf('SR TF Pair: Code=''A,B'',Location Code=MAIN'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_SrRejectedForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('unknown_second', SrEvalTf('SR TF Pair: Code=BIN01,Nope=1'));
        Observer.Observe('field_twice', SrEvalTf('SR TF Pair: Code=A,Code=B'));
        Observer.Observe('field_twice_caption', SrEvalTf('SR TF Pair: Code=A,SR Code Cap=B'));
        Observer.Observe('bad_int_second', SrEvalTf('SR TF Pair: Code=BIN01,Qty=abc'));
        Observer.Observe('bad_option_second', SrEvalTf('SR TF Pair: Code=BIN01,Kind=NOPE'));
        Observer.Observe('missing_equals_second', SrEvalTf('SR TF Pair: Code=BIN01,Qty'));
        Observer.Observe('trailing_comma', SrEvalTf('SR TF Pair: Code=BIN01,'));
        Observer.Observe('bare_unknown_second', EvalTfBare('SR TF Pair: Code=BIN01,Nope=1'));
        Observer.Observe('bare_field_twice', EvalTfBare('SR TF Pair: Code=A,Code=B'));
        Observer.Observe('bare_bad_int_second', EvalTfBare('SR TF Pair: Code=BIN01,Qty=abc'));
        Observer.Observe('bare_bad_option_second', EvalTfBare('SR TF Pair: Code=BIN01,Kind=NOPE'));
        Observer.Observe('bare_trailing_comma', EvalTfBare('SR TF Pair: Code=BIN01,'));
        Observer.Finish();
    end;

    [Test]
    procedure TableFilterEvaluate_SrStoredSpaceValue()
    var
        Row: Record "W4 TF Row";
        Got: Record "W4 TF Row";
        Copy: Record "W4 TF Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Ok := Evaluate(Row.Flt, 'SR TF Pair: Location Code=MAIN,Code=BIN WITH SPACE');
        Observer.Observe('ok', Format(Ok));
        Row.Insert();
        Got.Get(1);
        Observer.Observe('format_after_get', '[' + Format(Got.Flt) + ']');
        Observer.Observe('format_9_after_get', '[' + Format(Got.Flt, 0, 9) + ']');
        Observer.Observe('roundtrip_evaluate', Format(Evaluate(Copy.Flt, Format(Got.Flt))) + '|[' + Format(Copy.Flt) + ']');
        Clear(Copy);
        Observer.Observe('roundtrip_evaluate_9', Format(Evaluate(Copy.Flt, Format(Got.Flt, 0, 9), 9)) + '|[' + Format(Copy.Flt) + ']');
        Row.DeleteAll();
        Observer.Finish();
    end;
}
