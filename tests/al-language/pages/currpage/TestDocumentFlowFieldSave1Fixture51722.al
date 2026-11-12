// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
pageextension 51722 "Action Header Ext" extends "Action Header Document"
{
    actions
    {
        addlast(Processing)
        {
            action(CalculateAndWrite)
            {
                trigger OnAction()
                begin
                    Rec.CalcFields("Linked Code");
                    Rec.TestField("Linked Code", 'RELATED');
                    WriteCommittedDescription(Rec.Id);
                end;
            }
        }
    }

    local procedure WriteCommittedDescription(Id: Integer)
    var
        Header: Record "Action Header Row";
    begin
        Header.Get(Id);
        Header.Description := 'Written by action';
        Header.Modify(true);
        Commit();
    end;
}
