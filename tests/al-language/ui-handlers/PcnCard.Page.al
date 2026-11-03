// Fixture for "PCN Tests" (60535). A card over "PCN Header" (60533) hosting "PCN Lines Part"
// (60534). No triggers and no declared actions, so nothing this page does of its own is in the
// way of what the platform does by itself.
//
// This host carries the OK arm and the no-built-in-Cancel refusal arm. It cannot carry a Cancel
// MEASUREMENT: "Test Page Modal" (60703) records, verified against real BC, that a plain
// Card-type modal has no client Cancel affordance and that TestPage.Cancel() answers "not found"
// on one even when the page declares an action named Cancel. "PCN Dialog" (60535) is the host
// the Cancel measurements run on.
page 60533 "PCN Card"
{
    PageType = Card;
    SourceTable = "PCN Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "PCN Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
