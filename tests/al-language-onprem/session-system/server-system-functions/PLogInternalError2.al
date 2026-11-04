// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-loginternalerror-method
// Scope: in-scope (OnPrem app only: Dialog.LogInternalError (overload with Message, SubstitutionString, DataClassification, Verbosity))
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61256
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: writes to telemetry; if it raises uncatchable errors only this file fails
//
// LogInternalError(Message, SubstitutionString, DataClassification, Verbosity) via TryFunction: outcome and error text, with and without a %1 placeholder.
// BC versions: 29 (27 and 28 by CI)
codeunit 61256 "LT P109 LogInternalError2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLog(Message: Text; Substitution: Text; Class: DataClassification; Verb: Verbosity)
    begin
        Dialog.LogInternalError(Message, Substitution, Class, Verb);
    end;

    local procedure Outcome(Message: Text; Substitution: Text; Class: DataClassification; Verb: Verbosity): Text
    begin
        if TryLog(Message, Substitution, Class, Verb) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_LogInternalError_Substitution()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('with_placeholder', Outcome('LT P109 internal %1', 'LTP109', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('without_placeholder', Outcome('LT P109 internal', 'LTP109', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('blank_substitution', Outcome('LT P109 internal %1', '', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('blank_all', Outcome('', '', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('two_placeholders', Outcome('LT P109 %1 %2', 'LTP109', DataClassification::CustomerContent, Verbosity::Error));
        Observer.Observe('critical', Outcome('LT P109 %1', 'LTP109', DataClassification::EndUserIdentifiableInformation, Verbosity::Critical));
        Observer.Observe('warning', Outcome('LT P109 %1', 'LTP109', DataClassification::SystemMetadata, Verbosity::Warning));
        Observer.Observe('verbose', Outcome('LT P109 %1', 'LTP109', DataClassification::SystemMetadata, Verbosity::Verbose));
        Observer.Observe('long_substitution', Outcome('LT P109 %1', PadStr('', 800, 'x'), DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Expect('with_placeholder', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('without_placeholder', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('blank_substitution', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('blank_all', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('two_placeholders', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('critical', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('warning', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('verbose', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('long_substitution', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Verify();
    end;
}
