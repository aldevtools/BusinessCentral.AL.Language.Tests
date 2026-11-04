// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-logauditmessage-method
// Scope: in-scope (OnPrem app only: Session.LogAuditMessage)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61251
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: writes an audit message to telemetry of the service tier
//
// LogAuditMessage(Description, Result, Category, Operation, OperationResult [, CustomDimensions]): outcome and error text only; blank texts, negative integers, empty and filled dimensions.
// BC versions: 29 (27 and 28 by CI)
codeunit 61251 "LT P109 LogAuditMessage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLog(Description: Text; Op: Integer; OpResult: Integer)
    begin
        Session.LogAuditMessage(Description, SecurityOperationResult::Success, AuditCategory::ApplicationManagement, Op, OpResult);
    end;

    [TryFunction]
    local procedure TryLogDims(Description: Text; Dims: Dictionary of [Text, Text])
    begin
        Session.LogAuditMessage(Description, SecurityOperationResult::Failure, AuditCategory::Authorization, 1, 1, Dims);
    end;

    local procedure Outcome(Description: Text; Op: Integer; OpResult: Integer): Text
    begin
        if TryLog(Description, Op, OpResult) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure OutcomeDims(Description: Text; Dims: Dictionary of [Text, Text]): Text
    begin
        if TryLogDims(Description, Dims) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_LogAuditMessage_Overload1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('basic', Outcome('LT P109 audit', 1, 1));
        Observer.Observe('blank', Outcome('', 1, 1));
        Observer.Observe('zero', Outcome('LT P109 audit', 0, 0));
        Observer.Observe('negative', Outcome('LT P109 audit', -1, -1));
        Observer.Observe('large', Outcome('LT P109 audit', 2147483647, 2147483647));
        Observer.Observe('long_text', Outcome(PadStr('', 800, 'x'), 1, 1));
        Observer.Observe('unicode', Outcome('LT P109 ÄÖÜ 日本', 1, 1));
        Observer.Expect('basic', 'ok');
        Observer.Expect('blank', 'ok');
        Observer.Expect('zero', 'ok');
        Observer.Expect('negative', 'error:The AuditMessageOperation value ''-1'' is invalid. Please use one the following values: 0 = AdministeredEnvironment, 1 = ConfiguredExtension, 2 = AdministeredUser, 3 = AdministeredCompany, 4 = ConfiguredIntegration, 5 = ConfiguredCopilot, 6 = ConfiguredCloudMigration, 7 = AdministeredReport.|InvalidValue');
        Observer.Expect('large', 'error:The AuditMessageOperation value ''2147483647'' is invalid. Please use one the following values: 0 = AdministeredEnvironment, 1 = ConfiguredExtension, 2 = AdministeredUser, 3 = AdministeredCompany, 4 = ConfiguredIntegration, 5 = ConfiguredCopilot, 6 = ConfiguredCloudMigration, 7 = AdministeredReport.|InvalidValue');
        Observer.Expect('long_text', 'ok');
        Observer.Expect('unicode', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P109_LogAuditMessage_Overload2_Dimensions()
    var
        Observer: Codeunit "Probe Observer";
        Dims: Dictionary of [Text, Text];
    begin
        Observer.Observe('empty_dims', OutcomeDims('LT P109 audit', Dims));
        Dims.Add('LTP109Key', 'LTP109Value');
        Observer.Observe('one_dim', OutcomeDims('LT P109 audit', Dims));
        Dims.Add('', 'blankkey');
        Observer.Observe('blank_key', OutcomeDims('LT P109 audit', Dims));
        Dims.Add('LTP109Blank', '');
        Observer.Observe('blank_value', OutcomeDims('LT P109 audit', Dims));
        Observer.Expect('empty_dims', 'ok');
        Observer.Expect('one_dim', 'ok');
        Observer.Expect('blank_key', 'ok');
        Observer.Expect('blank_value', 'ok');
        Observer.Verify();
    end;
}
