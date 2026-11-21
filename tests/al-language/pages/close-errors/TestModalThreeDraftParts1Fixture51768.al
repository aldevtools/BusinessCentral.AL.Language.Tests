// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51768 "Three Part Probe Document"
{
    PageType = Document;
    SourceTable = "Three Part Probe Row";
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            part(Lines; "Three Part Probe Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
            part(OtherLines; "Three Part Probe Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
            part(ThirdLines; "Three Part Probe Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Codeunit "Three Part Probe Trace";
    begin
        Trace.Add('Document', CloseAction);
        exit(true);
    end;
}
