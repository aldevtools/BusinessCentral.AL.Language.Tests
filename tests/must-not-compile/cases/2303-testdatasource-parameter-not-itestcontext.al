// @expect AL0240 | The signature of procedure 'Run1' does not match the signature required by attribute 'TestDataSource': parameter 1 is expected to be of type 'interface ITestContext' but found type 'Integer'. The expected signature is: Run1(Context: interface ITestContext).
// @from 29
// @appjson {"runtime": "18.0"}
// The procedure of a data-driven test takes one Interface ITestContext parameter; an Integer parameter is wrong.
codeunit 59304 "MNC DS Src 2303" implements ITestDataSource
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

codeunit 59305 "MNC DS Test 2303"
{
    Subtype = Test;

    [TestDataSource(59304, 'Set')]
    procedure Run1(Context: Integer)
    begin
    end;
}
