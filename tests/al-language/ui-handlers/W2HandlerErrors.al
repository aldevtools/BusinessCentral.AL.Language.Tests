// Probe: the error code a caller sees when the error is raised inside a modal page handler or a page handler (Error, Get that finds nothing, TestField, division by zero).
// Settles: md:384 (code of an error raised inside a page handler; the Message / Confirm / StrMenu handler case is pinned).

page 68726 "W2 Handler Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }
}

codeunit 68727 "W2 Handler Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Text;

    [Test]
    [HandlerFunctions('ModalRaises')]
    procedure ModalPageHandler_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'error';
        asserterror Page.RunModal(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'W2 handler error');
        Observer.Expect('caller|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalRaises')]
    procedure ModalPageHandler_RecordNotFound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'get';
        asserterror Page.RunModal(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: NO-SUCH-ROW');
        Observer.Expect('caller|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalRaises')]
    procedure ModalPageHandler_TestField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'testfield';
        asserterror Page.RunModal(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'Descr must have a value in W2 Card Row: No.=. It cannot be zero or empty.');
        Observer.Expect('caller|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalRaises')]
    procedure ModalPageHandler_Divide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'divide';
        asserterror Page.RunModal(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'Attempted to divide by zero.');
        Observer.Expect('caller|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRaises')]
    procedure PageHandler_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'error';
        asserterror Page.Run(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'W2 handler error');
        Observer.Expect('caller|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRaises')]
    procedure PageHandler_RecordNotFound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'get';
        asserterror Page.Run(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: NO-SUCH-ROW');
        Observer.Expect('caller|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRaises')]
    procedure PageHandler_TestField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'testfield';
        asserterror Page.Run(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'Descr must have a value in W2 Card Row: No.=. It cannot be zero or empty.');
        Observer.Expect('caller|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageRaises')]
    procedure PageHandler_Divide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := 'divide';
        asserterror Page.Run(Page::"W2 Handler Card");
        Observer.ObserveError('caller');
        Observer.Expect('caller|text', 'Attempted to divide by zero.');
        Observer.Expect('caller|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ModalRaises(var Pg: TestPage "W2 Handler Card")
    begin
        RaiseNow();
    end;

    [PageHandler]
    procedure PageRaises(var Pg: TestPage "W2 Handler Card")
    begin
        RaiseNow();
    end;

    local procedure RaiseNow()
    var
        Row: Record "W2 Card Row";
        Zero: Integer;
        Result: Integer;
    begin
        case Mode of
            'error':
                Error('W2 handler error');
            'get':
                Row.Get('NO-SUCH-ROW');
            'testfield':
                Row.TestField(Descr);
            'divide':
                Result := 1 div Zero;
        end;
    end;
}
