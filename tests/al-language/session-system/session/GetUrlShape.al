// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74974, test codeunit 74975
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the shape of GetUrl results relative to the base address (the host part differs per environment and is replaced by <base>): company forms, object and record query parts, the client types, and the result inside a trigger.
// BC versions: 29 (27 and 28 by CI)

table 74974 "LT GU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74975 "LT GetUrl Shape"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryUrl(Client: ClientType; Company: Text; var Result: Text)
    begin
        Result := GetUrl(Client, Company);
    end;

    [TryFunction]
    local procedure TryUrlObject(Company: Text; ObjType: ObjectType; ObjId: Integer; var Result: Text)
    begin
        Result := GetUrl(ClientType::Web, Company, ObjType, ObjId);
    end;

    [TryFunction]
    local procedure TryUrlRecord(Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT GU Row"; var Result: Text)
    begin
        Result := GetUrl(ClientType::Web, Company, ObjType, ObjId, Row);
    end;

    // The environment's address is replaced by <base>: every result starts with the result of GetUrl(ClientType::Web) cut at its first '?' or after its last '/'.
    local procedure Base(): Text
    var
        Full: Text;
        At: Integer;
    begin
        Full := GetUrl(ClientType::Web);
        At := StrPos(Full, '?');
        if At > 0 then
            Full := CopyStr(Full, 1, At - 1);
        exit(Full);
    end;

    local procedure Shape(Value: Text): Text
    var
        B: Text;
    begin
        B := Base();
        if B <> '' then
            Value := Value.Replace(B, '<base>');
        exit(Value);
    end;

    local procedure UrlOf(Client: ClientType; Company: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryUrl(Client, Company, Result) then
            exit('ok|' + Shape(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure UrlObjOf(Company: Text; ObjType: ObjectType; ObjId: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryUrlObject(Company, ObjType, ObjId, Result) then
            exit('ok|' + Shape(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure UrlRecOf(Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT GU Row"): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryUrlRecord(Company, ObjType, ObjId, Row, Result) then
            exit('ok|' + Shape(Result));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure GetUrl_Web_CompanyForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_company_arg', Shape(GetUrl(ClientType::Web)));
        Observer.Observe('current', Format(UrlOf(ClientType::Web, CompanyName()) = 'ok|' + Shape(GetUrl(ClientType::Web, CompanyName()))));
        Observer.Observe('empty_string', UrlOf(ClientType::Web, ''));
        Observer.Observe('name_with_space', UrlOf(ClientType::Web, 'My Company'));
        Observer.Observe('name_with_ampersand', UrlOf(ClientType::Web, 'A&B'));
        Observer.Observe('name_with_quote', UrlOf(ClientType::Web, 'O''Neil'));
        Observer.Observe('name_with_slash', UrlOf(ClientType::Web, 'A/B'));
        Observer.Observe('name_with_umlaut', UrlOf(ClientType::Web, 'Müller'));
        Observer.Expect('no_company_arg', '<base>');
        Observer.Expect('current', 'Yes');
        Observer.Expect('empty_string', 'ok|<base>');
        Observer.Expect('name_with_space', 'ok|<base>/?company=My%20Company');
        Observer.Expect('name_with_ampersand', 'ok|<base>/?company=A%26B');
        Observer.Expect('name_with_quote', 'ok|<base>/?company=O%27Neil');
        Observer.Expect('name_with_slash', 'ok|<base>/?company=A%2FB');
        Observer.Expect('name_with_umlaut', 'ok|<base>/?company=M%C3%BCller');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_CurrentCompanyShape()
    var
        Observer: Codeunit "Probe Observer";
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web, CompanyName());
        Observer.Observe('starts_with_base', Format(Url.StartsWith(Base())));
        Observer.Observe('rest_prefix', CopyStr(Url, StrLen(Base()) + 1, 9));
        Observer.Observe('contains_company_name_encoded', Format(Url.Contains(CompanyName().Replace(' ', '%20'))));
        Observer.Expect('starts_with_base', 'Yes');
        Observer.Expect('rest_prefix', '/?company');
        Observer.Expect('contains_company_name_encoded', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_ObjectTypesAndIds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('page_21', UrlObjOf('', ObjectType::Page, 21));
        Observer.Observe('page_company', UrlObjOf('My Company', ObjectType::Page, 21));
        Observer.Observe('report_6', UrlObjOf('', ObjectType::Report, 6));
        Observer.Observe('codeunit_80', UrlObjOf('', ObjectType::Codeunit, 80));
        Observer.Observe('table_18', UrlObjOf('', ObjectType::Table, 18));
        Observer.Observe('query_9150', UrlObjOf('', ObjectType::Query, 9150));
        Observer.Observe('xmlport_1', UrlObjOf('', ObjectType::XMLport, 1));
        Observer.Observe('page_zero', UrlObjOf('', ObjectType::Page, 0));
        Observer.Observe('page_unknown', UrlObjOf('', ObjectType::Page, 99999999));
        Observer.Expect('page_21', 'ok|<base>/?page=21');
        Observer.Expect('page_company', 'ok|<base>/?company=My%20Company&page=21');
        Observer.Expect('report_6', 'ok|<base>/?report=6');
        Observer.Expect('codeunit_80', 'ok|');
        Observer.Expect('table_18', 'ok|<base>/?table=18');
        Observer.Expect('query_9150', 'ok|<base>/?query=9150');
        Observer.Expect('xmlport_1', 'ok|');
        Observer.Expect('page_zero', 'ok|');
        Observer.Expect('page_unknown', 'ok|<base>/?page=99999999');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_WithRecord()
    var
        Row: Record "LT GU Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Id := 5;
        Row.Name := 'five';
        Observer.Observe('page_record', UrlRecOf('', ObjectType::Page, 21, Row));
        Observer.Observe('table_record', UrlRecOf('', ObjectType::Table, 74974, Row));
        Observer.Observe('page_record_company', UrlRecOf('My Company', ObjectType::Page, 21, Row));
        Row.Id := 0;
        Observer.Observe('blank_key', UrlRecOf('', ObjectType::Page, 21, Row));
        Observer.Expect('page_record', 'ok|<base>/?page=21&bookmark=12%3b3iQBAACHBQ%3d%3d');
        Observer.Expect('table_record', 'ok|');
        Observer.Expect('page_record_company', 'ok|<base>/?company=My%20Company&page=21&bookmark=12%3b3iQBAACHBQ%3d%3d');
        Observer.Expect('blank_key', 'ok|<base>/?page=21&bookmark=12%3b3iQBAACH');
        Observer.Verify();
    end;

    local procedure SchemeOf(Client: ClientType): Text
    var
        Result: Text;
        At: Integer;
    begin
        ClearLastError();
        if not TryUrl(Client, '', Result) then
            exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
        At := StrPos(Result, '://');
        if At = 0 then
            exit('ok|no scheme|empty=' + Format(Result = ''));
        exit('ok|' + CopyStr(Result, 1, At + 2));
    end;

    // The host, ports and path of the other client types belong to the environment: only the scheme (or the empty result) is asserted.
    [Test]
    procedure GetUrl_OtherClientTypes_SchemeOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('phone', SchemeOf(ClientType::Phone));
        Observer.Observe('tablet', SchemeOf(ClientType::Tablet));
        Observer.Observe('desktop', SchemeOf(ClientType::Desktop));
        Observer.Observe('default', SchemeOf(ClientType::Default));
        Observer.Observe('background', SchemeOf(ClientType::Background));
        Observer.Observe('management', SchemeOf(ClientType::Management));
        Observer.Expect('phone', 'ok|ms-dynamicsnav://');
        Observer.Expect('tablet', 'ok|ms-dynamicsnav://');
        Observer.Expect('desktop', 'ok|ms-dynamicsnav://');
        Observer.Expect('default', 'ok|dynamicsnav://');
        Observer.Expect('background', 'ok|no scheme|empty=Yes');
        Observer.Expect('management', 'ok|no scheme|empty=Yes');
        Observer.Verify();
    end;

    // al-runtime-rs probes-needed row geturl-web-base-address (writer QA, 2026-10-20): GetUrl(ClientType::Web) with no argument, taken apart as
    // scheme | host | port | path | query. The host name differs per environment, so it is reported only as: empty, localhost, or <host> (any other
    // name), and whether it is in lower case; a port as <port> (the CI container's ports); the rest is reported as it is.
    local procedure WebParts(Url: Text): Text
    var
        Scheme: Text;
        Rest: Text;
        HostPort: Text;
        HostName: Text;
        Port: Text;
        PathPart: Text;
        Query: Text;
        HostShown: Text;
        PortShown: Text;
        At: Integer;
    begin
        At := StrPos(Url, '://');
        if At = 0 then
            exit('no scheme|' + Format(StrLen(Url)));
        Scheme := CopyStr(Url, 1, At - 1);
        Rest := CopyStr(Url, At + 3);
        At := StrPos(Rest, '?');
        if At > 0 then begin
            Query := CopyStr(Rest, At);
            Rest := CopyStr(Rest, 1, At - 1);
        end;
        At := StrPos(Rest, '/');
        if At > 0 then begin
            HostPort := CopyStr(Rest, 1, At - 1);
            PathPart := CopyStr(Rest, At);
        end else
            HostPort := Rest;
        At := StrPos(HostPort, ':');
        if At > 0 then begin
            HostName := CopyStr(HostPort, 1, At - 1);
            Port := CopyStr(HostPort, At + 1);
        end else
            HostName := HostPort;
        if Port <> '' then
            PortShown := '<port>';
        case true of
            HostName = '':
                HostShown := '<empty>';
            HostName = 'localhost':
                HostShown := 'localhost';
            else
                HostShown := '<host>';
        end;
        exit(Scheme + '|' + HostShown + '|lower=' + Format(HostName = LowerCase(HostName)) + '|port=' + PortShown + '|path=' + PathPart + '|query=' + Query);
    end;

    [Test]
    procedure QA_GetUrl_Web_NoArgument_Whole()
    var
        Observer: Codeunit "Probe Observer";
        Full: Text;
    begin
        Full := GetUrl(ClientType::Web);
        Observer.Observe('web alone', WebParts(Full));
        Observer.Observe('web alone ends with /', Format(Full.EndsWith('/')));
        Observer.Observe('web empty company equal', Format(GetUrl(ClientType::Web, '') = Full));
        Observer.Observe('web company starts with it', Format(GetUrl(ClientType::Web, CompanyName()).StartsWith(Full)));
        Observer.Observe('web company', WebParts(GetUrl(ClientType::Web, CompanyName())).Replace(CompanyName().Replace(' ', '%20'), '<company>'));
        Observer.Observe('web page', WebParts(GetUrl(ClientType::Web, '', ObjectType::Page, 21)));
        Observer.Observe('default alone', WebParts(GetUrl(ClientType::Default)));
        Observer.Expect('web alone', 'http|<host>|lower=Yes|port=<port>|path=/BC|query=');
        Observer.Expect('web alone ends with /', 'No');
        Observer.Expect('web empty company equal', 'Yes');
        Observer.Expect('web company starts with it', 'Yes');
        Observer.Expect('web company', 'http|<host>|lower=Yes|port=<port>|path=/BC/|query=?company=<company>');
        Observer.Expect('web page', 'http|<host>|lower=Yes|port=<port>|path=/BC/|query=?page=21');
        Observer.Expect('default alone', 'dynamicsnav|<host>|lower=Yes|port=<port>|path=/BC//|query=');
        Observer.Verify();
    end;
}
