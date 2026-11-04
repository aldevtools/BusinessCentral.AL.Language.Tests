// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 70203 "LT P115 Item"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; Flag; Boolean) { }
        field(5; Grp; Code[10]) { TableRelation = "LT P115 Grp".Code; }
        field(6; Note; Text[50]) { }
        field(7; Other; Text[50]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 70204 "LT P115 Grp"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Descr; Text[50]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 70209 "LT P115 State"
{
    SingleInstance = true;

    var
        PageEdit: Boolean;
        Entries: Text;

    procedure SetPageEditable(Value: Boolean)
    begin
        PageEdit := Value;
    end;

    procedure GetPageEditable(): Boolean
    begin
        exit(PageEdit);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 70226 "LT P115 Runner"
{
    trigger OnRun()
    var
        State: Codeunit "LT P115 State";
    begin
        State.Add('runner ran');
    end;
}

page 70205 "LT P115 Grp List"
{
    PageType = List;
    SourceTable = "LT P115 Grp";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
