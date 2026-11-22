// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51738 "Probe Packing Document"
{
    PageType = Document;
    SourceTable = "Probe Packing State";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(PackageCode; Rec.PackageCode) { ApplicationArea = All; }
                field(Scan; ScanValue)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.LastScannedPackage := Rec.PackageCode;
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            part(PackageActions; "Probe Package Actions")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
                UpdatePropagation = Both;
            }
        }
    }

    var
        ScanValue: Text[20];
}
