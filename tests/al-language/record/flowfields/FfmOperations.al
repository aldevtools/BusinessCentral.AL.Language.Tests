// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM Ops *)
// local object: the CalcFormula definitions and their OnValidate triggers are what the tests measure.
// Area: FlowField and FlowFilter matrix, operations. Every CalcFormula kind (sum, -sum, average, min, max, count, -count, exist, lookup of a Text
//   and of a Decimal field, -lookup) crossed with: Validate with a value and without (with and without an OnValidate trigger, the value and the
//   trigger log afterwards, whether a later CalcFields overwrites it), assignment then CalcFields, SetAutoCalcFields (Get, Find, FindSet and Next),
//   SetRange and SetFilter on the FlowField (the rows found and Count), SetCurrentKey with the FlowField (the row order).
//   CalcSums on a FlowField does not compile (tests/must-not-compile/cases, AL0827).
// Nearby: TestCalcFormulaValidationTests.Codeunit.al, TestSetAutoCalcFieldsOnGet.Codeunit.al, record/keys-sorting/PwFlowFieldKeyRule.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

table 64501 "FFM Ops Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Amt; Decimal) { }
        field(4; Name; Text[30]) { }
        field(5; Day; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64502 "FFM Ops Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Rank; Integer) { }
        field(3; DateF; Date) { FieldClass = FlowFilter; }
        field(100; SumF; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("FFM Ops Detail".Amt where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('SumF', Format(SumF));
            end;
        }
        field(101; NSumF; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -sum("FFM Ops Detail".Amt where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('NSumF', Format(NSumF));
            end;
        }
        field(102; AvgF; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM Ops Detail".Amt where(Owner = field(Code))); }
        field(103; MinF; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM Ops Detail".Amt where(Owner = field(Code))); }
        field(104; MaxF; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM Ops Detail".Amt where(Owner = field(Code))); }
        field(105; CntF; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("FFM Ops Detail" where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('CntF', Format(CntF));
            end;
        }
        field(106; NCntF; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = -count("FFM Ops Detail" where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('NCntF', Format(NCntF));
            end;
        }
        field(107; ExF; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("FFM Ops Detail" where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('ExF', Format(ExF));
            end;
        }
        field(108; LkF; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("FFM Ops Detail".Name where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM Ops Log";
            begin
                Log.Add('LkF', Format(LkF));
            end;
        }
        field(109; LkDecF; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Ops Detail".Amt where(Owner = field(Code))); }
        field(110; NLkDecF; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Ops Detail".Amt where(Owner = field(Code))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 64500 "FFM Ops Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Name: Text; Value: Text)
    begin
        Text += Name + '=' + Value + ';';
    end;

    procedure Get(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

codeunit 64503 "FFM Ops Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "FFM Ops Log";

    // Not a TryFunction: Validate of a Sum FlowField writes, and a write inside a TryFunction ends the test (INSERT is refused there, and that error is not caught).
    local procedure TryValidateSumF(var H: Record "FFM Ops Header"): Boolean
    begin
        H.Validate(SumF, 5.5);
        exit(true);
    end;

    // Not a TryFunction: Validate of a Sum FlowField writes, and a write inside a TryFunction ends the test (INSERT is refused there, and that error is not caught).
    local procedure TryValidateNoValueSumF(var H: Record "FFM Ops Header"): Boolean
    begin
        H.Validate(SumF);
        exit(true);
    end;

    // Not a TryFunction: Validate of a Sum FlowField writes, and a write inside a TryFunction ends the test (INSERT is refused there, and that error is not caught).
    local procedure TryValidateNSumF(var H: Record "FFM Ops Header"): Boolean
    begin
        H.Validate(NSumF, 5.5);
        exit(true);
    end;

    // Not a TryFunction: Validate of a Sum FlowField writes, and a write inside a TryFunction ends the test (INSERT is refused there, and that error is not caught).
    local procedure TryValidateNoValueNSumF(var H: Record "FFM Ops Header"): Boolean
    begin
        H.Validate(NSumF);
        exit(true);
    end;

    [TryFunction]
    local procedure TryValidateAvgF(var H: Record "FFM Ops Header")
    begin
        H.Validate(AvgF, 5.5);
    end;

    [TryFunction]
    local procedure TryValidateNoValueAvgF(var H: Record "FFM Ops Header")
    begin
        H.Validate(AvgF);
    end;

    [TryFunction]
    local procedure TryValidateMinF(var H: Record "FFM Ops Header")
    begin
        H.Validate(MinF, 5.5);
    end;

    [TryFunction]
    local procedure TryValidateNoValueMinF(var H: Record "FFM Ops Header")
    begin
        H.Validate(MinF);
    end;

    [TryFunction]
    local procedure TryValidateMaxF(var H: Record "FFM Ops Header")
    begin
        H.Validate(MaxF, 5.5);
    end;

    [TryFunction]
    local procedure TryValidateNoValueMaxF(var H: Record "FFM Ops Header")
    begin
        H.Validate(MaxF);
    end;

    [TryFunction]
    local procedure TryValidateCntF(var H: Record "FFM Ops Header")
    begin
        H.Validate(CntF, 7);
    end;

    [TryFunction]
    local procedure TryValidateNoValueCntF(var H: Record "FFM Ops Header")
    begin
        H.Validate(CntF);
    end;

    [TryFunction]
    local procedure TryValidateExF(var H: Record "FFM Ops Header")
    begin
        H.Validate(ExF, true);
    end;

    [TryFunction]
    local procedure TryValidateNoValueExF(var H: Record "FFM Ops Header")
    begin
        H.Validate(ExF);
    end;

    [TryFunction]
    local procedure TryValidateLkF(var H: Record "FFM Ops Header")
    begin
        H.Validate(LkF, 'zz');
    end;

    [TryFunction]
    local procedure TryValidateNoValueLkF(var H: Record "FFM Ops Header")
    begin
        H.Validate(LkF);
    end;

    [TryFunction]
    local procedure TryValidateLkDecF(var H: Record "FFM Ops Header")
    begin
        H.Validate(LkDecF, 5.5);
    end;

    [TryFunction]
    local procedure TryValidateNoValueLkDecF(var H: Record "FFM Ops Header")
    begin
        H.Validate(LkDecF);
    end;

    [TryFunction]
    local procedure TryValidateNLkDecF(var H: Record "FFM Ops Header")
    begin
        H.Validate(NLkDecF, 5.5);
    end;

    [TryFunction]
    local procedure TryValidateNoValueNLkDecF(var H: Record "FFM Ops Header")
    begin
        H.Validate(NLkDecF);
    end;

    [TryFunction]
    local procedure TryCalc_SumF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(SumF);
    end;

    [TryFunction]
    local procedure TryCalc_NSumF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(NSumF);
    end;

    [TryFunction]
    local procedure TryCalc_AvgF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(AvgF);
    end;

    [TryFunction]
    local procedure TryCalc_MinF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(MinF);
    end;

    [TryFunction]
    local procedure TryCalc_MaxF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(MaxF);
    end;

    [TryFunction]
    local procedure TryCalc_CntF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(CntF);
    end;

    [TryFunction]
    local procedure TryCalc_ExF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(ExF);
    end;

    [TryFunction]
    local procedure TryCalc_LkF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(LkF);
    end;

    [TryFunction]
    local procedure TryCalc_LkDecF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(LkDecF);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDecF(var H: Record "FFM Ops Header")
    begin
        H.CalcFields(NLkDecF);
    end;

    [Test]
    procedure FlowFieldValidate_ValueAndTrigger_Group1()
    // CLAIM: Validate on SumF, NSumF, AvgF with a value, with none, and plain assignment: the result, the OnValidate log and what CalcFields does afterwards.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_SumF(H) then
            Observer.ObserveError('SumF.calc1');
        Observer.Observe('SumF.calc', Format(H.SumF));
        Log.Get();
        if TryValidateSumF(H) then
            Observer.Observe('SumF.validate', 'ok')
        else
            Observer.Observe('SumF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('SumF.value', Format(H.SumF));
        Observer.Observe('SumF.log', Log.Get());
        if not TryCalc_SumF(H) then
            Observer.ObserveError('SumF.calc2');
        Observer.Observe('SumF.recalc', Format(H.SumF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueSumF(H) then
            Observer.Observe('SumF.validate1', 'ok')
        else
            Observer.Observe('SumF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('SumF.log1', Log.Get());
        H.SumF := 5.5;
        Observer.Observe('SumF.assigned', Format(H.SumF));
        if not TryCalc_SumF(H) then
            Observer.ObserveError('SumF.calc3');
        Observer.Observe('SumF.assigned.recalc', Format(H.SumF));
        H.Get('H1');
        if not TryCalc_NSumF(H) then
            Observer.ObserveError('NSumF.calc4');
        Observer.Observe('NSumF.calc', Format(H.NSumF));
        Log.Get();
        if TryValidateNSumF(H) then
            Observer.Observe('NSumF.validate', 'ok')
        else
            Observer.Observe('NSumF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('NSumF.value', Format(H.NSumF));
        Observer.Observe('NSumF.log', Log.Get());
        if not TryCalc_NSumF(H) then
            Observer.ObserveError('NSumF.calc5');
        Observer.Observe('NSumF.recalc', Format(H.NSumF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueNSumF(H) then
            Observer.Observe('NSumF.validate1', 'ok')
        else
            Observer.Observe('NSumF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('NSumF.log1', Log.Get());
        H.NSumF := 5.5;
        Observer.Observe('NSumF.assigned', Format(H.NSumF));
        if not TryCalc_NSumF(H) then
            Observer.ObserveError('NSumF.calc6');
        Observer.Observe('NSumF.assigned.recalc', Format(H.NSumF));
        H.Get('H1');
        if not TryCalc_AvgF(H) then
            Observer.ObserveError('AvgF.calc7');
        Observer.Observe('AvgF.calc', Format(H.AvgF));
        Log.Get();
        if TryValidateAvgF(H) then
            Observer.Observe('AvgF.validate', 'ok')
        else
            Observer.Observe('AvgF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('AvgF.value', Format(H.AvgF));
        Observer.Observe('AvgF.log', Log.Get());
        if not TryCalc_AvgF(H) then
            Observer.ObserveError('AvgF.calc8');
        Observer.Observe('AvgF.recalc', Format(H.AvgF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueAvgF(H) then
            Observer.Observe('AvgF.validate1', 'ok')
        else
            Observer.Observe('AvgF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('AvgF.log1', Log.Get());
        H.AvgF := 5.5;
        Observer.Observe('AvgF.assigned', Format(H.AvgF));
        if not TryCalc_AvgF(H) then
            Observer.ObserveError('AvgF.calc9');
        Observer.Observe('AvgF.assigned.recalc', Format(H.AvgF));
        Observer.Expect('SumF.calc', '150.75');
        Observer.Expect('SumF.validate', 'ok');
        Observer.Expect('SumF.value', '5.5');
        Observer.Expect('SumF.log', 'SumF=5.5;');
        Observer.Expect('SumF.recalc', '5.5');
        Observer.Expect('SumF.validate1', 'ok');
        Observer.Expect('SumF.log1', 'SumF=0;');
        Observer.Expect('SumF.assigned', '5.5');
        Observer.Expect('SumF.assigned.recalc', '0');
        Observer.Expect('NSumF.calc', '0');
        Observer.Expect('NSumF.validate', 'ok');
        Observer.Expect('NSumF.value', '5.5');
        Observer.Expect('NSumF.log', 'NSumF=5.5;');
        Observer.Expect('NSumF.recalc', '5.5');
        Observer.Expect('NSumF.validate1', 'ok');
        Observer.Expect('NSumF.log1', 'NSumF=0;');
        Observer.Expect('NSumF.assigned', '5.5');
        Observer.Expect('NSumF.assigned.recalc', '0');
        Observer.Expect('AvgF.calc', '0');
        Observer.Expect('AvgF.validate', 'error: The Calculation formula for the AvgF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('AvgF.value', '0');
        Observer.Expect('AvgF.log', '');
        Observer.Expect('AvgF.recalc', '0');
        Observer.Expect('AvgF.validate1', 'error: The Calculation formula for the AvgF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('AvgF.log1', '');
        Observer.Expect('AvgF.assigned', '5.5');
        Observer.Expect('AvgF.assigned.recalc', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldValidate_ValueAndTrigger_Group2()
    // CLAIM: Validate on MinF, MaxF, CntF with a value, with none, and plain assignment: the result, the OnValidate log and what CalcFields does afterwards.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_MinF(H) then
            Observer.ObserveError('MinF.calc10');
        Observer.Observe('MinF.calc', Format(H.MinF));
        Log.Get();
        if TryValidateMinF(H) then
            Observer.Observe('MinF.validate', 'ok')
        else
            Observer.Observe('MinF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('MinF.value', Format(H.MinF));
        Observer.Observe('MinF.log', Log.Get());
        if not TryCalc_MinF(H) then
            Observer.ObserveError('MinF.calc11');
        Observer.Observe('MinF.recalc', Format(H.MinF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueMinF(H) then
            Observer.Observe('MinF.validate1', 'ok')
        else
            Observer.Observe('MinF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('MinF.log1', Log.Get());
        H.MinF := 5.5;
        Observer.Observe('MinF.assigned', Format(H.MinF));
        if not TryCalc_MinF(H) then
            Observer.ObserveError('MinF.calc12');
        Observer.Observe('MinF.assigned.recalc', Format(H.MinF));
        H.Get('H1');
        if not TryCalc_MaxF(H) then
            Observer.ObserveError('MaxF.calc13');
        Observer.Observe('MaxF.calc', Format(H.MaxF));
        Log.Get();
        if TryValidateMaxF(H) then
            Observer.Observe('MaxF.validate', 'ok')
        else
            Observer.Observe('MaxF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('MaxF.value', Format(H.MaxF));
        Observer.Observe('MaxF.log', Log.Get());
        if not TryCalc_MaxF(H) then
            Observer.ObserveError('MaxF.calc14');
        Observer.Observe('MaxF.recalc', Format(H.MaxF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueMaxF(H) then
            Observer.Observe('MaxF.validate1', 'ok')
        else
            Observer.Observe('MaxF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('MaxF.log1', Log.Get());
        H.MaxF := 5.5;
        Observer.Observe('MaxF.assigned', Format(H.MaxF));
        if not TryCalc_MaxF(H) then
            Observer.ObserveError('MaxF.calc15');
        Observer.Observe('MaxF.assigned.recalc', Format(H.MaxF));
        H.Get('H1');
        if not TryCalc_CntF(H) then
            Observer.ObserveError('CntF.calc16');
        Observer.Observe('CntF.calc', Format(H.CntF));
        Log.Get();
        if TryValidateCntF(H) then
            Observer.Observe('CntF.validate', 'ok')
        else
            Observer.Observe('CntF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('CntF.value', Format(H.CntF));
        Observer.Observe('CntF.log', Log.Get());
        if not TryCalc_CntF(H) then
            Observer.ObserveError('CntF.calc17');
        Observer.Observe('CntF.recalc', Format(H.CntF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueCntF(H) then
            Observer.Observe('CntF.validate1', 'ok')
        else
            Observer.Observe('CntF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('CntF.log1', Log.Get());
        H.CntF := 7;
        Observer.Observe('CntF.assigned', Format(H.CntF));
        if not TryCalc_CntF(H) then
            Observer.ObserveError('CntF.calc18');
        Observer.Observe('CntF.assigned.recalc', Format(H.CntF));
        Observer.Expect('MinF.calc', '10.5');
        Observer.Expect('MinF.validate', 'error: The Calculation formula for the MinF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('MinF.value', '10.5');
        Observer.Expect('MinF.log', '');
        Observer.Expect('MinF.recalc', '10.5');
        Observer.Expect('MinF.validate1', 'error: The Calculation formula for the MinF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('MinF.log1', '');
        Observer.Expect('MinF.assigned', '5.5');
        Observer.Expect('MinF.assigned.recalc', '10.5');
        Observer.Expect('MaxF.calc', '80');
        Observer.Expect('MaxF.validate', 'error: The Calculation formula for the MaxF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('MaxF.value', '80');
        Observer.Expect('MaxF.log', '');
        Observer.Expect('MaxF.recalc', '80');
        Observer.Expect('MaxF.validate1', 'error: The Calculation formula for the MaxF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('MaxF.log1', '');
        Observer.Expect('MaxF.assigned', '5.5');
        Observer.Expect('MaxF.assigned.recalc', '80');
        Observer.Expect('CntF.calc', '4');
        Observer.Expect('CntF.validate', 'error: The type of the CntF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('CntF.value', '4');
        Observer.Expect('CntF.log', 'CntF=7;');
        Observer.Expect('CntF.recalc', '4');
        Observer.Expect('CntF.validate1', 'error: The type of the CntF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('CntF.log1', 'CntF=0;');
        Observer.Expect('CntF.assigned', '7');
        Observer.Expect('CntF.assigned.recalc', '4');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldValidate_ValueAndTrigger_Group3()
    // CLAIM: Validate on ExF, LkF with a value, with none, and plain assignment: the result, the OnValidate log and what CalcFields does afterwards.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Get('H1');
        H.Get('H1');
        if not TryCalc_ExF(H) then
            Observer.ObserveError('ExF.calc19');
        Observer.Observe('ExF.calc', Format(H.ExF));
        Log.Get();
        if TryValidateExF(H) then
            Observer.Observe('ExF.validate', 'ok')
        else
            Observer.Observe('ExF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('ExF.value', Format(H.ExF));
        Observer.Observe('ExF.log', Log.Get());
        if not TryCalc_ExF(H) then
            Observer.ObserveError('ExF.calc20');
        Observer.Observe('ExF.recalc', Format(H.ExF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueExF(H) then
            Observer.Observe('ExF.validate1', 'ok')
        else
            Observer.Observe('ExF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('ExF.log1', Log.Get());
        H.ExF := true;
        Observer.Observe('ExF.assigned', Format(H.ExF));
        if not TryCalc_ExF(H) then
            Observer.ObserveError('ExF.calc21');
        Observer.Observe('ExF.assigned.recalc', Format(H.ExF));
        H.Get('H1');
        if not TryCalc_LkF(H) then
            Observer.ObserveError('LkF.calc22');
        Observer.Observe('LkF.calc', Format(H.LkF));
        Log.Get();
        if TryValidateLkF(H) then
            Observer.Observe('LkF.validate', 'ok')
        else
            Observer.Observe('LkF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('LkF.value', Format(H.LkF));
        Observer.Observe('LkF.log', Log.Get());
        if not TryCalc_LkF(H) then
            Observer.ObserveError('LkF.calc23');
        Observer.Observe('LkF.recalc', Format(H.LkF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueLkF(H) then
            Observer.Observe('LkF.validate1', 'ok')
        else
            Observer.Observe('LkF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('LkF.log1', Log.Get());
        H.LkF := 'zz';
        Observer.Observe('LkF.assigned', Format(H.LkF));
        if not TryCalc_LkF(H) then
            Observer.ObserveError('LkF.calc24');
        Observer.Observe('LkF.assigned.recalc', Format(H.LkF));
        Observer.Expect('ExF.calc', 'Yes');
        Observer.Expect('ExF.validate', 'error: The type of the ExF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('ExF.value', 'Yes');
        Observer.Expect('ExF.log', 'ExF=Yes;');
        Observer.Expect('ExF.recalc', 'Yes');
        Observer.Expect('ExF.validate1', 'error: The type of the ExF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('ExF.log1', 'ExF=No;');
        Observer.Expect('ExF.assigned', 'Yes');
        Observer.Expect('ExF.assigned.recalc', 'Yes');
        Observer.Expect('LkF.calc', 'alpha');
        Observer.Expect('LkF.validate', 'error: The type of the LkF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('LkF.value', 'alpha');
        Observer.Expect('LkF.log', 'LkF=zz;');
        Observer.Expect('LkF.recalc', 'alpha');
        Observer.Expect('LkF.validate1', 'error: The type of the LkF FlowField in the FFM Ops Header table must be Decimal.');
        Observer.Expect('LkF.log1', 'LkF=;');
        Observer.Expect('LkF.assigned', 'zz');
        Observer.Expect('LkF.assigned.recalc', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldValidate_ValueAndTrigger_Group4()
    // CLAIM: Validate on LkDecF, NLkDecF with a value, with none, and plain assignment: the result, the OnValidate log and what CalcFields does afterwards.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_LkDecF(H) then
            Observer.ObserveError('LkDecF.calc25');
        Observer.Observe('LkDecF.calc', Format(H.LkDecF));
        Log.Get();
        if TryValidateLkDecF(H) then
            Observer.Observe('LkDecF.validate', 'ok')
        else
            Observer.Observe('LkDecF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('LkDecF.value', Format(H.LkDecF));
        Observer.Observe('LkDecF.log', Log.Get());
        if not TryCalc_LkDecF(H) then
            Observer.ObserveError('LkDecF.calc26');
        Observer.Observe('LkDecF.recalc', Format(H.LkDecF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueLkDecF(H) then
            Observer.Observe('LkDecF.validate1', 'ok')
        else
            Observer.Observe('LkDecF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('LkDecF.log1', Log.Get());
        H.LkDecF := 5.5;
        Observer.Observe('LkDecF.assigned', Format(H.LkDecF));
        if not TryCalc_LkDecF(H) then
            Observer.ObserveError('LkDecF.calc27');
        Observer.Observe('LkDecF.assigned.recalc', Format(H.LkDecF));
        H.Get('H1');
        if not TryCalc_NLkDecF(H) then
            Observer.ObserveError('NLkDecF.calc28');
        Observer.Observe('NLkDecF.calc', Format(H.NLkDecF));
        Log.Get();
        if TryValidateNLkDecF(H) then
            Observer.Observe('NLkDecF.validate', 'ok')
        else
            Observer.Observe('NLkDecF.validate', 'error: ' + GetLastErrorText());
        Observer.Observe('NLkDecF.value', Format(H.NLkDecF));
        Observer.Observe('NLkDecF.log', Log.Get());
        if not TryCalc_NLkDecF(H) then
            Observer.ObserveError('NLkDecF.calc29');
        Observer.Observe('NLkDecF.recalc', Format(H.NLkDecF));
        H.Get('H1');
        Log.Get();
        if TryValidateNoValueNLkDecF(H) then
            Observer.Observe('NLkDecF.validate1', 'ok')
        else
            Observer.Observe('NLkDecF.validate1', 'error: ' + GetLastErrorText());
        Observer.Observe('NLkDecF.log1', Log.Get());
        H.NLkDecF := 5.5;
        Observer.Observe('NLkDecF.assigned', Format(H.NLkDecF));
        if not TryCalc_NLkDecF(H) then
            Observer.ObserveError('NLkDecF.calc30');
        Observer.Observe('NLkDecF.assigned.recalc', Format(H.NLkDecF));
        Observer.Expect('LkDecF.calc', '10.5');
        Observer.Expect('LkDecF.validate', 'error: The Calculation formula for the LkDecF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('LkDecF.value', '10.5');
        Observer.Expect('LkDecF.log', '');
        Observer.Expect('LkDecF.recalc', '10.5');
        Observer.Expect('LkDecF.validate1', 'error: The Calculation formula for the LkDecF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('LkDecF.log1', '');
        Observer.Expect('LkDecF.assigned', '5.5');
        Observer.Expect('LkDecF.assigned.recalc', '10.5');
        Observer.Expect('NLkDecF.calc', '10.5');
        Observer.Expect('NLkDecF.validate', 'error: The Calculation formula for the NLkDecF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('NLkDecF.value', '10.5');
        Observer.Expect('NLkDecF.log', '');
        Observer.Expect('NLkDecF.recalc', '10.5');
        Observer.Expect('NLkDecF.validate1', 'error: The Calculation formula for the NLkDecF FlowField in the FFM Ops Header table must start with ''Sum(...''.');
        Observer.Expect('NLkDecF.log1', '');
        Observer.Expect('NLkDecF.assigned', '5.5');
        Observer.Expect('NLkDecF.assigned.recalc', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_EveryKind_GetFindSetNext()
    // CLAIM: SetAutoCalcFields over every CalcFormula kind: values after Get, FindFirst, FindSet and Next, with and without a FlowFilter, and after a reset.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.SetAutoCalcFields(SumF, NSumF, CntF, ExF, LkF);
        H.Get('H1');
        Observer.Observe('get', Format(H.SumF) + '|' + Format(H.NSumF) + '|' + Format(H.CntF) + '|' + Format(H.ExF) + '|' + H.LkF);
        H.Get('H3');
        Observer.Observe('get.empty', Format(H.SumF) + '|' + Format(H.NSumF) + '|' + Format(H.CntF) + '|' + Format(H.ExF) + '|' + H.LkF);
        H.FindFirst();
        Observer.Observe('findfirst', H.Code + ':' + Format(H.SumF) + '|' + Format(H.CntF) + '|' + Format(H.ExF) + '|' + H.LkF);
        H.FindSet();
        repeat
            Observer.Observe('findset.' + H.Code, Format(H.SumF) + '|' + Format(H.NSumF) + '|' + Format(H.CntF) + '|' + Format(H.ExF) + '|' + H.LkF);
        until H.Next() = 0;
        H.SetRange(DateF, 20260201D, 20260430D);
        H.Get('H1');
        Observer.Observe('get.dateF', Format(H.SumF) + '|' + Format(H.CntF));
        H.SetAutoCalcFields();
        H.Get('H1');
        Observer.Observe('get.reset', Format(H.SumF) + '|' + Format(H.CntF));
        H.SetAutoCalcFields(AvgF, MinF, MaxF, LkDecF, NLkDecF);
        H.Get('H2');
        Observer.Observe('get.more', Format(H.AvgF) + '|' + Format(H.MinF) + '|' + Format(H.MaxF) + '|' + Format(H.LkDecF) + '|' + Format(H.NLkDecF));
        Observer.Expect('get', '150.75|-150.75|4|Yes|alpha');
        Observer.Expect('get.empty', '0|0|0|No|');
        Observer.Expect('findfirst', 'H1:150.75|4|Yes|alpha');
        Observer.Expect('findset.H1', '150.75|-150.75|4|Yes|alpha');
        Observer.Expect('findset.H2', '21|-21|2|Yes|echo');
        Observer.Expect('findset.H3', '0|0|0|No|');
        Observer.Expect('get.dateF', '150.75|4');
        Observer.Expect('get.reset', '0|0');
        Observer.Expect('get.more', '10.5|7|14|7|7');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldFilter_SetRangeSetFilter_Group1()
    // CLAIM: SetRange and SetFilter on SumF, NSumF, AvgF, MinF: the headers found, Count and GetFilter.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Reset();
        H.SetFilter(SumF, '>100');
        Observer.Observe('SumF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(SumF));
        H.Reset();
        H.SetRange(SumF, 5.5);
        Observer.Observe('SumF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(SumF, 0);
        Observer.Observe('SumF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(NSumF, '<-100');
        Observer.Observe('NSumF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(NSumF));
        H.Reset();
        H.SetRange(NSumF, 5.5);
        Observer.Observe('NSumF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(NSumF, 0);
        Observer.Observe('NSumF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(AvgF, '>30');
        Observer.Observe('AvgF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(AvgF));
        H.Reset();
        H.SetRange(AvgF, 5.5);
        Observer.Observe('AvgF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(AvgF, 0);
        Observer.Observe('AvgF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(MinF, '<=10.5');
        Observer.Observe('MinF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(MinF));
        H.Reset();
        H.SetRange(MinF, 5.5);
        Observer.Observe('MinF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(MinF, 0);
        Observer.Observe('MinF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        Observer.Expect('SumF.setfilter', '1:H1,:>100');
        Observer.Expect('SumF.setrange.value', '0:');
        Observer.Expect('SumF.setrange.zero', '1:H3,');
        Observer.Expect('NSumF.setfilter', '1:H1,:<-100');
        Observer.Expect('NSumF.setrange.value', '0:');
        Observer.Expect('NSumF.setrange.zero', '1:H3,');
        Observer.Expect('AvgF.setfilter', '1:H1,:>30');
        Observer.Expect('AvgF.setrange.value', '0:');
        Observer.Expect('AvgF.setrange.zero', '1:H3,');
        Observer.Expect('MinF.setfilter', '3:H1,H2,H3,:<=10.5');
        Observer.Expect('MinF.setrange.value', '0:');
        Observer.Expect('MinF.setrange.zero', '1:H3,');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldFilter_SetRangeSetFilter_Group2()
    // CLAIM: SetRange and SetFilter on MaxF, CntF, NCntF, ExF: the headers found, Count and GetFilter.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Reset();
        H.SetFilter(MaxF, '>=80');
        Observer.Observe('MaxF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(MaxF));
        H.Reset();
        H.SetRange(MaxF, 5.5);
        Observer.Observe('MaxF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(MaxF, 0);
        Observer.Observe('MaxF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(CntF, '>2');
        Observer.Observe('CntF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(CntF));
        H.Reset();
        H.SetRange(CntF, 7);
        Observer.Observe('CntF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(CntF, 0);
        Observer.Observe('CntF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(NCntF, '<-2');
        Observer.Observe('NCntF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(NCntF));
        H.Reset();
        H.SetRange(NCntF, 7);
        Observer.Observe('NCntF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(NCntF, 0);
        Observer.Observe('NCntF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(ExF, true);
        Observer.Observe('ExF.setrange.true', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(ExF, false);
        Observer.Observe('ExF.setrange.false', Format(H.Count()) + ':' + Rows(H));
        Observer.Expect('MaxF.setfilter', '1:H1,:>=80');
        Observer.Expect('MaxF.setrange.value', '0:');
        Observer.Expect('MaxF.setrange.zero', '1:H3,');
        Observer.Expect('CntF.setfilter', '1:H1,:>2');
        Observer.Expect('CntF.setrange.value', '0:');
        Observer.Expect('CntF.setrange.zero', '1:H3,');
        Observer.Expect('NCntF.setfilter', '1:H1,:<-2');
        Observer.Expect('NCntF.setrange.value', '0:');
        Observer.Expect('NCntF.setrange.zero', '1:H3,');
        Observer.Expect('ExF.setrange.true', '2:H1,H2,');
        Observer.Expect('ExF.setrange.false', '1:H3,');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldFilter_SetRangeSetFilter_Group3()
    // CLAIM: SetRange and SetFilter on LkF, LkDecF, NLkDecF: the headers found, Count and GetFilter.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Reset();
        H.SetFilter(LkF, 'a*');
        Observer.Observe('LkF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(LkF));
        H.Reset();
        H.SetRange(LkF, 'zz');
        Observer.Observe('LkF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(LkF, '');
        Observer.Observe('LkF.setrange.empty', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(LkDecF, '>10');
        Observer.Observe('LkDecF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(LkDecF));
        H.Reset();
        H.SetRange(LkDecF, 5.5);
        Observer.Observe('LkDecF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(LkDecF, 0);
        Observer.Observe('LkDecF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetFilter(NLkDecF, '<-10');
        Observer.Observe('NLkDecF.setfilter', Format(H.Count()) + ':' + Rows(H) + ':' + H.GetFilter(NLkDecF));
        H.Reset();
        H.SetRange(NLkDecF, 5.5);
        Observer.Observe('NLkDecF.setrange.value', Format(H.Count()) + ':' + Rows(H));
        H.Reset();
        H.SetRange(NLkDecF, 0);
        Observer.Observe('NLkDecF.setrange.zero', Format(H.Count()) + ':' + Rows(H));
        Observer.Expect('LkF.setfilter', '1:H1,:a*');
        Observer.Expect('LkF.setrange.value', '0:');
        Observer.Expect('LkF.setrange.empty', '1:H3,');
        Observer.Expect('LkDecF.setfilter', '1:H1,:>10');
        Observer.Expect('LkDecF.setrange.value', '0:');
        Observer.Expect('LkDecF.setrange.zero', '1:H3,');
        Observer.Expect('NLkDecF.setfilter', '1:H1,:<-10');
        Observer.Expect('NLkDecF.setrange.value', '0:');
        Observer.Expect('NLkDecF.setrange.zero', '1:H3,');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSort_SetCurrentKeyFlowField_RowOrder()
    // CLAIM: SetCurrentKey on a FlowField of every CalcFormula kind: the CurrentKey and the row order read afterwards.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Rank := 0;
        H.Reset();
        H.SetCurrentKey(SumF);
        Observer.Observe('SumF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(NSumF);
        Observer.Observe('NSumF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(AvgF);
        Observer.Observe('AvgF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(MinF);
        Observer.Observe('MinF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(MaxF);
        Observer.Observe('MaxF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(CntF);
        Observer.Observe('CntF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(NCntF);
        Observer.Observe('NCntF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(ExF);
        Observer.Observe('ExF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(LkF);
        Observer.Observe('LkF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(LkDecF);
        Observer.Observe('LkDecF.key', H.CurrentKey() + ':' + Rows(H));
        H.Reset();
        H.SetCurrentKey(NLkDecF);
        Observer.Observe('NLkDecF.key', H.CurrentKey() + ':' + Rows(H));
        Observer.Expect('SumF.key', 'SumF:H3,H2,H1,');
        Observer.Expect('NSumF.key', 'NSumF:H1,H2,H3,');
        Observer.Expect('AvgF.key', 'AvgF:H3,H2,H1,');
        Observer.Expect('MinF.key', 'MinF:H3,H2,H1,');
        Observer.Expect('MaxF.key', 'MaxF:H3,H2,H1,');
        Observer.Expect('CntF.key', 'CntF:H3,H2,H1,');
        Observer.Expect('NCntF.key', 'NCntF:H1,H2,H3,');
        Observer.Expect('ExF.key', 'ExF:H3,H1,H2,');
        Observer.Expect('LkF.key', 'LkF:H3,H1,H2,');
        Observer.Expect('LkDecF.key', 'LkDecF:H3,H2,H1,');
        Observer.Expect('NLkDecF.key', 'NLkDecF:H1,H2,H3,');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSort_FlowFieldFirstThenStoredField_RowOrder()
    // CLAIM: SetCurrentKey with a FlowField first and a stored field second, with a filter on the stored field, ascending and descending.
    var
        H: Record "FFM Ops Header";
    begin
        Initialize();
        H.Reset();
        H.SetCurrentKey(SumF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('SumF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(SumF, Rank);
        H.Ascending(false);
        Observer.Observe('SumF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(NSumF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('NSumF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(NSumF, Rank);
        H.Ascending(false);
        Observer.Observe('NSumF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(AvgF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('AvgF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(AvgF, Rank);
        H.Ascending(false);
        Observer.Observe('AvgF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(MinF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('MinF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(MinF, Rank);
        H.Ascending(false);
        Observer.Observe('MinF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(MaxF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('MaxF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(MaxF, Rank);
        H.Ascending(false);
        Observer.Observe('MaxF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(CntF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('CntF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(CntF, Rank);
        H.Ascending(false);
        Observer.Observe('CntF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(NCntF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('NCntF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(NCntF, Rank);
        H.Ascending(false);
        Observer.Observe('NCntF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(ExF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('ExF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(ExF, Rank);
        H.Ascending(false);
        Observer.Observe('ExF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(LkF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('LkF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(LkF, Rank);
        H.Ascending(false);
        Observer.Observe('LkF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(LkDecF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('LkDecF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(LkDecF, Rank);
        H.Ascending(false);
        Observer.Observe('LkDecF.key.desc', Rows(H));
        H.Reset();
        H.SetCurrentKey(NLkDecF, Rank);
        H.SetRange(Rank, 1, 9);
        Observer.Observe('NLkDecF.key.rank', H.CurrentKey() + ':' + Rows(H));
        H.SetCurrentKey(NLkDecF, Rank);
        H.Ascending(false);
        Observer.Observe('NLkDecF.key.desc', Rows(H));
        Observer.Expect('SumF.key.rank', 'SumF,Rank:H3,H2,H1,');
        Observer.Expect('SumF.key.desc', 'H1,H2,H3,');
        Observer.Expect('NSumF.key.rank', 'NSumF,Rank:H1,H2,H3,');
        Observer.Expect('NSumF.key.desc', 'H3,H2,H1,');
        Observer.Expect('AvgF.key.rank', 'AvgF,Rank:H3,H2,H1,');
        Observer.Expect('AvgF.key.desc', 'H1,H2,H3,');
        Observer.Expect('MinF.key.rank', 'MinF,Rank:H3,H2,H1,');
        Observer.Expect('MinF.key.desc', 'H1,H2,H3,');
        Observer.Expect('MaxF.key.rank', 'MaxF,Rank:H3,H2,H1,');
        Observer.Expect('MaxF.key.desc', 'H1,H2,H3,');
        Observer.Expect('CntF.key.rank', 'CntF,Rank:H3,H2,H1,');
        Observer.Expect('CntF.key.desc', 'H1,H2,H3,');
        Observer.Expect('NCntF.key.rank', 'NCntF,Rank:H1,H2,H3,');
        Observer.Expect('NCntF.key.desc', 'H3,H2,H1,');
        Observer.Expect('ExF.key.rank', 'ExF,Rank:H3,H2,H1,');
        Observer.Expect('ExF.key.desc', 'H1,H2,H3,');
        Observer.Expect('LkF.key.rank', 'LkF,Rank:H3,H1,H2,');
        Observer.Expect('LkF.key.desc', 'H2,H1,H3,');
        Observer.Expect('LkDecF.key.rank', 'LkDecF,Rank:H3,H2,H1,');
        Observer.Expect('LkDecF.key.desc', 'H1,H2,H3,');
        Observer.Expect('NLkDecF.key.rank', 'NLkDecF,Rank:H1,H2,H3,');
        Observer.Expect('NLkDecF.key.desc', 'H3,H2,H1,');
        Observer.Verify();
    end;

    local procedure Rows(var H: Record "FFM Ops Header"): Text
    var
        Result: Text;
    begin
        if H.FindSet() then
            repeat
                Result += H.Code + ',';
            until H.Next() = 0;
        exit(Result);
    end;

    local procedure Initialize()
    var
        D: Record "FFM Ops Detail";
        H: Record "FFM Ops Header";
    begin
        D.DeleteAll();
        H.DeleteAll();
        AddDetail(1, 'H1', 10.5, 'alpha', 20260110D);
        AddDetail(2, 'H1', 20, 'bravo', 20260210D);
        AddDetail(3, 'H1', 40.25, 'charlie', 20260310D);
        AddDetail(4, 'H1', 80, 'delta', 20260410D);
        AddDetail(5, 'H2', 7, 'echo', 20260110D);
        AddDetail(6, 'H2', 14, 'foxtrot', 20260510D);
        AddHeader('H1', 3);
        AddHeader('H2', 2);
        AddHeader('H3', 1);
        Log.Get();
    end;

    local procedure AddDetail(EntryNo: Integer; OwnerCode: Code[10]; Amount: Decimal; NameValue: Text[30]; Date: Date)
    var
        D: Record "FFM Ops Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Amt := Amount;
        D.Name := NameValue;
        D.Day := Date;
        D.Insert();
    end;

    local procedure AddHeader(HeaderCode: Code[10]; RankValue: Integer)
    var
        H: Record "FFM Ops Header";
    begin
        H.Init();
        H.Code := HeaderCode;
        H.Rank := RankValue;
        H.Insert();
    end;
}
