// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/getlasterrorcallstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 72065 (P70_01Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorCallStack and GetLastErrorCode after different errors (non-empty only, no frames), the code text
// BC versions: 29 (27 and 28 by CI)

codeunit 72068 "LT P70 LastErr Stack Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Depth2()
    begin
        Error('deep');
    end;

    local procedure Depth1()
    begin
        Depth2();
    end;

    local procedure DivZero()
    var
        A: Integer;
        B: Integer;
    begin
        A := 1;
        B := 0;
        A := A div B;
    end;

    local procedure DupInsert()
    var
        Row: Record "LT P70 Row";
    begin
        Row.Code := 'DUP';
        Row.Insert();
        Row.Insert();
    end;

    local procedure Observe3(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '|stack_nonempty', Format(StrLen(GetLastErrorCallStack()) > 0));
        Observer.Observe(Name + '|code', GetLastErrorCode());
        Observer.Observe(Name + '|text_nonempty', Format(StrLen(GetLastErrorText()) > 0));
        Observer.Observe(Name + '|stack_equal_twice', Format(GetLastErrorCallStack() = GetLastErrorCallStack()));
    end;

    [Test]
    procedure StackAndCode_FieldErrors()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P70 Row";
    begin
        asserterror Row.TestField(Name);
        Observer.ObserveError('testfield');
        asserterror Row.TestField(Name);
        Observe3('testfield', Observer);
        asserterror Row.FieldError(Name);
        Observer.ObserveError('fielderror');
        asserterror Row.FieldError(Name);
        Observe3('fielderror', Observer);
        asserterror Row.FieldError(Name, 'why');
        Observer.ObserveError('fielderror_text');
        asserterror Row.FieldError(Name, 'why');
        Observe3('fielderror_text', Observer);
        Observer.Expect('testfield|text', 'Name must have a value in LT P70 Row: Code=. It cannot be zero or empty.');
        Observer.Expect('testfield|code', 'TestField');
        Observer.Expect('testfield|stack_nonempty', 'Yes');
        Observer.Expect('testfield|code', 'TestField');
        Observer.Expect('testfield|text_nonempty', 'Yes');
        Observer.Expect('testfield|stack_equal_twice', 'Yes');
        Observer.Expect('fielderror|text', 'You must specify Name in LT P70 Row Code=''''.');
        Observer.Expect('fielderror|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror|stack_nonempty', 'Yes');
        Observer.Expect('fielderror|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror|text_nonempty', 'Yes');
        Observer.Expect('fielderror|stack_equal_twice', 'Yes');
        Observer.Expect('fielderror_text|text', 'Name why in LT P70 Row Code=''''.');
        Observer.Expect('fielderror_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_text|stack_nonempty', 'Yes');
        Observer.Expect('fielderror_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_text|text_nonempty', 'Yes');
        Observer.Expect('fielderror_text|stack_equal_twice', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure StackAndCode_ClearAndNoError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('none_stack_len', Format(StrLen(GetLastErrorCallStack())));
        Observer.Observe('none_code', GetLastErrorCode());
        asserterror Depth1();
        Observer.Observe('set_stack_nonempty', Format(StrLen(GetLastErrorCallStack()) > 0));
        Observer.Observe('set_code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('cleared_stack_len', Format(StrLen(GetLastErrorCallStack())));
        Observer.Observe('cleared_code', GetLastErrorCode());
        Observer.Observe('cleared_text', GetLastErrorText());
        asserterror Error('a');
        asserterror Error('b');
        Observer.Observe('second_text', GetLastErrorText());
        Observer.Observe('second_code', GetLastErrorCode());
        Observer.Expect('none_stack_len', '0');
        Observer.Expect('none_code', '');
        Observer.Expect('set_stack_nonempty', 'Yes');
        Observer.Expect('set_code', 'Dialog');
        Observer.Expect('cleared_stack_len', '0');
        Observer.Expect('cleared_code', '');
        Observer.Expect('cleared_text', '');
        Observer.Expect('second_text', 'b');
        Observer.Expect('second_code', 'Dialog');
        Observer.Verify();
    end;
}
