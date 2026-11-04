// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72186 "LT P121 Prof Card"
{
    PageType = Card;
    SourceTable = "LT P121 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

pagecustomization "LT P121 Page Cust" customizes "LT P121 Prof Card"
{
    layout
    {
        modify(Txt)
        {
            Visible = false;
        }
    }
}

page 72187 "LT P121 Prof RC"
{
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
        }
    }
}

profile "LT P121 Profile"
{
    Description = 'LT P121 profile';
    RoleCenter = "LT P121 Prof RC";
    Customizations = "LT P121 Page Cust";
}
