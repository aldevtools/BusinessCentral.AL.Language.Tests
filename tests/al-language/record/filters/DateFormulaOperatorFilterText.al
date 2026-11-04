// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dateformula/dateformula-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95577 and test codeunit 95578
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 6998: a filter text `'<=' + Format(Date)` refused as the date formula `=11/04/26`). The same text on a Date field is pinned
//   by record/filters/P130DateFilters.al:86; this file covers the places where the text meets a DateFormula.
// Facts: SetFilter on a DateFormula field with an operator and a formatted date, a formatted date alone, and operators before a formula
//   (error text and code, or the filter and the rows it selects); Evaluate of `<=` plus a formatted date into a DateFormula (with and without
//   a return value); CalcDate of that text.
// BC versions: 27, 28, 29

table 95577 "LT R6 Date Formula Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DF; DateFormula) { }
        field(3; D; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95578 "LT R6 Date Formula Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT R6 Date Formula Row";
    begin
        R.DeleteAll();
        Add(1, '');
        Add(2, '<1D>');
        Add(3, '<1M>');
        Add(4, '<-1W>');
    end;

    local procedure Add(Id: Integer; Formula: Text)
    var
        R: Record "LT R6 Date Formula Row";
    begin
        R.Id := Id;
        Evaluate(R.DF, Formula);
        R.D := DMY2Date(Id, 1, 2024);
        R.Insert();
    end;

    local procedure Ids(var R: Record "LT R6 Date Formula Row"): Text
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
    local procedure TrySet(var R: Record "LT R6 Date Formula Row"; FilterText: Text)
    begin
        R.SetFilter(DF, FilterText);
    end;

    [TryFunction]
    local procedure TryRows(var R: Record "LT R6 Date Formula Row"; var Rows: Text)
    begin
        Rows := Ids(R);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT R6 Date Formula Row";
        Rows: Text;
    begin
        ClearLastError();
        if not TrySet(R, FilterText) then begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            exit;
        end;
        if TryRows(R, Rows) then
            Observer.Observe(Name, 'ok filter=' + R.GetFilter(DF) + ' rows=' + Rows)
        else
            Observer.Observe(Name, 'find error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SetFilter_DateFormula_OperatorAndDate()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
    begin
        Seed();
        D1 := 20241104D;
        Probe(Observer, 'le date', '<=' + Format(D1));
        Probe(Observer, 'lt date', '<' + Format(D1));
        Probe(Observer, 'ge date', '>=' + Format(D1));
        Probe(Observer, 'eq date', '=' + Format(D1));
        Probe(Observer, 'date alone', Format(D1));
        Probe(Observer, 'le date by StrSubstNo', StrSubstNo('<=%1', Format(D1)));
        Observer.Finish();
    end;

    [Test]
    procedure SetFilter_DateFormula_OperatorAndFormula()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'bracketed formula', '<1M>');
        Probe(Observer, 'formula without brackets', '1M');
        Probe(Observer, 'le bracketed formula', '<=<1M>');
        Probe(Observer, 'le formula without brackets', '<=1M');
        Probe(Observer, 'ne bracketed formula', '<><1M>');
        Probe(Observer, 'ne formula without brackets', '<>1M');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvaluate(var F: DateFormula; Value: Text)
    begin
        Evaluate(F, Value);
    end;

    [TryFunction]
    local procedure TryCalcDate(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    [Test]
    procedure Evaluate_And_CalcDate_OperatorAndDate()
    var
        Observer: Codeunit "Probe Observer";
        F: DateFormula;
        D1: Date;
        Result: Date;
    begin
        D1 := 20241104D;
        Observer.Observe('evaluate returns', Format(Evaluate(F, '<=' + Format(D1))));
        Observer.Observe('evaluate returns, formula after', Format(F));
        Clear(F);
        ClearLastError();
        if TryEvaluate(F, '<=' + Format(D1)) then
            Observer.Observe('evaluate without return', 'ok ' + Format(F))
        else
            Observer.Observe('evaluate without return', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Clear(F);
        ClearLastError();
        if TryEvaluate(F, Format(D1)) then
            Observer.Observe('evaluate date alone', 'ok ' + Format(F))
        else
            Observer.Observe('evaluate date alone', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryCalcDate('<=' + Format(D1), D1, Result) then
            Observer.Observe('calcdate', 'ok ' + Format(Result, 0, 9))
        else
            Observer.Observe('calcdate', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;
}
