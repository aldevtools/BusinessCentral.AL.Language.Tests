// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate(OptionField, Text) for table option fields whose OptionCaption differs from OptionMembers: by member name, by caption, by ordinal in and out of range, case, blanks, empty text; the boolean result, the value kept and its ordinal; Evaluate with the result unused (error text and code); a field with no OptionCaption and three members given '3'
// BC versions: 29 (27 and 28 by CI)

table 74427 "LT P137 Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cap; Option)
        {
            OptionMembers = Alpha,Beta,Gamma,Delta;
            OptionCaption = 'Uno,Dos,Tres,Cuatro';
        }
        field(3; Three; Option)
        {
            OptionMembers = A,B,C;
        }
        field(4; Blank; Option)
        {
            OptionMembers = " ",First,Second;
            OptionCaption = ' ,Primero,Segundo';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74428 "LT P137 Evaluate Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalCap(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Row: Record "LT P137 Opt Row";
        Ok: Boolean;
    begin
        Row.Cap := Row.Cap::Gamma;
        Ok := Evaluate(Row.Cap, Txt);
        Observer.Observe(Name, Format(Ok) + '|' + Format(Row.Cap) + '|' + Format(Row.Cap, 0, 2));
    end;

    local procedure EvalThree(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Row: Record "LT P137 Opt Row";
        Ok: Boolean;
    begin
        Row.Three := Row.Three::B;
        Ok := Evaluate(Row.Three, Txt);
        Observer.Observe(Name, Format(Ok) + '|' + Format(Row.Three) + '|' + Format(Row.Three, 0, 2));
    end;

    local procedure EvalBlank(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Row: Record "LT P137 Opt Row";
        Ok: Boolean;
    begin
        Row.Blank := Row.Blank::Second;
        Ok := Evaluate(Row.Blank, Txt);
        Observer.Observe(Name, Format(Ok) + '|' + Format(Row.Blank) + '|' + Format(Row.Blank, 0, 2));
    end;

    [TryFunction]
    local procedure TryEvalCap(var Row: Record "LT P137 Opt Row"; Txt: Text)
    begin
        Evaluate(Row.Cap, Txt);
    end;

    [TryFunction]
    local procedure TryEvalThree(var Row: Record "LT P137 Opt Row"; Txt: Text)
    begin
        Evaluate(Row.Three, Txt);
    end;

    [Test]
    procedure P137_Evaluate_OptionFieldWithCaption_ByName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCap(Observer, 'cap_member', 'Alpha');
        EvalCap(Observer, 'cap_member_lower', 'alpha');
        EvalCap(Observer, 'cap_member_upper', 'DELTA');
        EvalCap(Observer, 'cap_member_blanks', '  Beta  ');
        EvalCap(Observer, 'cap_caption', 'Uno');
        EvalCap(Observer, 'cap_caption_lower', 'uno');
        EvalCap(Observer, 'cap_caption_last', 'Cuatro');
        EvalCap(Observer, 'cap_caption_blanks', ' Dos ');
        EvalCap(Observer, 'cap_unknown', 'Zzz');
        EvalCap(Observer, 'cap_partial', 'Alp');
        EvalCap(Observer, 'cap_list', 'Alpha,Beta');
        EvalCap(Observer, 'cap_empty', '');
        EvalCap(Observer, 'cap_blank', ' ');
        Observer.Expect('cap_member', 'Yes|Uno|0');
        Observer.Expect('cap_member_lower', 'Yes|Uno|0');
        Observer.Expect('cap_member_upper', 'Yes|Cuatro|3');
        Observer.Expect('cap_member_blanks', 'Yes|Dos|1');
        Observer.Expect('cap_caption', 'Yes|Uno|0');
        Observer.Expect('cap_caption_lower', 'Yes|Uno|0');
        Observer.Expect('cap_caption_last', 'Yes|Cuatro|3');
        Observer.Expect('cap_caption_blanks', 'Yes|Dos|1');
        Observer.Expect('cap_unknown', 'No|Tres|2');
        Observer.Expect('cap_partial', 'No|Tres|2');
        Observer.Expect('cap_list', 'No|Tres|2');
        Observer.Expect('cap_empty', 'No|Tres|2');
        Observer.Expect('cap_blank', 'No|Tres|2');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Evaluate_OptionFieldWithCaption_ByOrdinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCap(Observer, 'cap_0', '0');
        EvalCap(Observer, 'cap_1', '1');
        EvalCap(Observer, 'cap_3', '3');
        EvalCap(Observer, 'cap_4', '4');
        EvalCap(Observer, 'cap_5', '5');
        EvalCap(Observer, 'cap_minus_1', '-1');
        EvalCap(Observer, 'cap_plus_1', '+1');
        EvalCap(Observer, 'cap_00', '00');
        EvalCap(Observer, 'cap_1_blanks', ' 1 ');
        EvalCap(Observer, 'cap_1_point_0', '1.0');
        EvalCap(Observer, 'cap_big', '2147483647');
        EvalCap(Observer, 'cap_overflow', '2147483648');
        Observer.Expect('cap_0', 'Yes|Uno|0');
        Observer.Expect('cap_1', 'Yes|Dos|1');
        Observer.Expect('cap_3', 'Yes|Cuatro|3');
        Observer.Expect('cap_4', 'Yes|4|4');
        Observer.Expect('cap_5', 'Yes|5|5');
        Observer.Expect('cap_minus_1', 'No|Tres|2');
        Observer.Expect('cap_plus_1', 'Yes|Dos|1');
        Observer.Expect('cap_00', 'Yes|Uno|0');
        Observer.Expect('cap_1_blanks', 'Yes|Dos|1');
        Observer.Expect('cap_1_point_0', 'No|Tres|2');
        Observer.Expect('cap_big', 'Yes|2147483647|2147483647');
        Observer.Expect('cap_overflow', 'No|Tres|2');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Evaluate_OptionFieldWithoutCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalThree(Observer, 'three_a', 'A');
        EvalThree(Observer, 'three_lower', 'c');
        EvalThree(Observer, 'three_0', '0');
        EvalThree(Observer, 'three_2', '2');
        EvalThree(Observer, 'three_3', '3');
        EvalThree(Observer, 'three_4', '4');
        EvalThree(Observer, 'three_minus', '-1');
        EvalThree(Observer, 'three_unknown', 'D');
        EvalThree(Observer, 'three_empty', '');
        EvalBlank(Observer, 'blank_first', 'First');
        EvalBlank(Observer, 'blank_caption', 'Primero');
        EvalBlank(Observer, 'blank_caption_second', 'segundo');
        EvalBlank(Observer, 'blank_empty', '');
        EvalBlank(Observer, 'blank_space', ' ');
        EvalBlank(Observer, 'blank_0', '0');
        EvalBlank(Observer, 'blank_3', '3');
        Observer.Expect('three_a', 'Yes|A|0');
        Observer.Expect('three_lower', 'Yes|C|2');
        Observer.Expect('three_0', 'Yes|A|0');
        Observer.Expect('three_2', 'Yes|C|2');
        Observer.Expect('three_3', 'Yes|3|3');
        Observer.Expect('three_4', 'Yes|4|4');
        Observer.Expect('three_minus', 'No|B|1');
        Observer.Expect('three_unknown', 'No|B|1');
        Observer.Expect('three_empty', 'No|B|1');
        Observer.Expect('blank_first', 'Yes|Primero|1');
        Observer.Expect('blank_caption', 'Yes|Primero|1');
        Observer.Expect('blank_caption_second', 'Yes|Segundo|2');
        Observer.Expect('blank_empty', 'Yes| |0');
        Observer.Expect('blank_space', 'Yes| |0');
        Observer.Expect('blank_0', 'Yes| |0');
        Observer.Expect('blank_3', 'Yes|3|3');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Evaluate_OptionFieldResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P137 Opt Row";
    begin
        Row.Cap := Row.Cap::Beta;
        if TryEvalCap(Row, 'Zzz') then
            Observer.Observe('cap_unknown', 'ok|' + Format(Row.Cap))
        else begin
            Observer.Observe('cap_unknown', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(Row.Cap));
            ClearLastError();
        end;
        if TryEvalThree(Row, '9x') then
            Observer.Observe('three_unknown', 'ok|' + Format(Row.Three))
        else begin
            Observer.Observe('three_unknown', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        if TryEvalCap(Row, '') then
            Observer.Observe('cap_empty', 'ok|' + Format(Row.Cap))
        else begin
            Observer.Observe('cap_empty', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        if TryEvalCap(Row, 'Dos') then
            Observer.Observe('cap_caption', 'ok|' + Format(Row.Cap, 0, 2))
        else begin
            Observer.Observe('cap_caption', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        if TryEvalThree(Row, '3') then
            Observer.Observe('three_3', 'ok|' + Format(Row.Three, 0, 2))
        else begin
            Observer.Observe('three_3', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('cap_unknown', 'error:''Zzz'' is not an option. The existing options are: Uno,Dos,Tres,Cuatro|InvalidOptionString|Dos');
        Observer.Expect('three_unknown', 'error:''9x'' is not an option. The existing options are: A,B,C|InvalidOptionString');
        Observer.Expect('cap_empty', 'error:'''' is not an option. The existing options are: Uno,Dos,Tres,Cuatro|InvalidOptionString');
        Observer.Expect('cap_caption', 'ok|1');
        Observer.Expect('three_3', 'ok|3');
        Observer.Verify();
    end;
}
