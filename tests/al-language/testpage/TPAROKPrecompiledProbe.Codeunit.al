// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none -- Base Application codeunit 235 "G/L Reg.-Gen. Ledger"
//
// Records which G/L Register Base Application codeunit 235 was handed, through the codeunit's
// own OnBeforeRun integration event, then marks the event handled so the codeunit exits
// before its PAGE.Run. Nothing opens, so no handler has to be bound and no page trigger can
// muddy the observation.
//
// SingleInstance so the observation survives the call, and ARMED so it never handles the
// event for any other test in the corpus: disarmed, it neither records nor sets IsHandled.

codeunit 60584 "TPAROKP Probe"
{
    SingleInstance = true;

    var
        Armed: Boolean;
        Ran: Boolean;
        RegisterNoSeen: Integer;

    procedure Arm()
    begin
        Armed := true;
        Ran := false;
        RegisterNoSeen := 0;
    end;

    procedure Disarm()
    begin
        Armed := false;
    end;

    procedure GetRan(): Boolean
    begin
        exit(Ran);
    end;

    procedure GetRegisterNoSeen(): Integer
    begin
        exit(RegisterNoSeen);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"G/L Reg.-Gen. Ledger", 'OnBeforeRun', '', false, false)]
    local procedure RecordRegisterOnBeforeRun(GLRegister: Record "G/L Register"; var IsHandled: Boolean)
    begin
        if not Armed then
            exit;
        Ran := true;
        RegisterNoSeen := GLRegister."No.";
        IsHandled := true;
    end;
}
