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
// Measured (corpus CI runs 42862333619 and its 28.5 and 29.0 legs for STC_Company_OwnCompanyForms and
//   STC_Company_OtherAndUnknownCompany, the runs named above for the other tests; identical on BC 27.5, 28.5 and 29.0): the Company
//   column holds the company argument as written, without changing its case and without checking that the company exists. A blank
//   argument stores CompanyName(). SetRange(Company, CompanyName()) finds the row only when the argument was CompanyName() or blank:
//   it does not find the row of UpperCase(CompanyName()), LowerCase(CompanyName()), another company or an unknown company.
//   The lengths are those of the names: 25 for the current company of the corpus CI database and for the unknown name, 10 for the
//   other company that database holds.
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
        Observer.Expect('CompanyName row', 'Yes');
        Observer.Expect('CompanyName company is argument', 'Yes');
        Observer.Expect('CompanyName company is CompanyName', 'Yes');
        Observer.Expect('CompanyName company is upper CompanyName', 'No');
        Observer.Expect('CompanyName company blank', 'No');
        Observer.Expect('CompanyName company length', '25');
        Observer.Expect('CompanyName found by CompanyName filter', 'Yes');
        Observer.Expect('CompanyName with NotBefore row', 'Yes');
        Observer.Expect('CompanyName with NotBefore company is argument', 'Yes');
        Observer.Expect('CompanyName with NotBefore company is CompanyName', 'Yes');
        Observer.Expect('CompanyName with NotBefore company is upper CompanyName', 'No');
        Observer.Expect('CompanyName with NotBefore company blank', 'No');
        Observer.Expect('CompanyName with NotBefore company length', '25');
        Observer.Expect('CompanyName with NotBefore found by CompanyName filter', 'Yes');
        Observer.Expect('blank row', 'Yes');
        Observer.Expect('blank company is argument', 'No');
        Observer.Expect('blank company is CompanyName', 'Yes');
        Observer.Expect('blank company is upper CompanyName', 'No');
        Observer.Expect('blank company blank', 'No');
        Observer.Expect('blank company length', '25');
        Observer.Expect('blank found by CompanyName filter', 'Yes');
        Observer.Expect('upper row', 'Yes');
        Observer.Expect('upper company is argument', 'Yes');
        Observer.Expect('upper company is CompanyName', 'No');
        Observer.Expect('upper company is upper CompanyName', 'Yes');
        Observer.Expect('upper company blank', 'No');
        Observer.Expect('upper company length', '25');
        Observer.Expect('upper found by CompanyName filter', 'No');
        Observer.Expect('lower row', 'Yes');
        Observer.Expect('lower company is argument', 'Yes');
        Observer.Expect('lower company is CompanyName', 'No');
        Observer.Expect('lower company is upper CompanyName', 'No');
        Observer.Expect('lower company blank', 'No');
        Observer.Expect('lower company length', '25');
        Observer.Expect('lower found by CompanyName filter', 'No');
        Observer.Verify();
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
        Observer.Expect('another company exists', 'Yes');
        Observer.Expect('another company row', 'Yes');
        Observer.Expect('another company company is argument', 'Yes');
        Observer.Expect('another company company is CompanyName', 'No');
        Observer.Expect('another company company is upper CompanyName', 'No');
        Observer.Expect('another company company blank', 'No');
        Observer.Expect('another company company length', '10');
        Observer.Expect('another company found by CompanyName filter', 'No');
        Observer.Expect('unknown company row', 'Yes');
        Observer.Expect('unknown company company is argument', 'Yes');
        Observer.Expect('unknown company company is CompanyName', 'No');
        Observer.Expect('unknown company company is upper CompanyName', 'No');
        Observer.Expect('unknown company company blank', 'No');
        Observer.Expect('unknown company company length', '25');
        Observer.Expect('unknown company found by CompanyName filter', 'No');
        Observer.Verify();
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
