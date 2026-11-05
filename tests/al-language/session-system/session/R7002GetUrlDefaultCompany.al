// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95695, test codeunit 95696
// Probe: al-runner issue 7002. How GetUrl(ClientType::Default, Company, ...) writes a company name of other characters than letters, digits and
// space (the corpus demo company 'CRONUS International Ltd.', a dot, a comma, an ampersand, an apostrophe, a slash and more), alone, with a page
// and with a page and a record with UseFilters true and false; ClientType::Web of the same names for comparison. Each result is shown after
// '<base>' (GetUrl(ClientType::Default) or GetUrl(ClientType::Web) without its trailing slash), with '%20' written as '<sp>' (so the Probe
// Observer does not replace the company name).
// BC versions: 29 (27 and 28 by CI)

table 95695 "R7002 GU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 95696 "R7002 GetUrl Default Company"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rel(Url: Text; Base: Text): Text
    begin
        if Url = '' then
            exit('<empty>');
        if Base.EndsWith('/') then
            Base := CopyStr(Base, 1, StrLen(Base) - 1);
        if Url.StartsWith(Base) then
            Url := '<base>' + CopyStr(Url, StrLen(Base) + 1);
        exit(Url.Replace('%20', '<sp>'));
    end;

    local procedure Def(Company: Text): Text
    begin
        exit(Rel(GetUrl(ClientType::Default, Company), GetUrl(ClientType::Default)));
    end;

    local procedure Web(Company: Text): Text
    begin
        exit(Rel(GetUrl(ClientType::Web, Company), GetUrl(ClientType::Web)));
    end;

    [Test]
    procedure Default_CompanyNames_Punctuation()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('cronus', Def('CRONUS International Ltd.'));
        Observer.Observe('dot', Def('A.B'));
        Observer.Observe('trailing dot', Def('AB.'));
        Observer.Observe('comma', Def('A,B'));
        Observer.Observe('ampersand', Def('A&B'));
        Observer.Observe('apostrophe', Def('O''Neil'));
        Observer.Observe('slash', Def('A/B'));
        Observer.Observe('hyphen underscore', Def('A-B_C'));
        Observer.Observe('parentheses', Def('A(B)'));
        Observer.Observe('plus', Def('A+B'));
        Observer.Observe('hash', Def('A#B'));
        Observer.Observe('percent', Def('A%B'));
        Observer.Observe('question', Def('A?B'));
        Observer.Observe('equals', Def('A=B'));
        Observer.Observe('colon', Def('A:B'));
        Observer.Observe('umlaut', Def('Müller'));
        Observer.Observe('double space', Def('A  B'));
        Observer.Finish();
    end;

    [Test]
    procedure Web_CompanyNames_Punctuation()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('cronus', Web('CRONUS International Ltd.'));
        Observer.Observe('dot', Web('A.B'));
        Observer.Observe('comma', Web('A,B'));
        Observer.Observe('hyphen underscore', Web('A-B_C'));
        Observer.Observe('parentheses', Web('A(B)'));
        Observer.Observe('plus', Web('A+B'));
        Observer.Observe('hash', Web('A#B'));
        Observer.Observe('percent', Web('A%B'));
        Observer.Observe('colon', Web('A:B'));
        Observer.Finish();
    end;

    [Test]
    procedure Default_Cronus_PageAndReport()
    var
        Observer: Codeunit "Probe Observer";
        Base: Text;
    begin
        Base := GetUrl(ClientType::Default);
        Observer.Observe('page', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21), Base));
        Observer.Observe('report', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Report, 69367), Base));
        Observer.Observe('apostrophe page', Rel(GetUrl(ClientType::Default, 'O''Neil & Co.', ObjectType::Page, 21), Base));
        Observer.Finish();
    end;

    [Test]
    procedure Default_Cronus_PageRecord_UseFilters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7002 GU Row";
        RecRef: RecordRef;
        Base: Text;
    begin
        Row.DeleteAll();
        Row.Id := 3;
        Row.Name := 'Alpha';
        Row.Insert();
        Row.Id := 4;
        Row.Name := 'Beta';
        Row.Insert();
        Base := GetUrl(ClientType::Default);
        Row.Get(3);
        Observer.Observe('record false', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21, Row, false), Base));
        Observer.Observe('record true no filter', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21, Row, true), Base));
        Row.SetRange(Name, 'Alpha');
        Observer.Observe('record true filter', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21, Row, true), Base));
        Observer.Observe('record false filter', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21, Row, false), Base));
        Observer.Observe('empty company true filter', Rel(GetUrl(ClientType::Default, '', ObjectType::Page, 21, Row, true), Base));
        Row.Reset();
        Row.Get(4);
        RecRef.GetTable(Row);
        Observer.Observe('recordref true', Rel(GetUrl(ClientType::Default, 'CRONUS International Ltd.', ObjectType::Page, 21, RecRef, true), Base));
        Observer.Observe('web recordref true', Rel(GetUrl(ClientType::Web, 'CRONUS International Ltd.', ObjectType::Page, 21, RecRef, true), GetUrl(ClientType::Web)));
        Observer.Finish();
    end;
}
