// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-createtask-integer-integer-boolean-string-datetime-recordid-duration-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 97027-97028.
// Probe: from al-runner issue 7589 (a guard against scheduling the same job twice: SetRange(Company, CompanyName()),
//   SetRange("Run Codeunit", ...) and IsEmpty, then TaskScheduler.CreateTask(Cu, 0, true, CompanyName(), NotBefore)).
// Area: the Company column of the "Scheduled Task" row of a task created with a company argument, read in the same transaction:
//   CompanyName(), CompanyName() with NotBefore, a blank text, UpperCase(CompanyName()), LowerCase(CompanyName()), another company of
//   the database (when there is one) and a company that does not exist. For each: whether CreateTask raised, the row exists, Company
//   equals the argument, CompanyName() and the blank text, its length, and whether SetRange(Company, CompanyName()) finds the row.
//   Then the reporter's guard run twice: how many rows it leaves.
// Already pinned elsewhere, not repeated: Company without a company argument is the current company (CnSessionLeads.al:34, :42); an
//   unknown company raises nothing at CreateTask (metadata/platform-tables/PlTTaskScheduler.al:189-196).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 97027 "LT STC Worker"
{
    trigger OnRun()
    begin
    end;
}

codeunit 97028 "LT STC Company Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCreate(CompanyArg: Text; WithNotBefore: Boolean; var Id: Guid)
    begin
        if WithNotBefore then
            Id := TaskScheduler.CreateTask(Codeunit::"LT STC Worker", 0, true, CompanyArg, CurrentDateTime() + 3600000)
        else
            Id := TaskScheduler.CreateTask(Codeunit::"LT STC Worker", 0, true, CompanyArg);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; CompanyArg: Text; WithNotBefore: Boolean)
    var
        Task: Record "Scheduled Task";
        Id: Guid;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCreate(CompanyArg, WithNotBefore, Id);
        Observer.Observe(Name + ' created', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Observer.Observe(Name + ' row', Format(Task.Get(Id)));
        Observer.Observe(Name + ' company is argument', Format(Task.Company = CompanyArg));
        Observer.Observe(Name + ' company is CompanyName', Format(Task.Company = CompanyName()));
        Observer.Observe(Name + ' company is upper CompanyName', Format(Task.Company = UpperCase(CompanyName())));
        Observer.Observe(Name + ' company blank', Format(Task.Company = ''));
        Observer.Observe(Name + ' company length', Format(StrLen(Task.Company)));
        Task.Reset();
        Task.SetRange(ID, Id);
        Task.SetRange(Company, CompanyName());
        Observer.Observe(Name + ' found by CompanyName filter', Format(not Task.IsEmpty()));
        TaskScheduler.CancelTask(Id);
    end;

    local procedure OtherCompany(): Text
    var
        Company: Record Company;
    begin
        Company.SetFilter(Name, '<>%1', CompanyName());
        if Company.FindFirst() then
            exit(Company.Name);
        exit('');
    end;

    [Test]
    procedure STC_Company_OwnCompanyForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'CompanyName', CompanyName(), false);
        RunCase(Observer, 'CompanyName with NotBefore', CompanyName(), true);
        RunCase(Observer, 'blank', '', false);
        RunCase(Observer, 'upper', UpperCase(CompanyName()), false);
        RunCase(Observer, 'lower', LowerCase(CompanyName()), false);
        Observer.Finish();
    end;

    [Test]
    procedure STC_Company_OtherAndUnknownCompany()
    var
        Observer: Codeunit "Probe Observer";
        Other: Text;
    begin
        Other := OtherCompany();
        Observer.Observe('another company exists', Format(Other <> ''));
        if Other <> '' then
            RunCase(Observer, 'another company', Other, false);
        RunCase(Observer, 'unknown company', 'No Such Company For Probe', false);
        Observer.Finish();
    end;

    [Test]
    procedure STC_Guard_RunTwice()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        I: Integer;
    begin
        for I := 1 to 2 do begin
            Task.Reset();
            Task.SetRange(Company, CompanyName());
            Task.SetRange("Run Codeunit", Codeunit::"LT STC Worker");
            Observer.Observe('guard empty ' + Format(I), Format(Task.IsEmpty()));
            if Task.IsEmpty() then
                TaskScheduler.CreateTask(Codeunit::"LT STC Worker", 0, true, CompanyName(), CurrentDateTime() + 3600000);
        end;
        Task.Reset();
        Task.SetRange("Run Codeunit", Codeunit::"LT STC Worker");
        Observer.Observe('rows', Format(Task.Count()));
        if Task.FindSet() then
            repeat
                TaskScheduler.CancelTask(Task.ID);
            until Task.Next() = 0;
        Observer.Finish();
    end;
}
