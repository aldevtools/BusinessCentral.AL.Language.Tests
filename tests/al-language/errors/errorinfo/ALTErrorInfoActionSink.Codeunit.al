// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-addaction-string-integer-string-method
// Scope: in-scope
//
// Target codeunit for ErrorInfo.AddAction() in the ErrorInfo surface suite (codeunit 60351).
//
// AddAction(Caption, CodeunitID, MethodName) names a codeunit and a global method to run
// when a user presses the action in the error UI. The method must be global and must take a
// single ErrorInfo parameter -- that signature is the contract AddAction is declared
// against, so this codeunit exists to give the suite a REAL, resolvable target rather than
// a made-up id.
//
// It deliberately does NOT try to observe the callback firing. Ncl.dll stores actions in a
// CodeunitFunctionAction list that only the CLIENT dispatches when a user presses the
// button, and a [Test] has no client -- see the "deliberately not covered" note in
// TestErrorInfoType.al. What this codeunit supports is the claim that AddAction BINDS and
// accepts a valid target without throwing.

codeunit 60352 "ALT ErrorInfo Action Sink"
{
    // Global (not local) and taking a single ErrorInfo: the signature AddAction requires.
    procedure HandleErrorAction(ErrorInfo: ErrorInfo)
    begin
    end;
}
