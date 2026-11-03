// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: ALT TestPart Row (60341)
//
// The subpage driven by the TestPart surface suite: an ordinary editable ListPart over its
// own source table, with no SubPageLink, so nothing about its rowset depends on the host.
//
// It carries its OWN Caption ('Part Lines Caption'), deliberately different from both the
// host page's caption and the part control's caption on the host. TestPart.Caption() has to
// resolve to exactly one of those three, and the suite asserts which -- an assertion that
// would be vacuous if any two of them were spelled the same.

page 60342 "ALT TestPart Lines"
{
    PageType = ListPart;
    SourceTable = "ALT TestPart Row";
    Caption = 'Part Lines Caption';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                    Caption = 'Group';
                }
                field(LineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(Grade; Rec.Grade)
                {
                    ApplicationArea = All;
                    Caption = 'Grade';
                }
            }
        }
    }
}
