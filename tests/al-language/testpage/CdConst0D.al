// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: LT CD Row (84280) from CdObjects.al
// Facts: item 58 of corpus issue #667 (Microsoft AL issue 3737): a page whose SourceTableView is where(D = const(0D)) compiles and the app installs; which rows the page shows.
// BC versions: all (CI)

page 84299 "LT CD Const0D List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Const0D List';
    SourceTableView = where(D = const(0D));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

// Writer SH, al-runner issues 5957 and 5958: SourceTableView where(D = filter('')) and where(D = filter(<> '')) on a Date field.
page 89429 "LT SH Blank Date List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'SH Blank Date List';
    SourceTableView = where(D = filter(''));
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89430 "LT SH NotBlank Date List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'SH NotBlank Date List';
    SourceTableView = where(D = filter(<> ''));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}
