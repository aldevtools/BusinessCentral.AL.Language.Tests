// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: XApp A report and trace
// BC versions: 27.5+

// local object: the dependency relationship between owning and consuming extensions is under test.
reportextension 61186 "RPT Rising Adds Rows" extends "RPT Dependency Rising Base"
{
    dataset
    {
        addlast(BaseRow)
        {
            dataitem(AddedRow; Integer)
            {
                DataItemTableView = where(Number = const(2));
                dataitem(FooterRow; Integer)
                {
                    DataItemTableView = where(Number = const(3));

                    trigger OnAfterGetRecord()
                    var
                        Trace: Codeunit "RPT Dependency Trace";
                    begin
                        Trace.Push('footer');
                    end;
                }
                column(AddedNo; Number) { }

                trigger OnAfterGetRecord()
                var
                    Trace: Codeunit "RPT Dependency Trace";
                begin
                    Trace.Push('owner=' + Format(Number));
                end;
            }
        }
    }
}
