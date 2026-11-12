// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 66417 and 66418, codeunit 66419, test codeunit 66420
// local object: the CalcFormula definitions and their OnValidate triggers are what the tests measure.
// Probe (al-runner issue 7422: codeunit 5923 "Service-Quote to Order" validates Service Line "Reserved Qty. (Base)", a FlowField whose
//   formula is a negated Sum): observation form, the values are read from the corpus CI matrix.
// Area: Validate with a value on a Sum FlowField while the FlowField's current sum is not 0 and the new value is not 0. Formulas: -sum with
//   one where-condition on a field, -sum with a field condition and a const condition, and sum for contrast. Values: larger than the sum,
//   smaller, of the other sign, equal to the sum, and a sum below 0. Read: whether Validate raises, the value right after it, the OnValidate
//   log, the value CalcFields gives afterwards, and every row of the source table (entry number, owner, kind, amount).
// Existing pins: record/flowfields/FfmOperations.al:381-399 and :433-441 (-sum with the sum at 0, and Validate without a value), DiFwWriteTests
//   (sum, the new entry number after the last row).
// BC versions: 27, 28, 29 by CI

table 66417 "FFM NSum Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Kind; Integer) { }
        field(4; Amt; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 66418 "FFM NSum Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
        field(100; SumF; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("FFM NSum Detail".Amt where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM NSum Log";
            begin
                Log.Add('SumF', Format(SumF));
            end;
        }
        field(101; NSumF; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -sum("FFM NSum Detail".Amt where(Owner = field(Code)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM NSum Log";
            begin
                Log.Add('NSumF', Format(NSumF));
            end;
        }
        field(102; NSumKindF; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -sum("FFM NSum Detail".Amt where(Owner = field(Code), Kind = const(1)));

            trigger OnValidate()
            var
                Log: Codeunit "FFM NSum Log";
            begin
                Log.Add('NSumKindF', Format(NSumKindF));
            end;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 66419 "FFM NSum Log"
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

codeunit 66420 "FFM NSum Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "FFM NSum Log";

    local procedure Initialize(var H: Record "FFM NSum Header")
    var
        D: Record "FFM NSum Detail";
    begin
        D.DeleteAll();
        H.DeleteAll();
        H.Init();
        H.Code := 'H1';
        H.Insert();
        H.Init();
        H.Code := 'H2';
        H.Insert();
        AddDetail(1, 'H2', 1, 100);
        Log.Get();
    end;

    local procedure AddDetail(EntryNo: Integer; Owner: Code[10]; Kind: Integer; Amt: Decimal)
    var
        D: Record "FFM NSum Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := Owner;
        D.Kind := Kind;
        D.Amt := Amt;
        D.Insert();
    end;

    local procedure Rows(): Text
    var
        D: Record "FFM NSum Detail";
        Result: Text;
    begin
        if D.FindSet() then
            repeat
                Result += StrSubstNo('%1/%2/%3/%4;', D."Entry No.", D.Owner, D.Kind, Format(D.Amt, 0, 9));
            until D.Next() = 0;
        exit(Result);
    end;

    local procedure Calculated(var H: Record "FFM NSum Header"): Text
    begin
        H.CalcFields(SumF, NSumF, NSumKindF);
        exit(StrSubstNo('sum=%1 nsum=%2 nsumkind=%3', Format(H.SumF, 0, 9), Format(H.NSumF, 0, 9), Format(H.NSumKindF, 0, 9)));
    end;

    // Not a TryFunction: Validate of a Sum FlowField writes, and a write inside a TryFunction ends the test (FfmOperations.al:157).
    local procedure ValidateCase(FieldName: Text; NewValue: Decimal; var Observer: Codeunit "Probe Observer"; var H: Record "FFM NSum Header")
    begin
        Observer.Observe('before', Calculated(H));
        Observer.Observe('rows before', Rows());
        case FieldName of
            'SumF':
                begin
                    H.Validate(SumF, NewValue);
                    Observer.Observe('value', Format(H.SumF, 0, 9));
                end;
            'NSumF':
                begin
                    H.Validate(NSumF, NewValue);
                    Observer.Observe('value', Format(H.NSumF, 0, 9));
                end;
            'NSumKindF':
                begin
                    H.Validate(NSumKindF, NewValue);
                    Observer.Observe('value', Format(H.NSumKindF, 0, 9));
                end;
        end;
        Observer.Observe('log', Log.Get());
        Observer.Observe('after', Calculated(H));
        Observer.Observe('rows after', Rows());
    end;

    [Test]
    procedure NSum_SumThree_ValidateEight()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -3);
        H.Get('H1');
        ValidateCase('NSumF', 8, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSum_SumThree_ValidateOne()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -3);
        H.Get('H1');
        ValidateCase('NSumF', 1, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSum_SumThree_ValidateMinusTwo()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -3);
        H.Get('H1');
        ValidateCase('NSumF', -2, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSum_SumThree_ValidateThree()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -3);
        H.Get('H1');
        ValidateCase('NSumF', 3, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSum_SumMinusFour_ValidateTwoAndAHalf()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, 4);
        H.Get('H1');
        ValidateCase('NSumF', 2.5, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSum_TwoRows_ValidateEight()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -1);
        AddDetail(11, 'H1', 2, -2);
        H.Get('H1');
        ValidateCase('NSumF', 8, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure NSumKind_SumThree_ValidateEight()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, -3);
        AddDetail(11, 'H1', 2, -5);
        H.Get('H1');
        ValidateCase('NSumKindF', 8, Observer, H);
        Observer.Finish();
    end;

    [Test]
    procedure Sum_SumThree_ValidateEight()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "FFM NSum Header";
    begin
        Initialize(H);
        AddDetail(10, 'H1', 1, 3);
        H.Get('H1');
        ValidateCase('SumF', 8, Observer, H);
        Observer.Finish();
    end;
}
