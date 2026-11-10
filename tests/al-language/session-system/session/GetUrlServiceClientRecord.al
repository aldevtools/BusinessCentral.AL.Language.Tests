// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97453-97455 (SS UrlSvc Row, SS UrlSvc List, SS UrlSvc Record Tests)
// Probe: from al-runner issue 7586 item 5 (GetUrl(ClientType::ODataV4, CompanyName(), ObjectType::Page, <page>, <record>), the form
//   with five arguments; met in Microsoft's test apps).
// Area: GetUrl for the service client types (SOAP, OData, ODataV4, Api) with an object and a record:
//   - five arguments (no UseFilters), six arguments with UseFilters false and true;
//   - the record: a Record variable that was never read, a row that was read, a row with a filter, and the same through a RecordRef;
//   - the company: CompanyName(), the empty text, a name that is no company;
//   - the object: a page of this app over the record's table, the page with the id of this test codeunit as ObjectType::Codeunit.
//   The page is not published as a web service, except in the last test: there it is a tenant web service for the length of the test
//   (Web Service Management.CreateTenantWebService writes the row, the test deletes it again).
//   The server address is written as <host>/<instance> (the masking of TGetUrl.al); Probe Observer writes the company as <Company>.
// Already pinned elsewhere, not repeated: the six-argument form with UseFilters false on page 21, with 'My Company' and '' as company
//   (metadata/session-system/TGetUrl.al, TV_GetUrl_ClientSOAP, TV_GetUrl_ClientOData, TV_GetUrl_ClientODataV4, TV_GetUrl_ClientApi);
//   the Web client forms with a record (GetUrlRecord.al, PGetUrl.al).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 97453 "SS UrlSvc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 97454 "SS UrlSvc List"
{
    PageType = List;
    SourceTable = "SS UrlSvc Row";
    ApplicationArea = All;
    Caption = 'SS UrlSvc List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TagCtl; Rec.Tag) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 97455 "SS UrlSvc Record Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "SS UrlSvc Row";
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Tag := 1;
        Row.Insert();
        Row.Id := 6;
        Row.Tag := 2;
        Row.Insert();
        ClearLastError();
    end;

    // A service address has the container's host, port and instance: they become <host>/<instance>.
    local procedure Host(Value: Text): Text
    var
        At: Integer;
        Rest: Text;
        Slash: Integer;
        Q: Integer;
    begin
        At := StrPos(Value, '://');
        if At = 0 then
            exit(Value);
        Rest := CopyStr(Value, At + 3);
        Slash := StrPos(Rest, '/');
        if Slash = 0 then
            exit(CopyStr(Value, 1, At + 2) + '<host>');
        Rest := CopyStr(Rest, Slash + 1);
        Slash := StrPos(Rest + '/', '/');
        Q := StrPos(Rest + '?', '?');
        if Q < Slash then
            Slash := Q;
        exit(CopyStr(Value, 1, At + 2) + '<host>/<instance>' + CopyStr(Rest, Slash));
    end;

    [TryFunction]
    local procedure TryFive(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "SS UrlSvc Row"; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, Row);
    end;

    [TryFunction]
    local procedure TrySix(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "SS UrlSvc Row"; UseFilters: Boolean; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, Row, UseFilters);
    end;

    [TryFunction]
    local procedure TryFiveRef(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var RecRef: RecordRef; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, RecRef);
    end;

    [TryFunction]
    local procedure TrySixRef(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var RecRef: RecordRef; UseFilters: Boolean; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, RecRef, UseFilters);
    end;

    local procedure Five(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "SS UrlSvc Row"): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFive(Client, Company, ObjType, ObjId, Row, Result) then
            exit('ok|' + Host(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Six(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "SS UrlSvc Row"; UseFilters: Boolean): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TrySix(Client, Company, ObjType, ObjId, Row, UseFilters, Result) then
            exit('ok|' + Host(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure FiveRef(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var RecRef: RecordRef): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFiveRef(Client, Company, ObjType, ObjId, RecRef, Result) then
            exit('ok|' + Host(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure SixRef(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var RecRef: RecordRef; UseFilters: Boolean): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TrySixRef(Client, Company, ObjType, ObjId, RecRef, UseFilters, Result) then
            exit('ok|' + Host(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure ClientCases(var Observer: Codeunit "Probe Observer"; Client: ClientType)
    var
        Unread: Record "SS UrlSvc Row";
        Row: Record "SS UrlSvc Row";
        Filtered: Record "SS UrlSvc Row";
        RecRef: RecordRef;
    begin
        Row.Get(5);
        Filtered.SetRange(Tag, 2);
        Filtered.FindFirst();
        Observer.Observe('5 args, row, current company', Five(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('5 args, row, empty company', Five(Client, '', ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('5 args, row, unknown company', Five(Client, 'My Company', ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('5 args, unread record', Five(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Unread));
        Observer.Observe('5 args, filtered row', Five(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Filtered));
        Observer.Observe('5 args, codeunit', Five(Client, CompanyName(), ObjectType::Codeunit, Codeunit::"SS UrlSvc Record Tests", Row));
        Observer.Observe('6 args false, row', Six(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row, false));
        Observer.Observe('6 args true, row', Six(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row, true));
        Observer.Observe('6 args true, filtered row', Six(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Filtered, true));
        RecRef.GetTable(Row);
        Observer.Observe('5 args, recordref', FiveRef(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", RecRef));
        Observer.Observe('6 args true, recordref', SixRef(Client, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", RecRef, true));
    end;

    [Test]
    procedure GetUrl_ODataV4_ObjectAndRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ClientCases(Observer, ClientType::ODataV4);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_OData_ObjectAndRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ClientCases(Observer, ClientType::OData);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_SOAP_ObjectAndRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ClientCases(Observer, ClientType::SOAP);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Api_ObjectAndRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ClientCases(Observer, ClientType::Api);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_ODataV4_FiveArguments_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "SS UrlSvc Row";
    begin
        // The reported statement, outside a TryFunction: is the text empty?
        Initialize();
        Observer.Observe('unread record is empty text', Format(GetUrl(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row) = ''));
        Row.Get(5);
        Observer.Observe('row is empty text', Format(GetUrl(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row) = ''));
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_ServiceClients_PagePublishedAsTenantWebService()
    var
        Observer: Codeunit "Probe Observer";
        WebServiceManagement: Codeunit "Web Service Management";
        TenantWebService: Record "Tenant Web Service";
        Row: Record "SS UrlSvc Row";
    begin
        // The page is published as the tenant web service SSUrlSvcList for the length of this test (System Application's
        // Web Service Management.CreateTenantWebService); the row is deleted again before the test ends.
        Initialize();
        Row.Get(5);
        Observer.Observe('odatav4 before', Five(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"SS UrlSvc List", 'SSUrlSvcList', true);
        Observer.Observe('odatav4 4 args', 'ok|' + Host(GetUrl(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List")));
        Observer.Observe('odatav4 5 args', Five(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('odatav4 5 args, empty company', Five(ClientType::ODataV4, '', ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('odatav4 6 args false', Six(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row, false));
        Observer.Observe('odatav4 6 args true', Six(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row, true));
        Observer.Observe('odata 5 args', Five(ClientType::OData, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('soap 5 args', Five(ClientType::SOAP, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Observe('api 5 args', Five(ClientType::Api, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        if TenantWebService.Get(TenantWebService."Object Type"::Page, 'SSUrlSvcList') then
            TenantWebService.Delete();
        Observer.Observe('odatav4 after delete', Five(ClientType::ODataV4, CompanyName(), ObjectType::Page, Page::"SS UrlSvc List", Row));
        Observer.Finish();
    end;
}
