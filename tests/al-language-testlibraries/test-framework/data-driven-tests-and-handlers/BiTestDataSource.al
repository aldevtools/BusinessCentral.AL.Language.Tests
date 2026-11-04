// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datasourcecontext/datasourcecontext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 81581, 81582, 81587 - 81590
// Corpus issues 629 item 16 (the rows a [TestDataSource] hands to a data-driven test) and 626 items 9 and 10
// (DataSourceContext.AppId and CodeunitId inside ListTestCases and GetTestCase of a codeunit that implements ITestDataSource).
// The test procedure of a data-driven test takes an Interface ITestContext and has no [Test] attribute (AL0189 with both).
// The corpus CI (BC 29.0, run 39225437143) ended every codeunit with a data-driven test with
// "session killed twice by this codeunit: hub connection closed", and no ListTestCases or GetTestCase call was logged.
// Cause (BC SaaS sandbox, 2026-10-30, same result there): this probe calls DataSourceContext.CodeunitId() and AppId() in its sources,
// and BC ends the session for that (not a Linux fault). The working data-driven tests, with the sandbox answers, are in BiDataDriven.al.
// This file stays switched off: it compiles only with the symbol LTBI_TESTDATASOURCE_PROBE, which no CI leg defines.
// Probe: observed values.
// BC versions: 29
#if LTBI_TESTDATASOURCE_PROBE
interface "LT BI TF Case Data"
{
    procedure CaseText(): Text;
}

codeunit 81590 "LT BI TF DS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 81581 "LT BI TF Case" implements ITestContext, "LT BI TF Case Data"
{
    var
        Value: Text;

    procedure SetText(NewValue: Text)
    begin
        Value := NewValue;
    end;

    procedure CaseText(): Text
    begin
        exit(Value);
    end;
}

codeunit 81582 "LT BI TF Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Log: Codeunit "LT BI TF DS Log";
        Cases: List of [Text];
    begin
        Log.Add('list(set=' + DataSetIdentifier + ',cu=' + Format(context.CodeunitId()) + ')');
        Cases.Add('alpha');
        Cases.Add('beta');
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        Log: Codeunit "LT BI TF DS Log";
        TestCase: Codeunit "LT BI TF Case";
    begin
        Log.Add('get(set=' + DataSetIdentifier + ',index=' + Format(TestCaseIndex) + ',id=' + TestCaseIdentifier + ',cu=' + Format(context.CodeunitId()) + ')');
        TestCase.SetText(TestCaseIdentifier + '#' + Format(TestCaseIndex));
        exit(TestCase);
    end;
}

codeunit 81587 "LT BI TF DS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One run per row; each run observes its row and the data source calls logged before it.
    [TestDataSource(81582, 'Set1')]
    procedure BiTf_Ds_Rows(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI TF DS Log";
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI TF Case Data";
    begin
        CaseData := Context as "LT BI TF Case Data";
        Observer.Observe('row', CaseData.CaseText());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}

codeunit 81588 "LT BI TF AppId Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        Cases.Add('list app=' + Format(context.AppId()));
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        TestCase: Codeunit "LT BI TF Case";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        TestCase.SetText(TestCaseIdentifier + ';get app=' + Format(context.AppId()) + ';own app=' + Format(Info.Id()));
        exit(TestCase);
    end;
}

// Highest id of the test framework probes: outside a handler, AppId() ends the test session (tests/al-language/lt-ac/ACContexts.al).
codeunit 81589 "LT BI TF AppId Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(81588, 'AppIdSet')]
    procedure BiTf_AppId_Case(Context: Interface ITestContext)
    var
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI TF Case Data";
    begin
        CaseData := Context as "LT BI TF Case Data";
        Observer.Observe('case', CaseData.CaseText());
        Observer.Finish();
    end;
}
#endif
