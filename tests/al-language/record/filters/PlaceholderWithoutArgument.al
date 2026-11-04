// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95575 and test codeunit 95576
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 6997: `SetFilter("No.", '<>%1')` with no value argument). record/crud/RcAFilters.al:446 pins the error on an Integer field.
// Facts: SetFilter with a placeholder (%1, %2) and no value argument for it, on a Code, a Text, a Decimal and a Date field: whether it raises
//   (text and code of the error) or which filter it sets (GetFilter) and which rows it selects. The rows hold the values blank, A and %1.
// BC versions: 27, 28, 29

table 95575 "LT R6 Placeholder Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Name; Text[30]) { }
        field(4; Qty; Decimal) { }
        field(5; D; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95576 "LT R6 Placeholder No Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT R6 Placeholder Row";
    begin
        R.DeleteAll();
        Add(1, '', '', 0, 0D);
        Add(2, 'A', 'A', 1, 20240101D);
        Add(3, '%1', '%1', 2, 20240201D);
    end;

    local procedure Add(Id: Integer; No: Code[20]; Name: Text[30]; Qty: Decimal; D: Date)
    var
        R: Record "LT R6 Placeholder Row";
    begin
        R.Id := Id;
        R."No." := No;
        R.Name := Name;
        R.Qty := Qty;
        R.D := D;
        R.Insert();
    end;

    local procedure Ids(var R: Record "LT R6 Placeholder Row"): Text
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
    local procedure TrySet(var R: Record "LT R6 Placeholder Row"; FieldNo: Integer; FilterText: Text)
    begin
        case FieldNo of
            2:
                R.SetFilter("No.", FilterText);
            3:
                R.SetFilter(Name, FilterText);
            4:
                R.SetFilter(Qty, FilterText);
            5:
                R.SetFilter(D, FilterText);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; FilterText: Text)
    var
        R: Record "LT R6 Placeholder Row";
    begin
        ClearLastError();
        if TrySet(R, FieldNo, FilterText) then
            Observer.Observe(Name, 'ok filter=' + R.GetFilters() + ' rows=' + Ids(R))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Code_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'ne', 2, '<>%1');
        Probe(Observer, 'eq', 2, '%1');
        Probe(Observer, 'gt', 2, '>%1');
        Probe(Observer, 'range', 2, '%1..%2');
        Probe(Observer, 'ne and ne literal', 2, '<>%1&<>A');
        Probe(Observer, 'second', 2, '%2');
        Observer.Finish();
    end;

    [Test]
    procedure Text_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'ne', 3, '<>%1');
        Probe(Observer, 'eq', 3, '%1');
        Probe(Observer, 'gt', 3, '>%1');
        Probe(Observer, 'range', 3, '%1..%2');
        Probe(Observer, 'ne and ne literal', 3, '<>%1&<>A');
        Observer.Finish();
    end;

    [Test]
    procedure DecimalAndDate_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'decimal ne', 4, '<>%1');
        Probe(Observer, 'decimal eq', 4, '%1');
        Probe(Observer, 'date ne', 5, '<>%1');
        Probe(Observer, 'date eq', 5, '%1');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryLiteral(var R: Record "LT R6 Placeholder Row")
    begin
        R.SetFilter("No.", '<>%1');
    end;

    // The issue's form: the filter text is a literal in the call, not a variable.
    [Test]
    procedure Code_LiteralNoArgument()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT R6 Placeholder Row";
    begin
        Seed();
        ClearLastError();
        if TryLiteral(R) then
            Observer.Observe('literal ne', 'ok filter=' + R.GetFilters() + ' rows=' + Ids(R))
        else
            Observer.Observe('literal ne', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure Code_EmptyArgumentForComparison()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT R6 Placeholder Row";
    begin
        Seed();
        R.SetFilter("No.", '<>%1', '');
        Observer.Observe('ne blank argument', 'filter=' + R.GetFilters() + ' rows=' + Ids(R));
        Observer.Finish();
    end;
}
