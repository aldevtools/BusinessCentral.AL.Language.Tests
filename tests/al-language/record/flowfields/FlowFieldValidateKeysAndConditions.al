// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 76617 and 76619, test codeunit 76618
// local object: the lookup FlowField of each source table and the key of the table whose first field is that FlowField are what is under
//   test, so the probe needs its own tables.
// Probe (al-runner issue 7427 neighbours, record/keys-sorting/KeyLookupFlowFieldFirst.al pins Boolean, Integer, Date, Text and Decimal): the
//   row order of a key whose first field is a lookup FlowField of a Code field (values that look like numbers and that do not) and of an
//   Option field, ascending and descending, with a filter on a stored field.
// BC versions: 27, 28, 29

table 76617 "REC FFV Key Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Code[20]) { }
        field(3; Opt; Option) { OptionMembers = " ",Low,High,Mid; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 76619 "REC FFV Key Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Type Code"; Code[10]) { }
        field(3; Grp; Integer) { }
        field(10; LkCode; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Key Setup".Val where("Code" = field("Type Code")));
        }
        field(11; LkOpt; Option)
        {
            OptionMembers = " ",Low,High,Mid;
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Key Setup".Opt where("Code" = field("Type Code")));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 76618 "REC FFV Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure SeedKeys()
    var
        Setup: Record "REC FFV Key Setup";
        Row: Record "REC FFV Key Row";
        i: Integer;
    begin
        Setup.DeleteAll();
        Row.DeleteAll();
        // setup codes S1..S6: Val '10', '9', 'A', '100', '', 'B 1'; Opt Mid, Low, High, ' ', Low, High
        AddSetup('S1', '10', 3);
        AddSetup('S2', '9', 1);
        AddSetup('S3', 'A', 2);
        AddSetup('S4', '100', 0);
        AddSetup('S5', '', 1);
        AddSetup('S6', 'B 1', 2);
        for i := 1 to 8 do begin
            Row.Init();
            Row.Id := i;
            Row."Type Code" := 'S' + Format(((i * 5) mod 7));
            Row.Grp := i mod 3;
            Row.Insert();
        end;
    end;

    local procedure AddSetup(Code: Code[10]; Val: Code[20]; Opt: Integer)
    var
        Setup: Record "REC FFV Key Setup";
    begin
        Setup.Init();
        Setup."Code" := Code;
        Setup.Val := Val;
        Setup.Opt := Opt;
        Setup.Insert();
    end;

    local procedure KeyOrder(var Row: Record "REC FFV Key Row") Result: Text
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ' ';
            until Row.Next() = 0;
    end;

    // Row order by a key whose first field is a lookup FlowField of a Code field and of an Option field.
    [Test]
    procedure LookupFirstKey_CodeAndOption_RowOrder()
    var
        Row: Record "REC FFV Key Row";
    begin
        Clear(Observer);
        SeedKeys();
        Observer.Observe('type codes', KeyOrder(Row));
        Row.SetCurrentKey(LkCode, Grp);
        Observer.Observe('code all', KeyOrder(Row));
        Row.Ascending(false);
        Observer.Observe('code descending', KeyOrder(Row));
        Row.Ascending(true);
        Row.SetRange(Grp, 1, 2);
        Observer.Observe('code grp 1..2', KeyOrder(Row));
        Clear(Row);
        Row.SetCurrentKey(LkOpt, Grp);
        Observer.Observe('opt all', KeyOrder(Row));
        Row.Ascending(false);
        Observer.Observe('opt descending', KeyOrder(Row));
        Row.Ascending(true);
        Row.SetRange(Grp, 1, 2);
        Observer.Observe('opt grp 1..2', KeyOrder(Row));
        Observer.Expect('type codes', '1 2 3 4 5 6 7 8 ');
        Observer.Expect('code all', '1 7 8 3 5 6 2 4 ');
        Observer.Expect('code descending', '4 2 6 5 3 8 7 1 ');
        Observer.Expect('code grp 1..2', '1 7 8 5 2 4 ');
        Observer.Expect('opt all', '7 5 6 1 8 4 2 3 ');
        Observer.Expect('opt descending', '3 2 4 8 1 6 5 7 ');
        Observer.Expect('opt grp 1..2', '7 5 1 8 4 2 ');
        Observer.Verify();
    end;



}
