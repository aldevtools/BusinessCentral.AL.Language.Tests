// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setpermissionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Permissions Mock (System Application Test Library); self-contained table 80206 and test codeunit 80207
// Probe: corpus issue 647 item 21 (writer AV). RISKY (own codeunit, one test): the test narrows its permissions with Permissions Mock to a tenant permission set
//   it creates (read on table 80206 with a security filter) and restores them before it reports.
// Facts: the text form Evaluate accepts for a Security Filter; Permissions Mock.Set refuses a tenant permission set ("The Permission Set does not exist.",
//   DB:RecordNotFound) and leaves the test without read permission on the table, so a security filter cannot be put on the test session this way (the
//   item's question, rows under a security filter, stays open); Record.SetPermissionFilter and RecordRef.SetPermissionFilter once the mock is stopped.
// BC versions: 27, 28, 29
table 80206 "LT AV Secured Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Category; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 80207 "LT AV Set Permission Filter"
{
    Subtype = Test;

    var
        RoleTok: Label 'LTAVSECFILTER', Locked = true;

    [TryFunction]
    local procedure TryEvaluateFilter(var TenantPermission: Record "Tenant Permission"; FilterText: Text)
    begin
        Evaluate(TenantPermission."Security Filter", FilterText);
    end;

    [TryFunction]
    local procedure TrySet(var PermissionsMock: Codeunit "Permissions Mock")
    begin
        PermissionsMock.Set(RoleTok);
    end;

    [TryFunction]
    local procedure TryReadAll(var Result: Text)
    var
        Row: Record "LT AV Secured Row";
    begin
        Result := 'count=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Result += ' ' + Format(Row.Id) + Row.Category;
            until Row.Next() = 0;
    end;

    [TryFunction]
    local procedure TryRecordFilter(var Result: Text)
    var
        Row: Record "LT AV Secured Row";
    begin
        Row.SetPermissionFilter();
        Result := 'filters=[' + Row.GetFilters() + '] count=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Result += ' ' + Format(Row.Id) + Row.Category;
            until Row.Next() = 0;
    end;

    [TryFunction]
    local procedure TryRecordRefFilter(var Result: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT AV Secured Row");
        RecRef.SetPermissionFilter();
        Result := 'filters=[' + RecRef.GetFilters() + '] count=' + Format(RecRef.Count());
    end;

    local procedure ObserveTry(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SetPermissionFilter_TenantSetWithSecurityFilter()
    var
        Observer: Codeunit "Probe Observer";
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "LT AV Secured Row";
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        NullGuid: Guid;
        WasStarted: Boolean;
        Result: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Category := 'A';
        Row.Insert();
        Row.Id := 2;
        Row.Category := 'B';
        Row.Insert();
        Row.Id := 3;
        Row.Category := 'A';
        Row.Insert();

        TenantPermissionSet."App ID" := NullGuid;
        TenantPermissionSet."Role ID" := RoleTok;
        TenantPermissionSet.Name := 'LT AV Security Filter';
        TenantPermissionSet.Insert();
        TenantPermission."App ID" := NullGuid;
        TenantPermission."Role ID" := RoleTok;
        TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
        TenantPermission."Object ID" := Database::"LT AV Secured Row";
        TenantPermission."Read Permission" := TenantPermission."Read Permission"::Yes;
        TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::" ";
        TenantPermission."Modify Permission" := TenantPermission."Modify Permission"::" ";
        TenantPermission."Delete Permission" := TenantPermission."Delete Permission"::" ";
        TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::" ";
        Ok := TryEvaluateFilter(TenantPermission, 'LT AV Secured Row: Category=A');
        Observer.Observe('evaluate table form', Format(Ok));
        if not Ok then begin
            ClearLastError();
            Observer.Observe('evaluate field form', Format(TryEvaluateFilter(TenantPermission, 'Category=A')));
        end;
        Observer.Observe('security filter text', Format(TenantPermission."Security Filter"));
        TenantPermission.Insert();

        WasStarted := PermissionsMock.IsStarted();
        if not WasStarted then
            PermissionsMock.Start();
        Ok := TrySet(PermissionsMock);
        if Ok then
            Observer.Observe('mock set', 'ok')
        else
            Observer.ObserveError('mock set');
        Ok := TryReadAll(Result);
        Observer.Observe('plain read under the mock', Format(Ok));
        Observer.Observe('plain read under the mock|code', GetLastErrorCode());
        ClearLastError();
        PermissionsMock.ClearAssignments();
        if not WasStarted then
            PermissionsMock.Stop();

        Ok := TryRecordFilter(Result);
        ObserveTry(Observer, 'record SetPermissionFilter after the mock stopped', Ok, Result);
        Ok := TryRecordRefFilter(Result);
        ObserveTry(Observer, 'recordref SetPermissionFilter after the mock stopped', Ok, Result);
        TenantPermission.Delete();
        TenantPermissionSet.Delete();
        Row.DeleteAll();
        Observer.Expect('evaluate table form', 'Yes');
        Observer.Expect('security filter text', 'LT AV Secured Row: Category=A');
        Observer.Expect('mock set|text', 'The Permission Set does not exist. Identification fields and values: Role ID=''LTAVSECFILTER''');
        Observer.Expect('mock set|code', 'DB:RecordNotFound');
        Observer.Expect('plain read under the mock', 'No');
        Observer.Expect('plain read under the mock|code', 'DB:ClientReadDenied');
        Observer.Expect('record SetPermissionFilter after the mock stopped', 'filters=[] count=3 1A 2B 3A');
        Observer.Expect('recordref SetPermissionFilter after the mock stopped', 'filters=[] count=3');
        Observer.Verify();
    end;
}
