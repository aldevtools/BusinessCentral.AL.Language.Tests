namespace ALLanguage.IsolationProbe;

// Starts "LT SD Isol Session Writer" (61319) in a background session. "LT SD Isol StartSession"
// (61318) runs it with Codeunit.Run, so a refused StartSession comes back as false with its text.
codeunit 61320 "LT SD Isol Session Starter"
{
    trigger OnRun()
    begin
        Session.StartSession(SessionId, Codeunit::"LT SD Isol Session Writer");
    end;

    procedure GetSessionId(): Integer
    begin
        exit(SessionId);
    end;

    var
        SessionId: Integer;
}
