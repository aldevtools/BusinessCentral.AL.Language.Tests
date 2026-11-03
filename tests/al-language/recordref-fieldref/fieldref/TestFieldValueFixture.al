// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: shared fixture for the TestField value-type probes (issues 589, 590, 591)
// BC versions: 27 and later (values by CI matrix)

enum 68080 "LT R Color"
{
    Extensible = true;

    value(0; Red) { Caption = 'Red Cap'; }
    value(1; Green) { Caption = 'Green Cap'; }
    value(2; Blue) { Caption = 'Blue Cap'; }
}

table 67900 "LT R Row"
{
    DataClassification = SystemMetadata;
    Caption = 'R Row Caption';

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code Cap'; }
        field(2; "Big Int"; BigInteger) { Caption = 'Big Cap'; }
        field(3; Bool; Boolean) { Caption = 'Bool Cap'; }
        field(4; Dec; Decimal) { Caption = 'Dec Cap'; }
        field(5; Dt; Date) { Caption = 'Dt Cap'; }
        field(6; Dtm; DateTime) { Caption = 'Dtm Cap'; }
        field(7; Gd; Guid) { Caption = 'Gd Cap'; }
        field(8; En; Enum "LT R Color") { Caption = 'En Cap'; }
        field(9; Txt; Text[20]) { Caption = 'Txt Cap'; }
        field(10; Cd; Code[10]) { Caption = 'Cd Cap'; }
        field(11; Num; Integer) { Caption = 'Num Cap'; }
        field(12; Ch; Text[1]) { Caption = 'Ch Cap'; }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 67901 "LT R Helper"
{
    procedure Seed()
    var
        Row: Record "LT R Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'K1';
        Row."Big Int" := 5000000000L;
        Row.Bool := true;
        Row.Dec := 12.5;
        Row.Dt := 20240131D;
        Row.Dtm := CreateDateTime(20240131D, 123456T);
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        Row.En := Row.En::Green;
        Row.Txt := 'Hello';
        Row.Cd := 'ABC';
        Row.Num := 5;
        Row.Ch := 'A';
        Row.Insert();
    end;
}
