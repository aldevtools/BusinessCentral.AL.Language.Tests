// Migrated from AL Runner tests/runner-extras/testpage-setrecord (TsrSrc.al).
/// <summary>
/// The caller-side shape this suite is about: the AL has already found the row it wants and
/// hands it to the page, rather than letting the page find one. Two actions picking two
/// different rows, so a runner that simply opened on the first row of the table cannot satisfy
/// both.
/// </summary>
page 60847 "TSR Host"
{
    PageType = Card;
    SourceTable = "TSR Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenB)
            {
                ApplicationArea = All;
                Caption = 'Open B';

                trigger OnAction()
                var
                    Target: Record "TSR Row";
                    Card: Page "TSR Card";
                begin
                    Target.Get('B');
                    Card.SetRecord(Target);
                    Card.RunModal();
                end;
            }

            action(OpenC)
            {
                ApplicationArea = All;
                Caption = 'Open C';

                trigger OnAction()
                var
                    Target: Record "TSR Row";
                    Card: Page "TSR Card";
                begin
                    Target.Get('C');
                    Card.SetRecord(Target);
                    Card.RunModal();
                end;
            }
        }
    }
}
