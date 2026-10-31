// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem (the tables have Scope = OnPrem in the system symbols; a Cloud app gets AL0296, see must-not-compile cases 0020 to 0022).
// Fixtures used: PtOnPremOps.al (LT PT OnPrem Ops), tests/al-language/platform/lt-platform-tables/PtHelper.al (LT PT Arg, LT PT Ops)
// Probe: platform tables that have no row provider in the AL runtime, the OnPrem ones: the column list, whether rows exist, the first row, an Insert,
// a second Insert of the same key, a Modify, a Delete and an Insert without triggers (the same sequence as PtCloudTables.al). Object id 61229.

codeunit 61229 "LT PT OnPrem Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT OnPrem Ops";

    local procedure Standard(var Observer: Codeunit "Probe Observer"; TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    begin
        Observer.Observe('columns', Ops.Perform(TableNo, 'columns', '', false));
        Observer.Observe('has_rows', Ops.Perform(TableNo, 'hasrows', '', false));
        Observer.Observe('first_row', Ops.Perform(TableNo, 'first', '', false));
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', FilterRequest, true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_no_triggers', Ops.Perform(TableNo, 'insert', InsertRequest, false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', FilterRequest, false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', FilterRequest, false));
    end;

    [Test]
    procedure WebService_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Web Service", '3=8;6=10;9=LTPTSvc;12=true', '3=8;9=LTPTSvc', '12=false');
        Observer.Expect('columns', 'ok:3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:3=Codeunit;9=CompanySetupService;6=1801;12=Yes;13=No;14=No;');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:3=Page;9=LTPTSvc;6=10;12=Yes;13=No;14=No;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:3=Page;9=LTPTSvc;6=10;12=No;13=No;14=No;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure ConfigurationPackageFile_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Configuration Package File", '1=LTPT;2=LT PT Package;3=1033;4=1;5=7', '1=LTPT', '2=Renamed');
        Observer.Expect('columns', 'ok:1:Code:Code:20:Normal;2:Name:Text:50:Normal;3:Language ID:Integer:4:Normal;4:Setup Type:Option:4:Normal;5:Processing Order:Integer:4:Normal;6:Package:BLOB:8:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=LTPT;2=LT PT Package;3=1033;4=Application;5=7;6=<BLOB>;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=LTPT;2=Renamed;3=1033;4=Application;5=7;6=<BLOB>;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentServiceScenario_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Document Service Scenario", '1=0;2={44444444-4444-4444-4444-444444444444};3=LTPT;4=true;5=false', '1=0;2={44444444-4444-4444-4444-444444444444}', '4=false');
        Observer.Expect('columns', 'ok:1:Service Integration:Option:4:Normal;2:Company:GUID:16:Normal;3:Document Service:Code:30:Normal;4:Use for Application:Boolean:4:Normal;5:Use for Platform:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=OneDrive;2=<guid>;3=LTPT;4=Yes;5=No;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=OneDrive;2=<guid>;3=LTPT;4=No;5=No;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentService_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Document Service", '1=LTPT;3=LT PT Service;5=http://localhost/ltpt;7=ltpt;21=1', '1=LTPT', '3=Renamed');
        Observer.Expect('columns', 'ok:1:Service ID:Code:30:Normal;3:Description:Text:80:Normal;5:Location:Text:250:Normal;7:User Name:Text:128:Normal;9:Password:Text:128:Normal;11:Document Repository:Text:250:Normal;13:Folder:Text:250:Normal;15:Client Id:Text:250:Normal;17:Client Secret:Text:250:Normal;19:Redirect URL:Text:2048:Normal;21:Authentication Type:Option:4:Normal;23:Client Secret Key:GUID:16:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'error:Folder must have a value in Document Service: Service ID=LTPT. It cannot be zero or empty.|TestField');
        Observer.Expect('find_inserted', 'ok:none');
        Observer.Expect('count_inserted', 'ok:0');
        Observer.Expect('insert_duplicate', 'error:Folder must have a value in Document Service: Service ID=LTPT. It cannot be zero or empty.|TestField');
        Observer.Expect('modify', 'error:There is no Document Service within the filter.\\Filters: Service ID: LTPT|DB:NothingInsideFilter');
        Observer.Expect('find_modified', 'ok:none');
        Observer.Expect('delete', 'error:There is no Document Service within the filter.\\Filters: Service ID: LTPT|DB:NothingInsideFilter');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TableInformation_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Table Information", '1=LTPT;2=99999;3=LT PT Table;4=5', '1=LTPT;2=99999', '4=6');
        Observer.Expect('columns', 'ok:1:Company Name:Text:30:Normal;2:Table No.:Integer:4:Normal;3:Table Name:Text:30:Normal;4:No. of Records:Integer:4:Normal;5:Record Size:Decimal:12:Normal;6:Size (KB):Integer:4:Normal;7:Compression:Option:4:Normal;8:Data Size (KB):Integer:4:Normal;9:Index Size (KB):Integer:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=;2=78;3=Printer Selection;4=0;5=0;6=0;7=Page;8=0;9=0;');
        Observer.Expect('insert', 'error:The Table Information table is read-only.|DB:Ok');
        Observer.Expect('find_inserted', 'ok:none');
        Observer.Expect('count_inserted', 'ok:0');
        Observer.Expect('insert_duplicate', 'error:The Table Information table is read-only.|DB:Ok');
        Observer.Expect('modify', 'error:There is no Table Information within the filter.\\Filters: Company Name: LTPT, Table No.: 99999|DB:NothingInsideFilter');
        Observer.Expect('find_modified', 'ok:none');
        Observer.Expect('delete', 'error:There is no Table Information within the filter.\\Filters: Company Name: LTPT, Table No.: 99999|DB:NothingInsideFilter');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'error:The Table Information table is read-only.|DB:Ok');
        Observer.Expect('delete_all_no_triggers', 'error:The Table Information table is read-only.|DB:Ok');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportSettingsOverride_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Report Settings Override", '1=99999;2=LTPT;3=30;4=100;5=10;6=en-US;7=1033', '1=99999;2=LTPT', '3=60');
        Observer.Expect('columns', 'ok:1:Object ID:Integer:4:Normal;2:Company Name:Text:30:Normal;3:Timeout:Integer:4:Normal;4:MaxRows:Integer:4:Normal;5:MaxDocuments:Integer:4:Normal;6:Format Language Tag:Text:80:Normal;7:Language ID:Integer:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=99999;2=LTPT;3=30;4=100;5=10;6=en-US;7=1033;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=99999;2=LTPT;3=60;4=100;5=10;6=en-US;7=1033;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure Device_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // An insert is refused by the license check with an error that Codeunit.Run does not catch, so the insert is observed with asserterror.
        Observer.Observe('columns', Ops.Perform(Database::"Device", 'columns', '', false));
        Observer.Observe('has_rows', Ops.Perform(Database::"Device", 'hasrows', '', false));
        Observer.Observe('first_row', Ops.Perform(Database::"Device", 'first', '', false));
        asserterror Ops.Perform(Database::"Device", 'insert', '1=LTPT0001;2=LT PT Device;3=1;4=true', true);
        Observer.Observe('insert_error', GetLastErrorText());
        Observer.Observe('count_after_error', Ops.Perform(Database::"Device", 'count', '1=LTPT0001', false));
        Observer.Expect('columns', 'ok:1:MAC Address:Code:20:Normal;2:Name:Text:80:Normal;3:Device Type:Option:4:Normal;4:Enabled:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert_error', 'The new devices do not meet the terms of the current license. The current license allows 0 full devices, 0 limited devices, 0 ISV devices, 0 ISV functional devices and 1 devices.');
        Observer.Expect('count_after_error', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantProfile_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Tenant Profile", '1={55555555-5555-5555-5555-555555555555};2=LTPTPROFILE;3=LT PT Profile;4=9022;5=false', '2=LTPTPROFILE', '3=Renamed');
        Observer.Expect('columns', 'ok:1:App ID:GUID:16:Normal;2:Profile ID:Code:30:Normal;3:Description:Text:250:Normal;4:Role Center ID:Integer:4:Normal;5:Default Role Center:Boolean:4:Normal;6:Disable Personalization:Boolean:4:Normal;7:Metadata:BLOB:8:Normal;8:User AL Code:BLOB:8:Normal;9:Customization Status:Option:4:Normal;10:Emit Version:Integer:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=<guid>;2=LTPTPROFILE;3=LT PT Profile;4=9022;5=No;6=No;7=<BLOB>;8=<BLOB>;9=Updated;10=0;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=<guid>;2=LTPTPROFILE;3=Renamed;4=9022;5=No;6=No;7=<BLOB>;8=<BLOB>;9=Updated;10=0;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantProfilePageMetadata_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, Database::"Tenant Profile Page Metadata", '1={55555555-5555-5555-5555-555555555555};2=LTPTPROFILE;3=99999;6=1', '2=LTPTPROFILE;3=99999', '7=2');
        Observer.Expect('columns', 'ok:2:Profile ID:Code:30:Normal;3:Page ID:Integer:4:Normal;1:App ID:GUID:16:Normal;6:Owner:Option:4:Normal;4:Page Metadata:BLOB:8:Normal;5:Page AL:BLOB:8:Normal;7:Emit Version:Integer:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:2=LTPTPROFILE;3=99999;1=<guid>;6=Tenant;4=<BLOB>;5=<BLOB>;7=0;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:2=LTPTPROFILE;3=99999;1=<guid>;6=Tenant;4=<BLOB>;5=<BLOB>;7=2;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    // Writer QZ: the platform table "Intelligent Cloud" read from an OnPrem app, outside and inside a [TryFunction]
    // (Microsoft's Permission Manager.IsIntelligentCloud reads it with Get()).
    [TryFunction]
    local procedure QzTryReadIntelligentCloud(var Found: Boolean)
    var
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        Found := IntelligentCloud.Get();
    end;

    [Test]
    procedure QZ_IntelligentCloud_Read()
    var
        Observer: Codeunit "Probe Observer";
        IntelligentCloud: Record "Intelligent Cloud";
        RecRef: RecordRef;
        Columns: Text;
        Index: Integer;
        Found: Boolean;
    begin
        RecRef.Open(Database::"Intelligent Cloud");
        for Index := 1 to RecRef.FieldCount() do
            Columns += Format(RecRef.FieldIndex(Index).Number()) + '=' + RecRef.FieldIndex(Index).Name() + ',';
        Observer.Observe('columns', Columns);
        Observer.Observe('is empty', Format(IntelligentCloud.IsEmpty()));
        Observer.Observe('count', Format(IntelligentCloud.Count()));
        Observer.Observe('get', Format(IntelligentCloud.Get()));
        Observer.Observe('find first', Format(IntelligentCloud.FindFirst()));
        ClearLastError();
        Observer.Observe('try', Format(QzTryReadIntelligentCloud(Found)) + '|' + Format(Found));
        Observer.ObserveError('try');
        Observer.Expect('columns', '1=Primary Key,2=Enabled,');
        Observer.Expect('is empty', 'Yes');
        Observer.Expect('count', '0');
        Observer.Expect('get', 'No');
        Observer.Expect('find first', 'No');
        Observer.Expect('try', 'Yes|No');
        Observer.Expect('try|text', '');
        Observer.Expect('try|code', '');
        Observer.Verify();
    end;
    // Writer Y17 (gap cycle 1 G8): Power BI Blob (2000000144, Scope OnPrem), the table Microsoft's Power BI tests fill with a row whose
    // "Blob File" holds a text and read back with SetAutoCalcFields("Blob File") + Get, SetRange("GP Enabled") + FindFirst.
    [Test]
    procedure Y17_PowerBIBlob_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000144, '1={66666666-6666-6666-6666-666666666666};3=LT PT Blob;4=1;5=false', '1={66666666-6666-6666-6666-666666666666}', '3=Renamed');
        Observer.Finish();
    end;

    [Test]
    procedure Y17_PowerBIBlob_BlobRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        PowerBIBlob: Record "Power BI Blob";
        ReadBack: Record "Power BI Blob";
        OutS: OutStream;
        InS: InStream;
        Id: Guid;
        Line: Text;
        Rows: Text;
    begin
        Observer.Observe('fresh count', Format(PowerBIBlob.Count()));
        if PowerBIBlob.FindSet() then
            repeat
                Rows += PowerBIBlob.Name + '|' + Format(PowerBIBlob.Version) + '|' + Format(PowerBIBlob."GP Enabled") + ';';
            until PowerBIBlob.Next() = 0;
        Observer.Observe('fresh rows', Rows);
        PowerBIBlob.DeleteAll();
        Evaluate(Id, '{77777777-7777-7777-7777-777777777777}');
        PowerBIBlob.Init();
        PowerBIBlob.Id := Id;
        PowerBIBlob.Name := 'LT Y17 Blob';
        PowerBIBlob.Version := 3;
        PowerBIBlob."Blob File".CreateOutStream(OutS);
        OutS.WriteText('This is not really relevant');
        Observer.Observe('insert', Format(PowerBIBlob.Insert()));
        Observer.Observe('has value without calcfields', Format(ReadBack.Get(Id)) + '|' + Format(ReadBack."Blob File".HasValue()));
        Clear(ReadBack);
        ReadBack.SetAutoCalcFields("Blob File");
        Observer.Observe('get with autocalc', Format(ReadBack.Get(Id)) + '|' + Format(ReadBack."Blob File".HasValue()));
        ReadBack."Blob File".CreateInStream(InS);
        InS.ReadText(Line);
        Observer.Observe('text', Line);
        Clear(ReadBack);
        ReadBack.SetRange("GP Enabled", false);
        Observer.Observe('gp enabled false findfirst', Format(ReadBack.FindFirst()) + '|' + ReadBack.Name);
        ReadBack.SetRange("GP Enabled", true);
        Observer.Observe('gp enabled true isempty', Format(ReadBack.IsEmpty()));
        PowerBIBlob.DeleteAll();
        Observer.Observe('count after delete', Format(PowerBIBlob.Count()));
        Observer.Finish();
    end;
}

codeunit 61252 "LT PT Cloud Runner OnPrem"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

    // The runner of PtHelper.al is compiled in the Target = Cloud app: what does it do with an OnPrem-scope system table (Document Service Scenario, 2000000115)?
    [Test]
    procedure CloudRunner_RefusesOnPremTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', Ops.Perform(2000000115, 'columns', '', false));
        Observer.Observe('has_rows', Ops.Perform(2000000115, 'hasrows', '', false));
        Observer.Observe('insert', Ops.Perform(2000000115, 'insert', '1=0;3=LTPTCloudRunner', true));
#if BC28PLUS
        Observer.Expect('columns', 'error:You cannot open record 2000000115 from a RecordRef data type when you are using target Cloud.|NotAllowedForCompilationTarget');
#else
        Observer.Expect('columns', 'ok:1:Service Integration:Option:4:Normal;2:Company:GUID:16:Normal;3:Document Service:Code:30:Normal;4:Use for Application:Boolean:4:Normal;5:Use for Platform:Boolean:4:Normal;');
#endif
#if BC28PLUS
        Observer.Expect('has_rows', 'error:You cannot open record 2000000115 from a RecordRef data type when you are using target Cloud.|NotAllowedForCompilationTarget');
#else
        Observer.Expect('has_rows', 'ok:No');
#endif
#if BC28PLUS
        Observer.Expect('insert', 'error:You cannot open record 2000000115 from a RecordRef data type when you are using target Cloud.|NotAllowedForCompilationTarget');
#else
        Observer.Expect('insert', 'ok:Yes');
#endif
        Observer.Verify();
    end;
}
