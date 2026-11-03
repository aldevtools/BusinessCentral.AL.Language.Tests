// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); layout file ./ProbeSaveAsDatasetLayout.rdl of the app root (only named, SaveAs Xml does not render it)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73763 "LT P165 SaveAs Parent"
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

table 73764 "LT P165 SaveAs Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 73765 "LT P165 SaveAs Identity"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(P; "LT P165 SaveAs Parent")
        {
            column(PNo; Id) { }
            column(PName; Name) { }

            dataitem(C; "LT P165 SaveAs Child")
            {
                DataItemLink = ParentId = field(Id);

                column(CNo; Id) { }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout_3.rdl';
            Caption = 'LT P165 layout';
        }
    }
}

