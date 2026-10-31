// @expect AL0189 | Attribute 'Test' cannot be specified, because 'TestDataSource' is already specified
// @from 29
// @appjson {"runtime": "18.0"}
// A data-driven test procedure ([TestDataSource]) cannot also carry [Test].
codeunit 59302 "MNC DS Src 2302" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        Ctx: Interface ITestContext;
    begin
        exit(Ctx);
    end;
}

codeunit 59303 "MNC DS Test 2302"
{
    Subtype = Test;

    [Test]
    [TestDataSource(59302, 'Set')]
    procedure Run1(Context: Interface ITestContext)
    begin
    end;
}
