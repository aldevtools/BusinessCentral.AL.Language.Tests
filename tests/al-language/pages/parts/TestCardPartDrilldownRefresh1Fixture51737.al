// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51737 "Probe Package Actions"
{
    PageType = CardPart;
    SourceTable = "Probe Packing State";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            cuegroup(Commands)
            {
                field(NewPackage; Count)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Header: Record "Probe Packing State";
                    begin
                        Rec.FilterGroup(4);
                        Header.Get(Rec.GetRangeMax(Id));
                        Rec.FilterGroup(0);
                        Header.PackageCode := 'SECOND';
                        Header.Modify(true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Count: Integer;
}
