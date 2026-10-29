// Cross-app fixture C: a second page extension of cross-app fixture B's page 61110. It reads and assigns the protected variables that fixture B's
// page extension 61119 declares (AL Runner issue 6159). Test: tests/al-language/pageext/lt-ue-pageext-leads/UeCrossAppTests.al.
pageextension 61129 "LT UE XC PV Top Ext" extends "LT BW XB Master Card"
{
    layout
    {
        addlast(Content)
        {
            field(UeTopField; UeTrace)
            {
                Caption = 'UE Top';
                ApplicationArea = All;
            }
            field(UeTopShown; UeMidText)
            {
                Caption = 'UE Top shown';
                ApplicationArea = All;
                Visible = UeShow;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UeTrace += 'top(' + Format(UeShow) + ')';
        UeShow := not UeShow;
    end;
}
