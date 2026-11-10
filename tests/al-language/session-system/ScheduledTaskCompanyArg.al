// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-createtask-integer-integer-boolean-string-datetime-recordid-duration-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 97027-97029.
// Probe: from al-runner issue 7589 (a guard against scheduling the same job twice: SetRange(Company, CompanyName()),
//   SetRange("Run Codeunit", ...) and IsEmpty, then TaskScheduler.CreateTask(Cu, 0, true, CompanyName(), NotBefore)).
// Area: the Company column of the "Scheduled Task" row of a task created with a company argument, read in the same transaction:
//   CompanyName(), CompanyName() with NotBefore, a blank text, UpperCase(CompanyName()), LowerCase(CompanyName()), another company of
//   the database (when there is one) and a company that does not exist. For each: the row exists, Company equals the argument,
//   CompanyName(), UpperCase(CompanyName()) and the blank text, its length, and whether SetRange(Company, CompanyName()) finds the row.
//   CreateTask is called directly: inside a TryFunction it ends the test with "Call to the function 'INSERT' is not allowed inside the
//   call to '<test>' when it is used as a TryFunction." (corpus CI runs 42852007063, 42852095520, 42852195813: BC 27.5, 28.5, 29.0).
//   Then the reporter's guard run twice: how many rows it leaves. Then Company after Commit() and in the next test of the codeunit
//   (STC_AfterCommit_Create leaves two tasks of worker 97029 committed; STC_AfterCommit_NextTest reads and cancels them).
// Already pinned elsewhere, not repeated: Company without a company argument is the current company (CnSessionLeads.al:34, :42); an
//   unknown company raises nothing at CreateTask (metadata/platform-tables/PlTTaskScheduler.al:189-196).
// Observation form: STC_Company_OwnCompanyForms and STC_Company_OtherAndUnknownCompany end in Finish() (not measured yet). The other
//   tests assert what BC produced in the corpus CI runs named above.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 97027 "LT STC Worker"
{
    trigger OnRun()
    begin
    end;
}

codeunit 97029 "LT STC Worker Committed"
{
    trigger OnRun()
    begin
    end;
}

codeunit 97028 "LT STC Company Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; CompanyArg: Text; WithNotBefore: Boolean)
    var
        Task: Record "Scheduled Task";
        Id: Guid;
    begin
        if WithNotBefore then
            Id := TaskScheduler.CreateTask(Codeunit::"LT STC Worker", 0, true, CompanyArg, CurrentDateTime() + 3600000)
        else
            Id := TaskScheduler.CreateTask(Codeunit::"LT STC Worker", 0, true, CompanyArg);
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
        Observer.Expect('guard empty 1', 'Yes');
        Observer.Expect('guard empty 2', 'No');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    local procedure ReadCommitted(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Task: Record "Scheduled Task";
    begin
        Task.SetRange("Run Codeunit", Codeunit::"LT STC Worker Committed");
        Observer.Observe(Prefix + ' rows', Format(Task.Count()));
        Task.SetRange(Company, CompanyName());
        Observer.Observe(Prefix + ' rows with CompanyName', Format(Task.Count()));
        Task.SetRange(Company, UpperCase(CompanyName()));
        Observer.Observe(Prefix + ' rows with upper CompanyName', Format(Task.Count()));
    end;

    [Test]
    procedure STC_AfterCommit_Create()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TaskScheduler.CreateTask(Codeunit::"LT STC Worker Committed", 0, true, CompanyName(), CurrentDateTime() + 3600000);
        TaskScheduler.CreateTask(Codeunit::"LT STC Worker Committed", 0, true, UpperCase(CompanyName()), CurrentDateTime() + 3600000);
        Commit();
        ReadCommitted(Observer, 'after commit');
        Observer.Expect('after commit rows', '2');
        Observer.Expect('after commit rows with CompanyName', '1');
        Observer.Expect('after commit rows with upper CompanyName', '1');
        Observer.Verify();
    end;

    [Test]
    procedure STC_AfterCommit_NextTest()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
    begin
        ReadCommitted(Observer, 'next test');
        Task.SetRange("Run Codeunit", Codeunit::"LT STC Worker Committed");
        if Task.FindSet() then
            repeat
                TaskScheduler.CancelTask(Task.ID);
            until Task.Next() = 0;
        Observer.Expect('next test rows', '2');
        Observer.Expect('next test rows with CompanyName', '1');
        Observer.Expect('next test rows with upper CompanyName', '1');
        Observer.Verify();
    end;
}
