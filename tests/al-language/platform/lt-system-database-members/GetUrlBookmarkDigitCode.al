// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 91300 / 91301, enum 91302, pages 91303 / 91304 and test codeunit 91305
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the bookmark= value of GetUrl(ClientType::Web, Company, ObjectType::Page, Id, Record, false) for a record whose only key field is a Code[20]
//   that starts with a digit: all-digit values of 1, 5, 6, 7, 10 and 20 digits, leading zeros, digits followed by letters, and a letter reference;
//   and for a record whose only key field is an enum (ordinals 0, 1, 5). GetUrlBookmarkEnumKey.al pins the six-digit Purchase Header number and
//   the enum + Code key; GetUrlBookmarkFilter.al pins Code keys that start with a letter.
// BC versions: 27, 28, 29
table 91300 "LT Y6 Url Code Row"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

enum 91302 "LT Y6 Url Kind"
{
    value(0; First) { }
    value(1; Second) { }
    value(5; Fifth) { }
}

table 91301 "LT Y6 Url Enum Only"
{
    fields
    {
        field(1; Kind; Enum "LT Y6 Url Kind") { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Kind) { Clustered = true; }
    }
}

page 91303 "LT Y6 Url Code Page"
{
    PageType = List;
    SourceTable = "LT Y6 Url Code Row";
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

page 91304 "LT Y6 Url Enum Page"
{
    PageType = List;
    SourceTable = "LT Y6 Url Enum Only";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 91305 "LT Y6 GetUrl Digit Code"
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

    local procedure CodeUrl(No: Code[20]): Text
    var
        Row: Record "LT Y6 Url Code Row";
    begin
        Row.Init();
        Row.Code := No;
        exit(Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Code Page", Row, false)));
    end;

    [Test]
    procedure CodeKey_AllDigits_Lengths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1', CodeUrl('1'));
        Observer.Observe('0', CodeUrl('0'));
        Observer.Observe('12345', CodeUrl('12345'));
        Observer.Observe('123456', CodeUrl('123456'));
        Observer.Observe('1234567', CodeUrl('1234567'));
        Observer.Observe('1234567890', CodeUrl('1234567890'));
        Observer.Observe('12345678901234567890', CodeUrl('12345678901234567890'));
        Observer.Observe('000001', CodeUrl('000001'));
        Observer.Observe('007', CodeUrl('007'));
        Observer.Finish();
    end;

    [Test]
    procedure CodeKey_DigitsThenLetters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1A', CodeUrl('1A'));
        Observer.Observe('12345A', CodeUrl('12345A'));
        Observer.Observe('123456A', CodeUrl('123456A'));
        Observer.Observe('1-2', CodeUrl('1-2'));
        Observer.Observe('1 2', CodeUrl('1 2'));
        Observer.Observe('A1 reference', CodeUrl('A1'));
        Observer.Finish();
    end;

    [Test]
    procedure CodeKey_AllDigits_InsertedRowSameAsNotInserted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y6 Url Code Row";
        Before: Text;
    begin
        Row.DeleteAll();
        Before := CodeUrl('1234567');
        Row.Init();
        Row.Code := '1234567';
        Row.Insert();
        Row.Get('1234567');
        Observer.Observe('inserted equal', Format(Before = Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Code Page", Row, false))));
        Observer.Finish();
    end;

    [Test]
    procedure EnumOnlyKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y6 Url Enum Only";
    begin
        Row.Init();
        Row.Kind := "LT Y6 Url Kind"::First;
        Observer.Observe('first', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Enum Page", Row, false)));
        Row.Kind := "LT Y6 Url Kind"::Second;
        Observer.Observe('second', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Enum Page", Row, false)));
        Row.Kind := "LT Y6 Url Kind"::Fifth;
        Observer.Observe('fifth', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Enum Page", Row, false)));
        Observer.Observe('fifth usefilters', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y6 Url Enum Page", Row, true)));
        Observer.Finish();
    end;
}
