// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-eventsubscriber-attribute
// Scope: in-scope
// Fixtures used: SbiFixtures.al (tables 76250 - 76253, page 76254, report 76255, log 76256, publisher 76257, subscribers 76258 - 76269,
//   enum extension 76270), Probe Observer (69160).
// Probe (al-runner issue 8470 part 1): is a subscriber that names its publisher by object id ([EventSubscriber(ObjectType::Codeunit, 76257, ...)],
//   ObjectType::Table, 76250 and so on) called when the event is raised, and in what order next to subscribers that name the same publisher by
//   name? Cells: an own codeunit (integration event, business event, IncludeSender, manual binding), an own table, an own page, an own report,
//   and the platform codeunits by literal id: Global Triggers 2000000002, Company Triggers 2000000003, UI Helper Triggers 2000000004, Reporting
//   Triggers 2000000005, Filter Helper Triggers 2000000007, Extension Triggers 2000000010, Caption Class 42 and Auto Format 45.
//   Compile cells: the bare id compiles with AL 16, 17 and 18 (this file); Codeunit::<id>, Database::<id> and Page::<id> are syntax errors, and a
//   bare id that names no object is AL0185 (must-not-compile cases 3216 to 3220).
//   Method names in one subscriber codeunit start with a letter that orders them (the corpus pins the alphabetical order of the subscriber methods
//   of one codeunit: events/ProbeEventSubscriberOrder.al).
// Probe: written against a local BC service tier; every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 - 29

codeunit 76271 "LT SBI Subscriber By Id Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ById_OwnCodeunit_OneSubscriberCodeunit_Order()
    var
        Publisher: Codeunit "LT SBI Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('raise', Publisher.RaiseOne());
        Observer.Observe('raise again', Publisher.RaiseOne());
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnCodeunit_ThreeSubscriberCodeunits_Order()
    var
        Publisher: Codeunit "LT SBI Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('raise', Publisher.RaiseCross());
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnCodeunit_ManualSubscriber_BindUnbind()
    var
        Publisher: Codeunit "LT SBI Publisher";
        Manual: Codeunit "LT SBI Manual By Id";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('before bind', Publisher.RaiseManual());
        BindSubscription(Manual);
        Observer.Observe('bound', Publisher.RaiseManual());
        UnbindSubscription(Manual);
        Observer.Observe('after unbind', Publisher.RaiseManual());
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnCodeunit_BusinessEventAndSender()
    var
        Publisher: Codeunit "LT SBI Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('business event', Publisher.RaiseBusiness());
        Observer.Observe('include sender', Publisher.RaiseSender());
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnTable_TableEvents()
    var
        Row: Record "LT SBI Row";
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        L.Start();
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('insert true', L.Take());
        Row.Id := 2;
        Row.Insert(false);
        Observer.Observe('insert false', L.Take());
        Row.Validate(Name, 'n1');
        Observer.Observe('validate', L.Take());
        Row.Modify(true);
        Observer.Observe('modify', L.Take());
        Row.Delete(true);
        Observer.Observe('delete', L.Take());
        L.Stop();
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnPage_PageEvents()
    var
        Row: Record "LT SBI Row";
        L: Codeunit "LT SBI Log";
        Card: TestPage "LT SBI Card";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        L.Start();
        Card.OpenEdit();
        Observer.Observe('open', L.Take());
        Card.Name.SetValue('p1');
        Observer.Observe('validate', L.Take());
        Card.Close();
        L.Stop();
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure ById_OwnReport_ReportEvent()
    var
        Rep: Report "LT SBI Report";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('raise', Rep.RaiseIt());
        Observer.Finish();
    end;

    [Test]
    procedure ById_GlobalTriggers_SetupAndDatabaseInsert()
    var
        A: Record "LT SBI GT Row A";
        B: Record "LT SBI GT Row B";
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Start();
        A.DeleteAll(true);
        B.DeleteAll(true);
        Observer.Observe('deleteall', L.Take());
        A.Id := 1;
        A.Insert(true);
        Observer.Observe('insert A (setup by id)', L.Take());
        B.Id := 1;
        B.Insert(true);
        Observer.Observe('insert B (setup by name)', L.Take());
        L.Stop();
        A.DeleteAll();
        B.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure ById_UIHelperTriggers_CaptionClassTranslate()
    var
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Start();
        Observer.Observe('result', CaptionClassTranslate('LTSBIU,x'));
        Observer.Observe('log', L.Take());
        L.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure ById_CaptionClass42_OnResolveCaptionClass()
    var
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Start();
        Observer.Observe('result', CaptionClassTranslate('LTSBIC,x'));
        Observer.Observe('log', L.Take());
        L.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure ById_AutoFormat45_OnResolveAutoFormat()
    var
        Row: Record "LT SBI Row";
        L: Codeunit "LT SBI Log";
        Card: TestPage "LT SBI Card";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amount := 2.25;
        Row.Insert();
        L.Start();
        Card.OpenView();
        Observer.Observe('value', Card.Amount.Value());
        Card.Close();
        Observer.Observe('log', L.Take());
        L.Stop();
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure ById_ReportingTriggers_SubstituteReport()
    var
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Start();
        Report.Run(Report::"LT SBI Report", false, false);
        Observer.Observe('run', L.Take());
        L.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure ById_FilterHelperTriggers_MakeDateFilter()
    var
        Row: Record "LT SBI Row";
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Start();
        if TrySetDateFilter(Row) then
            Observer.Observe('setfilter', 'ok ' + Row.GetFilter(D))
        else
            Observer.Observe('setfilter', 'error ' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('log', L.Take());
        L.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure ById_CompanyTriggers_OnCompanyOpen()
    var
        L: Codeunit "LT SBI Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('company open', L.OpenText());
        Observer.Finish();
    end;

    [Test]
    procedure ById_ExtensionTriggers_OnInstallApp()
    var
        Row: Record "LT SBI Install Log";
        Observer: Codeunit "Probe Observer";
        Db: Text;
        Comp: Text;
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                if Row.Tag.Contains('Database') then
                    Db += Row.Tag + ';'
                else
                    if Row.Company = CompanyName() then
                        Comp += Row.Tag + ';';
            until Row.Next() = 0;
        Observer.Observe('per database', Db);
        Observer.Observe('per company', Comp);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetDateFilter(var Row: Record "LT SBI Row")
    begin
        Row.SetFilter(D, 'ltsbi');
    end;
}
