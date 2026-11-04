// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73984
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl with a Record argument: bookmark, filters, UseFilters
// BC versions: 29
// Tag: P95

table 73982 "LT P95 U73982"
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

page 73983 "LT P95 U73983"
{
    PageType = List;
    SourceTable = "LT P95 U73982";
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

codeunit 73984 "LT P95 GetUrl Record"
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
    local procedure TryR(var Row: Record "LT P95 U73982"; Filters: Boolean; var R: Text)
    begin
        R := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 73983, Row, Filters);
    end;

    [TryFunction]
    local procedure TryRDefault(var Row: Record "LT P95 U73982"; var R: Text)
    begin
        R := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 73983, Row);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT P95 U73982"; Filters: Boolean)
    var
        R: Text;
    begin
        if TryR(Row, Filters, R) then
            Observer.Observe(Name, Shape(R) + '|' + Format(R.Contains('bookmark=')) + '|' + Format(R.Contains('filter=')))
        else
            Observer.Observe(Name, Err());
    end;

    local procedure Seed(var Row: Record "LT P95 U73982")
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A1'; Row.Name := 'Alpha'; Row.Qty := 1; Row.Insert();
        Row.Init(); Row."No." := 'B2'; Row.Name := 'Beta'; Row.Qty := 2; Row.Insert();
        Row.Init(); Row."No." := 'C3'; Row.Name := 'Gamma'; Row.Qty := 3; Row.Insert();
    end;

    [Test]
    procedure GetUrl_Record_Basic()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P95 U73982";
        R1: Text;
        R2: Text;
    begin
        Seed(Row);
        Row.FindFirst();
        One(Observer, 'nofilters_false', Row, false);
        One(Observer, 'nofilters_true', Row, true);
        TryRDefault(Row, R1);
        TryR(Row, false, R2);
        Observer.Observe('default_equals_false', Format(R1 = R2));
        Row.FindLast();
        TryR(Row, false, R1);
        Observer.Observe('other_record_differs', Format(R1 <> R2));
        Observer.Expect('nofilters_false', 'Yes|Yes|Yes|Yes|No|No|No|Yes|No');
        Observer.Expect('nofilters_true', 'Yes|Yes|Yes|Yes|No|No|No|No|No');
        Observer.Expect('default_equals_false', 'Yes');
        Observer.Expect('other_record_differs', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Record_Filters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P95 U73982";
        RF: Text;
        RN: Text;
        RN2: Text;
    begin
        Seed(Row);
        Row.SetRange("No.", 'A1', 'B2');
        Row.FindFirst();
        One(Observer, 'range_nofilters', Row, false);
        One(Observer, 'range_filters', Row, true);
        TryR(Row, true, RF);
        TryR(Row, false, RN);
        Observer.Observe('filters_change_url', Format(RF <> RN));
        Row.Reset();
        TryR(Row, true, RN2);
        Observer.Observe('reset_equals_nofilter_url', Format(RN2 = RN));
        Row.SetFilter(Name, '<>%1', 'Alpha');
        Row.FindFirst();
        One(Observer, 'name_filter', Row, true);
        Row.Reset();
        Row.SetRange(Qty, 99);
        One(Observer, 'filter_matches_nothing_unread', Row, true);
        Observer.Expect('range_nofilters', 'Yes|Yes|Yes|Yes|No|No|No|Yes|No');
        Observer.Expect('range_filters', 'Yes|Yes|Yes|Yes|No|No|No|No|Yes');
        Observer.Expect('filters_change_url', 'Yes');
        Observer.Expect('reset_equals_nofilter_url', 'No');
        Observer.Expect('name_filter', 'Yes|Yes|Yes|Yes|No|No|No|No|Yes');
        Observer.Expect('filter_matches_nothing_unread', 'Yes|Yes|Yes|Yes|No|No|No|No|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Record_EmptyAndKeys()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P95 U73982";
        Row2: Record "LT P95 U73982";
    begin
        Row.DeleteAll();
        One(Observer, 'empty_table_init_row', Row, false);
        Row.Init();
        One(Observer, 'init_row', Row, false);
        Seed(Row);
        Row2.SetCurrentKey(Name);
        Row2.FindFirst();
        One(Observer, 'secondary_key', Row2, true);
        Observer.Expect('empty_table_init_row', 'Yes|Yes|Yes|Yes|No|No|No|Yes|No');
        Observer.Expect('init_row', 'Yes|Yes|Yes|Yes|No|No|No|Yes|No');
        Observer.Expect('secondary_key', 'Yes|Yes|Yes|Yes|No|No|No|No|No');
        Observer.Verify();
    end;

}
