// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51745 "Probe Auto Split Document"
{
    PageType = Document;
    SourceTable = "Probe Host";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            part(Lines; "Probe Auto Split Lines")
            {
                ApplicationArea = All;
                SubPageLink = ParentId = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Lines.Page.Bind(HostShadow);
    end;

    trigger OnClosePage()
    begin
        CurrPage.Lines.Page.SaveRecord();
        CurrPage.Lines.Page.Unbind();
    end;

    procedure Initialize(var Shared: Record "Probe Shadow" temporary)
    begin
        HostShadow.Copy(Shared, true);
    end;

    var
        HostShadow: Record "Probe Shadow" temporary;
}
