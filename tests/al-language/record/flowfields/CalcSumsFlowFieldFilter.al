// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcSums on a record whose filter is on a FlowField: SetFilter(FlowField, '<>0'), SetRange(FlowField, 0), SetRange to a value, a range, combined with a stored-field filter (assumption calcsums-flowfield-filter); record/TestRecordFlowField.al:141-160 pins stored-field filters only.
// BC versions: 29 (27 and 28 by CI)

table 70392 "LT CSFF Row"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Amount; Decimal) { }
        field(3; Qty; Decimal) { }
        field(4; "Entry Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CSFF Entry" where("Row No." = field("No.")));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 70393 "LT CSFF Entry"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Row No."; Code[10]) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 70394 "LT CSFF CalcSums"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT CSFF Row";
        Entry: Record "LT CSFF Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        AddRow('R1', 10, 1);
        AddRow('R2', 20, 2);
        AddRow('R3', 40, 4);
        AddRow('R4', 80, 8);
        AddEntry(1, 'R2');
        AddEntry(2, 'R3');
        AddEntry(3, 'R3');
        AddEntry(4, 'R4');
        AddEntry(5, 'R4');
        AddEntry(6, 'R4');
    end;

    local procedure AddRow(No: Code[10]; Amt: Decimal; Q: Decimal)
    var
        Row: Record "LT CSFF Row";
    begin
        Row."No." := No;
        Row.Amount := Amt;
        Row.Qty := Q;
        Row.Insert();
    end;

    local procedure AddEntry(No: Integer; RowNo: Code[10])
    var
        Entry: Record "LT CSFF Entry";
    begin
        Entry."Entry No." := No;
        Entry."Row No." := RowNo;
        Entry.Insert();
    end;

    [Test]
    procedure CalcSums_FilterFlowFieldNotZero_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CSFF Row";
    begin
        Seed();
        Row.SetFilter("Entry Count", '<>0');
        Observer.Observe('count_not_zero', Format(Row.Count()));
        Row.CalcSums(Amount);
        Observer.Observe('sum_amount_not_zero', Format(Row.Amount));
        Row.CalcSums(Amount, Qty);
        Observer.Observe('sum_two_amount', Format(Row.Amount));
        Observer.Observe('sum_two_qty', Format(Row.Qty));
        Observer.Expect('count_not_zero', '3');
        Observer.Expect('sum_amount_not_zero', '140');
        Observer.Expect('sum_two_amount', '140');
        Observer.Expect('sum_two_qty', '14');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_SetRangeFlowFieldZero_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CSFF Row";
    begin
        Seed();
        Row.SetRange("Entry Count", 0);
        Observer.Observe('count_zero', Format(Row.Count()));
        Row.CalcSums(Amount);
        Observer.Observe('sum_amount_zero', Format(Row.Amount));
        Row.SetRange("Entry Count", 3);
        Row.CalcSums(Amount);
        Observer.Observe('sum_amount_three', Format(Row.Amount));
        Row.SetRange("Entry Count", 7);
        Row.CalcSums(Amount);
        Observer.Observe('sum_amount_seven_none', Format(Row.Amount));
        Observer.Expect('count_zero', '1');
        Observer.Expect('sum_amount_zero', '10');
        Observer.Expect('sum_amount_three', '80');
        Observer.Expect('sum_amount_seven_none', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_FlowFieldRangeAndStoredFilter_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CSFF Row";
    begin
        Seed();
        Row.SetFilter("Entry Count", '2..3');
        Row.CalcSums(Amount);
        Observer.Observe('sum_range_2_3', Format(Row.Amount));
        Row.SetFilter("Entry Count", '>=1');
        Row.SetFilter(Qty, '<8');
        Row.CalcSums(Amount);
        Observer.Observe('sum_flow_and_stored', Format(Row.Amount));
        Row.Reset();
        Row.SetFilter("Entry Count", '<>0');
        Row.SetFilter("No.", 'R2|R4');
        Row.CalcSums(Amount);
        Observer.Observe('sum_flow_and_key', Format(Row.Amount));
        Observer.Expect('sum_range_2_3', '120');
        Observer.Expect('sum_flow_and_stored', '60');
        Observer.Expect('sum_flow_and_key', '100');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_AfterFlowFieldFilterReset_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CSFF Row";
    begin
        Seed();
        Row.SetFilter("Entry Count", '<>0');
        Row.CalcSums(Amount);
        Observer.Observe('filtered', Format(Row.Amount));
        Row.SetRange("Entry Count");
        Row.CalcSums(Amount);
        Observer.Observe('range_cleared', Format(Row.Amount));
        Observer.Observe('getfilter_after_clear', Row.GetFilter("Entry Count"));
        Observer.Expect('filtered', '140');
        Observer.Expect('range_cleared', '150');
        Observer.Expect('getfilter_after_clear', '');
        Observer.Verify();
    end;
}
