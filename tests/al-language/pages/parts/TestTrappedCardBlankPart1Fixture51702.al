// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51702 "Draft Probe Detail Part"
{
    PageType = ListPart;
    SourceTable = "Draft Probe Detail";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Trace: Codeunit "Draft Probe Trace";
    begin
        Trace.Add('part.new');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Trace: Codeunit "Draft Probe Trace";
    begin
        Trace.Add('part.current');
    end;
}
