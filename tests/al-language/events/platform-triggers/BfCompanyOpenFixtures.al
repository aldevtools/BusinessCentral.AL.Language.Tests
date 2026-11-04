// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Probe: corpus issue 661 item 10 (writer BF): the Company Triggers events OnCompanyOpen and OnCompanyOpenCompleted in a test session.
//   The subscribers keep what they saw in a SingleInstance codeunit (state of the session): the event, CompanyName(), the execution context,
//   CurrentClientType(), GuiAllowed() and SessionId(). They run in every session of the server, so they never touch the database and cannot fail.
//   The install code of this app (install/lt-bf-install-probes) also reads Calls(), to show whether the install session raised these events.
// BC versions: 27 - 29

codeunit 81258 "LT BF Company Open State"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        Sessions: List of [Integer];

    procedure Add(Entry: Text; SessionNo: Integer)
    begin
        Entries.Add(Entry);
        Sessions.Add(SessionNo);
    end;

    procedure Calls(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure AsText(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;

    // How many of the recorded calls ran in session SessionNo.
    procedure CallsInSession(SessionNo: Integer): Integer
    var
        S: Integer;
        N: Integer;
    begin
        foreach S in Sessions do
            if S = SessionNo then
                N += 1;
        exit(N);
    end;
}

codeunit 81259 "LT BF Company Open Subs"
{
    local procedure Note(EventName: Text)
    var
        State: Codeunit "LT BF Company Open State";
    begin
        State.Add(EventName + '|' + CompanyName() + '|' + Format(Session.GetExecutionContext()) + '|' + Format(CurrentClientType()) + '|' + Format(GuiAllowed()), SessionId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    begin
        Note('OnCompanyOpen');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    begin
        Note('OnCompanyOpenCompleted');
    end;
}
