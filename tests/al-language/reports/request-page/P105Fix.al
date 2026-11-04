// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); this file holds the tables 72225, 72226 and the helper codeunit 72227 (not a test codeunit)

table 72225 "LT P105 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72226 "LT P105 Store"
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

codeunit 72227 "LT P105 Helper"
{
    procedure Seed()
    var
        Row: Record "LT P105 Row";
        Store: Record "LT P105 Store";
    begin
        Row.DeleteAll();
        Store.DeleteAll();
        Add(1, 1, 'one', 10.5);
        Add(2, 1, 'two', 20);
        Add(3, 2, 'three', 30.25);
        Add(4, 2, 'four', -5);
        Commit();
    end;

    procedure SeedEmpty()
    var
        Row: Record "LT P105 Row";
        Store: Record "LT P105 Store";
    begin
        Row.DeleteAll();
        Store.DeleteAll();
        Commit();
    end;

    local procedure Add(Id: Integer; Grp: Integer; Name: Text[30]; Amount: Decimal)
    var
        Row: Record "LT P105 Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Grp := Grp;
        Row.Name := Name;
        Row.Amount := Amount;
        Row.Insert();
    end;

    procedure ReadAll(var Store: Record "LT P105 Store"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Store.CalcFields(Data);
        if not Store.Data.HasValue() then
            exit('<no value>');
        Store.Data.CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;
}
