// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (al-runner issue 7348): what a write inside a [TryFunction] whose result is used does in install code (OnInstallAppPerDatabase,
//   tables with DataPerCompany = false) when the service tier setting DisableWriteInsideTryFunctions is false (SaaS). This app runs only in
//   the CI job "BC TryWrites", which sets that value and publishes the app to a fresh database, so the install code runs once there.
//   The install code runs each case in a TryFunction (Modify, Modify then an error, Insert, a Modify through a RecordRef, NavApp.GetResource
//   plus Media.ImportStream plus Modify, and the same with a resource that does not exist) and logs the result of the call, the last error
//   text and code. The tests read the rows and the log.
//   The install code writes outside the TryFunctions only with `if Insert() then;` and `if Modify() then;`, so it cannot fail the publish.
// BC versions: 27.5, 28.5, 29.0

table 81701 "LT TW Install Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Description; Text[50]) { }
        field(3; Thumbnail; Media) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 81702 "LT TW Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Name; Text[50]) { }
        field(2; Value; Text[250]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

codeunit 81703 "LT TW Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Row: Record "LT TW Install Row";
    begin
        AddRow(1, 'a');
        AddRow(2, 'b');
        AddRow(3, 'c');
        AddRow(4, 'd');
        AddRow(5, 'e');

        ClearLastError();
        if Row.Get(1) then
            Log('modify', TrySetDescription(Row, 'Set in install', false));

        ClearLastError();
        if Row.Get(2) then
            Log('modify error after', TrySetDescription(Row, 'Set before error', true));

        ClearLastError();
        Log('insert', TryInsertRow(6, 'inserted'));

        ClearLastError();
        Log('recref modify', TryModifyViaRecRef(5, 'Set via RecordRef'));

        ClearLastError();
        if Row.Get(3) then
            Log('media', TrySetResourceThumbnail(Row, 'tw-thumb.png'));

        ClearLastError();
        if Row.Get(4) then
            Log('media missing', TrySetResourceThumbnail(Row, 'tw-missing.png'));
        ClearLastError();
    end;

    local procedure AddRow(No: Integer; Description: Text[50])
    var
        Row: Record "LT TW Install Row";
    begin
        Row."No." := No;
        Row.Description := Description;
        if Row.Insert() then;
    end;

    local procedure Log(Name: Text[50]; Ok: Boolean)
    begin
        LogValue(Name + ' ok', Format(Ok));
        LogValue(Name + ' lasterror', CopyStr(GetLastErrorText(), 1, 250));
        LogValue(Name + ' lastcode', CopyStr(GetLastErrorCode(), 1, 250));
    end;

    local procedure LogValue(Name: Text[50]; Value: Text[250])
    var
        LogRow: Record "LT TW Install Log";
    begin
        LogRow.Name := Name;
        LogRow.Value := Value;
        if not LogRow.Insert() then
            if LogRow.Modify() then;
    end;

    [TryFunction]
    local procedure TrySetDescription(var Row: Record "LT TW Install Row"; Description: Text[50]; FailAfter: Boolean)
    begin
        Row.Description := Description;
        Row.Modify();
        if FailAfter then
            Error('error after write');
    end;

    [TryFunction]
    local procedure TryInsertRow(No: Integer; Description: Text[50])
    var
        Row: Record "LT TW Install Row";
    begin
        Row."No." := No;
        Row.Description := Description;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryModifyViaRecRef(No: Integer; Description: Text[50])
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT TW Install Row");
        RecRef.Field(1).SetRange(No);
        RecRef.FindFirst();
        RecRef.Field(2).Value := Description;
        RecRef.Modify();
    end;

    // The shape of al-runner issue 7348: a thumbnail from the app's resources into a Media field, then Modify.
    [TryFunction]
    local procedure TrySetResourceThumbnail(var Row: Record "LT TW Install Row"; FileName: Text)
    var
        Logo: InStream;
    begin
        NavApp.GetResource(FileName, Logo);
        Row.Thumbnail.ImportStream(Logo, FileName);
        Row.Description := 'media';
        Row.Modify();
    end;
}

codeunit 81704 "LT TW Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LogValue(Name: Text): Text
    var
        LogRow: Record "LT TW Install Log";
    begin
        if LogRow.Get(Name) then
            exit(LogRow.Value);
        exit('<no log row>');
    end;

    local procedure RowState(No: Integer): Text
    var
        Row: Record "LT TW Install Row";
    begin
        if not Row.Get(No) then
            exit('<no row>');
        exit(Row.Description + ' thumbnail=' + Format(Row.Thumbnail.HasValue()));
    end;

    local procedure ObserveCase(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + ' ok', LogValue(Name + ' ok'));
        Observer.Observe(Name + ' lasterror', LogValue(Name + ' lasterror'));
        Observer.Observe(Name + ' lastcode', LogValue(Name + ' lastcode'));
    end;

    [Test]
    procedure Install_ModifyInTryFunction_Kept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'modify');
        Observer.Observe('row', RowState(1));
        Observer.Expect('modify ok', 'Yes');
        Observer.Expect('modify lasterror', '');
        Observer.Expect('modify lastcode', '');
        Observer.Expect('row', 'Set in install thumbnail=No');
        Observer.Verify();
    end;

    [Test]
    procedure Install_ModifyInTryFunction_ErrorAfter_Kept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'modify error after');
        Observer.Observe('row', RowState(2));
        Observer.Expect('modify error after ok', 'No');
        Observer.Expect('modify error after lasterror', 'error after write');
        Observer.Expect('modify error after lastcode', 'Dialog');
        Observer.Expect('row', 'Set before error thumbnail=No');
        Observer.Verify();
    end;

    [Test]
    procedure Install_InsertInTryFunction_Kept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'insert');
        Observer.Observe('row', RowState(6));
        Observer.Expect('insert ok', 'Yes');
        Observer.Expect('insert lasterror', '');
        Observer.Expect('insert lastcode', '');
        Observer.Expect('row', 'inserted thumbnail=No');
        Observer.Verify();
    end;

    [Test]
    procedure Install_RecRefModifyInTryFunction_Kept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'recref modify');
        Observer.Observe('row', RowState(5));
        Observer.Expect('recref modify ok', 'Yes');
        Observer.Expect('recref modify lasterror', '');
        Observer.Expect('recref modify lastcode', '');
        Observer.Expect('row', 'Set via RecordRef thumbnail=No');
        Observer.Verify();
    end;

    [Test]
    procedure Install_ResourceThumbnailInTryFunction_Kept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'media');
        Observer.Observe('row', RowState(3));
        Observer.Expect('media ok', 'Yes');
        Observer.Expect('media lasterror', '');
        Observer.Expect('media lastcode', '');
        Observer.Expect('row', 'media thumbnail=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Install_MissingResourceInTryFunction_NoWrite()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveCase(Observer, 'media missing');
        Observer.Observe('row', RowState(4));
        Observer.Expect('media missing ok', 'No');
        Observer.Expect('media missing lasterror', '<observe>');
        Observer.Expect('media missing lastcode', '<observe>');
        Observer.Expect('row', 'd thumbnail=No');
        Observer.Verify();
    end;
}
