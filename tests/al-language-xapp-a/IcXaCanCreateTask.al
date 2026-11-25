// Login and company-open subscriber of cross-app fixture A for al-runner issue 9123 (tests: tests/al-language/install-upgrade/IcInstallCanCreateTaskTests.al).
// XApp A is installed before the AL Language Coverage Tests app. This SingleInstance codeunit notes, for each "Company Triggers".OnCompanyOpen and
// OnCompanyOpenCompleted and "System Initialization".OnAfterLogin call it gets, what TaskScheduler.CanCreateTask() answers there, beside
// Session.GetExecutionContext(), Session.GetCurrentModuleExecutionContext() and Session.CurrentExecutionMode(). The main app's install subscribers
// read the list (IcInstallCanCreateTask.al): Microsoft's own login subscribers (System Application) are in another app than the one being installed,
// like this one. No writes, no install code.
// BC versions: 27 - 29

codeunit 98498 "LT IC XA Seen"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure AsText(): Text
    begin
        exit(Calls);
    end;

    local procedure Note(Name: Text)
    begin
        Calls += Name + '|ctx=' + Format(Session.GetExecutionContext()) + ',mod=' + Format(Session.GetCurrentModuleExecutionContext()) +
            ',mode=' + Format(Session.CurrentExecutionMode()) + ',cct=' + Format(TaskScheduler.CanCreateTask()) + ';';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    begin
        Note('OnCompanyOpen');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('OnAfterLogin');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    begin
        Note('OnCompanyOpenCompleted');
    end;
}
