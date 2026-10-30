// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90647, table 90648
// Probe: written against al-runner issue 6319 (SetFilter with invalid expressions); every value asserted below is what the BC service tier produced.
// Facts: SetFilter on a Text field with a malformed expression (unbalanced parenthesis, an at sign before the operator) in a TryFunction: error text and code,
//        or the filter and rows kept; and the not-equal case-insensitive filter on a value without a wildcard.
// BC versions: 27, 28, 29

table 90648 "LT WC Value"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Value; Text[100]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 90647 "LT WC Invalid Filter Expr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(var V: Record "LT WC Value" temporary; No: Integer; Txt: Text)
    begin
        V."Entry No." := No;
        V.Value := Txt;
        V.Insert();
    end;

    local procedure Ids(var V: Record "LT WC Value" temporary): Text
    var
        Result: Text;
    begin
        if V.FindSet() then
            repeat
                Result += Format(V."Entry No.") + ',';
            until V.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFilter(Txt: Text; var Result: Text)
    var
        V: Record "LT WC Value" temporary;
    begin
        Add(V, 1, 'c-a');
        Add(V, 2, 'c-b');
        Add(V, 3, 'C-A');
        Add(V, 4, '((x');
        Add(V, 5, '');
        V.SetFilter(Value, Txt);
        Result := 'filter=[' + V.GetFilter(Value) + '] ids=' + Ids(V);
    end;

    local procedure Probe(Txt: Text): Text
    var
        Result: Text;
    begin
        if TryFilter(Txt, Result) then
            exit(Result);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure WC_InvalidFilter_Malformed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('((*', Probe('((*'));
        Observer.Observe('(', Probe('('));
        Observer.Observe('((x', Probe('((x'));
        Observer.Observe('(c-a', Probe('(c-a'));
        Observer.Observe('c-a)', Probe('c-a)'));
        Observer.Observe('(c-a)', Probe('(c-a)'));
        Observer.Observe('@<>C-A', Probe('@<>C-A'));
        Observer.Observe('@<>', Probe('@<>'));
        Observer.Observe('@', Probe('@'));
        Observer.Observe('@@C-A', Probe('@@C-A'));
        Observer.Finish();
    end;

    [Test]
    procedure WC_InvalidFilter_NotEqualCaseInsensitive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<>@C-A', Probe('<>@C-A'));
        Observer.Observe('<>@c-b', Probe('<>@c-b'));
        Observer.Observe('<>@', Probe('<>@'));
        Observer.Observe('<>C-A', Probe('<>C-A'));
        Observer.Observe('<>@c-a*', Probe('<>@c-a*'));
        Observer.Finish();
    end;
}
