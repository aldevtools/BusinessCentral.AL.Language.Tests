// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-directive
// Scope: in-scope
// Fixtures used: none (read by P163AllObjNamespace.al; a file with a namespace cannot name AllObj, so the test is in a second file)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.

namespace P163Probe.Names;

table 73191 "LT P163 NS Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73192 "LT P163 NS Codeunit"
{
    procedure Nothing()
    begin
    end;
}

page 73194 "LT P163 NS Page"
{
    PageType = Card;
    SourceTable = "LT P163 NS Table";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}
