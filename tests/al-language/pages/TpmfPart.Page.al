// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TPMF Line (60415)
//
// The subpage for the modal-close part-flush suite: an ordinary editable ListPart over its
// own source table, declaring NO SubPageLink, so its rowset does not depend on the host
// record. A test that had to establish a parent record first could not tell a missing part
// flush apart from a SubPageLink that never resolved.

page 60417 "TPMF Part"
{
    PageType = ListPart;
    SourceTable = "TPMF Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadNo; Rec."Head No.")
                {
                    ApplicationArea = All;
                    Caption = 'Head No.';
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
            }
        }
    }
}
