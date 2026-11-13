// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: XApp A report and trace
// BC versions: 27.5+

// local object: the dependency relationship between owning and consuming extensions is under test.
reportextension 61124 "RPT Dependency Uses Added Rows" extends "RPT Dependency Base"
{
    dataset
    {
        modify(AddedRow)
        {
            trigger OnAfterAfterGetRecord()
            var
                Trace: Codeunit "RPT Dependency Trace";
            begin
                Trace.Push('dependent=' + Format(AddedRow.Number));
            end;
        }
        add(AddedRow)
        {
            column(DependentNo; AddedRow.Number) { }
        }
        addbefore(FooterRow)
        {
            dataitem(BeforeFooter; Integer)
            {
                DataItemTableView = where(Number = const(4));

                trigger OnAfterGetRecord()
                var
                    Trace: Codeunit "RPT Dependency Trace";
                begin
                    Trace.Push('before');
                end;
            }
        }
        addafter(FooterRow)
        {
            dataitem(AfterFooter; Integer)
            {
                DataItemLinkReference = AddedRow;
                DataItemLink = Number = field(Number);

                trigger OnAfterGetRecord()
                var
                    Trace: Codeunit "RPT Dependency Trace";
                begin
                    Trace.Push('after=' + Format(Number));
                end;
            }
        }
    }
}
