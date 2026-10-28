// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Probe: AL Runner issue 5859 (writer SW). The rows Microsoft's Test Runner app ("Test Method Line", table 130450) records for a
//   test codeunit whose OnRun is empty, whose OnRun raises, and whose OnRun calls one of its own test methods.
// Control codeunit 89670 has a plain OnRun; 89671 raises in OnRun; 89672 calls a test method from OnRun. The reader (89675, a higher
//   id, so the runner reaches it last) reads the runner's rows for the three codeunits: per row line type, function name, result,
//   error preview and error code.
// BC versions: 27 - 29

codeunit 89670 "LT SW OnRun Plain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure PlainFirst()
    begin
    end;

    [Test]
    procedure PlainSecond()
    begin
    end;
}

codeunit 89671 "LT SW OnRun Raises"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Error('LT SW onrun boom');
    end;

    [Test]
    procedure AfterRaisingFirst()
    begin
    end;

    [Test]
    procedure AfterRaisingSecond()
    begin
    end;
}

codeunit 89672 "LT SW OnRun Calls Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        CalledFromOnRun();
    end;

    [Test]
    procedure CalledFromOnRun()
    begin
    end;

    [Test]
    procedure OtherTest()
    begin
    end;
}

codeunit 89675 "LT SW OnRun Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RunnerLinesOfOnRunCodeunits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plain', Lines(Codeunit::"LT SW OnRun Plain"));
        Observer.Observe('raises', Lines(Codeunit::"LT SW OnRun Raises"));
        Observer.Observe('calls test', Lines(Codeunit::"LT SW OnRun Calls Test"));
        Observer.Finish();
    end;

    // One entry per "Test Method Line" row of the codeunit, in key order (Test Suite, Line No.):
    //   <line type>:<function>:<result>:<error preview>:<error code>
    local procedure Lines(CodeunitId: Integer): Text
    var
        RecRef: RecordRef;
        Result: Text;
    begin
        RecRef.Open(130450);
        RecRef.Field(4).SetRange(CodeunitId);
        if RecRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ; ';
                Result += Format(RecRef.Field(3).Value()) + ':' + Format(RecRef.Field(6).Value()) + ':' + Format(RecRef.Field(8).Value()) + ':' +
                  Format(RecRef.Field(50).Value()) + ':' + Format(RecRef.Field(51).Value());
            until RecRef.Next() = 0;
        if Result = '' then
            exit('<no rows>');
        exit(Result);
    end;
}
