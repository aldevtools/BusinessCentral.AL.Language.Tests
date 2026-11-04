// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73990
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl overload with Record and Layout text
// BC versions: 29
// Tag: P95

table 73988 "LT P95 U73988"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Name) { }
    }
}

page 73989 "LT P95 U73989"
{
    PageType = List;
    SourceTable = "LT P95 U73988";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 73990 "LT P95 GetUrl Layout"
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
    local procedure TryL(var Row: Record "LT P95 U73988"; Layout: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 73989, Row, true, Layout);
    end;

    local procedure Seed(var Row: Record "LT P95 U73988")
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A1'; Row.Name := 'Alpha'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B2'; Row.Name := 'Beta'; Row.Qty := 2; Row.Insert();
        Row.Init(); Row."No." := 'C3'; Row.Name := 'Gamma'; Row.Qty := 3; Row.Insert();
    end;

    [Test]
    procedure GetUrl_Record_Layout()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P95 U73988";
        R: Text;
        RPlain: Text;
    begin
        Seed(Row);
        Row.FindFirst();
        RPlain := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 73989, Row, true);
        if TryL(Row, 'Layout1', R) then begin
            Observer.Observe('layout_differs', Format(R <> RPlain));
            Observer.Observe('layout_in_url', Format(R.Contains('Layout1')));
        end else
            Observer.Observe('layout', Err());
        if TryL(Row, '', R) then
            Observer.Observe('empty_equals_plain', Format(R = RPlain))
        else
            Observer.Observe('empty', Err());
        Observer.Expect('layout_differs', 'No');
        Observer.Expect('layout_in_url', 'No');
        Observer.Expect('empty_equals_plain', 'Yes');
        Observer.Verify();
    end;

}
