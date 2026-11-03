// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72463 "LT P194 Gen"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P194 Log";
            begin
                Log.Add('Validate Name');
            end;
        }
        field(3; Amount; Decimal) { }
        field(4; Note; Text[100]) { }
        field(5; Data; Blob) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 72464 "LT P194 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure GetAll(): Text
    begin
        exit(Entries);
    end;

    procedure Wipe()
    begin
        Entries := '';
    end;
}
