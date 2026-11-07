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

    // Al-runner issue 6924 item 2.17: the same statement form on a Guid field (and the other field types the tests above leave out:
    // BigInteger, Time, DateTime, DateFormula, Duration, an Option with an OptionCaption and an Enum), next to the form with the result
    // used and Evaluate with format 9. Table 95366 below; every field starts with a value, so a kept value shows.
    [TryFunction]
    local procedure P6924_TryEvalUsed(FldRef: FieldRef; Txt: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(FldRef, Txt);
    end;

    [TryFunction]
    local procedure P6924_TryEval9(FldRef: FieldRef; Txt: Text)
    begin
        Evaluate(FldRef, Txt, 9);
    end;

    local procedure P6924_Field(FieldNo: Integer; var RecRef: RecordRef; var FldRef: FieldRef)
    var
        Row: Record "REC Eval Guid Row";
    begin
        Row.Id := 1;
        Row.G := '{11111111-2222-3333-4444-555555555555}';
        Row.Big := 9;
        Row.Tm := 101010T;
        Row.Dtm := CreateDateTime(20240101D, 101010T);
        Evaluate(Row.DF, '<1D>');
        Row.Dur := 1000;
        Row.OptCap := Row.OptCap::One;
        Row.Kind := Row.Kind::Customer;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(FieldNo);
    end;

    // Mode 0: statement; 1: result used; 9: statement with format 9.
    local procedure P6924_Eval(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text; Mode: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ok: Boolean;
        Done: Boolean;
    begin
        P6924_Field(FieldNo, RecRef, FldRef);
        ClearLastError();
        case Mode of
            0:
                Done := TryEval(FldRef, Txt);
            1:
                Done := P6924_TryEvalUsed(FldRef, Txt, Ok);
            9:
                Done := P6924_TryEval9(FldRef, Txt);
        end;
        if not Done then
            Observer.ObserveError(Name)
        else
            if Mode = 1 then begin
                Observer.Observe(Name, 'returned ' + Format(Ok));
                Observer.ObserveError(Name);
            end else
                Observer.Observe(Name, 'no error');
        Observer.Observe(Name + '|value', Format(FldRef.Value));
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Guid_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Eval(Observer, 'guid braces', 2, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}', 0);
        P6924_Eval(Observer, 'guid no braces', 2, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 0);
        P6924_Eval(Observer, 'guid digits only', 2, 'AAAAAAAABBBBCCCCDDDDEEEEEEEEEEEE', 0);
        P6924_Eval(Observer, 'guid parentheses', 2, '(AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE)', 0);
        P6924_Eval(Observer, 'guid blanks', 2, ' {AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE} ', 0);
        P6924_Eval(Observer, 'guid bad', 2, 'abc', 0);
        P6924_Eval(Observer, 'guid empty', 2, '', 0);
        P6924_Eval(Observer, 'guid null', 2, '{00000000-0000-0000-0000-000000000000}', 0);
        Observer.Expect('guid braces', 'no error');
        Observer.Expect('guid braces|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid no braces', 'no error');
        Observer.Expect('guid no braces|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid digits only', 'no error');
        Observer.Expect('guid digits only|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid parentheses', 'no error');
        Observer.Expect('guid parentheses|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid blanks', 'no error');
        Observer.Expect('guid blanks|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid bad|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid bad|code', 'InvalidGuidFormat');
        Observer.Expect('guid bad|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('guid empty|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid empty|code', 'InvalidGuidFormat');
        Observer.Expect('guid empty|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('guid null', 'no error');
        Observer.Expect('guid null|value', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Guid_ResultUsedAndFormat9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Eval(Observer, 'used braces', 2, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}', 1);
        P6924_Eval(Observer, 'used bad', 2, 'abc', 1);
        P6924_Eval(Observer, 'used empty', 2, '', 1);
        P6924_Eval(Observer, 'used too short', 2, '{AAAAAAAA-BBBB-CCCC-DDDD}', 1);
        P6924_Eval(Observer, 'nine braces', 2, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}', 9);
        P6924_Eval(Observer, 'nine no braces', 2, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 9);
        P6924_Eval(Observer, 'nine bad', 2, 'abc', 9);
        Observer.Expect('used braces', 'returned Yes');
        Observer.Expect('used braces|text', '');
        Observer.Expect('used braces|code', '');
        Observer.Expect('used braces|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('used bad', 'returned No');
#if BC28PLUS // BC 28.5 and 29.0 clear the last error when Evaluate into a Guid FieldRef answers false; BC 27.5 keeps it
        Observer.Expect('used bad|text', '');
        Observer.Expect('used bad|code', '');
#else
        Observer.Expect('used bad|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('used bad|code', 'InvalidGuidFormat');
#endif
        Observer.Expect('used bad|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('used empty', 'returned No');
#if BC28PLUS // BC 28.5 and 29.0 clear the last error when Evaluate into a Guid FieldRef answers false; BC 27.5 keeps it
        Observer.Expect('used empty|text', '');
        Observer.Expect('used empty|code', '');
#else
        Observer.Expect('used empty|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('used empty|code', 'InvalidGuidFormat');
#endif
        Observer.Expect('used empty|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('used too short', 'returned No');
#if BC28PLUS // BC 28.5 and 29.0 clear the last error when Evaluate into a Guid FieldRef answers false; BC 27.5 keeps it
        Observer.Expect('used too short|text', '');
        Observer.Expect('used too short|code', '');
#else
        Observer.Expect('used too short|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('used too short|code', 'InvalidGuidFormat');
#endif
        Observer.Expect('used too short|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('nine braces', 'no error');
        Observer.Expect('nine braces|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('nine no braces', 'no error');
        Observer.Expect('nine no braces|value', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('nine bad|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('nine bad|code', 'InvalidGuidFormat');
        Observer.Expect('nine bad|value', '{11111111-2222-3333-4444-555555555555}');
        Observer.Verify();
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Statement_BadText_MoreTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Eval(Observer, 'biginteger abc', 3, 'abc', 0);
        P6924_Eval(Observer, 'biginteger ok', 3, '12345678901', 0);
        P6924_Eval(Observer, 'time abc', 4, 'abc', 0);
        P6924_Eval(Observer, 'datetime abc', 5, 'abc', 0);
        P6924_Eval(Observer, 'dateformula abc', 6, 'abc', 0);
        P6924_Eval(Observer, 'dateformula ok', 6, '<2W>', 0);
        P6924_Eval(Observer, 'duration abc', 7, 'abc', 0);
        Observer.Expect('biginteger abc|text', 'The value "abc" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger abc|code', 'Evaluate');
        Observer.Expect('biginteger abc|value', '9');
        Observer.Expect('biginteger ok', 'no error');
        Observer.Expect('biginteger ok|value', '12345678901');
        Observer.Expect('time abc|text', 'The value "abc" can''t be evaluated into type Time.');
        Observer.Expect('time abc|code', 'Evaluate');
        Observer.Expect('time abc|value', '10:10:10 AM');
        Observer.Expect('datetime abc|text', 'The value "abc" can''t be evaluated into type DateTime.');
        Observer.Expect('datetime abc|code', 'Evaluate');
        Observer.Expect('datetime abc|value', '01/01/24 10:10 AM');
        Observer.Expect('dateformula abc|text', 'The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('dateformula abc|code', 'Evaluate');
        Observer.Expect('dateformula abc|value', '1D');
        Observer.Expect('dateformula ok', 'no error');
        Observer.Expect('dateformula ok|value', '2W');
        Observer.Expect('duration abc|text', 'The value "abc" can''t be evaluated into type Duration.');
        Observer.Expect('duration abc|code', 'Evaluate');
        Observer.Expect('duration abc|value', '1 second');
        Observer.Verify();
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Statement_BadText_OptionCaptionAndEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Eval(Observer, 'option caption Nope', 8, 'Nope', 0);
        P6924_Eval(Observer, 'option caption by caption', 8, 'Two Cap', 0);
        P6924_Eval(Observer, 'option caption by name', 8, 'Two', 0);
        P6924_Eval(Observer, 'enum Nope', 9, 'Nope', 0);
        P6924_Eval(Observer, 'enum by name', 9, 'Vendor', 0);
        P6924_Eval(Observer, 'enum by caption', 9, 'Vendor Cap', 0);
        P6924_Eval(Observer, 'enum empty', 9, '', 0);
        Observer.Expect('option caption Nope|text', '''Nope'' is not an option. The existing options are: Zero Cap,One Cap,Two Cap');
        Observer.Expect('option caption Nope|code', 'InvalidOptionString');
        Observer.Expect('option caption Nope|value', 'One Cap');
        Observer.Expect('option caption by caption', 'no error');
        Observer.Expect('option caption by caption|value', 'Two Cap');
        Observer.Expect('option caption by name', 'no error');
        Observer.Expect('option caption by name|value', 'Two Cap');
        Observer.Expect('enum Nope|text', '''Nope'' is not an option. The existing options are:  ,Customer Cap,Vendor Cap,Sales Order Cap');
        Observer.Expect('enum Nope|code', 'InvalidOptionString');
        Observer.Expect('enum Nope|value', 'Customer Cap');
        Observer.Expect('enum by name', 'no error');
        Observer.Expect('enum by name|value', 'Vendor Cap');
        Observer.Expect('enum by caption', 'no error');
        Observer.Expect('enum by caption|value', 'Vendor Cap');
        Observer.Expect('enum empty', 'no error');
        Observer.Expect('enum empty|value', ' ');
        Observer.Verify();
    end;

    // Waldo run 2 (al-runner issue 6924): the same statement form on a RecordId field. Table 97240 below; Rid starts as the RecordId of the
    // row itself, Rid2 starts blank. Mode 0: statement; 1: result used; 9: statement with format 9.
    [TryFunction]
    local procedure WA_TryEval9(FldRef: FieldRef; Txt: Text)
    begin
        Evaluate(FldRef, Txt, 9);
    end;

    local procedure WA_Eval(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text; Mode: Integer)
    var
        Row: Record "LT WA RecId Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ok: Boolean;
        Done: Boolean;
    begin
        Row.Id := 1;
        Row.Rid := Row.RecordId();
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(FieldNo);
        ClearLastError();
        case Mode of
            0:
                Done := TryEval(FldRef, Txt);
            1:
                Done := P6924_TryEvalUsed(FldRef, Txt, Ok);
            9:
                Done := WA_TryEval9(FldRef, Txt);
        end;
        if not Done then
            Observer.ObserveError(Name)
        else
            if Mode = 1 then begin
                Observer.Observe(Name, 'returned ' + Format(Ok));
                Observer.ObserveError(Name);
            end else
                Observer.Observe(Name, 'no error');
        Observer.Observe(Name + '|value', Format(FldRef.Value));
        Observer.Observe(Name + '|value9', Format(FldRef.Value, 0, 9));
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_Statement_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'own row', 2, 'LT WA RecId Row: 2', 0);
        WA_Eval(Observer, 'own row lower case', 2, 'lt wa recid row: 2', 0);
        WA_Eval(Observer, 'own row no blank', 2, 'LT WA RecId Row:3', 0);
        WA_Eval(Observer, 'own row not stored', 2, 'LT WA RecId Row: 99999', 0);
        WA_Eval(Observer, 'customer', 2, 'Customer: 10000', 0);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_Statement_Invalid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'abc', 2, 'abc', 0);
        WA_Eval(Observer, 'empty', 2, '', 0);
        WA_Eval(Observer, 'blank', 2, ' ', 0);
        WA_Eval(Observer, 'unknown table', 2, 'No Such Table LT: 1', 0);
        WA_Eval(Observer, 'key not a number', 2, 'LT WA RecId Row: abc', 0);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_Statement_KeyShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'empty key', 2, 'LT WA RecId Row: ', 0);
        WA_Eval(Observer, 'no colon', 2, 'LT WA RecId Row', 0);
        WA_Eval(Observer, 'two part key', 2, 'LT WA RecId Two: A,1', 0);
        WA_Eval(Observer, 'two part key one value', 2, 'LT WA RecId Two: A', 0);
        WA_Eval(Observer, 'one part key two values', 2, 'LT WA RecId Row: 1,2', 0);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_Statement_BlankStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'blank start valid', 3, 'LT WA RecId Row: 2', 0);
        WA_Eval(Observer, 'blank start abc', 3, 'abc', 0);
        WA_Eval(Observer, 'blank start empty', 3, '', 0);
        WA_Eval(Observer, 'blank start customer', 3, 'Customer: 10000', 0);
        WA_Eval(Observer, 'table id text', 2, 'Table 97240: 2', 0);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'used own row', 2, 'LT WA RecId Row: 2', 1);
        WA_Eval(Observer, 'used customer', 2, 'Customer: 10000', 1);
        WA_Eval(Observer, 'used abc', 2, 'abc', 1);
        WA_Eval(Observer, 'used empty', 2, '', 1);
        WA_Eval(Observer, 'used unknown table', 2, 'No Such Table LT: 1', 1);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Evaluate_FieldRef_RecordId_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Eval(Observer, 'nine own row', 2, 'LT WA RecId Row: 2', 9);
        WA_Eval(Observer, 'nine customer', 2, 'Customer: 10000', 9);
        WA_Eval(Observer, 'nine abc', 2, 'abc', 9);
        WA_Eval(Observer, 'nine empty', 2, '', 9);
        Observer.Finish();
    end;

    // The text Format gives for a RecordId, evaluated back into the field (round trip), and the variable form with a bad text.
    [Test]
    procedure WA_Evaluate_RecordId_RoundTripAndVariable()
    var
        Row: Record "LT WA RecId Row";
        Two: Record "LT WA RecId Two";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rid: RecordId;
        Ok: Boolean;
    begin
        Row.Id := 7;
        Two.Code := 'A';
        Two.Num := 5;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(2);
        Observer.Observe('format own', Format(Row.RecordId()));
        Observer.Observe('format two', Format(Two.RecordId()));
        Evaluate(FldRef, Format(Two.RecordId()));
        Observer.Observe('field after round trip', Format(FldRef.Value));
        Evaluate(FldRef, Format(Row.RecordId()));
        Observer.Observe('field after round trip own', Format(FldRef.Value));
        Rid := Row.RecordId();
        Ok := Evaluate(Rid, 'abc');
        Observer.Observe('variable abc', Format(Ok));
        Observer.ObserveError('variable abc');
        Observer.Observe('variable abc|value', Format(Rid));
        Ok := Evaluate(Rid, Format(Two.RecordId()));
        Observer.Observe('variable valid', Format(Ok));
        Observer.Observe('variable valid|value', Format(Rid));
        Observer.Finish();
    end;
}

// local object: the field types are what the tests above check (al-runner issue 6924 item 2.17).
table 95366 "REC Eval Guid Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; G; Guid) { }
        field(3; Big; BigInteger) { }
        field(4; Tm; Time) { }
        field(5; Dtm; DateTime) { }
        field(6; DF; DateFormula) { }
        field(7; Dur; Duration) { }
        field(8; OptCap; Option) { OptionMembers = Zero,One,Two; OptionCaption = 'Zero Cap,One Cap,Two Cap'; }
        field(9; Kind; Enum "REC TF Source Kind") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// local objects of the RecordId tests above (al-runner issue 6924, waldo run 2).
table 97240 "LT WA RecId Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Rid; RecordId) { }
        field(3; Rid2; RecordId) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 97241 "LT WA RecId Two"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Num; Integer) { }
    }
    keys { key(PK; Code, Num) { Clustered = true; } }
}
