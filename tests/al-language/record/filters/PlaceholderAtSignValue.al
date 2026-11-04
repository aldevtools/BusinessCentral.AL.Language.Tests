// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95583 and test codeunit 95584
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 7034: `SetFilter(Printer, '<>%1', '@NO PRINT')`).
// Facts: a placeholder value that starts with `@`, after `<>` and alone, with and without a wildcard, on a Text and a Code field,
//   next to the same text written in the filter: which rows it keeps and how GetFilter reads it back. Rows: NO PRINT, no print
//   (Text only; the Code field upper-cases it), @NO PRINT, ABC.
// BC versions: 27, 28, 29

table 95583 "LT R6 At Sign Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Printer; Text[250]) { }
        field(3; "Code"; Code[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95584 "LT R6 Placeholder At Sign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT R6 At Sign Row";
    begin
        R.DeleteAll();
        Add(1, 'NO PRINT', 'NO PRINT');
        Add(2, 'no print', 'NO PRINTX');
        Add(3, '@NO PRINT', '@NO PRINT');
        Add(4, 'ABC', 'ABC');
    end;

    local procedure Add(Id: Integer; Printer: Text[250]; CodeValue: Code[50])
    var
        R: Record "LT R6 At Sign Row";
    begin
        R.Id := Id;
        R.Printer := Printer;
        R."Code" := CodeValue;
        R.Insert();
    end;

    local procedure Ids(var R: Record "LT R6 At Sign Row"): Text
    var
        Result: Text;
    begin
        if not R.FindSet() then
            exit('none');
        repeat
            Result += Format(R.Id);
        until R.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT R6 At Sign Row"; OnCode: Boolean; FilterText: Text; Value: Text)
    begin
        if OnCode then
            R.SetFilter("Code", FilterText, Value)
        else
            R.SetFilter(Printer, FilterText, Value);
    end;

    [TryFunction]
    local procedure TrySetLiteral(var R: Record "LT R6 At Sign Row"; OnCode: Boolean; FilterText: Text)
    begin
        if OnCode then
            R.SetFilter("Code", FilterText)
        else
            R.SetFilter(Printer, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; FilterText: Text; Value: Text)
    var
        R: Record "LT R6 At Sign Row";
    begin
        ClearLastError();
        if TrySet(R, OnCode, FilterText, Value) then
            Observer.Observe(Name, 'ok filter=' + R.GetFilters() + ' rows=' + Ids(R))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ProbeLiteral(var Observer: Codeunit "Probe Observer"; Name: Text; OnCode: Boolean; FilterText: Text)
    var
        R: Record "LT R6 At Sign Row";
    begin
        ClearLastError();
        if TrySetLiteral(R, OnCode, FilterText) then
            Observer.Observe(Name, 'ok filter=' + R.GetFilters() + ' rows=' + Ids(R))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Text_AtSignValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ProbeLiteral(Observer, 'literal ne at', false, '<>@NO PRINT');
        Probe(Observer, 'ne at value', false, '<>%1', '@NO PRINT');
        Probe(Observer, 'ne plain value', false, '<>%1', 'NO PRINT');
        Probe(Observer, 'at value alone', false, '%1', '@NO PRINT');
        Probe(Observer, 'ne at value with wildcard', false, '<>%1', '@no*');
        Probe(Observer, 'ne at value lower case', false, '<>%1', '@no print');
        Probe(Observer, 'ne at value and literal', false, '<>%1&<>ABC', '@NO PRINT');
        Probe(Observer, 'at value or literal', false, '%1|ABC', '@NO PRINT');
        Observer.Expect('literal ne at', 'ok filter=Printer: <>@NO PRINT rows=34');
        Observer.Expect('ne at value', 'ok filter=Printer: <>@NO PRINT rows=34');
        Observer.Expect('ne plain value', 'ok filter=Printer: <>NO PRINT rows=234');
        Observer.Expect('at value alone', 'ok filter=Printer: @NO PRINT rows=12');
        Observer.Expect('ne at value with wildcard', 'ok filter=Printer: <>@no* rows=34');
        Observer.Expect('ne at value lower case', 'ok filter=Printer: <>@no print rows=34');
        Observer.Expect('ne at value and literal', 'ok filter=Printer: <>@NO PRINT&<>ABC rows=3');
        Observer.Expect('at value or literal', 'ok filter=Printer: @NO PRINT|ABC rows=124');
        Observer.Verify();
    end;

    [Test]
    procedure Code_AtSignValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ProbeLiteral(Observer, 'literal ne at', true, '<>@NO PRINT');
        Probe(Observer, 'ne at value', true, '<>%1', '@NO PRINT');
        Probe(Observer, 'at value alone', true, '%1', '@NO PRINT');
        Probe(Observer, 'ne at value lower case', true, '<>%1', '@no print');
        Observer.Expect('literal ne at', 'ok filter=Code: <>@NO PRINT rows=234');
        Observer.Expect('ne at value', 'ok filter=Code: <>@NO PRINT rows=234');
        Observer.Expect('at value alone', 'ok filter=Code: @NO PRINT rows=1');
        Observer.Expect('ne at value lower case', 'ok filter=Code: <>@NO PRINT rows=234');
        Observer.Verify();
    end;
}
