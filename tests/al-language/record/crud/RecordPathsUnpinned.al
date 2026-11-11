// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/library
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), System Application "Base64 Convert" and "Temp Blob"; own tables 76620 to 76622, 76625 and 76626,
//   codeunit 76623 (a manual subscriber), test codeunit 76624
// local object: the OnDelete trigger that logs the order of the deletes, the Media and MediaSet fields whose Tenant Media rows are counted,
//   and a subscriber bound only inside one test are what is under test.
// Probe (al-runner issues 7632 and 7626): record paths that no corpus test pinned. Area:
//   DeleteAll(true) on a record sorted descending (by Ascending(false), by a descending secondary key) with a stored filter: the order of the
//   OnDelete calls; DeleteAll() and DeleteAll(true) on rows that hold Media and MediaSet values: the Tenant Media rows of those values after it,
//   next to a row-by-row Delete; Count of the Company table; the SystemId a record holds after a failed Insert whose result is used (a
//   temporary record and a normal one with Insert(false, true)); AreFieldsLoaded after a Modify of a record nothing was fetched into, after
//   SetLoadFields without a fetch then Modify, and after Get, Clear and the assignment of one field; SystemRowVersion of a temporary record
//   after Insert and Modify; FilterPageBuilder.GetView with a Boolean filter, localized and not;
//   whether "Filter Helper Triggers".MakeDateFilter is raised for a Date filter text with a piece it cannot read when the filter has
//   placeholders, and in a session whose language is not English; a copy of a RecordRef that is not open (RR2 := RR, V := RR) before
//   RR.Open; Date and DateTime values before 1753-01-02 other than the ones record/filters/P130DateFilters.al:255-293 pins; Blob.Length
//   and HasValue of a stored Blob before and after CalcFields; a [FilterPageHandler] that points its RecordRef at another record or table.
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 76620 "REC RPU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Other; Text[30]) { }
        field(4; Flag; Boolean) { }
        field(5; "Posting Date"; Date) { }
        field(6; Grp; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByGrp; Grp) { }
    }

    trigger OnDelete()
    var
        Log: Record "REC RPU Log";
    begin
        Log.Init();
        Log.Text := 'del ' + "No.";
        Log.Insert();
    end;
}

table 76621 "REC RPU Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Text; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 76622 "REC RPU Media"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnDelete()
    begin
    end;
}

table 76625 "REC RPU Dates"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 76626 "REC RPU Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; B; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 76623 "REC RPU Date Sub"
{
    EventSubscriberInstance = Manual;

    var
        Calls: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateFilter', '', false, false)]
    local procedure MakeDateFilter(var DateFilterText: Text)
    begin
        Calls += '[' + DateFilterText + ']';
        if DateFilterText = 'abc' then
            DateFilterText := '2020-12-31';
    end;

    procedure Take() Result: Text
    begin
        Result := Calls;
        Calls := '';
    end;
}

codeunit 76624 "REC RPU Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRows()
    var
        Row: Record "REC RPU Row";
        Log: Record "REC RPU Log";
        i: Integer;
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        for i := 1 to 5 do begin
            Row.Init();
            Row."No." := 'R' + Format(i);
            Row.Name := 'n' + Format(i);
            Row.Grp := 10 - i;
            Row.Flag := (i mod 2) = 0;
            Row."Posting Date" := DMY2Date(i, 1, 2020);
            Row.Insert();
        end;
    end;

    local procedure TakeLog() Result: Text
    var
        Log: Record "REC RPU Log";
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Text + ';';
            until Log.Next() = 0;
        Log.DeleteAll();
    end;

    local procedure Left(): Text
    var
        Row: Record "REC RPU Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."No." + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    // DeleteAll(true) with a stored filter on a record sorted descending: the order of the OnDelete calls.
    [Test]
    procedure DeleteAllTrue_Descending_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC RPU Row";
    begin
        SeedRows();
        Row.SetFilter("No.", 'R2..R4');
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('pk_descending_filter', TakeLog());
        Observer.Observe('pk_descending_filter|left', Left());

        SeedRows();
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.SetFilter(Grp, '6..8');
        Row.DeleteAll(true);
        Observer.Observe('grp_descending_filter', TakeLog());

        SeedRows();
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.SetFilter(Grp, '6..8');
        Row.DeleteAll(true);
        Observer.Observe('grp_ascending_filter', TakeLog());

        SeedRows();
        Clear(Row);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('pk_descending_nofilter', TakeLog());

        SeedRows();
        Clear(Row);
        Row.SetFilter("No.", 'R2..R4');
        Row.Ascending(false);
        Row.FindFirst();
        Row.DeleteAll(true);
        Observer.Observe('pk_descending_filter_after_find', TakeLog());
        Observer.Finish();
    end;

    local procedure PngIn(var TempBlob: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        Out: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Out);
        TempBlob.CreateInStream(Ins);
    end;

    local procedure SeedMedia(var PicIds: List of [Guid]; var SetIds: List of [Guid])
    var
        Row: Record "REC RPU Media";
        TempBlob: Codeunit "Temp Blob";
        Ins: InStream;
        i: Integer;
    begin
        Row.DeleteAll();
        Clear(PicIds);
        Clear(SetIds);
        for i := 1 to 2 do begin
            Row.Init();
            Row.Id := i;
            PngIn(TempBlob, Ins);
            Row.Pic.ImportStream(Ins, 'pic');
            PngIn(TempBlob, Ins);
            Row.Pics.ImportStream(Ins, 'set');
            Row.Insert();
            PicIds.Add(Row.Pic.MediaId());
            SetIds.Add(Row.Pics.Item(1));
        end;
    end;

    local procedure TenantRows(Ids: List of [Guid]) Result: Integer
    var
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        foreach Id in Ids do
            if TenantMedia.Get(Id) then
                Result += 1;
    end;

    local procedure Orphans(Ids: List of [Guid]) Result: Integer
    var
        Found: List of [Guid];
        Id: Guid;
    begin
        Found := Media.FindOrphans();
        foreach Id in Ids do
            if Found.Contains(Id) then
                Result += 1;
    end;

    local procedure MediaCell(var Observer: Codeunit "Probe Observer"; Name: Text; How: Text)
    var
        Row: Record "REC RPU Media";
        PicIds: List of [Guid];
        SetIds: List of [Guid];
    begin
        SeedMedia(PicIds, SetIds);
        Observer.Observe(Name + '|before', Format(TenantRows(PicIds)) + '/' + Format(TenantRows(SetIds)));
        case How of
            'deleteall':
                Row.DeleteAll();
            'deleteall_true':
                Row.DeleteAll(true);
            'delete_each':
                if Row.FindSet() then
                    repeat
                        Row.Delete();
                    until Row.Next() = 0;
        end;
        Observer.Observe(Name + '|tenant media pic/set', Format(TenantRows(PicIds)) + '/' + Format(TenantRows(SetIds)));
        Observer.Observe(Name + '|orphans pic/set', Format(Orphans(PicIds)) + '/' + Format(Orphans(SetIds)));
    end;

    // The Tenant Media rows of Media and MediaSet values after DeleteAll(), DeleteAll(true) (the table has an OnDelete trigger) and a Delete
    // of each row.
    [Test]
    procedure DeleteAll_MediaRows_TenantMedia()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MediaCell(Observer, 'deleteall', 'deleteall');
        MediaCell(Observer, 'deleteall_true', 'deleteall_true');
        MediaCell(Observer, 'delete_each', 'delete_each');
        Observer.Finish();
    end;

    [Test]
    procedure Company_Count()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        Observer.Observe('count', Format(Company.Count()));
        Observer.Observe('current found', Format(Company.Get(CompanyName())));
        Observer.Finish();
    end;

    local procedure GuidKind(Value: Guid; Assigned: Guid; First: Guid): Text
    begin
        if IsNullGuid(Value) then
            exit('null');
        if Value = Assigned then
            exit('assigned');
        if Value = First then
            exit('first row');
        exit('other');
    end;

    // The SystemId a record holds after a failed Insert whose result is used.
    [Test]
    procedure FailedGuardedInsert_SystemIdAfter()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "REC RPU Row" temporary;
        TempSecond: Record "REC RPU Row" temporary;
        Row: Record "REC RPU Row";
        Second: Record "REC RPU Row";
        First: Guid;
        Assigned: Guid;
        Ok: Boolean;
    begin
        TempRow.Init();
        TempRow."No." := 'T1';
        TempRow.Insert();
        First := TempRow.SystemId;
        TempSecond.Copy(TempRow, true);
        TempSecond.Init();
        TempSecond."No." := 'T1';
        Assigned := CreateGuid();
        TempSecond.SystemId := Assigned;
        Ok := TempSecond.Insert();
        Observer.Observe('temp insert', Format(Ok) + ' ' + GuidKind(TempSecond.SystemId, Assigned, First));
        TempSecond.Init();
        TempSecond."No." := 'T1';
        Ok := TempSecond.Insert();
        Observer.Observe('temp insert no assignment', Format(Ok) + ' ' + GuidKind(TempSecond.SystemId, Assigned, First));
        Assigned := CreateGuid();
        TempSecond.Init();
        TempSecond."No." := 'T1';
        TempSecond.SystemId := Assigned;
        Ok := TempSecond.Insert(false, true);
        Observer.Observe('temp insert with systemid', Format(Ok) + ' ' + GuidKind(TempSecond.SystemId, Assigned, First));

        SeedRows();
        Row.Get('R1');
        First := Row.SystemId;
        Second.Init();
        Second."No." := 'R1';
        Assigned := CreateGuid();
        Second.SystemId := Assigned;
        Ok := Second.Insert(false, true);
        Observer.Observe('insert with systemid', Format(Ok) + ' ' + GuidKind(Second.SystemId, Assigned, First));
        Second.Init();
        Second."No." := 'R1';
        Assigned := CreateGuid();
        Second.SystemId := Assigned;
        Ok := Second.Insert();
        Observer.Observe('insert', Format(Ok) + ' ' + GuidKind(Second.SystemId, Assigned, First));
        Observer.Finish();
    end;

    local procedure Loaded(var Row: Record "REC RPU Row"): Text
    begin
        exit(Format(Row.AreFieldsLoaded("No.")) + '/' + Format(Row.AreFieldsLoaded(Name)) + '/' + Format(Row.AreFieldsLoaded(Other)) + '/' + Format(Row.AreFieldsLoaded(Grp)));
    end;

    // AreFieldsLoaded ("No." / Name / Other / Grp) in record states no corpus test pinned.
    [Test]
    procedure AreFieldsLoaded_UnfetchedAndCleared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC RPU Row";
        Ok: Boolean;
    begin
        SeedRows();
        Row.Init();
        Row."No." := 'R1';
        Observer.Observe('init', Loaded(Row));
        Ok := Row.Modify();
        Observer.Observe('init modify', Format(Ok) + ' ' + Loaded(Row));

        Clear(Row);
        Row.SetLoadFields(Name);
        Row."No." := 'R2';
        Row.Name := 'changed';
        Observer.Observe('setloadfields no fetch', Loaded(Row));
        Ok := Row.Modify();
        Observer.Observe('setloadfields no fetch modify', Format(Ok) + ' ' + Loaded(Row));

        Clear(Row);
        Row.Get('R3');
        Clear(Row);
        Row.Name := 'assigned';
        Observer.Observe('get clear assign', Loaded(Row));

        Clear(Row);
        Row.SetLoadFields(Name);
        Row.Get('R4');
        Clear(Row);
        Row.Other := 'assigned';
        Observer.Observe('partial get clear assign', Loaded(Row));

        Clear(Row);
        Row.Get('R5');
        Row := Row;
        Row.Init();
        Observer.Observe('get init', Loaded(Row));
        Observer.Finish();
    end;

    // SystemRowVersion of a temporary record after Insert and Modify.
    [Test]
    procedure Temporary_SystemRowVersion()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "REC RPU Row" temporary;
    begin
        TempRow.Init();
        TempRow."No." := 'T1';
        Observer.Observe('before insert', Format(TempRow.SystemRowVersion));
        TempRow.Insert();
        Observer.Observe('after insert', Format(TempRow.SystemRowVersion));
        TempRow.Name := 'x';
        TempRow.Modify();
        Observer.Observe('after modify', Format(TempRow.SystemRowVersion));
        TempRow.Get('T1');
        Observer.Observe('after get', Format(TempRow.SystemRowVersion));
        Observer.Finish();
    end;

    // FilterPageBuilder.GetView of a record with a Boolean filter, localized (true) and not (false).
    [Test]
    procedure FilterPageBuilder_GetView_BooleanFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC RPU Row";
        Builder: FilterPageBuilder;
    begin
        Row.SetRange(Flag, true);
        Builder.AddRecord('Rows', Row);
        Builder.AddField('Rows', Row.Flag);
        Observer.Observe('getview false', Builder.GetView('Rows', false));
        Observer.Observe('getview true', Builder.GetView('Rows', true));
        Clear(Builder);
        Row.SetFilter(Flag, '%1', false);
        Row.SetRange(Grp, 1, 3);
        Builder.AddRecord('Rows', Row);
        Observer.Observe('getview false two', Builder.GetView('Rows', false));
        Observer.Observe('getview true two', Builder.GetView('Rows', true));
        Observer.Finish();
    end;

    local procedure DateCell(var Observer: Codeunit "Probe Observer"; var Sub: Codeunit "REC RPU Date Sub"; Name: Text; Filter: Text; WithArg: Boolean)
    var
        Row: Record "REC RPU Row";
    begin
        ClearLastError();
        asserterror
        begin
            if WithArg then
                Row.SetFilter("Posting Date", Filter, DMY2Date(2, 1, 2020))
            else
                Row.SetFilter("Posting Date", Filter);
            Error('REC_RPU_FILTER %1', Row.GetFilter("Posting Date"));
        end;
        if GetLastErrorText().StartsWith('REC_RPU_FILTER ') then
            Observer.Observe(Name, 'ok ' + CopyStr(GetLastErrorText(), StrLen('REC_RPU_FILTER ') + 1))
        else begin
            Observer.Observe(Name, 'error');
            Observer.Observe(Name + '|text', GetLastErrorText());
            Observer.Observe(Name + '|code', GetLastErrorCode());
        end;
        Observer.Observe(Name + '|calls', Sub.Take());
        ClearLastError();
    end;

    // MakeDateFilter for an unreadable piece of a Date filter: with placeholders, and with the session language not English.
    [Test]
    procedure MakeDateFilter_PlaceholdersAndLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "REC RPU Date Sub";
    begin
        BindSubscription(Sub);
        DateCell(Observer, Sub, 'english plain', 'abc', false);
        DateCell(Observer, Sub, 'english placeholder or', '%1|abc', true);
        DateCell(Observer, Sub, 'english placeholder range', 'abc..%1', true);
        DateCell(Observer, Sub, 'english placeholder only', '%1', true);
        GlobalLanguage(1031);
        DateCell(Observer, Sub, 'german plain', 'abc', false);
        DateCell(Observer, Sub, 'german placeholder or', '%1|abc', true);
        GlobalLanguage(1033);
        UnbindSubscription(Sub);
        Observer.Finish();
    end;

    // A copy of a RecordRef that is not open, before the original is opened (RR2 := RR, and RR through a Variant).
    [Test]
    procedure RecordRefCopy_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
        Back: RecordRef;
        V: Variant;
    begin
        SeedRows();
        RR2 := RR;
        V := RR;
        RR.Open(Database::"REC RPU Row");
        RR.FindFirst();
        Observer.Observe('rr number', Format(RR.Number()));
        Observer.Observe('rr2 number', Format(RR2.Number()));
        Observer.Observe('variant is recordref', Format(V.IsRecordRef()));
        Back := V;
        Observer.Observe('back number', Format(Back.Number()));
        ClearLastError();
        asserterror
        begin
            RR2.FindFirst();
            Error('REC_RPU_FOUND %1', Format(RR2.Field(1).Value));
        end;
        Observer.Observe('rr2 findfirst', GetLastErrorText());
        Observer.Observe('rr2 findfirst|code', GetLastErrorCode());
        ClearLastError();
        Observer.Finish();
    end;

    local procedure StoreDate(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date; Dtm: DateTime)
    var
        Row: Record "REC RPU Dates";
        Stored: Record "REC RPU Dates";
    begin
        Row.DeleteAll();
        ClearLastError();
        asserterror
        begin
            Row.Init();
            Row.Id := 1;
            Row.Dt := D;
            Row.Dtm := Dtm;
            Row.Insert();
            Stored.Get(1);
            Error('REC_RPU_STORED %1|%2|%3|%4', Format(Stored.Dt, 0, 9), Format(Stored.Dtm, 0, 9), Format(Stored.Dt = D), Format(Stored.Dtm = Dtm));
        end;
        if GetLastErrorText().StartsWith('REC_RPU_STORED ') then
            Observer.Observe(Name, 'stored ' + CopyStr(GetLastErrorText(), StrLen('REC_RPU_STORED ') + 1))
        else begin
            Observer.Observe(Name, 'error');
            Observer.Observe(Name + '|text', GetLastErrorText());
            Observer.Observe(Name + '|code', GetLastErrorCode());
        end;
        ClearLastError();
    end;

    // Date and DateTime values before 1753-01-02 other than the pinned ones, written by Insert and read back by Get.
    [Test]
    procedure DatesBefore1753_InsertAndGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoreDate(Observer, 'date 1700-06-15', DMY2Date(15, 6, 1700), 0DT);
        StoreDate(Observer, 'date 0001-01-02', DMY2Date(2, 1, 1), 0DT);
        StoreDate(Observer, 'date 1753-01-02', DMY2Date(2, 1, 1753), 0DT);
        StoreDate(Observer, 'datetime 1753-01-01 12:00', 0D, CreateDateTime(DMY2Date(1, 1, 1753), 120000T));
        StoreDate(Observer, 'datetime 1753-01-01 23:59', 0D, CreateDateTime(DMY2Date(1, 1, 1753), 235900T));
        StoreDate(Observer, 'datetime 1753-01-02 00:00', 0D, CreateDateTime(DMY2Date(2, 1, 1753), 000000T));
        StoreDate(Observer, 'datetime 1752-01-01 00:00', 0D, CreateDateTime(DMY2Date(1, 1, 1752), 000000T));
        StoreDate(Observer, 'datetime 0001-01-01 00:00', 0D, CreateDateTime(DMY2Date(1, 1, 1), 000000T));
        StoreDate(Observer, 'datetime 0001-01-02 08:00', 0D, CreateDateTime(DMY2Date(2, 1, 1), 080000T));
        Observer.Finish();
    end;

    // Blob.Length and HasValue of a stored Blob of 24 bytes, read by Get without CalcFields, then after CalcFields.
    [Test]
    procedure StoredBlob_LengthBeforeCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC RPU Blob";
        Out: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.B.CreateOutStream(Out);
        Out.WriteText('abcdefghijklmnopqrstuvwx');
        Row.Insert();
        Observer.Observe('buffer after insert', Format(Row.B.Length) + ' ' + Format(Row.B.HasValue()));
        Clear(Row);
        Row.Get(1);
        Observer.Observe('get', Format(Row.B.Length) + ' ' + Format(Row.B.HasValue()));
        Row.CalcFields(B);
        Observer.Observe('calcfields', Format(Row.B.Length) + ' ' + Format(Row.B.HasValue()));
        Clear(Row);
        Row.FindFirst();
        Observer.Observe('findfirst', Format(Row.B.Length) + ' ' + Format(Row.B.HasValue()));
        Commit();
        Clear(Row);
        Row.Get(1);
        Observer.Observe('get after commit', Format(Row.B.Length) + ' ' + Format(Row.B.HasValue()));
        Observer.Finish();
    end;

    var
        FilterPageMode: Integer;

    [FilterPageHandler]
    procedure PointElsewhereHandler(var RecRef: RecordRef): Boolean
    var
        OtherRow: Record "REC RPU Row";
    begin
        case FilterPageMode of
            1:
                RecRef.Field(6).SetFilter('1..3');
            2:
                begin
                    OtherRow.SetRange(Grp, 7);
                    RecRef.GetTable(OtherRow);
                end;
            3:
                begin
                    RecRef.Close();
                    RecRef.Open(Database::"REC RPU Log");
                    RecRef.Field(2).SetFilter('x*');
                end;
            4:
                begin
                    RecRef.Close();
                    RecRef.Open(Database::"REC RPU Row");
                    RecRef.Field(2).SetFilter('n1');
                end;
        end;
        exit(true);
    end;

    local procedure FilterPageCell(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer)
    var
        Row: Record "REC RPU Row";
        Builder: FilterPageBuilder;
        Ok: Boolean;
    begin
        FilterPageMode := Mode;
        Row.SetRange(Flag, true);
        Builder.AddRecord('Rows', Row);
        Builder.AddField('Rows', Row.Grp);
        ClearLastError();
        asserterror
        begin
            Ok := Builder.RunModal();
            Error('REC_RPU_FPB %1|%2|%3|%4', Format(Ok), Builder.Count(), Builder.Name(1), Builder.GetView('Rows', false));
        end;
        if GetLastErrorText().StartsWith('REC_RPU_FPB ') then
            Observer.Observe(Name, CopyStr(GetLastErrorText(), StrLen('REC_RPU_FPB ') + 1))
        else begin
            Observer.Observe(Name, 'error');
            Observer.Observe(Name + '|text', GetLastErrorText());
            Observer.Observe(Name + '|code', GetLastErrorCode());
        end;
        ClearLastError();
    end;

    // A [FilterPageHandler] that sets a filter (control), points its RecordRef at another record of the table (GetTable), at another
    // table (Close, Open), or at the same table opened again: what RunModal returns and what the builder keeps.
    [Test]
    [HandlerFunctions('PointElsewhereHandler')]
    procedure FilterPageHandler_PointsRecordRefElsewhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterPageCell(Observer, 'set filter', 1);
        FilterPageCell(Observer, 'gettable other record', 2);
        FilterPageCell(Observer, 'open other table', 3);
        FilterPageCell(Observer, 'open same table again', 4);
        Observer.Finish();
    end;
}
