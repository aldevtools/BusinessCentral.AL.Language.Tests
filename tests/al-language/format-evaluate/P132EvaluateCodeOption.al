// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-function
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73706
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73706 "LT P132 Eval Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; CodeField; Code[5]) { }
        field(3; OptField; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'First,Second,Third';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73705 "LT P132 Eval Code Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalCode(var Observer: Codeunit "Probe Observer"; ObsName: Text; Input: Text)
    var
        C: Code[10];
        Ok: Boolean;
    begin
        C := 'PRESET';
        Ok := Evaluate(C, Input);
        Observer.Observe(ObsName, Format(Ok) + '|[' + C + ']');
    end;

    local procedure EvalCodeField(var Observer: Codeunit "Probe Observer"; ObsName: Text; Input: Text)
    var
        Row: Record "LT P132 Eval Row";
        Ok: Boolean;
    begin
        Row.CodeField := 'PRE';
        Ok := Evaluate(Row.CodeField, Input);
        Observer.Observe(ObsName, Format(Ok) + '|[' + Row.CodeField + ']');
    end;

    local procedure EvalOpt(var Observer: Codeunit "Probe Observer"; ObsName: Text; Input: Text)
    var
        Row: Record "LT P132 Eval Row";
        Ok: Boolean;
    begin
        Row.OptField := Row.OptField::Beta;
        Ok := Evaluate(Row.OptField, Input);
        Observer.Observe(ObsName, Format(Ok) + '|' + Format(Row.OptField) + '|' + Format(Row.OptField, 0, 9));
    end;

    local procedure EvalOptVar(var Observer: Codeunit "Probe Observer"; ObsName: Text; Input: Text)
    var
        Opt: Option A,B,C;
        Ok: Boolean;
    begin
        Opt := Opt::B;
        Ok := Evaluate(Opt, Input);
        Observer.Observe(ObsName, Format(Ok) + '|' + Format(Opt) + '|' + Format(Opt, 0, 9));
    end;

    [Test]
    procedure P132_EvaluateCodeVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCode(Observer, 'empty', '');
        EvalCode(Observer, 'one_space', ' ');
        EvalCode(Observer, 'three_spaces', '   ');
        EvalCode(Observer, 'lower', 'abc');
        EvalCode(Observer, 'mixed', 'aBc');
        EvalCode(Observer, 'inner_space', 'a b');
        EvalCode(Observer, 'leading_space', ' ab');
        EvalCode(Observer, 'trailing_space', 'ab ');
        EvalCode(Observer, 'exact_len', '0123456789');
        EvalCode(Observer, 'too_long', '01234567890');
        EvalCode(Observer, 'quote', 'a''b');
        EvalCode(Observer, 'number', '42');
        EvalCode(Observer, 'umlaut', 'äöü');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('one_space', 'Yes|[]');
        Observer.Expect('three_spaces', 'Yes|[]');
        Observer.Expect('lower', 'Yes|[ABC]');
        Observer.Expect('mixed', 'Yes|[ABC]');
        Observer.Expect('inner_space', 'Yes|[A B]');
        Observer.Expect('leading_space', 'Yes|[AB]');
        Observer.Expect('trailing_space', 'Yes|[AB]');
        Observer.Expect('exact_len', 'Yes|[0123456789]');
        Observer.Expect('too_long', 'No|[PRESET]');
        Observer.Expect('quote', 'Yes|[A''B]');
        Observer.Expect('number', 'Yes|[42]');
        Observer.Expect('umlaut', 'Yes|[ÄÖÜ]');
        Observer.Verify();
    end;

    [Test]
    procedure P132_EvaluateCodeField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCodeField(Observer, 'empty', '');
        EvalCodeField(Observer, 'lower', 'abc');
        EvalCodeField(Observer, 'exact_len', 'abcde');
        EvalCodeField(Observer, 'too_long', 'abcdef');
        EvalCodeField(Observer, 'blank', ' ');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('lower', 'Yes|[ABC]');
        Observer.Expect('exact_len', 'Yes|[ABCDE]');
        Observer.Expect('too_long', 'No|[PRE]');
        Observer.Expect('blank', 'Yes|[]');
        Observer.Verify();
    end;

    [Test]
    procedure P132_EvaluateOptionField_WithOptionCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalOpt(Observer, 'member_Gamma', 'Gamma');
        EvalOpt(Observer, 'member_lower', 'gamma');
        EvalOpt(Observer, 'caption_Third', 'Third');
        EvalOpt(Observer, 'caption_lower', 'third');
        EvalOpt(Observer, 'caption_First', 'First');
        EvalOpt(Observer, 'ordinal_0', '0');
        EvalOpt(Observer, 'ordinal_2', '2');
        EvalOpt(Observer, 'ordinal_3', '3');
        EvalOpt(Observer, 'ordinal_7', '7');
        EvalOpt(Observer, 'ordinal_minus_1', '-1');
        EvalOpt(Observer, 'ordinal_1_5', '1.5');
        EvalOpt(Observer, 'empty', '');
        EvalOpt(Observer, 'blank', ' ');
        EvalOpt(Observer, 'unknown', 'Delta');
        EvalOpt(Observer, 'prefix', 'Gam');
        EvalOpt(Observer, 'padded_member', ' Gamma ');
        Observer.Expect('member_Gamma', 'Yes|Third|2');
        Observer.Expect('member_lower', 'Yes|Third|2');
        Observer.Expect('caption_Third', 'Yes|Third|2');
        Observer.Expect('caption_lower', 'Yes|Third|2');
        Observer.Expect('caption_First', 'Yes|First|0');
        Observer.Expect('ordinal_0', 'Yes|First|0');
        Observer.Expect('ordinal_2', 'Yes|Third|2');
        Observer.Expect('ordinal_3', 'Yes|3|3');
        Observer.Expect('ordinal_7', 'Yes|7|7');
        Observer.Expect('ordinal_minus_1', 'No|Second|1');
        Observer.Expect('ordinal_1_5', 'No|Second|1');
        Observer.Expect('empty', 'No|Second|1');
        Observer.Expect('blank', 'No|Second|1');
        Observer.Expect('unknown', 'No|Second|1');
        Observer.Expect('prefix', 'No|Second|1');
        Observer.Expect('padded_member', 'Yes|Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure P132_EvaluateOptionVariable_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalOptVar(Observer, 'member_C', 'C');
        EvalOptVar(Observer, 'member_lower', 'c');
        EvalOptVar(Observer, 'ordinal_0', '0');
        EvalOptVar(Observer, 'ordinal_2', '2');
        EvalOptVar(Observer, 'ordinal_3', '3');
        EvalOptVar(Observer, 'ordinal_4', '4');
        EvalOptVar(Observer, 'ordinal_100', '100');
        EvalOptVar(Observer, 'ordinal_minus_1', '-1');
        EvalOptVar(Observer, 'empty', '');
        EvalOptVar(Observer, 'unknown', 'Z');
        Observer.Expect('member_C', 'Yes|C|2');
        Observer.Expect('member_lower', 'Yes|C|2');
        Observer.Expect('ordinal_0', 'Yes|A|0');
        Observer.Expect('ordinal_2', 'Yes|C|2');
        Observer.Expect('ordinal_3', 'Yes|3|3');
        Observer.Expect('ordinal_4', 'Yes|4|4');
        Observer.Expect('ordinal_100', 'Yes|100|100');
        Observer.Expect('ordinal_minus_1', 'No|B|1');
        Observer.Expect('empty', 'No|B|1');
        Observer.Expect('unknown', 'No|B|1');
        Observer.Verify();
    end;
}
