// Fixture of the writer SP rollback probes in "LT CT Error Leads" (85240): a Collect scope that inserts rows around a
// collected error and takes the errors with GetCollectedErrors(true), run through Codeunit.Run.
// Scope: in-scope
// Not a test codeunit. Used only by "LT CT Error Leads".

// Inserts row 2531, raises a collectible error, takes it with GetCollectedErrors(true), inserts row 2532 and returns.
// GetLog returns what the scope saw (the instance keeps it after the run).
codeunit 89553 "LT SP Collect Get Runner"
{
    trigger OnRun()
    begin
        InsertCollectGet();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure InsertCollectGet()
    var
        Row: Record "LT CT Row";
        Errors: List of [ErrorInfo];
    begin
        Row.Id := 2531;
        Row.Insert();
        Error(ErrorInfo.Create('taken by get', true));
        Errors := GetCollectedErrors(true);
        Log += 'count=' + Format(Errors.Count()) + ';has=' + Format(HasCollectedErrors()) + ';';
        Row.Id := 2532;
        Row.Insert();
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    var
        Log: Text;
}
