// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51769 "Three Part Probe Part"
{
    PageType = ListPart;
    SourceTable = "Three Part Probe Row";
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Payload; Rec.Payload)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Error('Repro part validation failed.');
                    end;
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Codeunit "Three Part Probe Trace";
    begin
        Trace.Add('Part', CloseAction);
        exit(true);
    end;
}
