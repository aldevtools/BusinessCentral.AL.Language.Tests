// Fixtures of the writer SP rollback probes in "LT CU Commit Tests" (85311): a Commit in an event subscriber of an
// integration event and a business event, [CommitBehavior] on the event declaration, and a guarded Codeunit.Run inside
// another guarded Codeunit.Run.
// Scope: in-scope
// Not test codeunits. Each object is used only by "LT CU Commit Tests".

// Publisher: inserts row FirstId, raises the event named by Kind with SecondId, then fails with 'unrelated'.
codeunit 89550 "LT SP Event Publisher"
{
    procedure InsertRaiseThenFail(Kind: Text; FirstId: Integer; SecondId: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := FirstId;
        Row.Name := 'publisher';
        Row.Insert();
        case Kind of
            'integration':
                OnIntegrationPlain(SecondId);
            'integration ignore':
                OnIntegrationIgnore(SecondId);
            'integration error':
                OnIntegrationError(SecondId);
            'business':
                OnBusinessPlain(SecondId);
            'business ignore':
                OnBusinessIgnore(SecondId);
            'business error':
                OnBusinessError(SecondId);
        end;
        Error('unrelated');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIntegrationPlain(Id: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OnIntegrationIgnore(Id: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [CommitBehavior(CommitBehavior::Error)]
    local procedure OnIntegrationError(Id: Integer)
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnBusinessPlain(Id: Integer)
    begin
    end;

    [BusinessEvent(false)]
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OnBusinessIgnore(Id: Integer)
    begin
    end;

    [BusinessEvent(false)]
    [CommitBehavior(CommitBehavior::Error)]
    local procedure OnBusinessError(Id: Integer)
    begin
    end;
}

// Manual subscriber to every event of "LT SP Event Publisher": inserts row Id, then commits.
codeunit 89551 "LT SP Event Commit Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnIntegrationPlain', '', false, false)]
    local procedure OnIntegrationPlain(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnIntegrationIgnore', '', false, false)]
    local procedure OnIntegrationIgnore(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnIntegrationError', '', false, false)]
    local procedure OnIntegrationError(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnBusinessPlain', '', false, false)]
    local procedure OnBusinessPlain(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnBusinessIgnore', '', false, false)]
    local procedure OnBusinessIgnore(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SP Event Publisher", 'OnBusinessError', '', false, false)]
    local procedure OnBusinessError(Id: Integer)
    begin
        InsertAndCommit(Id);
    end;

    local procedure InsertAndCommit(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Name := 'subscriber';
        Row.Insert();
        Commit();
    end;
}

// Outer codeunit for a guarded Codeunit.Run of "LT CU Inserter" (85303, inserts row 100) inside a guarded run of this
// codeunit. Mode 'error scope': the inner run happens in a [CommitBehavior(Error)] procedure; mode 'plain': without
// the attribute. After the inner run the outer run inserts row 102 and fails with 'outer failed'. GetLog returns what
// happened inside (the instance keeps it after the run).
codeunit 89552 "LT SP Outer Run"
{
    trigger OnRun()
    var
        Row: Record "LT CU Row";
    begin
        if Mode = 'error scope' then
            ErrorScopeInnerRun()
        else
            InnerRun();
        Row.Id := 102;
        Row.Name := 'outer';
        Row.Insert();
        Error('outer failed');
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ErrorScopeInnerRun()
    begin
        InnerRun();
    end;

    local procedure InnerRun()
    begin
        Log += 'inner run=' + Format(Codeunit.Run(Codeunit::"LT CU Inserter")) + ';';
        Log += 'inner lasterror=' + GetLastErrorText() + ';';
    end;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    var
        Mode: Text;
        Log: Text;
}
