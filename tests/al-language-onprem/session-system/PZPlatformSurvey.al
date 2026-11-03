// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: these platform tables are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61299 and 61261
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions are checked by the CI matrix.
//
// What a fresh test tenant holds in platform tables that have no AL declaration to read, and whether Insert, Modify and Delete work from AL on them.
// Empty at the start: Object Options, Tenant License State, Document Service, Privacy Notice, Signup Context, Tenant Profile Page Metadata, Chart, Performance Profile Scheduler.
// Not empty: Tenant Report Layout Selection, Media Resources, Tenant Web Service, Web Service, Report Layout List, MCP Configuration (one row with an empty Name, BC 28 and later) and User Personalization (one row, key {00000000-0000-0000-0000-000000000001}).
// Writes: Insert (a default initialised record), Modify and Delete of that row are allowed on all of them except: Tenant License State takes Insert but raises
// "It is not possible to modify any record in the Tenant License State table." / "It is not possible to delete any record in the Tenant License State table." (code DB:Ok);
// Report Layout List raises "The Report Layout List table is read-only." (code DB:Ok) for Insert, Modify, Delete and DeleteAll; MCP Configuration raises DB:RecordExists for the second row with an empty Name.
// An Insert into Tenant Profile Page Metadata with an empty Profile ID raises an uncatchable CLR exception (ArgumentNullException, parameter profileId), so no write is tried there.
// The test only counts "not empty" for the tables that hold rows (the counts depend on the apps installed).
// BC versions: 29.0 (MCP Configuration exists from BC 28)
codeunit 61299 "PZ Platform Op"
{
    var
        TableId: Integer;
        Op: Text;

    procedure Setup(NewTableId: Integer; NewOp: Text)
    begin
        TableId := NewTableId;
        Op := NewOp;
    end;

    trigger OnRun()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        case Op of
            'insert':
                begin
                    RecRef.Init();
                    RecRef.Insert();
                end;
            'modify':
                begin
                    RecRef.FindFirst();
                    RecRef.Modify();
                end;
            'delete':
                begin
                    RecRef.FindFirst();
                    RecRef.Delete();
                end;
            'deleteall':
                RecRef.DeleteAll();
        end;
    end;
}

codeunit 61261 "PZ Platform Survey"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdOf(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(0);
    end;

    local procedure Attempt(TableId: Integer; OpName: Text): Text
    var
        Op: Codeunit "PZ Platform Op";
        Ok: Boolean;
    begin
        Op.Setup(TableId, OpName);
        Ok := Op.Run();
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Rows(TableId: Integer; WithKey: Boolean): Text
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.Open(TableId);
        if RecRef.IsEmpty() then
            exit('empty');
        Result := 'not empty';
        if WithKey and RecRef.FindFirst() then begin
            KeyRef := RecRef.KeyIndex(1);
            Result += ' first key ';
            for i := 1 to KeyRef.FieldCount() do
                Result += Format(KeyRef.FieldIndex(i).Value()) + '/';
        end;
        exit(Result);
    end;

    local procedure Survey(TableName: Text; WithKey: Boolean; Insert: Boolean; DeleteAll: Boolean; ExpRows: Text; ExpInsert: Text; ExpModify: Text; ExpDelete: Text; ExpDeleteAll: Text)
    var
        Id: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Id := TableIdOf(TableName);
        Observer.Observe('table exists', Format(Id <> 0));
        Observer.Observe('rows', Rows(Id, WithKey));
        if Insert then begin
            Observer.Observe('insert', Attempt(Id, 'insert'));
            Observer.Observe('modify', Attempt(Id, 'modify'));
            Observer.Observe('delete', Attempt(Id, 'delete'));
        end;
        if DeleteAll then
            Observer.Observe('deleteall', Attempt(Id, 'deleteall'));
        Observer.Expect('table exists', 'Yes');
        Observer.Expect('rows', ExpRows);
        if Insert then begin
            Observer.Expect('insert', ExpInsert);
            Observer.Expect('modify', ExpModify);
            Observer.Expect('delete', ExpDelete);
        end;
        if DeleteAll then
            Observer.Expect('deleteall', ExpDeleteAll);
        Observer.Verify();
    end;

    [Test]
    procedure PlatformTable_ObjectOptions()
    begin
        Survey('Object Options', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

    [Test]
    procedure PlatformTable_TenantLicenseState()
    begin
        Survey('Tenant License State', false, true, false, 'empty', 'ok', 'error:It is not possible to modify any record in the Tenant License State table.|DB:Ok', 'error:It is not possible to delete any record in the Tenant License State table.|DB:Ok', '');
    end;

    [Test]
    procedure PlatformTable_DocumentService()
    begin
        Survey('Document Service', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

    [Test]
    procedure PlatformTable_TenantReportLayoutSelection()
    begin
        Survey('Tenant Report Layout Selection', false, true, false, 'not empty', 'ok', 'ok', 'ok', '');
    end;

    [Test]
    procedure PlatformTable_MediaResources()
    begin
        Survey('Media Resources', false, true, false, 'not empty', 'ok', 'ok', 'ok', '');
    end;

    [Test]
    procedure PlatformTable_PrivacyNotice()
    begin
        Survey('Privacy Notice', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

    [Test]
    procedure PlatformTable_SignupContext()
    begin
        Survey('Signup Context', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

    [Test]
    procedure PlatformTable_TenantProfilePageMetadata()
    begin
        Survey('Tenant Profile Page Metadata', false, false, false, 'empty', '', '', '', '');
    end;

    [Test]
    procedure PlatformTable_TenantWebService()
    begin
        Survey('Tenant Web Service', false, true, false, 'not empty', 'ok', 'ok', 'ok', '');
    end;

    [Test]
    procedure PlatformTable_WebService()
    begin
        Survey('Web Service', false, true, false, 'not empty', 'ok', 'ok', 'ok', '');
    end;

    [Test]
    procedure PlatformTable_Chart()
    begin
        Survey('Chart', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

#if BC28PLUS
    [Test]
    procedure PlatformTable_MCPConfiguration()
    begin
        Survey('MCP Configuration', true, true, false, 'not empty first key /', 'error:The record in table MCP Configuration already exists. Identification fields and values: Name=''''|DB:RecordExists', 'ok', 'ok', '');
    end;
#endif

    [Test]
    procedure PlatformTable_PerformanceProfileScheduler()
    begin
        Survey('Performance Profile Scheduler', false, true, true, 'empty', 'ok', 'ok', 'ok', 'ok');
    end;

    [Test]
    procedure PlatformTable_ReportLayoutList()
    begin
        Survey('Report Layout List', false, true, true, 'not empty', 'error:The Report Layout List table is read-only.|DB:Ok', 'error:The Report Layout List table is read-only.|DB:Ok', 'error:The Report Layout List table is read-only.|DB:Ok', 'error:The Report Layout List table is read-only.|DB:Ok');
    end;

    [Test]
    procedure PlatformTable_UserPersonalization()
    begin
        Survey('User Personalization', true, true, false, 'not empty first key {00000000-0000-0000-0000-000000000001}/', 'ok', 'ok', 'ok', '');
    end;
}
