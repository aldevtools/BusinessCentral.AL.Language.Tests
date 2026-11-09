// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73981
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl with object type and id, without record: each object type, odd ids, other client types
// BC versions: 29
// Tag: P95

codeunit 73981 "LT P95 GetUrl Objects"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(Url: Text): Text
    begin
        exit(Format(Url <> '') + '|' + Format(Url.StartsWith('http')) + '|' + Format(Url.Contains('company=')) + '|' + Format(Url.Contains('page=')) + '|' + Format(Url.Contains('report=')) + '|' + Format(Url.Contains('codeunit=')) + '|' + Format(Url.Contains('table=')));
    end;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;


    [TryFunction]
    local procedure TryO(CT: ClientType; OT: ObjectType; Id: Integer; var R: Text)
    begin
        R := GetUrl(CT, CompanyName(), OT, Id);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; CT: ClientType; OT: ObjectType; Id: Integer)
    var
        R: Text;
    begin
        if TryO(CT, OT, Id, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_Object_Types_Web()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'page', ClientType::Web, ObjectType::Page, 21);
        One(Observer, 'report', ClientType::Web, ObjectType::Report, 101);
        One(Observer, 'codeunit', ClientType::Web, ObjectType::Codeunit, 1);
        One(Observer, 'table', ClientType::Web, ObjectType::Table, 18);
        One(Observer, 'query', ClientType::Web, ObjectType::Query, 100);
        One(Observer, 'xmlport', ClientType::Web, ObjectType::XMLport, 1);
        Observer.Expect('page', 'Yes|Yes|Yes|Yes|No|No|No|?company=<Company>&page=21');
        Observer.Expect('report', 'Yes|Yes|Yes|No|Yes|No|No|?company=<Company>&report=101');
        Observer.Expect('codeunit', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('table', 'Yes|Yes|Yes|No|No|No|Yes|?company=<Company>&table=18');
        Observer.Expect('query', 'Yes|Yes|Yes|No|No|No|No|?company=<Company>&query=100');
        Observer.Expect('xmlport', 'No|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Object_Ids_Web()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'page_zero', ClientType::Web, ObjectType::Page, 0);
        One(Observer, 'page_negative', ClientType::Web, ObjectType::Page, -1);
        One(Observer, 'page_missing', ClientType::Web, ObjectType::Page, 2147483647);
        One(Observer, 'page_unused_id', ClientType::Web, ObjectType::Page, 73999);
        One(Observer, 'report_missing', ClientType::Web, ObjectType::Report, 2147483647);
        One(Observer, 'codeunit_zero', ClientType::Web, ObjectType::Codeunit, 0);
        One(Observer, 'table_zero', ClientType::Web, ObjectType::Table, 0);
        One(Observer, 'table_missing', ClientType::Web, ObjectType::Table, 2147483647);
        Observer.Expect('page_zero', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('page_negative', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('page_missing', 'Yes|Yes|Yes|Yes|No|No|No|?company=<Company>&page=2147483647');
        Observer.Expect('page_unused_id', 'Yes|Yes|Yes|Yes|No|No|No|?company=<Company>&page=73999');
        Observer.Expect('report_missing', 'Yes|Yes|Yes|No|Yes|No|No|?company=<Company>&report=2147483647');
        Observer.Expect('codeunit_zero', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('table_zero', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('table_missing', 'Yes|Yes|Yes|No|No|No|Yes|?company=<Company>&table=2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Object_Types_OtherClients()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'tablet_page', ClientType::Tablet, ObjectType::Page, 21);
        One(Observer, 'phone_page', ClientType::Phone, ObjectType::Page, 21);
        One(Observer, 'desktop_page', ClientType::Desktop, ObjectType::Page, 21);
        One(Observer, 'default_page', ClientType::Default, ObjectType::Page, 21);
        One(Observer, 'soap_page', ClientType::SOAP, ObjectType::Page, 21);
        One(Observer, 'soap_codeunit', ClientType::SOAP, ObjectType::Codeunit, 1);
        One(Observer, 'odata_page', ClientType::OData, ObjectType::Page, 21);
        One(Observer, 'odata_table', ClientType::OData, ObjectType::Table, 18);
        One(Observer, 'odatav4_page', ClientType::ODataV4, ObjectType::Page, 21);
        One(Observer, 'api_page', ClientType::Api, ObjectType::Page, 21);
        One(Observer, 'web_report_tablet', ClientType::Tablet, ObjectType::Report, 101);
        Observer.Expect('tablet_page', 'Yes|No|Yes|Yes|No|No|No|?company=<Company>&page=21');
        Observer.Expect('phone_page', 'Yes|No|Yes|Yes|No|No|No|?company=<Company>&page=21');
        Observer.Expect('desktop_page', 'Yes|No|Yes|Yes|No|No|No|?company=<Company>&page=21');
        Observer.Expect('default_page', 'Yes|No|No|Yes|No|No|No|?page=21');
        Observer.Expect('soap_page', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('soap_codeunit', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('odata_page', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('odata_table', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('odatav4_page', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('api_page', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('web_report_tablet', 'Yes|No|Yes|No|Yes|No|No|?company=<Company>&report=101');
        Observer.Verify();
    end;

    // Corpus issue 670 (writer CY): GetUrl with a record and UseFilters for the service client types, and with an object type but no object id.
    [TryFunction]
    local procedure TryRec(CT: ClientType; OT: ObjectType; Id: Integer; var Cust: Record Customer; UseFilters: Boolean; var R: Text)
    begin
        R := GetUrl(CT, CompanyName(), OT, Id, Cust, UseFilters);
    end;

    local procedure OneRec(var Observer: Codeunit "Probe Observer"; Name: Text; CT: ClientType; OT: ObjectType; Id: Integer; UseFilters: Boolean)
    var
        Cust: Record Customer;
        R: Text;
    begin
        Cust."No." := 'CYX';
        Cust.SetRange("No.", 'CYA', 'CYZ');
        ClearLastError();
        if TryRec(CT, OT, Id, Cust, UseFilters, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [TryFunction]
    local procedure TryTypeOnly(CT: ClientType; OT: ObjectType; var R: Text)
    begin
        R := GetUrl(CT, CompanyName(), OT);
    end;

    local procedure OneTypeOnly(var Observer: Codeunit "Probe Observer"; Name: Text; CT: ClientType; OT: ObjectType)
    var
        R: Text;
    begin
        ClearLastError();
        if TryTypeOnly(CT, OT, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure CY_GetUrl_ServiceClients_UseFilters_And_TypeWithoutId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneRec(Observer, 'web_filters', ClientType::Web, ObjectType::Page, 21, true);
        OneRec(Observer, 'soap_filters', ClientType::SOAP, ObjectType::Page, 21, true);
        OneRec(Observer, 'soap_nofilters', ClientType::SOAP, ObjectType::Page, 21, false);
        OneRec(Observer, 'odata_filters', ClientType::OData, ObjectType::Page, 21, true);
        OneRec(Observer, 'odatav4_filters', ClientType::ODataV4, ObjectType::Page, 21, true);
        OneRec(Observer, 'api_filters', ClientType::Api, ObjectType::Page, 21, true);
        OneRec(Observer, 'web_table_filters', ClientType::Web, ObjectType::Table, 18, true);
        OneTypeOnly(Observer, 'web_page_no_id', ClientType::Web, ObjectType::Page);
        OneTypeOnly(Observer, 'web_report_no_id', ClientType::Web, ObjectType::Report);
        OneTypeOnly(Observer, 'soap_page_no_id', ClientType::SOAP, ObjectType::Page);
        Observer.Expect('web_filters', 'Yes|Yes|Yes|Yes|No|No|No|?company=<Company>&page=21&filter=%27No.%27%20IS%20%27CYA..CYZ%27');
        Observer.Expect('soap_filters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('soap_nofilters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('odata_filters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('odatav4_filters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('api_filters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('web_table_filters', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('web_page_no_id', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('web_report_no_id', 'No|No|No|No|No|No|No|noquery');
        Observer.Expect('soap_page_no_id', 'No|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    // GetUrl with the client type given by DefaultClientType() (a function, not the enum value), a page, a record or a RecordRef, and UseFilters
    // true or false (al-runner issue 7370); ClientType::Default and Windows beside it.
    [TryFunction]
    local procedure TryRecRef(CT: ClientType; OT: ObjectType; Id: Integer; var Cust: Record Customer; UseFilters: Boolean; var R: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Cust);
        R := GetUrl(CT, CompanyName(), OT, Id, RecRef, UseFilters);
    end;

    local procedure DefaultCT(Name: Text; Kind: Integer; UseFilters: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Cust: Record Customer;
        R: Text;
        Ok: Boolean;
    begin
        Cust."No." := 'CYX';
        Cust.SetRange("No.", 'CYA', 'CYZ');
        ClearLastError();
        case Kind of
            1:
                Ok := TryRec(DefaultClientType(), ObjectType::Page, 21, Cust, UseFilters, R);
            2:
                Ok := TryRecRef(DefaultClientType(), ObjectType::Page, 21, Cust, UseFilters, R);
            4:
                Ok := TryRecRef(ClientType::Default, ObjectType::Page, 21, Cust, UseFilters, R);
            5:
                Ok := TryRecRef(ClientType::Windows, ObjectType::Page, 21, Cust, UseFilters, R);
            6:
                Ok := TryRec(ClientType::Default, ObjectType::Page, 21, Cust, UseFilters, R);
            7:
                Ok := TryRec(ClientType::Windows, ObjectType::Page, 21, Cust, UseFilters, R);
            8:
                Ok := TryRecRef(Session.DefaultClientType(), ObjectType::Page, 21, Cust, UseFilters, R);
            9:
                Ok := TryRecRef(DefaultClientType(), ObjectType::Report, 101, Cust, UseFilters, R);
            10:
                Ok := TryRecRef(ClientType::Web, ObjectType::Page, 21, Cust, UseFilters, R);
        end;
        if Ok then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_DefaultClientTypeFunction_PageRecord_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DefaultCT('fn_record_true', 1, true, Observer);
        DefaultCT('fn_record_false', 1, false, Observer);
        DefaultCT('fn_recref_true', 2, true, Observer);
        DefaultCT('fn_recref_false', 2, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_DefaultClientTypeFunction_PageRecord_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DefaultCT('enum_default_recref_true', 4, true, Observer);
        DefaultCT('enum_default_recref_false', 4, false, Observer);
        DefaultCT('enum_windows_recref_true', 5, true, Observer);
        DefaultCT('enum_windows_recref_false', 5, false, Observer);
        DefaultCT('enum_default_record_true', 6, true, Observer);
        DefaultCT('enum_windows_record_true', 7, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_DefaultClientTypeFunction_PageRecord_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DefaultCT('session_fn_recref_true', 8, true, Observer);
        DefaultCT('fn_report_recref_true', 9, true, Observer);
        DefaultCT('fn_report_recref_false', 9, false, Observer);
        DefaultCT('web_recref_true', 10, true, Observer);
        Observer.Observe('default_client_type', Format(DefaultClientType()));
        Observer.Finish();
    end;

    // GetUrl with a page id of 0 or a negative id, with a record and UseFilters (al-runner 7429: ClientType ODataV4, the id comes from a setup row).
    local procedure ZeroId(Name: Text; CT: ClientType; OT: ObjectType; Id: Integer; UseFilters: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Cust: Record Customer;
        R: Text;
    begin
        Cust."No." := 'CYX';
        Cust.SetRange("No.", 'CYA', 'CYZ');
        ClearLastError();
        if TryRecRef(CT, OT, Id, Cust, UseFilters, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_ObjectIdZero_Record_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ZeroId('odatav4_page0_true', ClientType::ODataV4, ObjectType::Page, 0, true, Observer);
        ZeroId('odatav4_page0_false', ClientType::ODataV4, ObjectType::Page, 0, false, Observer);
        ZeroId('odatav4_page21_true', ClientType::ODataV4, ObjectType::Page, 21, true, Observer);
        ZeroId('odata_page0_true', ClientType::OData, ObjectType::Page, 0, true, Observer);
        ZeroId('soap_page0_true', ClientType::SOAP, ObjectType::Page, 0, true, Observer);
        ZeroId('api_page0_true', ClientType::Api, ObjectType::Page, 0, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_ObjectIdZero_Record_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ZeroId('web_page0_true', ClientType::Web, ObjectType::Page, 0, true, Observer);
        ZeroId('web_page0_false', ClientType::Web, ObjectType::Page, 0, false, Observer);
        ZeroId('web_pageneg1_true', ClientType::Web, ObjectType::Page, -1, true, Observer);
        ZeroId('web_report0_true', ClientType::Web, ObjectType::Report, 0, true, Observer);
        ZeroId('web_table0_true', ClientType::Web, ObjectType::Table, 0, true, Observer);
        ZeroId('default_page0_true', ClientType::Default, ObjectType::Page, 0, true, Observer);
        ZeroId('windows_page0_true', ClientType::Windows, ObjectType::Page, 0, true, Observer);
        ZeroId('tablet_page0_true', ClientType::Tablet, ObjectType::Page, 0, true, Observer);
        Observer.Finish();
    end;
}
