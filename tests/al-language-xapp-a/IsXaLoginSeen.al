// Login and company-open subscriber of cross-app fixture A for al-runner issue 9046 (tests: tests/al-language/install-upgrade/IsInstallSessionTests.al).
// XApp A is installed before the AL Language Coverage Tests app. This SingleInstance codeunit notes each "System Initialization".OnAfterLogin and
// "Company Triggers".OnCompanyOpenCompleted call it gets, with the execution context; the main app's install subscribers read the list
// (IsInstallSession.al): does a subscriber of an app installed earlier run in a later app's install session? No writes, no install code.
// BC versions: 27 - 29

codeunit 98499 "LT IS9 XA Login Seen"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure AsText(): Text
    begin
        exit(Calls);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Calls += 'OnAfterLogin|' + Format(Session.GetExecutionContext()) + ';';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    begin
        Calls += 'OnCompanyOpenCompleted|' + Format(Session.GetExecutionContext()) + ';';
    end;
}
