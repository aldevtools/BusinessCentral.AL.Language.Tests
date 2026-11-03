// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 67605, codeunit 67605
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// The call runs inside a TryFunction, so a call that raises and one that does not are both observed.
// Facts: Evaluate(FieldRef, Text) called as a statement (result not used) with text that does not parse: does it raise, with which code and text,
// and what the field holds afterwards (Decimal, Date, Boolean, Code, Option, Integer).
// BC versions: 27, 28, 29

table 67605 "LT N582 Eval Fld"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Dt; Date) { }
        field(4; Dec; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(7; Num; Integer) { }
        field(8; Txt; Text[5]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67605 "LT N582 Eval FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEval(FldRef: FieldRef; Txt: Text)
    begin
        Evaluate(FldRef, Txt);
    end;

    local procedure EvalStatement(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text)
    var
        Row: Record "LT N582 Eval Fld";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.Id := 1;
        Row.Cd := 'KEEP';
        Row.Dt := 20240101D;
        Row.Dec := 9;
        Row.Flag := true;
        Row.Opt := Row.Opt::One;
        Row.Num := 9;
        Row.Txt := 'KEEP';
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TryEval(FldRef, Txt) then
            Observer.Observe(Name, 'no error')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Format(FldRef.Value));
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Statement_BadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalStatement(Observer, 'decimal abc', 4, 'abc');
        EvalStatement(Observer, 'decimal empty', 4, '');
        EvalStatement(Observer, 'decimal ok', 4, '12.5');
        EvalStatement(Observer, 'date abc', 3, 'abc');
        EvalStatement(Observer, 'date empty', 3, '');
        EvalStatement(Observer, 'date 32th', 3, '320124');
        EvalStatement(Observer, 'boolean maybe', 5, 'maybe');
        EvalStatement(Observer, 'boolean empty', 5, '');
        EvalStatement(Observer, 'boolean yes', 5, 'Yes');
        Observer.Expect('decimal abc|text', 'The value "abc" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal abc|code', 'Evaluate');
        Observer.Expect('decimal abc|value', '9');
        Observer.Expect('decimal empty|text', 'The value "" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal empty|code', 'Evaluate');
        Observer.Expect('decimal empty|value', '9');
        Observer.Expect('decimal ok', 'no error');
        Observer.Expect('decimal ok|value', '12.5');
        Observer.Expect('date abc|text', 'The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('date abc|code', 'Evaluate');
        Observer.Expect('date abc|value', '01/01/24');
        Observer.Expect('date empty', 'no error');
        Observer.Expect('date empty|value', '');
        Observer.Expect('date 32th|text', 'The format of the Date ''320124'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('date 32th|code', 'Evaluate');
        Observer.Expect('date 32th|value', '01/01/24');
        Observer.Expect('boolean maybe|text', 'The value "maybe" can''t be evaluated into type Boolean.');
        Observer.Expect('boolean maybe|code', 'Evaluate');
        Observer.Expect('boolean maybe|value', 'Yes');
        Observer.Expect('boolean empty|text', 'The value "" can''t be evaluated into type Boolean.');
        Observer.Expect('boolean empty|code', 'Evaluate');
        Observer.Expect('boolean empty|value', 'Yes');
        Observer.Expect('boolean yes', 'no error');
        Observer.Expect('boolean yes|value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Statement_BadText_Others()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalStatement(Observer, 'code too long', 2, 'ABCDEFGHIJKLMNOP');
        EvalStatement(Observer, 'code ok', 2, 'abc');
        EvalStatement(Observer, 'text too long', 8, 'ABCDEFGHIJ');
        EvalStatement(Observer, 'option Nope', 6, 'Nope');
        EvalStatement(Observer, 'option empty', 6, '');
        EvalStatement(Observer, 'option out of range', 6, '7');
        EvalStatement(Observer, 'option ok', 6, 'Two');
        EvalStatement(Observer, 'integer abc', 7, 'abc');
        EvalStatement(Observer, 'integer overflow', 7, '99999999999');
        Observer.Expect('code too long|text', 'The length of the string is 16, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJKLMNOP');
        Observer.Expect('code too long|code', 'StringLengthExceeded');
        Observer.Expect('code too long|value', 'KEEP');
        Observer.Expect('code ok', 'no error');
        Observer.Expect('code ok|value', 'ABC');
        Observer.Expect('text too long|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: ABCDEFGHIJ');
        Observer.Expect('text too long|code', 'StringLengthExceeded');
        Observer.Expect('text too long|value', 'KEEP');
        Observer.Expect('option Nope|text', '''Nope'' is not an option. The existing options are: Zero,One,Two');
        Observer.Expect('option Nope|code', 'InvalidOptionString');
        Observer.Expect('option Nope|value', 'One');
        Observer.Expect('option empty|text', ''''' is not an option. The existing options are: Zero,One,Two');
        Observer.Expect('option empty|code', 'InvalidOptionString');
        Observer.Expect('option empty|value', 'One');
        Observer.Expect('option out of range', 'no error');
        Observer.Expect('option out of range|value', '7');
        Observer.Expect('option ok', 'no error');
        Observer.Expect('option ok|value', 'Two');
        Observer.Expect('integer abc|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('integer abc|code', 'Evaluate');
        Observer.Expect('integer abc|value', '9');
        Observer.Expect('integer overflow|text', 'The value "99999999999" can''t be evaluated into type Integer.');
        Observer.Expect('integer overflow|code', 'Evaluate');
        Observer.Expect('integer overflow|value', '9');
        Observer.Verify();
    end;
}
