namespace ALLanguage.IsolationProbe;

// singleinstance-shared-on-purpose: the log is written by many test codeunits and read by "LT RP Reader" (61346) in a later one; that is the measurement.

// The probe log of the runner-trigger probes (ADR-066 of al-runtime-rs, probes P1-P8).
//
// SingleInstance on purpose: its state is not part of any transaction, so a test isolation
// rollback cannot erase what the runner's triggers and the test bodies recorded, and "LT RP
// Reader" (61346) reads it in a later runner invocation of the same session. That the state
// survives from one test codeunit to the next is itself probe P7; if it did not, every reader
// test fails with an empty log.
//
// Each entry: the runner that was running (61330, 61331, or 0 for none of ours), the test
// codeunit, the function name the platform passed, an event and a data text.
//   B      OnBeforeTestRun was called; data = Format(FunctionTestPermissions)
//   A Yes  OnAfterTestRun was called with IsSuccess = true (A No: false); data = GetLastErrorText()
//   RUN Yes / RUN No   the runner's `Ok := Codeunit.Run(...)` returned true / false; data = GetLastErrorText()
//   X ...  something a test body, an OnRun or a trigger recorded
codeunit 61332 "LT RP Log"
{
    SingleInstance = true;

    procedure SetRunner(RunnerId: Integer)
    begin
        CurrentRunnerId := RunnerId;
    end;

    procedure CurrentRunner(): Integer
    begin
        exit(CurrentRunnerId);
    end;

    // C for 61330 (TestIsolation = Codeunit), F for 61331 (Function), D for anything else.
    procedure RunnerTag(): Text
    begin
        case CurrentRunnerId of
            61330:
                exit('C');
            61331:
                exit('F');
        end;
        exit('D');
    end;

    procedure NextSeq(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure ArmOnRunError(Armed: Boolean)
    begin
        OnRunErrorArmed := Armed;
    end;

    procedure IsOnRunErrorArmed(): Boolean
    begin
        exit(OnRunErrorArmed);
    end;

    procedure Add(CodeunitId: Integer; FunctionName: Text; Ev: Text; Data: Text)
    begin
        Runners.Add(CurrentRunnerId);
        Codeunits.Add(CodeunitId);
        Functions.Add(FunctionName);
        Events.Add(Ev);
        Datas.Add(Data);
    end;

    // The events of one runner and test codeunit in order, joined with " ; ". With a function
    // name (any case), only that function's events; with '', every event as "<function>:<event>".
    procedure Seq(RunnerId: Integer; CodeunitId: Integer; FunctionName: Text): Text
    var
        i: Integer;
        Result: Text;
        Item: Text;
    begin
        for i := 1 to Runners.Count() do
            if (Runners.Get(i) = RunnerId) and (Codeunits.Get(i) = CodeunitId) then
                if (FunctionName = '') or (UpperCase(Functions.Get(i)) = UpperCase(FunctionName)) then begin
                    if FunctionName = '' then
                        Item := Functions.Get(i) + ':' + Events.Get(i)
                    else
                        Item := Events.Get(i);
                    if Result <> '' then
                        Result += ' ; ';
                    Result += Item;
                end;
        if Result = '' then
            exit('<no entry>');
        exit(Result);
    end;

    // The data of the Occurrence-th entry (1 = first, -1 = last) of that runner, codeunit,
    // function and event, or '<no entry>'.
    procedure DataOf(RunnerId: Integer; CodeunitId: Integer; FunctionName: Text; Ev: Text; Occurrence: Integer): Text
    var
        i: Integer;
        Found: Integer;
        Last: Text;
    begin
        Last := '<no entry>';
        for i := 1 to Runners.Count() do
            if (Runners.Get(i) = RunnerId) and (Codeunits.Get(i) = CodeunitId) and
               (UpperCase(Functions.Get(i)) = UpperCase(FunctionName)) and (Events.Get(i) = Ev)
            then begin
                Found += 1;
                Last := Datas.Get(i);
                if Found = Occurrence then
                    exit(Last);
            end;
        if Occurrence = -1 then
            exit(Last);
        exit('<no entry>');
    end;

    procedure RaiseTriggerWrite(RowKey: Code[50])
    begin
        OnTriggerWrite(RowKey);
    end;

    // Raised by the runner's triggers for probe P4; "LT RP Subscriber" (61334) inserts a row.
    [IntegrationEvent(false, false)]
    local procedure OnTriggerWrite(RowKey: Code[50])
    begin
    end;

    var
        Runners: List of [Integer];
        Codeunits: List of [Integer];
        Functions: List of [Text];
        Events: List of [Text];
        Datas: List of [Text];
        CurrentRunnerId: Integer;
        Counter: Integer;
        OnRunErrorArmed: Boolean;
}
