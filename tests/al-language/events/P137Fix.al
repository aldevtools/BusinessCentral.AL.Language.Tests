// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); shared by the other P137 files
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: fixtures only (tables, a SingleInstance log and mode holder)
// BC versions: 29 (27 and 28 by CI)

table 74415 "LT P137 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; "Parent Id"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

table 74416 "LT P137 Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74417 "LT P137 Ctl"
{
    SingleInstance = true;

    var
        LogText: Text;
        ModeText: Text;

    procedure Add(Entry: Text)
    begin
        LogText += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := LogText;
        LogText := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        ModeText := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(ModeText);
    end;

    procedure CutRunner(Stack: Text): Text
    var
        Position: Integer;
    begin
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            Stack := CopyStr(Stack, 1, Position - 1);
        exit(CopyStr(Stack, 1, 800));
    end;
}
