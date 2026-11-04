// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods
// Scope: in-scope
// Fixtures used: self-contained objects 85368
// Facts: corpus issue 670 (odd AL behavior leads, part E): the order in which the test runner runs the [Test] procedures of one codeunit.
//   The procedures below are declared in an order that is neither alphabetic nor the reverse; each appends its name to a log table
//   (the default TransactionModel commits at the end of each test), and the last declared test reads the log.
// Leads: microsoft/AL issues 4417, 2711.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
table 85368 "LT CV Run Order Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Seq) { Clustered = true; }
    }
}

codeunit 85368 "LT CV Test Run Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Log(Name: Text)
    var
        L: Record "LT CV Run Order Log";
    begin
        L.Name := CopyStr(Name, 1, 50);
        L.Insert();
    end;

    [Test]
    procedure M_RunOrder_Start()
    var
        L: Record "LT CV Run Order Log";
    begin
        L.DeleteAll();
        Log('M');
    end;

    [Test]
    procedure Z_RunOrder_Second()
    begin
        Log('Z');
    end;

    [Test]
    procedure A_RunOrder_Third()
    begin
        Log('A');
    end;

    [Test]
    procedure Q_RunOrder_Fourth()
    begin
        Log('Q');
    end;

    [Test]
    procedure C_RunOrder_Fifth()
    begin
        Log('C');
    end;

    [Test]
    procedure N_RunOrder_Check()
    var
        L: Record "LT CV Run Order Log";
        Seen: Text;
    begin
        if L.FindSet() then
            repeat
                Seen += L.Name + ';';
            until L.Next() = 0;
        L.DeleteAll();
        if Seen <> 'M;Z;A;Q;C;' then
            Error('Run order: %1', Seen);
    end;
}
