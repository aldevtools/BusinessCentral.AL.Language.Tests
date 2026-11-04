// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-loginternalerror-method
// Scope: in-scope (OnPrem app only: Dialog.LogInternalError (overload with Message, DataClassification, Verbosity))
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61255
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: writes to telemetry; if it raises uncatchable errors only this file fails
//
// LogInternalError(Message, DataClassification, Verbosity) via TryFunction: outcome and error text, over data classifications and verbosities.
// BC versions: 29 (27 and 28 by CI)
codeunit 61255 "LT P109 LogInternalError1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLog(Message: Text; Class: DataClassification; Verb: Verbosity)
    begin
        Dialog.LogInternalError(Message, Class, Verb);
    end;

    local procedure Outcome(Message: Text; Class: DataClassification; Verb: Verbosity): Text
    begin
        if TryLog(Message, Class, Verb) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_LogInternalError_Basic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('normal', Outcome('LT P109 internal', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('error', Outcome('LT P109 internal', DataClassification::SystemMetadata, Verbosity::Error));
        Observer.Observe('critical', Outcome('LT P109 internal', DataClassification::SystemMetadata, Verbosity::Critical));
        Observer.Observe('warning', Outcome('LT P109 internal', DataClassification::SystemMetadata, Verbosity::Warning));
        Observer.Observe('verbose', Outcome('LT P109 internal', DataClassification::SystemMetadata, Verbosity::Verbose));
        Observer.Observe('customer_content', Outcome('LT P109 internal', DataClassification::CustomerContent, Verbosity::Normal));
        Observer.Observe('blank_message', Outcome('', DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('long_message', Outcome(PadStr('', 800, 'x'), DataClassification::SystemMetadata, Verbosity::Normal));
        Observer.Observe('after_last_error_text', GetLastErrorText());
        Observer.Expect('normal', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('error', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('critical', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('warning', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('verbose', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('customer_content', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('blank_message', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('long_message', 'error:An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Expect('after_last_error_text', 'An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Observer.Verify();
    end;
}
