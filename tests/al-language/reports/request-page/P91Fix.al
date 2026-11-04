// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against BC 29 (observation only; the literals are measured later). Tag P91 (GitHub issue 91).
// BC versions: 29
// Fixtures used: Probe Observer (codeunit 69160); this file holds the tables 71591, 71592 and the helper codeunit 71593 (not a test codeunit)

table 71591 "LT P91 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71592 "LT P91 Store"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71593 "LT P91 Helper"
{
    procedure Seed()
    var
        Row: Record "LT P91 Row";
        Store: Record "LT P91 Store";
    begin
        Row.DeleteAll();
        Store.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Grp := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Grp := 1;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Grp := 2;
        Row.Name := 'three';
        Row.Insert();
        Row.Id := 4;
        Row.Grp := 2;
        Row.Name := 'four';
        Row.Insert();
    end;
}
