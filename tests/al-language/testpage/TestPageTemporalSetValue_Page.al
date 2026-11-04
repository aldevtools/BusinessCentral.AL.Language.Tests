// Two shapes of temporal control, because a TestPage reaches them by different routes: a
// control bound to a source-table field, and a control bound to a page variable.
page 60668 "ALT Temporal Card"
{
    PageType = Card;
    SourceTable = "ALT Temporal Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Temporal)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("The Date"; Rec."The Date") { ApplicationArea = All; }
                field("The DateTime"; Rec."The DateTime") { ApplicationArea = All; }
                field("The Time"; Rec."The Time") { ApplicationArea = All; }
            }
        }
    }
}

// No SourceTable: every control here is bound to a page variable. Each temporal control's
// OnValidate writes the value it received into GEcho in an unambiguous, culture-independent
// spelling, so a test can assert what the page variable actually holds without depending on
// how the control renders it back.
page 60669 "ALT Temporal Globals"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Temporal)
            {
                field(GDate; GDate)
                {
                    ApplicationArea = All;
                    Caption = 'GDate';
                    trigger OnValidate()
                    begin
                        GEcho := Format(GDate, 0, '<Year4>-<Month,2>-<Day,2>');
                    end;
                }
                field(GDateTime; GDateTime)
                {
                    ApplicationArea = All;
                    Caption = 'GDateTime';
                    trigger OnValidate()
                    begin
                        GEcho := Format(GDateTime, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>');
                    end;
                }
                field(GTime; GTime)
                {
                    ApplicationArea = All;
                    Caption = 'GTime';
                    trigger OnValidate()
                    begin
                        GEcho := Format(GTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
                    end;
                }
                field(GEcho; GEcho) { ApplicationArea = All; Caption = 'GEcho'; }
            }
        }
    }

    var
        GDate: Date;
        GDateTime: DateTime;
        GTime: Time;
        GEcho: Text;
}
