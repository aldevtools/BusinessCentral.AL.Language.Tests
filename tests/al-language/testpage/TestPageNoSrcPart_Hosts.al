// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page NoSrc CardPart (60800)
//
// The two host shapes for the no-SourceTable-PART suite. Both host the SAME CardPart
// (60800); they differ only in whether the HOST has a source table. Keeping both is what
// separates "a part with no source table works" from "a page with no source table works
// anywhere in the tree" — a change that only handled the all-record-less tree would pass
// the second host and fail the first.

page 60801 "Test Page NoSrc Part Bound"
{
    PageType = Card;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(RowNo; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                }
            }

            part(Info; "Test Page NoSrc CardPart")
            {
                ApplicationArea = All;
                Caption = 'Info';
            }
        }
    }
}

page 60802 "Test Page NoSrc Part NoSrc"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Mode; SelectedMode)
                {
                    ApplicationArea = All;
                    Caption = 'Mode';

                    trigger OnValidate()
                    begin
                        CurrPage.Info.Page.SetTag(SelectedMode);
                        CurrPage.Update(false);
                    end;
                }
            }

            part(Info; "Test Page NoSrc CardPart")
            {
                ApplicationArea = All;
                Caption = 'Info';
            }
        }
    }

    var
        SelectedMode: Text;
}
