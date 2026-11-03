// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 601.21): TestIsolation is a property of a test RUNNER codeunit (a test codeunit gets AL0223, see the must-not-compile case). The runners below start
// the test codeunit "LT U Isolation Tests" (one test inserts a row, the next one counts the rows) with TestIsolation = Function and = Codeunit; the counts
// the tests saw and the rows left behind after the run are kept in a single instance codeunit. Object ids 69596 to 69599 and 69790; the driver tests that start the runners are in report/lt-u-report-props/UPropertyTests.al.

table 69596 "LT U Isolation Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69598 "LT U State"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

codeunit 69597 "LT U Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure A_Insert()
    var
        Row: Record "LT U Isolation Row";
    begin
        Row.Id := 1;
        Row.Note := 'inserted by A';
        Row.Insert();
    end;

    [Test]
    procedure B_Count()
    var
        Row: Record "LT U Isolation Row";
    begin
        Row.Id := 2;
        Row.Note := 'inserted by B';
        Row.Insert();
    end;

    [Test]
    procedure C_Count()
    var
        Row: Record "LT U Isolation Row";
    begin
    end;
}

codeunit 69599 "LT U Runner Function"
{
    Subtype = TestRunner;
    TestIsolation = Function;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"LT U Isolation Tests");
    end;
}

codeunit 69790 "LT U Runner Codeunit"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"LT U Isolation Tests");
    end;
}
