// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 27+ (tested by the corpus CI matrix)
// Facts: objects shared by the "LT AA" page control probes (page fields, labels, parts, system parts, views, actions, repeaters).

table 76500 "LT AA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'Alpha,Beta,Gamma';
        }
        field(5; Dt; DateTime) { }
        field(6; Rel; Code[20]) { TableRelation = "LT AA Row"; }
        field(7; Lvl; Integer) { }
        field(8; Lower; Text[30]) { CharAllowed = 'az'; }
        field(9; "When"; Text[30]) { }
        field(10; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 76501 "LT AA Target Card"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

page 76507 "LT AA Part List"
{
    PageType = ListPart;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }
}

codeunit 76520 "LT AA Counter"
{
    SingleInstance = true;

    var
        HostLoads: Integer;

    procedure Reset()
    begin
        HostLoads := 0;
    end;

    procedure HostLoaded()
    begin
        HostLoads += 1;
    end;

    procedure GetHostLoads(): Integer
    begin
        exit(HostLoads);
    end;
}
