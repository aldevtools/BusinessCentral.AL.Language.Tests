// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: virtual Integer table
// BC versions: 27.5+

// local object: a dependency app must own the base report.
report 61134 "RPT Dependency Base"
{
    DefaultRenderingLayout = Rdlc;
    UseRequestPage = false;

    dataset
    {
        dataitem(BaseRow; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(BaseNo; Number) { }
        }
    }
    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = 'DependencyLayout.rdl';
        }
    }
}
