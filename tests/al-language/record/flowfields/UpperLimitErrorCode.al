// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 78004, 78005
// Probe: GetLastErrorCode (and the text) after CalcFields on a Sum FlowField with `Date = field(upperlimit(F))` when the date flow filter F holds more
// than one range ("results in more than one range"), for a range with an open end, an or-list, a not-equal and a greater-than filter. The error text is
// pinned in calcfields/lt-upperlimit-single-value. Object ids 78004 - 78006.

table 78004 "LT AD UL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(3; "Up To"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT AD UL Line".Amount where("Doc No." = field("No."), "Posting Date" = field(upperlimit("Date Filter"))));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 78005 "LT AD UL Line"
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

codeunit 78006 "LT AD UL Error Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "LT AD UL Header";
        Line: Record "LT AD UL Line";
        Index: Integer;
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Header.Init();
        Header."No." := 'D1';
        Header.Insert();
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
    local procedure TryCalcUpTo(var Header: Record "LT AD UL Header")
    begin
        Header.CalcFields("Up To");
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; var Header: Record "LT AD UL Header")
    begin
        ClearLastError();
        if TryCalcUpTo(Header) then
            Observer.Observe(Name, 'ok:' + Format(Header."Up To"))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|hasError=' + Format(GetLastErrorText() <> ''));
    end;

    [Test]
    procedure UpperLimit_MoreThanOneRange_ErrorCode()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT AD UL Header";
    begin
        Seed();
        Header.SetFilter("Date Filter", '01/03/24..');
        Probe(Observer, 'open_end', Header);
        Header.SetFilter("Date Filter", '01/02/24|01/04/24');
        Probe(Observer, 'or_list', Header);
        Header.SetFilter("Date Filter", '<>01/03/24');
        Probe(Observer, 'not_equal', Header);
        Header.SetFilter("Date Filter", '>01/03/24');
        Probe(Observer, 'greater_than', Header);
        Header.SetFilter("Date Filter", '<01/03/24');
        Probe(Observer, 'less_than', Header);
        Header.SetFilter("Date Filter", '..01/03/24');
        Probe(Observer, 'single_range_ok', Header);
        Observer.Expect('open_end', 'error:The filter expression "01/03/24.." applied to the field Date Filter in the LT AD UL Header table results in more than one range.|DB:NotIntervalFilter|hasError=Yes');
        Observer.Expect('or_list', 'error:The filter expression "01/02/24|01/04/24" applied to the field Date Filter in the LT AD UL Header table results in more than one range.|DB:NotIntervalFilter|hasError=Yes');
        Observer.Expect('not_equal', 'error:The filter expression "<>01/03/24" applied to the field Date Filter in the LT AD UL Header table results in more than one range.|DB:NotIntervalFilter|hasError=Yes');
        Observer.Expect('greater_than', 'error:The filter expression ">01/03/24" applied to the field Date Filter in the LT AD UL Header table results in more than one range.|DB:NotIntervalFilter|hasError=Yes');
        Observer.Expect('less_than', 'error:The filter expression "<01/03/24" applied to the field Date Filter in the LT AD UL Header table results in more than one range.|DB:NotIntervalFilter|hasError=Yes');
        Observer.Expect('single_range_ok', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure UpperLimit_ErrorCode_ThenClear()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT AD UL Header";
        Code1: Text;
    begin
        Seed();
        Header.SetFilter("Date Filter", '01/02/24|01/04/24');
        ClearLastError();
        if not TryCalcUpTo(Header) then
            Code1 := GetLastErrorCode();
        Observer.Observe('code_after_failure', Code1);
        ClearLastError();
        Observer.Observe('code_after_clear', GetLastErrorCode());
        Observer.Expect('code_after_failure', 'DB:NotIntervalFilter');
        Observer.Expect('code_after_clear', '');
        Observer.Verify();
    end;
}
