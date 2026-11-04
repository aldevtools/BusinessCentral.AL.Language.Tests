// Fixture for TestPageCaptionClass.al — see that file's header.
page 60981 "TPCC Card"
{
    PageType = Card;
    SourceTable = "TPCC Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            // Page-variable controls whose CaptionClass is built from a page global at runtime,
            // the shape Base Application matrix pages use for their column captions.
            field(Column1; CellData[1])
            {
                ApplicationArea = All;
                CaptionClass = '3,' + ColumnCaption[1];
            }
            field(Column2; CellData[2])
            {
                ApplicationArea = All;
                CaptionClass = '3,' + ColumnCaption[2];
            }
            // Rec-bound control with a constant CaptionClass; the source field has its own Caption.
            field(ConstantClass; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = '3,Fixed Text';
            }
            // Rec-bound control with no CaptionClass: the source field's Caption.
            field(NoClass; Rec.Quantity)
            {
                ApplicationArea = All;
            }
            // Both a declared Caption and a CaptionClass.
            field(CaptionAndClass; Rec.Description)
            {
                ApplicationArea = All;
                Caption = 'Declared Control Caption';
                CaptionClass = '3,Class Caption';
            }
            // A CaptionClass no resolver claims: an area nobody resolves, and no area at all.
            field(UnknownArea; Rec.Remark)
            {
                ApplicationArea = All;
                CaptionClass = 'ZZ,Unknown Area';
            }
            field(NoComma; CellData[3])
            {
                ApplicationArea = All;
                CaptionClass = 'No Comma Here';
            }
        }
    }

    trigger OnOpenPage()
    begin
        ColumnCaption[1] := 'Sep 2026';
        ColumnCaption[2] := 'Oct 2026';
    end;

    var
        CellData: array[3] of Decimal;
        ColumnCaption: array[2] of Text[80];
}
