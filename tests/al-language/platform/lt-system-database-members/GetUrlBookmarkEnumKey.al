// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 91260, tables 91261 / 91262, page 91263 and test codeunit 91264
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the bookmark= value of GetUrl(ClientType::Web, Company, ObjectType::Page, Id, Record, false) for a record whose primary key starts with an enum
//   field followed by a Code[20] field: an own table, Purchase Header with three document types and a blank and a long number, an Option field in the
//   same position, and an enum as the only key field. Code and Integer keys are pinned in GetUrlBookmarkFilter.al.
// BC versions: 27, 28, 29
enum 91260 "LT SC Url Kind"
{
    value(0; First) { }
    value(1; Second) { }
    value(5; Fifth) { }
}

table 91261 "LT SC Url Enum Row"
{
    fields
    {
        field(1; Kind; Enum "LT SC Url Kind") { }
        field(2; Code; Code[20]) { }
        field(3; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Kind, Code) { Clustered = true; }
    }
}

table 91262 "LT SC Url Option Row"
{
    fields
    {
        field(1; Kind; Option)
        {
            OptionMembers = First,Second,Fifth;
        }
        field(2; Code; Code[20]) { }
    }
    keys
    {
        key(PK; Kind, Code) { Clustered = true; }
    }
}

page 91263 "LT SC Url Page"
{
    PageType = List;
    SourceTable = "LT SC Url Enum Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 91264 "LT SC GetUrl Enum Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    [Test]
    procedure EnumAndCodeKey_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SC Url Enum Row";
    begin
        Row.Init();
        Row.Kind := "LT SC Url Kind"::First;
        Row.Code := 'A1';
        Observer.Observe('first A1', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Kind := "LT SC Url Kind"::Second;
        Observer.Observe('second A1', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Kind := "LT SC Url Kind"::Fifth;
        Observer.Observe('fifth A1', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Code := '';
        Observer.Observe('fifth empty code', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Code := 'X&Y 2';
        Observer.Observe('fifth special code', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Code := 'ABCDEFGHIJKLMNOPQRST';
        Observer.Observe('fifth full code', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Observer.Finish();
    end;

    [Test]
    procedure EnumAndCodeKey_InsertedRow_SameAsNotInserted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SC Url Enum Row";
        Before: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Kind := "LT SC Url Kind"::Second;
        Row.Code := 'A1';
        Before := Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false));
        Row.Insert();
        Row.Get("LT SC Url Kind"::Second, 'A1');
        Observer.Observe('inserted equal', Format(Before = Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false))));
        Observer.Finish();
    end;

    [Test]
    procedure PurchaseHeader_DocumentTypeAndNo()
    var
        Observer: Codeunit "Probe Observer";
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader."No." := 'X';
        Observer.Observe('order X', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Order", PurchHeader, true)));
        Observer.Observe('order X no filters', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Order", PurchHeader, false)));
        PurchHeader."No." := '106001';
        Observer.Observe('order 106001', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Order", PurchHeader, false)));
        PurchHeader."Document Type" := PurchHeader."Document Type"::Quote;
        Observer.Observe('quote 106001', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Quote", PurchHeader, false)));
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader."No." := '';
        Observer.Observe('invoice empty', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Invoice", PurchHeader, false)));
        PurchHeader."No." := 'ABCDEFGHIJKLMNOPQRST';
        Observer.Observe('invoice full no', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"Purchase Invoice", PurchHeader, false)));
        Observer.Finish();
    end;

    [Test]
    procedure OptionAndCodeKey_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SC Url Option Row";
    begin
        Row.Init();
        Row.Kind := Row.Kind::First;
        Row.Code := 'A1';
        Observer.Observe('first A1', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Row.Kind := Row.Kind::Fifth;
        Observer.Observe('fifth A1', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT SC Url Page", Row, false)));
        Observer.Finish();
    end;
}
