// Publisher fixture for "Test Event Quoted Name" (67046): integration events whose names are
// quoted identifiers - with spaces, with punctuation, with a non-ASCII letter, and one quoted
// name that needs no quotes. Each Raise* procedure raises one of them.
codeunit 67042 "QEvt Publisher"
{
    procedure RaiseSpaced(var Log: Text): Boolean
    var
        Handled: Boolean;
    begin
        "On Before Quoted"(Handled, Log);
        exit(Handled);
    end;

    procedure RaisePunctuated(var Log: Text)
    begin
        "On-Check.Value (Qty) & Amt"(Log);
    end;

    procedure RaiseUmlaut(var Log: Text)
    begin
        "On Bestätigt Evt"(Log);
    end;

    procedure RaiseQuotedPlain(var Log: Text)
    begin
        "OnQuotedPlain"(Log);
    end;

    procedure RaiseStrict(Value: Integer)
    begin
        "On Strict Check"(Value);
    end;

    procedure RaiseIsolated()
    begin
        "On Isolated Quoted"();
    end;

    [IntegrationEvent(false, false)]
    local procedure "On Before Quoted"(var Handled: Boolean; var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure "On-Check.Value (Qty) & Amt"(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure "On Bestätigt Evt"(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure "OnQuotedPlain"(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure "On Strict Check"(Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false, true)]
    local procedure "On Isolated Quoted"()
    begin
    end;
}
