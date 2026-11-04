// Batch 5, md:153 (WebServiceActionContext): the full error text of a duplicate entity key, captured and not captured; odd field numbers.

codeunit 67060 "W5 WSAC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Result captured: false, and the text stays in GetLastErrorText.
    [Test]
    procedure AddEntityKey_Duplicate_Captured()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: WebServiceActionContext;
        Added: Boolean;
    begin
        ClearLastError();
        Observer.Observe('first_add', Format(Ctx.AddEntityKey(7, 'a')));
        Added := Ctx.AddEntityKey(7, 'b');
        Observer.Observe('second_add_captured', Format(Added));
        Observer.ObserveError('duplicate_captured');
        Observer.Expect('first_add', 'Yes');
        Observer.Expect('second_add_captured', 'No');
        Observer.Expect('duplicate_captured|text', 'An invalid argument was passed to a ''WebServiceActionContext'' data type method.');
        Observer.Expect('duplicate_captured|code', 'Argument');
        Observer.Verify();
    end;

    // Result dropped: raises (the corpus pins that the type name is in the text).
    [Test]
    procedure AddEntityKey_Duplicate_Dropped()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: WebServiceActionContext;
    begin
        Ctx.AddEntityKey(7, 'a');
        asserterror Ctx.AddEntityKey(7, 'b');
        Observer.ObserveError('duplicate_dropped');
        Observer.Expect('duplicate_dropped|text', 'An invalid argument was passed to a ''WebServiceActionContext'' data type method.');
        Observer.Expect('duplicate_dropped|code', 'Argument');
        Observer.Verify();
    end;

    // The same field number with the same value, and a different number afterwards.
    [Test]
    procedure AddEntityKey_Duplicate_SameValue_ThenOtherNumber()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: WebServiceActionContext;
    begin
        Ctx.AddEntityKey(7, 'a');
        Observer.Observe('same_value_again', Format(Ctx.AddEntityKey(7, 'a')));
        Observer.ObserveError('same_value');
        Observer.Observe('other_number', Format(Ctx.AddEntityKey(8, 'a')));
        Observer.Expect('same_value_again', 'No');
        Observer.Expect('same_value|text', 'An invalid argument was passed to a ''WebServiceActionContext'' data type method.');
        Observer.Expect('same_value|code', 'Argument');
        Observer.Expect('other_number', 'Yes');
        Observer.Verify();
    end;

    // Field numbers 0 and negative: unsure whether they raise or return false.
    [Test]
    procedure AddEntityKey_OddFieldNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Ctx: WebServiceActionContext;
        Ok: Boolean;
        Added: Boolean;
    begin
        ClearLastError();
        Ok := TryAdd(Ctx, 0, Added);
        Observer.Observe('number_0_ok', Format(Ok));
        Observer.Observe('number_0_added', Format(Added));
        Observer.ObserveError('number_0');
        Ok := TryAdd(Ctx, -1, Added);
        Observer.Observe('number_minus_1_ok', Format(Ok));
        Observer.Observe('number_minus_1_added', Format(Added));
        Observer.ObserveError('number_minus_1');
        Observer.Expect('number_0_ok', 'Yes');
        Observer.Expect('number_0_added', 'Yes');
        Observer.Expect('number_0|text', '');
        Observer.Expect('number_0|code', '');
        Observer.Expect('number_minus_1_ok', 'Yes');
        Observer.Expect('number_minus_1_added', 'Yes');
        Observer.Expect('number_minus_1|text', '');
        Observer.Expect('number_minus_1|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAdd(var Ctx: WebServiceActionContext; FieldNumber: Integer; var Added: Boolean)
    begin
        Added := Ctx.AddEntityKey(FieldNumber, 'x');
    end;
}
