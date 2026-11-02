// Database.CopyCompany on a company the test creates (al-runner issue 6507). The error arms for a missing source and an existing
// destination are pinned in lt-o-small-builtins/OSmallBuiltins.al (O_Database_CopyCompany). The session company is never the source:
// copying it also copies the test runner's own rows (corpus issue 654). Every test commits its setup and drops the companies it made.
// One copy scenario per test codeunit, with company names no other codeunit uses: a second copy in the same session, after the first
// copy's companies were deleted and the source made again under the same name, did not return (SaaS BC 29; the BC 29.0 hang of issue 654).
codeunit 92176 "LT Y22 Copy Helper"
{
    procedure DropCompany(Name: Text)
    var
        Company: Record Company;
    begin
        if Company.Get(Name) then
            Company.Delete(true);
    end;

    procedure MakeSource(Name: Text)
    var
        Company: Record Company;
    begin
        Company.Init();
        Company.Name := CopyStr(Name, 1, MaxStrLen(Company.Name));
        Company."Display Name" := 'LT Y22 Source Display';
        Company."Evaluation Company" := true;
        Company."Business Profile Id" := 'LT Y22 Profile';
        Company.Insert();
    end;

    procedure CopyIt(Source: Text; Destination: Text): Boolean
    var
        Runner: Codeunit "LT Y22 Copy Runner";
    begin
        Runner.Setup(Source, Destination);
        exit(Runner.Run());
    end;

    procedure Same(A: Guid; B: Guid): Text
    begin
        if IsNullGuid(B) then
            exit('null');
        if A = B then
            exit('same');
        exit('other');
    end;
}

codeunit 92173 "LT Y22 Copy Company Tests"
{
    Subtype = Test;

    var
        Helper: Codeunit "LT Y22 Copy Helper";
        SourceTok: Label 'LT Y22 Src', Locked = true;
        DestinationTok: Label 'LT Y22 Dst', Locked = true;

    local procedure DropAll()
    var
        Shared: Record "LT Y22 Shared";
    begin
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Shared.DeleteAll();
    end;

    [Test]
    procedure Y22_CopyCompany_CopiesCompanyAndRows()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT Y22 Copy Subs";
        Source: Record Company;
        Destination: Record Company;
        Row: Record "LT Y22 Row";
        SourceRow: Record "LT Y22 Row";
        Shared: Record "LT Y22 Shared";
        Log: Record "LT Y22 Log";
        SourceInfo: Record "Company Information";
        Info: Record "Company Information";
        Mark: Integer;
        i: Integer;
        Rows: Text;
    begin
        DropAll();
        Commit();
        BindSubscription(Subs);
        Helper.MakeSource(SourceTok);
        Mark := Log.Last();
        Row.ChangeCompany(SourceTok);
        for i := 1 to 3 do begin
            Row.Init();
            Row.No := i;
            Row.Name := 'row ' + Format(i);
            Row.Insert(true);
        end;
        SourceInfo.ChangeCompany(SourceTok);
        SourceInfo.Init();
        SourceInfo.Name := 'LT Y22 Source Info';
        SourceInfo.Insert();
        Shared.No := 1;
        Shared.Insert();
        Commit();
        Observer.Observe('setup log', Log.After(Mark));
        Mark := Log.Last();
        if Helper.CopyIt(SourceTok, DestinationTok) then
            Observer.Observe('copy', 'no error')
        else
            Observer.ObserveError('copy');
        Observer.Observe('copy log', Log.After(Mark));
        UnbindSubscription(Subs);
        Source.Get(SourceTok);
        Observer.Observe('destination exists', Format(Destination.Get(DestinationTok)));
        Observer.Observe('destination name', Destination.Name);
        Observer.Observe('destination display name', Destination."Display Name");
        Observer.Observe('destination evaluation', Format(Destination."Evaluation Company"));
        Observer.Observe('destination business profile id', Destination."Business Profile Id");
        Observer.Observe('destination id', Helper.Same(Source.Id, Destination.Id));
        Observer.Observe('destination systemid', Helper.Same(Source.SystemId, Destination.SystemId));
        Observer.Observe('source display name', Source."Display Name");
        Clear(Row);
        Row.ChangeCompany(DestinationTok);
        SourceRow.ChangeCompany(SourceTok);
        Observer.Observe('rows count', Format(Row.Count()));
        if Row.FindSet() then
            repeat
                SourceRow.Get(Row.No);
                Rows += Format(Row.No) + '|' + Row.Name + '|' + Format(Row."By Trigger") + '|' + Helper.Same(SourceRow.SystemId, Row.SystemId) + '|' +
                    Format(SourceRow.SystemCreatedAt = Row.SystemCreatedAt) + '|' + Format(SourceRow.SystemModifiedBy = Row.SystemModifiedBy) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Observe('source rows count', Format(SourceRow.Count()));
        Info.ChangeCompany(DestinationTok);
        if Info.Get() then
            Observer.Observe('company information', Info.Name)
        else
            Observer.Observe('company information', 'no row');
        Observer.Observe('shared count', Format(Shared.Count()));
        DropAll();
        Commit();
        Observer.Expect('setup log', 'trigger 1;database insert 1;event 1 Yes;trigger 2;database insert 2;event 2 Yes;trigger 3;database insert 3;event 3 Yes;');
        Observer.Expect('copy', 'no error');
        Observer.Expect('copy log', 'company insert LT Y22 Dst;');
        Observer.Expect('destination exists', 'Yes');
        Observer.Expect('destination name', 'LT Y22 Dst');
        Observer.Expect('destination display name', '');
        Observer.Expect('destination evaluation', 'Yes');
        Observer.Expect('destination business profile id', '');
        Observer.Expect('destination id', 'other');
        Observer.Expect('destination systemid', 'other');
        Observer.Expect('source display name', 'LT Y22 Source Display');
        Observer.Expect('rows count', '3');
        Observer.Expect('rows', '1|row 1|Yes|same|Yes|Yes;2|row 2|Yes|same|Yes|Yes;3|row 3|Yes|same|Yes|Yes;');
        Observer.Expect('source rows count', '3');
        Observer.Expect('company information', 'LT Y22 Source Info');
        Observer.Expect('shared count', '1');
        Observer.Verify();
    end;
}

// Database.CopyCompany returns a Boolean (the compiler types it so).
codeunit 92177 "LT Y22 Copy Return Tests"
{
    Subtype = Test;

    var
        Helper: Codeunit "LT Y22 Copy Helper";
        SourceTok: Label 'LT Y22 B Src', Locked = true;
        DestinationTok: Label 'LT Y22 B Dst', Locked = true;

    [Test]
    procedure Y22_CopyCompany_ReturnValue()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Ok: Boolean;
    begin
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Helper.MakeSource(SourceTok);
        Commit();
        ClearLastError();
        Ok := Database.CopyCompany(SourceTok, DestinationTok);
        Observer.Observe('copy', Format(Ok) + '|' + Format(Company.Get(DestinationTok)) + '|' + GetLastErrorText());
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Commit();
        Observer.Expect('copy', 'Yes|Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Y22_CopyCompany_ReturnValueMissingSource()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Ok: Boolean;
    begin
        // The error is raised even though the return value is used (SaaS BC 29: the call did not return false).
        asserterror Ok := Database.CopyCompany('LT Y22 No Such Company', DestinationTok);
        Observer.ObserveError('missing source');
        Observer.Observe('missing source|destination', Format(Company.Get(DestinationTok)));
        Observer.Expect('missing source|text', 'The Company does not exist. Identification fields and values: Name=''LT Y22 No Such Company''');
        Observer.Expect('missing source|code', 'DB:RecordNotFound');
        Observer.Expect('missing source|destination', 'No');
        Observer.Verify();
    end;
}

codeunit 92178 "LT Y22 Copy Name Tests"
{
    Subtype = Test;

    var
        Helper: Codeunit "LT Y22 Copy Helper";
        SourceTok: Label 'LT Y22 C Src', Locked = true;
        LongTok: Label 'LT Y22 C Destination Name 31Ch', Locked = true;

    [Test]
    procedure Y22_CopyCompany_DestinationNames()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(LongTok);
        Helper.MakeSource(SourceTok);
        Commit();
        if Helper.CopyIt(SourceTok, LongTok + 'X') then
            Observer.Observe('31 chars', 'no error')
        else
            Observer.ObserveError('31 chars');
        Observer.Observe('31 chars|company', Format(Company.Get(LongTok)));
        if Helper.CopyIt(SourceTok, '') then
            Observer.Observe('empty', 'no error')
        else
            Observer.ObserveError('empty');
        if Helper.CopyIt(SourceTok, LowerCase(SourceTok)) then
            Observer.Observe('other case of source', 'no error')
        else
            Observer.ObserveError('other case of source');
        Helper.DropCompany(LongTok);
        Helper.DropCompany(SourceTok);
        Commit();
        Observer.Expect('31 chars|text', 'The length of the string is 31, but it must be less than or equal to 30 characters. Value: LT Y22 C Destination Name 31ChX');
        Observer.Expect('31 chars|code', 'StringLengthExceeded');
        Observer.Expect('31 chars|company', 'No');
        Observer.Expect('empty|text', 'Company name cannot be empty or only consist of spaces.');
        Observer.Expect('empty|code', 'DB:Ok');
        Observer.Expect('other case of source|text', 'Cannot rename or create a new company with the name (lt y22 c src) because a company with the same name already exists');
        Observer.Expect('other case of source|code', 'DB:Ok');
        Observer.Verify();
    end;
}

codeunit 92179 "LT Y22 Copy Transaction Tests"
{
    Subtype = Test;

    var
        Helper: Codeunit "LT Y22 Copy Helper";
        SourceTok: Label 'LT Y22 D Src', Locked = true;
        DestinationTok: Label 'LT Y22 D Dst', Locked = true;

    [Test]
    procedure Y22_CopyCompany_InWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Shared: Record "LT Y22 Shared";
    begin
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Shared.DeleteAll();
        Helper.MakeSource(SourceTok);
        Commit();
        Shared.No := 2;
        Shared.Insert();
        Database.CopyCompany(SourceTok, DestinationTok);
        Observer.Observe('after copy', Format(Company.Get(DestinationTok)) + '|' + Format(Shared.Count()));
        asserterror Error('LT Y22 roll back');
        Observer.Observe('after rollback', Format(Company.Get(DestinationTok)) + '|' + Format(Shared.Count()));
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Shared.DeleteAll();
        Commit();
        Observer.Expect('after copy', 'Yes|1');
        Observer.Expect('after rollback', 'No|0');
        Observer.Verify();
    end;
}

codeunit 92180 "LT Y22 Copy Report Tests"
{
    Subtype = Test;

    var
        Helper: Codeunit "LT Y22 Copy Helper";
        SourceTok: Label 'LT Y22 E Src', Locked = true;
        DestinationTok: Label 'LT Y22 E Dst', Locked = true;
        Messages: Text;

    // The report ends with a Message in a client session (CI 27.5, 29.0: OnPostDataItem of the Company data item); the SaaS run through
    // the API showed none.
    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure Y22_CopyCompany_Report()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Parameters: Text;
    begin
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Helper.MakeSource(SourceTok);
        Commit();
        Parameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="Copy Company" id="357"><Options><Field name="NewCompanyName">' +
            DestinationTok + '</Field></Options><DataItems><DataItem name="Company">VERSION(1) SORTING(Field1) WHERE(Field1=1(' + SourceTok +
            '))</DataItem></DataItems></ReportParameters>';
        Report.Execute(Report::"Copy Company", Parameters);
        Observer.Observe('report', Format(Company.Get(DestinationTok)) + '|' + Company."Display Name" + '|' + Format(Company."Evaluation Company"));
        Observer.Observe('messages', Messages);
        Helper.DropCompany(SourceTok);
        Helper.DropCompany(DestinationTok);
        Commit();
        Observer.Expect('report', 'Yes|LT Y22 E Dst|Yes');
        Observer.Expect('messages', 'Company LT Y22 E Src has been copied successfully.;');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MessageHandler(Text: Text[1024])
    begin
        Messages += Text + ';';
    end;
}
