// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73169, codeunit 73168
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into a Code variable ('' and blanks, case, exact length, too long; the previous value after a failure) and into a Text variable (empty text, a Text[n] that is too short), with and
// without the Boolean result used; Evaluate into an Option that is neither an ordinal nor a member name, with numeric OptionCaptions (ordinal 0..2 against captions 1..3).
// BC versions: 29 (27 and 28 by CI)

table 73169 "LT P128 Eval Opt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; NumCap; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = '1,2,3';
        }
        field(3; Words; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Ten,Twenty,Thirty';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Corpus issue 672 item 14 (AL issue 4102): an Option whose captions are numbers that clash with the ordinals (caption '1' is
// member Round, ordinal 2; ordinal 1 is Ordinary, caption '0.01').
table 83350 "LT BT Rounding Opt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Rounding; Option)
        {
            OptionMembers = " ",Ordinary,Round,Tens,Fifties,Hundreds,Thousands;
            OptionCaption = ' ,0.01,1,10,50,100,1000';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73168 "LT P128 Eval Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalCode(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        C: Code[5];
        Ok: Boolean;
    begin
        C := 'KEEP';
        Ok := Evaluate(C, Txt);
        Observer.Observe(Name, Format(Ok) + '|[' + C + ']');
    end;

    local procedure EvalText(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        T: Text;
        Ok: Boolean;
    begin
        T := 'KEEP';
        Ok := Evaluate(T, Txt);
        Observer.Observe(Name, Format(Ok) + '|[' + T + ']');
    end;

    [TryFunction]
    local procedure TryEvalCodeUnused(Txt: Text; var C: Code[5])
    begin
        Evaluate(C, Txt);
    end;

    [TryFunction]
    local procedure TryEvalShortTextUnused(Txt: Text; var T: Text[5])
    begin
        Evaluate(T, Txt);
    end;

    local procedure EvalShortText(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        T: Text[5];
        Ok: Boolean;
    begin
        T := 'KEEP';
        if TryEvalShortTextUnused(Txt, T) then
            Observer.Observe(Name, 'ok|[' + T + ']')
        else begin
            Observer.ObserveError(Name);
            Ok := false;
        end;
    end;

    [Test]
    procedure P128_Evaluate_IntoCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCode(Observer, 'empty', '');
        EvalCode(Observer, 'lower', 'abc');
        EvalCode(Observer, 'padded', ' ab ');
        EvalCode(Observer, 'inner blank', 'a b');
        EvalCode(Observer, 'exact length', 'abcde');
        EvalCode(Observer, 'one too long', 'abcdef');
        EvalCode(Observer, 'blank only', ' ');
        EvalCode(Observer, 'digits', '00123');
        EvalCode(Observer, 'unicode', 'äbc');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('lower', 'Yes|[ABC]');
        Observer.Expect('padded', 'Yes|[AB]');
        Observer.Expect('inner blank', 'Yes|[A B]');
        Observer.Expect('exact length', 'Yes|[ABCDE]');
        Observer.Expect('one too long', 'No|[KEEP]');
        Observer.Expect('blank only', 'Yes|[]');
        Observer.Expect('digits', 'Yes|[00123]');
        Observer.Expect('unicode', 'Yes|[ÄBC]');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoCode_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[5];
    begin
        C := 'KEEP';
        if TryEvalCodeUnused('', C) then
            Observer.Observe('empty', 'ok|[' + C + ']')
        else
            Observer.ObserveError('empty');
        C := 'KEEP';
        if TryEvalCodeUnused('abc', C) then
            Observer.Observe('abc', 'ok|[' + C + ']')
        else
            Observer.ObserveError('abc');
        C := 'KEEP';
        if TryEvalCodeUnused('abcdef', C) then
            Observer.Observe('too long', 'ok|[' + C + ']')
        else
            Observer.ObserveError('too long');
        Observer.Expect('empty', 'ok|[]');
        Observer.Expect('abc', 'ok|[ABC]');
        Observer.Expect('too long|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('too long|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalText(Observer, 'empty', '');
        EvalText(Observer, 'plain', 'hello');
        EvalText(Observer, 'padded', ' hello ');
        EvalText(Observer, 'blank only', ' ');
        EvalText(Observer, 'quotes', '''a''');
        EvalText(Observer, 'unicode', 'äöü');
        Observer.Expect('empty', 'Yes|[]');
        Observer.Expect('plain', 'Yes|[hello]');
        Observer.Expect('padded', 'Yes|[ hello ]');
        Observer.Expect('blank only', 'Yes|[ ]');
        Observer.Expect('quotes', 'Yes|[''a'']');
        Observer.Expect('unicode', 'Yes|[äöü]');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoShortText_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalShortText(Observer, 'empty', '');
        EvalShortText(Observer, 'fits', 'abcde');
        EvalShortText(Observer, 'too long', 'abcdef');
        Observer.Expect('empty', 'ok|[]');
        Observer.Expect('fits', 'ok|[abcde]');
        Observer.Expect('too long|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('too long|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoOption_LocalVariable()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B;
        Ok: Boolean;
    begin
        Opt := Opt::B;
        Ok := Evaluate(Opt, '2');
        Observer.Observe('ordinal 2 of 2 members', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '-1');
        Observer.Observe('minus 1', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, ' 0 ');
        Observer.Observe('padded 0', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '1.0');
        Observer.Observe('1.0', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, 'a');
        Observer.Observe('lower a', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '1x');
        Observer.Observe('1x', Format(Ok) + '|' + Format(Opt));
        Ok := Evaluate(Opt, '+1');
        Observer.Observe('plus 1', Format(Ok) + '|' + Format(Opt));
        Observer.Expect('ordinal 2 of 2 members', 'Yes|2');
        Observer.Expect('minus 1', 'No|2');
        Observer.Expect('padded 0', 'Yes|A');
        Observer.Expect('1.0', 'No|A');
        Observer.Expect('lower a', 'Yes|A');
        Observer.Expect('1x', 'No|A');
        Observer.Expect('plus 1', 'Yes|B');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoOptionField_NumericCaptions()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 Eval Opt";
        Ok: Boolean;
    begin
        Row.NumCap := Row.NumCap::A;
        Ok := Evaluate(Row.NumCap, '0');
        Observer.Observe('0', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '1');
        Observer.Observe('1', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '2');
        Observer.Observe('2', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '3');
        Observer.Observe('3 (caption of C, no such ordinal)', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.NumCap, '4');
        Observer.Observe('4', Format(Ok) + '|' + Format(Row.NumCap) + '|' + Format(Row.NumCap, 0, 2));
        Ok := Evaluate(Row.Words, 'Twenty');
        Observer.Observe('caption Twenty', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'twenty');
        Observer.Observe('caption twenty lower', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Two');
        Observer.Observe('member Two', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Thirty');
        Observer.Observe('caption Thirty', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, 'Three');
        Observer.Observe('neither Three', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Ok := Evaluate(Row.Words, '5');
        Observer.Observe('ordinal 5', Format(Ok) + '|' + Format(Row.Words) + '|' + Format(Row.Words, 0, 2));
        Observer.Expect('0', 'Yes|1|0');
        Observer.Expect('1', 'Yes|1|0');
        Observer.Expect('2', 'Yes|2|1');
        Observer.Expect('3 (caption of C, no such ordinal)', 'Yes|3|2');
        Observer.Expect('4', 'Yes|4|4');
        Observer.Expect('caption Twenty', 'Yes|Twenty|1');
        Observer.Expect('caption twenty lower', 'Yes|Twenty|1');
        Observer.Expect('member Two', 'Yes|Thirty|2');
        Observer.Expect('caption Thirty', 'Yes|Thirty|2');
        Observer.Expect('neither Three', 'No|Thirty|2');
        Observer.Expect('ordinal 5', 'Yes|5|5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateRoundingText(var Row: Record "LT BT Rounding Opt"; Txt: Text)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(Row.FieldNo(Rounding));
        Evaluate(FldRef, Txt);
        FldRef.Validate();
        RecRef.SetTable(Row);
    end;

    // Corpus issue 672 item 14 (AL issue 4102): Evaluate of the texts '1', '0.01', '10', '2', '1000' and 'Round' into the Option field
    // above, and the same texts through Evaluate(FieldRef) + FieldRef.Validate (result | Format | ordinal).
    [Test]
    procedure BT_Evaluate_IntoOptionField_CaptionsClashWithOrdinals()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BT Rounding Opt";
        Ok: Boolean;
        Inputs: List of [Text];
        Input: Text;
    begin
        Inputs.Add('1');
        Inputs.Add('0.01');
        Inputs.Add('10');
        Inputs.Add('2');
        Inputs.Add('1000');
        Inputs.Add('7');
        Inputs.Add('Round');
        Inputs.Add('');
        foreach Input in Inputs do begin
            Row.Rounding := Row.Rounding::Fifties;
            Ok := Evaluate(Row.Rounding, Input);
            Observer.Observe('eval [' + Input + ']', Format(Ok) + '|' + Format(Row.Rounding) + '|' + Format(Row.Rounding, 0, 2));
        end;
        foreach Input in Inputs do begin
            Row.Rounding := Row.Rounding::Fifties;
            ClearLastError();
            if TryValidateRoundingText(Row, Input) then
                Observer.Observe('fieldref [' + Input + ']', 'ok|' + Format(Row.Rounding) + '|' + Format(Row.Rounding, 0, 2))
            else
                Observer.Observe('fieldref [' + Input + ']', 'err|' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('eval [1]', 'Yes|1|2');
        Observer.Expect('eval [0.01]', 'Yes|0.01|1');
        Observer.Expect('eval [10]', 'Yes|10|3');
        Observer.Expect('eval [2]', 'Yes|1|2');
        Observer.Expect('eval [1000]', 'Yes|1000|6');
        Observer.Expect('eval [7]', 'Yes|7|7');
        Observer.Expect('eval [Round]', 'Yes|1|2');
        Observer.Expect('eval []', 'Yes| |0');
        Observer.Expect('fieldref [1]', 'ok|1|2');
        Observer.Expect('fieldref [0.01]', 'ok|0.01|1');
        Observer.Expect('fieldref [10]', 'ok|10|3');
        Observer.Expect('fieldref [2]', 'ok|1|2');
        Observer.Expect('fieldref [1000]', 'ok|1000|6');
        Observer.Expect('fieldref [7]', 'ok|7|7');
        Observer.Expect('fieldref [Round]', 'ok|1|2');
        Observer.Expect('fieldref []', 'ok| |0');
        Observer.Verify();
    end;
}
