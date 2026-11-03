// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67178, 67179
// Probe: a Sum FlowField with `Date = field(upperlimit(F))` where the date flow filter F holds ONE value, set by SetFilter(F, Format(d)), SetFilter(F, '..d'),
// SetFilter(F, '<=d'), SetRange(F, d), SetRange(F, 0D, d), SetRange(F, d, 0D), an open lower bound 'd..' and an empty filter: which detail rows are counted.
// The existing upperlimit probes (CFF Header) use a range. Settles: upperlimit-of-a-single-value. Object ids 67178 - 67180.

table 67178 "LT UL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(3; "Up To"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT UL Line".Amount where("Doc No." = field("No."), "Posting Date" = field(upperlimit("Date Filter"))));
        }
        field(4; "In Range"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT UL Line".Amount where("Doc No." = field("No."), "Posting Date" = field("Date Filter")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67179 "LT UL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[10]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; SumIndexFields = Amount; }
    }
}

codeunit 67180 "LT UL Upper Limit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "LT UL Header";
        Line: Record "LT UL Line";
        Index: Integer;
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Header.Init();
        Header."No." := 'D1';
        Header.Insert();
        // One line per day on 1 to 5 January 2024 with the amounts 1, 10, 100, 1000, 10000.
        for Index := 1 to 5 do begin
            Line.Init();
            Line."Entry No." := Index;
            Line."Doc No." := 'D1';
            Line."Posting Date" := DMY2Date(Index, 1, 2024);
            Line.Amount := Power(10, Index - 1);
            Line.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryCalcUpTo(var Header: Record "LT UL Header")
    begin
        Header.CalcFields("Up To");
    end;

    [TryFunction]
    local procedure TryCalcInRange(var Header: Record "LT UL Header")
    begin
        Header.CalcFields("In Range");
    end;

    local procedure Both(var Header: Record "LT UL Header"): Text
    var
        UpTo: Text;
        InRange: Text;
    begin
        ClearLastError();
        if TryCalcUpTo(Header) then
            UpTo := Format(Header."Up To")
        else
            UpTo := 'error:' + GetLastErrorText();
        ClearLastError();
        if TryCalcInRange(Header) then
            InRange := Format(Header."In Range")
        else
            InRange := 'error:' + GetLastErrorText();
        exit('filter=' + Header.GetFilter("Date Filter") + '|upto=' + UpTo + '|inrange=' + InRange);
    end;

    [Test]
    procedure UpperLimit_OneValue()
    var
        Header: Record "LT UL Header";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Header.Get('D1');
        Header.SetFilter("Date Filter", Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_format_d', Both(Header));
        Header.SetFilter("Date Filter", '..' + Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_dotdot_d', Both(Header));
        Header.SetFilter("Date Filter", '<=' + Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_le_d', Both(Header));
        Header.SetFilter("Date Filter", '<' + Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_lt_d', Both(Header));
        Header.SetRange("Date Filter", DMY2Date(3, 1, 2024));
        Observer.Observe('setrange_d', Both(Header));
        Header.SetRange("Date Filter", 0D, DMY2Date(3, 1, 2024));
        Observer.Observe('setrange_0d_d', Both(Header));
        Header.SetRange("Date Filter", DMY2Date(3, 1, 2024), 0D);
        Observer.Observe('setrange_d_0d', Both(Header));
        Observer.Expect('setfilter_format_d', 'filter=01/03/24|upto=111|inrange=100');
        Observer.Expect('setfilter_dotdot_d', 'filter=..01/03/24|upto=111|inrange=111');
        Observer.Expect('setfilter_le_d', 'filter=<=01/03/24|upto=111|inrange=111');
        Observer.Expect('setfilter_lt_d', 'filter=<01/03/24|upto=error:The filter expression "<01/03/24" applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=11');
        Observer.Expect('setrange_d', 'filter=01/03/24|upto=111|inrange=100');
        Observer.Expect('setrange_0d_d', 'filter=''''..01/03/24|upto=111|inrange=111');
        Observer.Expect('setrange_d_0d', 'filter=01/03/24..''''|upto=0|inrange=0');
        Observer.Verify();
    end;

    [Test]
    procedure UpperLimit_OpenAndEmpty()
    var
        Header: Record "LT UL Header";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Header.Get('D1');
        Header.SetFilter("Date Filter", Format(DMY2Date(3, 1, 2024)) + '..');
        Observer.Observe('setfilter_d_dotdot', Both(Header));
        Header.SetFilter("Date Filter", '>' + Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_gt_d', Both(Header));
        Header.SetFilter("Date Filter", '');
        Observer.Observe('setfilter_empty', Both(Header));
        Header.SetFilter("Date Filter", '%1|%2', DMY2Date(2, 1, 2024), DMY2Date(4, 1, 2024));
        Observer.Observe('setfilter_two_values', Both(Header));
        Header.SetFilter("Date Filter", '%1..%2|%3', DMY2Date(1, 1, 2024), DMY2Date(2, 1, 2024), DMY2Date(4, 1, 2024));
        Observer.Observe('setfilter_range_and_value', Both(Header));
        Header.SetFilter("Date Filter", '<>' + Format(DMY2Date(3, 1, 2024)));
        Observer.Observe('setfilter_not_d', Both(Header));
        Header.SetRange("Date Filter", DMY2Date(1, 1, 2023));
        Observer.Observe('setrange_before_all', Both(Header));
        Header.SetRange("Date Filter", DMY2Date(1, 1, 2025));
        Observer.Observe('setrange_after_all', Both(Header));
        Observer.Expect('setfilter_d_dotdot', 'filter=01/03/24..|upto=error:The filter expression "01/03/24.." applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=11,100');
        Observer.Expect('setfilter_gt_d', 'filter=>01/03/24|upto=error:The filter expression ">01/03/24" applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=11,000');
        Observer.Expect('setfilter_empty', 'filter=|upto=11,111|inrange=11,111');
        Observer.Expect('setfilter_two_values', 'filter=01/02/24|01/04/24|upto=error:The filter expression "01/02/24|01/04/24" applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=1,010');
        Observer.Expect('setfilter_range_and_value', 'filter=01/01/24..01/02/24|01/04/24|upto=error:The filter expression "01/01/24..01/02/24|01/04/24" applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=1,011');
        Observer.Expect('setfilter_not_d', 'filter=<>01/03/24|upto=error:The filter expression "<>01/03/24" applied to the field Date Filter in the LT UL Header table results in more than one range.|inrange=11,011');
        Observer.Expect('setrange_before_all', 'filter=01/01/23|upto=0|inrange=0');
        Observer.Expect('setrange_after_all', 'filter=01/01/25|upto=11,111|inrange=0');
        Observer.Verify();
    end;
}
