// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70116
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Filters: GetFilters is Caption: filter pairs joined by `, `; a filter reads back as a..b, a, <>a, >a, a|b, a&b (values needing quotes)
// Facts: Record.GetFilters and GetFilter after SetRange/SetFilter with all filter shapes, quoting needs and several fields
// BC versions: 29 (27 and 28 by CI)

codeunit 70118 "LT PnA GetFilters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; var G: Record "LT PnA Gen"; FieldNo: Integer)
    var
        R: RecordRef;
        F: FieldRef;
    begin
        R.GetTable(G);
        F := R.Field(FieldNo);
        Observer.Observe(Name, G.GetFilters() + '|' + F.GetFilter());
    end;

    [Test]
    procedure Text_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT PnA Gen";
    begin
        G.SetRange(Name, 'a', 'b');
        Show(Observer, 'range', G, 2);
        G.Reset();
        G.SetRange(Name, 'a');
        Show(Observer, 'single', G, 2);
        G.Reset();
        G.SetFilter(Name, '<>a');
        Show(Observer, 'not-equal', G, 2);
        G.Reset();
        G.SetFilter(Name, '>a');
        Show(Observer, 'greater', G, 2);
        G.Reset();
        G.SetFilter(Name, '>=a&<=c');
        Show(Observer, 'and', G, 2);
        G.Reset();
        G.SetFilter(Name, 'a|b');
        Show(Observer, 'or', G, 2);
        G.Reset();
        G.SetFilter(Name, '<a|>c');
        Show(Observer, 'or-comparisons', G, 2);
        G.Reset();
        G.SetFilter(Name, 'A*|B*');
        Show(Observer, 'wildcards-or', G, 2);
        G.Reset();
        G.SetFilter(Name, '@abc*');
        Show(Observer, 'case-insensitive', G, 2);
        G.Reset();
        G.SetFilter(Name, '');
        Show(Observer, 'empty-filter', G, 2);
        G.Reset();
        G.SetRange(Name, '');
        Show(Observer, 'empty-range', G, 2);
        G.Reset();
        G.SetFilter(Name, '""');
        Show(Observer, 'blank-quoted', G, 2);
        Observer.Expect('range', 'Name: a..b|a..b');
        Observer.Expect('single', 'Name: a|a');
        Observer.Expect('not-equal', 'Name: <>a|<>a');
        Observer.Expect('greater', 'Name: >a|>a');
        Observer.Expect('and', 'Name: >=a&<=c|>=a&<=c');
        Observer.Expect('or', 'Name: a|b|a|b');
        Observer.Expect('or-comparisons', 'Name: <a|>c|<a|>c');
        Observer.Expect('wildcards-or', 'Name: A*|B*|A*|B*');
        Observer.Expect('case-insensitive', 'Name: @abc*|@abc*');
        Observer.Expect('empty-filter', '|');
        Observer.Expect('empty-range', 'Name: ''''|''''');
        Observer.Expect('blank-quoted', 'Name: ""|""');
        Observer.Verify();
    end;

    [Test]
    procedure Text_ValuesNeedingQuotes()
    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT PnA Gen";
    begin
        G.SetRange(Name, 'a b');
        Show(Observer, 'space', G, 2);
        G.Reset();
        G.SetRange(Name, 'a|b');
        Show(Observer, 'pipe', G, 2);
        G.Reset();
        G.SetRange(Name, 'a&b');
        Show(Observer, 'ampersand', G, 2);
        G.Reset();
        G.SetRange(Name, '(x)');
        Show(Observer, 'parentheses', G, 2);
        G.Reset();
        G.SetRange(Name, 'a''b');
        Show(Observer, 'apostrophe', G, 2);
        G.Reset();
        G.SetRange(Name, '*');
        Show(Observer, 'star', G, 2);
        G.Reset();
        G.SetRange(Name, '<x');
        Show(Observer, 'less-than', G, 2);
        G.Reset();
        G.SetRange(Name, 'a..b');
        Show(Observer, 'dots', G, 2);
        G.Reset();
        G.SetRange(Name, '=a');
        Show(Observer, 'equals', G, 2);
        G.Reset();
        G.SetRange(Name, 'a', 'b c');
        Show(Observer, 'range-with-space', G, 2);
        G.Reset();
        G.SetRange(Name, '@a');
        Show(Observer, 'at-sign', G, 2);
        Observer.Expect('space', 'Name: a b|a b');
        Observer.Expect('pipe', 'Name: ''a|b''|''a|b''');
        Observer.Expect('ampersand', 'Name: ''a&b''|''a&b''');
        Observer.Expect('parentheses', 'Name: ''(x)''|''(x)''');
        Observer.Expect('apostrophe', 'Name: a''b|a''b');
        Observer.Expect('star', 'Name: =''*''|=''*''');
        Observer.Expect('less-than', 'Name: ''<x''|''<x''');
        Observer.Expect('dots', 'Name: ''a..b''|''a..b''');
        Observer.Expect('equals', 'Name: ''=a''|''=a''');
        Observer.Expect('range-with-space', 'Name: a..b c|a..b c');
        Observer.Expect('at-sign', 'Name: ''@a''|''@a''');
        Observer.Verify();
    end;

    [Test]
    procedure Other_Types()
    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT PnA Gen";
    begin
        G.SetFilter(Qty, '1..5|8');
        Show(Observer, 'integer-or-range', G, 3);
        G.Reset();
        G.SetRange(Qty, -3);
        Show(Observer, 'integer-negative', G, 3);
        G.Reset();
        G.SetRange(Amt, 1.5);
        Show(Observer, 'decimal', G, 4);
        G.Reset();
        G.SetRange(Amt, 1.5, 22222.125);
        Show(Observer, 'decimal-range-thousands', G, 4);
        G.Reset();
        G.SetRange(DateF, DMY2Date(1, 1, 2024));
        Show(Observer, 'date', G, 5);
        G.Reset();
        G.SetRange(DateF, DMY2Date(1, 1, 2024), DMY2Date(31, 12, 2024));
        Show(Observer, 'date-range', G, 5);
        G.Reset();
        G.SetRange(Flag, true);
        Show(Observer, 'boolean-true', G, 6);
        G.Reset();
        G.SetRange(Flag, false);
        Show(Observer, 'boolean-false', G, 6);
        G.Reset();
        G.SetRange(Code, 'x');
        Show(Observer, 'code', G, 1);
        G.Reset();
        G.SetFilter(Code, 'a*');
        Show(Observer, 'code-wildcard', G, 1);
        G.Reset();
        G.SetRange(DateF, 0D);
        Show(Observer, 'date-zero', G, 5);
        Observer.Expect('integer-or-range', 'Qty: 1..5|8|1..5|8');
        Observer.Expect('integer-negative', 'Qty: -3|-3');
        Observer.Expect('decimal', 'Amt: 1.5|1.5');
        Observer.Expect('decimal-range-thousands', 'Amt: 1.5..22,222.125|1.5..22,222.125');
        Observer.Expect('date', 'DateF: 01/01/24|01/01/24');
        Observer.Expect('date-range', 'DateF: 01/01/24..12/31/24|01/01/24..12/31/24');
        Observer.Expect('boolean-true', 'Flag: Yes|Yes');
        Observer.Expect('boolean-false', 'Flag: No|No');
        Observer.Expect('code', 'Code: X|X');
        Observer.Expect('code-wildcard', 'Code: A*|A*');
        Observer.Expect('date-zero', 'DateF: ''''|''''');
        Observer.Verify();
    end;

    [Test]
    procedure SeveralFields_Order()
    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT PnA Gen";
    begin
        G.SetRange(Qty, 1);
        G.SetRange(Code, 'x');
        Show(Observer, 'qty-then-code', G, 3);
        G.Reset();
        G.SetRange(Code, 'x');
        G.SetRange(Qty, 1);
        Show(Observer, 'code-then-qty', G, 3);
        G.Reset();
        G.SetRange(Flag, true);
        G.SetRange(Name, 'n');
        G.SetRange(Qty, 2);
        Show(Observer, 'flag-name-qty', G, 3);
        G.Reset();
        G.SetRange(Qty, 2);
        G.SetRange(Name, 'n');
        G.SetRange(Flag, true);
        Show(Observer, 'qty-name-flag', G, 3);
        G.SetRange(Name, 'm');
        Show(Observer, 'name-reset-in-place', G, 3);
        G.SetRange(Name);
        Show(Observer, 'name-cleared', G, 3);
        G.Reset();
        G.SetFilter(Name, 'a|b');
        G.SetFilter(Qty, '>1');
        Show(Observer, 'two-expressions', G, 3);
        Observer.Expect('qty-then-code', 'Code: X, Qty: 1|1');
        Observer.Expect('code-then-qty', 'Code: X, Qty: 1|1');
        Observer.Expect('flag-name-qty', 'Name: n, Qty: 2, Flag: Yes|2');
        Observer.Expect('qty-name-flag', 'Name: n, Qty: 2, Flag: Yes|2');
        Observer.Expect('name-reset-in-place', 'Name: m, Qty: 2, Flag: Yes|2');
        Observer.Expect('name-cleared', 'Qty: 2, Flag: Yes|2');
        Observer.Expect('two-expressions', 'Name: a|b, Qty: >1|>1');
        Observer.Verify();
    end;
}
