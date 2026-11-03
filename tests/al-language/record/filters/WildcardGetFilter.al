// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81870
// Probe: corpus issue 673 item 4 (al-runtime-rs #295). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: SetFilter with wildcard and not-equal forms ('<>*', '*', '<>A*', '*A*', '<>*A*', 'A*|B*', '<>A&<>B', '?', '<>?', '@*a*', '<>''''&<>*') on a Code[20] field and a Text[50] field of a temporary record, also through %1 placeholders: GetFilter, GetFilters and the keys of the rows the filter keeps (rows '', A1, AB, B1, XA), or the error text and code.
// BC versions: 27+

table 81870 "LT BL Wildcard Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 81871 "LT BL Wildcard GetFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT BL Wildcard Row" temporary)
    begin
        Row.Reset();
        Row.DeleteAll();
        Add(Row, '', '');
        Add(Row, 'A1', 'apple');
        Add(Row, 'AB', 'Avocado');
        Add(Row, 'B1', 'banana');
        Add(Row, 'XA', 'xa');
    end;

    local procedure Add(var Row: Record "LT BL Wildcard Row" temporary; No: Code[20]; Name: Text[50])
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Insert();
    end;

    local procedure Kept(var Row: Record "LT BL Wildcard Row" temporary) Result: Text
    begin
        Result := '{';
        if Row.FindSet() then
            repeat
                Result += '[' + Row."No." + ']';
            until Row.Next() = 0;
        Result += '}';
    end;

    [TryFunction]
    local procedure TrySetNo(var Row: Record "LT BL Wildcard Row" temporary; Filter: Text)
    begin
        Row.SetFilter("No.", Filter);
    end;

    [TryFunction]
    local procedure TrySetName(var Row: Record "LT BL Wildcard Row" temporary; Filter: Text)
    begin
        Row.SetFilter(Name, Filter);
    end;

    local procedure OnNo(var Observer: Codeunit "Probe Observer"; var Row: Record "LT BL Wildcard Row" temporary; Filter: Text)
    begin
        Row.Reset();
        ClearLastError();
        if TrySetNo(Row, Filter) then
            Observer.Observe('No ' + Filter, Row.GetFilter("No.") + ' | ' + Row.GetFilters() + ' | ' + Kept(Row))
        else
            Observer.Observe('No ' + Filter, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + ']');
    end;

    local procedure OnName(var Observer: Codeunit "Probe Observer"; var Row: Record "LT BL Wildcard Row" temporary; Filter: Text)
    begin
        Row.Reset();
        ClearLastError();
        if TrySetName(Row, Filter) then
            Observer.Observe('Name ' + Filter, Row.GetFilter(Name) + ' | ' + Row.GetFilters() + ' | ' + Kept(Row))
        else
            Observer.Observe('Name ' + Filter, 'error [' + GetLastErrorText() + '] [' + GetLastErrorCode() + ']');
    end;

    // The al-runtime-rs #295 repro.
    [Test]
    procedure Repro_NotWildcard_RoundTrips()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Wildcard Row" temporary;
    begin
        Row.SetFilter("No.", '<>*');
        Observer.Observe('getfilter', Row.GetFilter("No."));
        Observer.Observe('equal', Format(Row.GetFilter("No.") = '<>*'));
        Observer.Expect('getfilter', '<>*');
        Observer.Expect('equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Forms_CodeField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Wildcard Row" temporary;
    begin
        Seed(Row);
        OnNo(Observer, Row, '<>*');
        OnNo(Observer, Row, '*');
        OnNo(Observer, Row, '<>A*');
        OnNo(Observer, Row, '*A*');
        OnNo(Observer, Row, '<>*A*');
        OnNo(Observer, Row, 'A*|B*');
        OnNo(Observer, Row, '<>A1&<>B1');
        OnNo(Observer, Row, '?');
        OnNo(Observer, Row, '<>?');
        OnNo(Observer, Row, '??');
        OnNo(Observer, Row, '@*a*');
        OnNo(Observer, Row, '<>''''&<>*');
        OnNo(Observer, Row, 'a*');
        Observer.Expect('No <>*', '<>* | No.: <>* | {}');
        Observer.Expect('No *', '* | No.: * | {[][A1][AB][B1][XA]}');
        Observer.Expect('No <>A*', '<>A* | No.: <>A* | {[][B1][XA]}');
        Observer.Expect('No *A*', '*A* | No.: *A* | {[A1][AB][XA]}');
        Observer.Expect('No <>*A*', '<>*A* | No.: <>*A* | {[][B1]}');
        Observer.Expect('No A*|B*', 'A*|B* | No.: A*|B* | {[A1][AB][B1]}');
        Observer.Expect('No <>A1&<>B1', '<>A1&<>B1 | No.: <>A1&<>B1 | {[][AB][XA]}');
        Observer.Expect('No ?', '? | No.: ? | {}');
        Observer.Expect('No <>?', '<>? | No.: <>? | {[][A1][AB][B1][XA]}');
        Observer.Expect('No ??', '?? | No.: ?? | {[A1][AB][B1][XA]}');
        Observer.Expect('No @*a*', '@*A* | No.: @*A* | {[A1][AB][XA]}');
        Observer.Expect('No <>''''&<>*', '<>''''&<>* | No.: <>''''&<>* | {}');
        Observer.Expect('No a*', 'A* | No.: A* | {[A1][AB]}');
        Observer.Verify();
    end;

    [Test]
    procedure Forms_TextField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Wildcard Row" temporary;
    begin
        Seed(Row);
        OnName(Observer, Row, '<>*');
        OnName(Observer, Row, '*');
        OnName(Observer, Row, '<>a*');
        OnName(Observer, Row, '*a*');
        OnName(Observer, Row, '<>*a*');
        OnName(Observer, Row, 'a*|b*');
        OnName(Observer, Row, '<>apple&<>xa');
        OnName(Observer, Row, '??');
        OnName(Observer, Row, '<>??');
        OnName(Observer, Row, '@*A*');
        OnName(Observer, Row, '<>@a*');
        OnName(Observer, Row, '<>''''&<>*');
        Observer.Expect('Name <>*', '<>* | Name: <>* | {}');
        Observer.Expect('Name *', '* | Name: * | {[][A1][AB][B1][XA]}');
        Observer.Expect('Name <>a*', '<>a* | Name: <>a* | {[][AB][B1][XA]}');
        Observer.Expect('Name *a*', '*a* | Name: *a* | {[A1][AB][B1][XA]}');
        Observer.Expect('Name <>*a*', '<>*a* | Name: <>*a* | {[]}');
        Observer.Expect('Name a*|b*', 'a*|b* | Name: a*|b* | {[A1][B1]}');
        Observer.Expect('Name <>apple&<>xa', '<>apple&<>xa | Name: <>apple&<>xa | {[][AB][B1]}');
        Observer.Expect('Name ??', '?? | Name: ?? | {[XA]}');
        Observer.Expect('Name <>??', '<>?? | Name: <>?? | {[][A1][AB][B1]}');
        Observer.Expect('Name @*A*', '@*A* | Name: @*A* | {[A1][AB][B1][XA]}');
        Observer.Expect('Name <>@a*', '<>@a* | Name: <>@a* | {[][B1][XA]}');
        Observer.Expect('Name <>''''&<>*', '<>''''&<>* | Name: <>''''&<>* | {}');
        Observer.Verify();
    end;

    [Test]
    procedure Placeholders()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Wildcard Row" temporary;
    begin
        Seed(Row);
        Row.SetFilter("No.", '<>%1', '*');
        Observer.Observe('No <>%1 *', Row.GetFilter("No.") + ' | ' + Kept(Row));
        Row.Reset();
        Row.SetFilter("No.", '%1', 'A*');
        Observer.Observe('No %1 A*', Row.GetFilter("No.") + ' | ' + Kept(Row));
        Row.Reset();
        Row.SetFilter("No.", '<>%1*', 'A');
        Observer.Observe('No <>%1* A', Row.GetFilter("No.") + ' | ' + Kept(Row));
        Row.Reset();
        Row.SetFilter(Name, '<>%1', '*');
        Observer.Observe('Name <>%1 *', Row.GetFilter(Name) + ' | ' + Kept(Row));
        Row.Reset();
        Row.SetFilter(Name, '%1&<>%2', '*a*', 'xa');
        Observer.Observe('Name %1&<>%2', Row.GetFilter(Name) + ' | ' + Kept(Row));
        Observer.Expect('No <>%1 *', '<>''*'' | {[][A1][AB][B1][XA]}');
        Observer.Expect('No %1 A*', 'A* | {[A1][AB]}');
        Observer.Expect('No <>%1* A', '<>%1* | {[][A1][AB][B1][XA]}');
        Observer.Expect('Name <>%1 *', '<>''*'' | {[][A1][AB][B1][XA]}');
        Observer.Expect('Name %1&<>%2', '*a*&<>xa | {[A1][AB][B1]}');
        Observer.Verify();
    end;

    [Test]
    procedure NotWildcard_GetView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Wildcard Row" temporary;
        Copy: Record "LT BL Wildcard Row" temporary;
    begin
        Row.SetFilter("No.", '<>*');
        Observer.Observe('view', Row.GetView(false));
        Copy.SetView(Row.GetView(false));
        Observer.Observe('copy getfilter', Copy.GetFilter("No."));
        Copy.Reset();
        Copy.CopyFilters(Row);
        Observer.Observe('copyfilters getfilter', Copy.GetFilter("No."));
        Observer.Expect('view', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(<>*))');
        Observer.Expect('copy getfilter', '<>*');
        Observer.Expect('copyfilters getfilter', '<>*');
        Observer.Verify();
    end;
}
