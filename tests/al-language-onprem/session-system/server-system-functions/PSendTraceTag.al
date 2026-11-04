// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-sendtracetag-method
// Scope: in-scope (OnPrem app only: Session.SendTraceTag)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61253
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: writes a trace tag to telemetry of the service tier
//
// SendTraceTag(Tag, Category, Verbosity, Message [, DataClassification]): outcome and error text only; all verbosities, blank values, all data classifications.
// BC versions: 29 (27 and 28 by CI)
codeunit 61253 "LT P109 SendTraceTag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySend(Tag: Text; Category: Text; Verb: Verbosity; Message: Text)
    begin
        Session.SendTraceTag(Tag, Category, Verb, Message);
    end;

    [TryFunction]
    local procedure TrySendClass(Class: DataClassification)
    begin
        Session.SendTraceTag('LTP109', 'LT P109', Verbosity::Normal, 'LT P109 message', Class);
    end;

    local procedure Outcome(Tag: Text; Category: Text; Verb: Verbosity; Message: Text): Text
    begin
        if TrySend(Tag, Category, Verb, Message) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure OutcomeClass(Class: DataClassification): Text
    begin
        if TrySendClass(Class) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_SendTraceTag_Verbosities()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('critical', Outcome('LTP109', 'LT P109', Verbosity::Critical, 'LT P109 message'));
        Observer.Observe('error', Outcome('LTP109', 'LT P109', Verbosity::Error, 'LT P109 message'));
        Observer.Observe('warning', Outcome('LTP109', 'LT P109', Verbosity::Warning, 'LT P109 message'));
        Observer.Observe('normal', Outcome('LTP109', 'LT P109', Verbosity::Normal, 'LT P109 message'));
        Observer.Observe('verbose', Outcome('LTP109', 'LT P109', Verbosity::Verbose, 'LT P109 message'));
        Observer.Expect('critical', 'ok');
        Observer.Expect('error', 'ok');
        Observer.Expect('warning', 'ok');
        Observer.Expect('normal', 'ok');
        Observer.Expect('verbose', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P109_SendTraceTag_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blank_tag', Outcome('', 'LT P109', Verbosity::Normal, 'LT P109 message'));
        Observer.Observe('blank_category', Outcome('LTP109', '', Verbosity::Normal, 'LT P109 message'));
        Observer.Observe('blank_message', Outcome('LTP109', 'LT P109', Verbosity::Normal, ''));
        Observer.Observe('all_blank', Outcome('', '', Verbosity::Normal, ''));
        Observer.Observe('long_message', Outcome('LTP109', 'LT P109', Verbosity::Normal, PadStr('', 800, 'x')));
        Observer.Observe('unicode', Outcome('LTP109', 'LT P109', Verbosity::Normal, 'ÄÖÜ 日本'));
        Observer.Expect('blank_tag', 'ok');
        Observer.Expect('blank_category', 'ok');
        Observer.Expect('blank_message', 'ok');
        Observer.Expect('all_blank', 'ok');
        Observer.Expect('long_message', 'ok');
        Observer.Expect('unicode', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P109_SendTraceTag_DataClassification()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('customer_content', OutcomeClass(DataClassification::CustomerContent));
        Observer.Observe('end_user_identifiable', OutcomeClass(DataClassification::EndUserIdentifiableInformation));
        Observer.Observe('account_data', OutcomeClass(DataClassification::AccountData));
        Observer.Observe('organization_identifiable', OutcomeClass(DataClassification::OrganizationIdentifiableInformation));
        Observer.Observe('system_metadata', OutcomeClass(DataClassification::SystemMetadata));
        Observer.Observe('to_be_classified', OutcomeClass(DataClassification::ToBeClassified));
        Observer.Observe('end_user_pseudonymous', OutcomeClass(DataClassification::EndUserPseudonymousIdentifiers));
        Observer.Expect('customer_content', 'ok');
        Observer.Expect('end_user_identifiable', 'ok');
        Observer.Expect('account_data', 'ok');
        Observer.Expect('organization_identifiable', 'ok');
        Observer.Expect('system_metadata', 'ok');
        Observer.Expect('to_be_classified', 'ok');
        Observer.Expect('end_user_pseudonymous', 'ok');
        Observer.Verify();
    end;
}
