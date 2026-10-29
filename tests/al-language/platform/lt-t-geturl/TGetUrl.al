// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 69377-69380, query 69376, test codeunit 69381; report 69367 and codeunit 69366 of lt-t-validate-layout
// Facts: GetUrl text for every client type (Default, Web, Windows, Phone, Tablet, Desktop) with and without company, object and record; special characters in the company and in a filter; Report, Query and Codeunit
// with a record; the bookmark of Code[10], Code[50] and two-Code-field keys. The server address (the GetUrl(ClientType::Web) text up to the first ?) is replaced by <base>.
// Writer TV (2026-10-29, TV_* tests): the same texts for the client types SOAP, OData, ODataV4 and Api.
// BC versions: 27.0 and later

table 69377 "LT T Url Code10"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; K) { Clustered = true; } }
}

table 69378 "LT T Url Code50"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[50]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; K) { Clustered = true; } }
}

table 69379 "LT T Url Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Code[20]) { }
        field(2; K2; Code[20]) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; K1, K2) { Clustered = true; } }
}

table 69380 "LT T Url Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 69376 "LT T Url Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT T Url Row")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 69381 "LT T GetUrl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

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
        exit(Host(Value));
    end;

    // A non-Web address (dynamicsnav://host:port/BC...) has the container's host and port: they become <host>.
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
    local procedure TryCompany(Client: ClientType; Company: Text; var Result: Text)
    begin
        Result := GetUrl(Client, Company);
    end;

    [TryFunction]
    local procedure TryObject(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId);
    end;

    [TryFunction]
    local procedure TryRecord(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT T Url Row"; UseFilters: Boolean; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, Row, UseFilters);
    end;

    local procedure Company(Client: ClientType; Name: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryCompany(Client, Name, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Obj(Client: ClientType; Name: Text; ObjType: ObjectType; ObjId: Integer): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryObject(Client, Name, ObjType, ObjId, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Rec(Client: ClientType; Name: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT T Url Row"; UseFilters: Boolean): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryRecord(Client, Name, ObjType, ObjId, Row, UseFilters, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Seed(var Row: Record "LT T Url Row")
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'Alpha';
        Row.Insert();
    end;

    local procedure ClientTest(Client: ClientType; Tag: Text)
    var
        Row: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Observer.Observe(Tag + ' alone', Shape(GetUrl(Client)));
        Observer.Observe(Tag + ' company', Company(Client, 'My Company'));
        Observer.Observe(Tag + ' empty company', Company(Client, ''));
        Observer.Observe(Tag + ' page', Obj(Client, '', ObjectType::Page, 21));
        Observer.Observe(Tag + ' company page', Obj(Client, 'My Company', ObjectType::Page, 21));
        Observer.Observe(Tag + ' company report', Obj(Client, 'My Company', ObjectType::Report, 69367));
        Observer.Observe(Tag + ' company page record', Rec(Client, 'My Company', ObjectType::Page, 21, Row, false));
        Observer.Observe(Tag + ' page record no company', Rec(Client, '', ObjectType::Page, 21, Row, false));
    end;

    [Test]
    procedure GetUrl_ClientDefault()
    begin
        ClientTest(ClientType::Default, 'default');
        Observer.Expect('default alone', 'dynamicsnav://<host>/<instance>//');
        Observer.Expect('default company', 'ok|dynamicsnav://<host>/<instance>/My%20Company/');
        Observer.Expect('default empty company', 'ok|dynamicsnav://<host>/<instance>//');
        Observer.Expect('default page', 'ok|dynamicsnav://<host>/<instance>//runpage?page=21');
        Observer.Expect('default company page', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runpage?page=21');
        Observer.Expect('default company report', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runreport?report=69367');
        Observer.Expect('default company page record', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runpage?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('default page record no company', 'ok|dynamicsnav://<host>/<instance>//runpage?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_ClientWeb()
    begin
        ClientTest(ClientType::Web, 'web');
        Observer.Expect('web alone', '<base>');
        Observer.Expect('web company', 'ok|<base>/?company=My%20Company');
        Observer.Expect('web empty company', 'ok|<base>');
        Observer.Expect('web page', 'ok|<base>/?page=21');
        Observer.Expect('web company page', 'ok|<base>/?company=My%20Company&page=21');
        Observer.Expect('web company report', 'ok|<base>/?company=My%20Company&report=69367');
        Observer.Expect('web company page record', 'ok|<base>/?company=My%20Company&page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('web page record no company', 'ok|<base>/?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_ClientWindows()
    begin
        ClientTest(ClientType::Windows, 'windows');
        Observer.Expect('windows alone', 'dynamicsnav://<host>/<instance>//');
        Observer.Expect('windows company', 'ok|dynamicsnav://<host>/<instance>/My%20Company/');
        Observer.Expect('windows empty company', 'ok|dynamicsnav://<host>/<instance>//');
        Observer.Expect('windows page', 'ok|dynamicsnav://<host>/<instance>//runpage?page=21');
        Observer.Expect('windows company page', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runpage?page=21');
        Observer.Expect('windows company report', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runreport?report=69367');
        Observer.Expect('windows company page record', 'ok|dynamicsnav://<host>/<instance>/My%20Company/runpage?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('windows page record no company', 'ok|dynamicsnav://<host>/<instance>//runpage?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_ClientPhone()
    begin
        ClientTest(ClientType::Phone, 'phone');
        Observer.Expect('phone alone', 'ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('phone company', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company');
        Observer.Expect('phone empty company', 'ok|ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('phone page', 'ok|ms-dynamicsnav://<host>/<instance>?page=21');
        Observer.Expect('phone company page', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21');
        Observer.Expect('phone company report', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&report=69367');
        Observer.Expect('phone company page record', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('phone page record no company', 'ok|ms-dynamicsnav://<host>/<instance>?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_ClientTablet()
    begin
        ClientTest(ClientType::Tablet, 'tablet');
        Observer.Expect('tablet alone', 'ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('tablet company', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company');
        Observer.Expect('tablet empty company', 'ok|ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('tablet page', 'ok|ms-dynamicsnav://<host>/<instance>?page=21');
        Observer.Expect('tablet company page', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21');
        Observer.Expect('tablet company report', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&report=69367');
        Observer.Expect('tablet company page record', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('tablet page record no company', 'ok|ms-dynamicsnav://<host>/<instance>?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_ClientDesktop()
    begin
        ClientTest(ClientType::Desktop, 'desktop');
        Observer.Expect('desktop alone', 'ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('desktop company', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company');
        Observer.Expect('desktop empty company', 'ok|ms-dynamicsnav://<host>/<instance>');
        Observer.Expect('desktop page', 'ok|ms-dynamicsnav://<host>/<instance>?page=21');
        Observer.Expect('desktop company page', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21');
        Observer.Expect('desktop company report', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&report=69367');
        Observer.Expect('desktop company page record', 'ok|ms-dynamicsnav://<host>/<instance>?company=My%20Company&page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Expect('desktop page record no company', 'ok|ms-dynamicsnav://<host>/<instance>?page=21&bookmark=12%3bBA8BAACHBQ%3d%3d');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_CompanyCharacters()
    begin
        Observer.Observe('comma', Company(ClientType::Web, 'CRONUS USA, Inc.'));
        Observer.Observe('underscore', Company(ClientType::Web, 'A_B'));
        Observer.Observe('parentheses', Company(ClientType::Web, 'A(B)'));
        Observer.Observe('semicolon', Company(ClientType::Web, 'A;B'));
        Observer.Observe('colon', Company(ClientType::Web, 'A:B'));
        Observer.Observe('plus', Company(ClientType::Web, 'A+B'));
        Observer.Observe('at', Company(ClientType::Web, 'A@B'));
        Observer.Observe('exclamation', Company(ClientType::Web, 'A!B'));
        Observer.Observe('hash', Company(ClientType::Web, 'A#B'));
        Observer.Observe('percent', Company(ClientType::Web, 'A%B'));
        Observer.Observe('equals', Company(ClientType::Web, 'A=B'));
        Observer.Observe('question', Company(ClientType::Web, 'A?B'));
        Observer.Observe('dash dot tilde', Company(ClientType::Web, 'A-B.C~D'));
        Observer.Observe('star dollar', Company(ClientType::Web, 'A*B$C'));
        Observer.Observe('brackets', Company(ClientType::Web, 'A[B]{C}'));
        Observer.Observe('backslash', Company(ClientType::Web, 'A\B'));
        Observer.Observe('less greater', Company(ClientType::Web, 'A<B>C'));
        Observer.Observe('pipe caret', Company(ClientType::Web, 'A|B^C'));
        Observer.Observe('double quote', Company(ClientType::Web, 'A"B'));
        Observer.Observe('plus in object url', Obj(ClientType::Web, 'A+B,C', ObjectType::Page, 21));
        Observer.Expect('comma', 'ok|<base>/?company=CRONUS%20USA%2C%20Inc.');
        Observer.Expect('underscore', 'ok|<base>/?company=A_B');
        Observer.Expect('parentheses', 'ok|<base>/?company=A%28B%29');
        Observer.Expect('semicolon', 'ok|<base>/?company=A%3BB');
        Observer.Expect('colon', 'ok|<base>/?company=A%3AB');
        Observer.Expect('plus', 'ok|<base>/?company=A%2BB');
        Observer.Expect('at', 'ok|<base>/?company=A%40B');
        Observer.Expect('exclamation', 'ok|<base>/?company=A%21B');
        Observer.Expect('hash', 'ok|<base>/?company=A%23B');
        Observer.Expect('percent', 'ok|<base>/?company=A%25B');
        Observer.Expect('equals', 'ok|<base>/?company=A%3DB');
        Observer.Expect('question', 'ok|<base>/?company=A%3FB');
        Observer.Expect('dash dot tilde', 'ok|<base>/?company=A-B.C~D');
        Observer.Expect('star dollar', 'ok|<base>/?company=A%2AB%24C');
        Observer.Expect('brackets', 'ok|<base>/?company=A%5BB%5D%7BC%7D');
        Observer.Expect('backslash', 'ok|<base>/?company=A%5CB');
        Observer.Expect('less greater', 'ok|<base>/?company=A%3CB%3EC');
        Observer.Expect('pipe caret', 'ok|<base>/?company=A%7CB%5EC');
        Observer.Expect('double quote', 'ok|<base>/?company=A%22B');
        Observer.Expect('plus in object url', 'ok|<base>/?company=A%2BB%2CC&page=21');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_FilterCharacters()
    var
        Row: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Row.SetFilter(Name, '%1', 'A,B');
        Observer.Observe('comma', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A_B');
        Observer.Observe('underscore', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A(B)');
        Observer.Observe('parentheses', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A;B');
        Observer.Observe('semicolon', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A:B');
        Observer.Observe('colon', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A+B');
        Observer.Observe('plus', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A@B');
        Observer.Observe('at', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A!B');
        Observer.Observe('exclamation', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, 'A*|B..C');
        Observer.Observe('filter expression', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Observer.Expect('comma', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%2CB%27');
        Observer.Expect('underscore', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A_B%27');
        Observer.Expect('parentheses', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27%27%27A%28B%29%27%27%27');
        Observer.Expect('semicolon', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%3BB%27');
        Observer.Expect('colon', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%3AB%27');
        Observer.Expect('plus', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%2BB%27');
        Observer.Expect('at', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%40B%27');
        Observer.Expect('exclamation', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%21B%27');
        Observer.Expect('filter expression', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27A%2A%7CB..C%27');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_ReportQueryCodeunitWithRecord()
    var
        Row: Record "LT T Url Row";
        Rep: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Observer.Observe('report', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Row, false));
        Observer.Observe('query', Rec(ClientType::Web, 'My Company', ObjectType::Query, 69376, Row, false));
        Observer.Observe('codeunit', Rec(ClientType::Web, 'My Company', ObjectType::Codeunit, 69366, Row, false));
        Observer.Observe('table', Rec(ClientType::Web, 'My Company', ObjectType::Table, 69380, Row, false));
        Observer.Observe('report no company', Rec(ClientType::Web, '', ObjectType::Report, 69367, Row, false));
        Observer.Observe('query no company', Rec(ClientType::Web, '', ObjectType::Query, 69376, Row, false));
        Observer.Observe('codeunit no company', Rec(ClientType::Web, '', ObjectType::Codeunit, 69366, Row, false));
        Rep.SetRange(Name, 'Alpha');
        Observer.Observe('report with filter', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Rep, false));
        Observer.Observe('report with filter use filters', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Rep, true));
        Observer.Observe('page with filter use filters', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Rep, true));
        Observer.Observe('report without record', Obj(ClientType::Web, 'My Company', ObjectType::Report, 69367));
        Observer.Observe('query without record', Obj(ClientType::Web, 'My Company', ObjectType::Query, 69376));
        Observer.Observe('codeunit without record', Obj(ClientType::Web, 'My Company', ObjectType::Codeunit, 69366));
        Observer.Expect('report', 'ok|');
        Observer.Expect('query', 'ok|');
        Observer.Expect('codeunit', 'ok|');
        Observer.Expect('table', 'ok|');
        Observer.Expect('report no company', 'ok|');
        Observer.Expect('query no company', 'ok|');
        Observer.Expect('codeunit no company', 'ok|');
        Observer.Expect('report with filter', 'ok|');
        Observer.Expect('report with filter use filters', 'ok|');
        Observer.Expect('page with filter use filters', 'ok|<base>/?company=My%20Company&page=21&filter=%27Name%27%20IS%20%27Alpha%27');
        Observer.Expect('report without record', 'ok|<base>/?company=My%20Company&report=69367');
        Observer.Expect('query without record', 'ok|<base>/?company=My%20Company&query=69376');
        Observer.Expect('codeunit without record', 'ok|');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Web_BookmarkOfCodeKeys()
    var
        C10: Record "LT T Url Code10";
        C50: Record "LT T Url Code50";
        Two: Record "LT T Url Two";
    begin
        C10.DeleteAll();
        C50.DeleteAll();
        Two.DeleteAll();
        C10.K := 'A1';
        C10.Insert();
        Observer.Observe('code10 short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C10, false)));
        C10.K := 'ABCDEFGHIJ';
        C10.Insert();
        Observer.Observe('code10 full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C10, false)));
        C50.K := 'A1';
        C50.Insert();
        Observer.Observe('code50 short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        C50.K := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMN';
        C50.Insert();
        Observer.Observe('code50 full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        C50.K := 'A-B_C.D';
        C50.Insert();
        Observer.Observe('code50 symbols', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        Two.K1 := 'A1';
        Two.K2 := 'B2';
        Two.Insert();
        Observer.Observe('two short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := 'ABCDEFGHIJKLMNOPQRST';
        Two.K2 := 'UVWXYZ0123456789ABCD';
        Two.Insert();
        Observer.Observe('two full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := 'A';
        Two.K2 := '';
        Two.Insert();
        Observer.Observe('two second empty', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := '';
        Two.K2 := 'B';
        Two.Insert();
        Observer.Observe('two first empty', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Observer.Expect('code10 short', '<base>/?company=My%20Company&page=21&bookmark=15%3bAQ8BAAJ7%2f0EAMQ%3d%3d');
        Observer.Expect('code10 full', '<base>/?company=My%20Company&page=21&bookmark=31%3bAQ8BAAJ7%2f0EAQgBDAEQARQBGAEcASABJAEo%3d');
        Observer.Expect('code50 short', '<base>/?company=My%20Company&page=21&bookmark=15%3bAg8BAAJ7%2f0EAMQ%3d%3d');
        Observer.Expect('code50 full', '<base>/?company=My%20Company&page=21&bookmark=111%3bAg8BAAJ7%2f0EAQgBDAEQARQBGAEcASABJAEoASwBMAE0ATgBPAFAAUQBSAFMAVABVAFYAVwBYAFkAWgAwADEAMgAzADQANQA2ADcAOAA5AEEAQgBDAEQARQBGAEcASABJAEoASwBMAE0ATg%3d%3d');
        Observer.Expect('code50 symbols', '<base>/?company=My%20Company&page=21&bookmark=25%3bAg8BAAJ7%2f0EALQBCAF8AQwAuAEQ%3d');
        Observer.Expect('two short', '<base>/?company=My%20Company&page=21&bookmark=24%3bAw8BAAJ7%2f0EAMQAAAAJ7%2f0IAMg%3d%3d');
        Observer.Expect('two full', '<base>/?company=My%20Company&page=21&bookmark=96%3bAw8BAAJ7%2f0EAQgBDAEQARQBGAEcASABJAEoASwBMAE0ATgBPAFAAUQBSAFMAVAAAAAJ7%2f1UAVgBXAFgAWQBaADAAMQAyADMANAA1ADYANwA4ADkAQQBCAEMARA%3d%3d');
        Observer.Expect('two second empty', '<base>/?company=My%20Company&page=21&bookmark=18%3bAw8BAAJ7%2f0EAAAACew%3d%3d');
        Observer.Expect('two first empty', '<base>/?company=My%20Company&page=21&bookmark=18%3bAw8BAAJ7AAAAAnv%2fQg%3d%3d');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): the full text (host and instance masked) of GetUrl for the service client types SOAP, OData, ODataV4
    // and Api, alone, with a company, with an object and with a record; SOAP and ODataV4 with a codeunit. ----

    [Test]
    procedure TV_GetUrl_ClientSOAP()
    begin
        ClientTest(ClientType::SOAP, 'soap');
        Observer.Observe('soap company codeunit', Obj(ClientType::SOAP, 'My Company', ObjectType::Codeunit, 69366));
        Observer.Observe('soap codeunit', Obj(ClientType::SOAP, '', ObjectType::Codeunit, 69366));
        Observer.Finish();
    end;

    [Test]
    procedure TV_GetUrl_ClientOData()
    begin
        ClientTest(ClientType::OData, 'odata');
        Observer.Finish();
    end;

    [Test]
    procedure TV_GetUrl_ClientODataV4()
    begin
        ClientTest(ClientType::ODataV4, 'odatav4');
        Observer.Observe('odatav4 company codeunit', Obj(ClientType::ODataV4, 'My Company', ObjectType::Codeunit, 69366));
        Observer.Observe('odatav4 company query', Obj(ClientType::ODataV4, 'My Company', ObjectType::Query, 69376));
        Observer.Finish();
    end;

    [Test]
    procedure TV_GetUrl_ClientApi()
    begin
        ClientTest(ClientType::Api, 'api');
        Observer.Finish();
    end;
}
