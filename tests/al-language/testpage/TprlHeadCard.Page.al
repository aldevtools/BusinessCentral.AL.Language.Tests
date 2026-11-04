// Fixture host for TestPageActionRunPageLink.al. Five actions over the SAME two targets, so
// the only thing that varies between them is the RunPageLink declaration itself:
//   LinesUnfiltered   RunObject only                            -- the control
//   LinesByField      RunPageLink = "Head No." = field("No.")   -- reads the HOST's row
//   LinesByConst      RunPageLink = "Head No." = const('H1')    -- ignores the host's row
//   LinesByFilter     RunPageLink = "Head No." = filter('H1'|'H3')
//   HeadsByFieldOnRec RunPageLink = "No." = field("No."), RunPageOnRec = true
//
// The const and filter arms deliberately select a rowset the host is NOT sitting on, so an
// implementation that answered every link kind with "the host's current row" is caught.
page 60466 "TPRL Head Card"
{
    PageType = Card;
    SourceTable = "TPRL Head";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LinesUnfiltered)
            {
                ApplicationArea = All;
                Caption = 'Lines Unfiltered';
                RunObject = Page "TPRL Line List";
            }

            action(LinesByField)
            {
                ApplicationArea = All;
                Caption = 'Lines By Field';
                RunObject = Page "TPRL Line List";
                RunPageLink = "Head No." = field("No.");
            }

            action(LinesByConst)
            {
                ApplicationArea = All;
                Caption = 'Lines By Const';
                RunObject = Page "TPRL Line List";
                RunPageLink = "Head No." = const('H1');
            }

            action(LinesByFilter)
            {
                ApplicationArea = All;
                Caption = 'Lines By Filter';
                RunObject = Page "TPRL Line List";
                RunPageLink = "Head No." = filter('H1' | 'H3');
            }

            action(HeadsByFieldOnRec)
            {
                ApplicationArea = All;
                Caption = 'Heads By Field On Rec';
                RunObject = Page "TPRL Head List";
                RunPageLink = "No." = field("No.");
                RunPageOnRec = true;
            }
        }
    }
}
