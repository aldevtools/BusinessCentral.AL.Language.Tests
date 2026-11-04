// Fixture for "PCN Tests" (60535). The same header and part as "PCN Card" (60533), on a
// StandardDialog instead of a Card. Two page types, because whether a page has a built-in Cancel
// at all is a property of the chrome its builder puts on the form and the types do not agree
// ("TBA Tests" (60338) measures four that differ).
//
// This is the host the Cancel measurements run on, because a StandardDialog is the type already
// shown to offer a built-in Cancel: page 60703 "Test Page Modal" is one, and codeunits 60706
// "Test Page Modal Handler Tests" and 60717 "Test Page Modal Handler Static" invoke its
// Cancel(). That same page records the other half -- a plain Card-type modal has none.
page 60535 "PCN Dialog"
{
    PageType = StandardDialog;
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
