// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72103 "LT P121 Rpt LabelLocked"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
            column(Id; Id) { }
        }
    }

    labels
    {
        LockedLbl = 'locked text', Locked = true;
        PlainLbl = 'plain text';
    }
}
