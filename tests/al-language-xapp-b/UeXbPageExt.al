// Cross-app fixture B: a page extension of its own page 61110 that declares protected variables. A page extension of cross-app fixture C
// (UeXcPageExt.al) reads and assigns them (AL Runner issue 6159). Test: tests/al-language/pageext/lt-ue-pageext-leads/UeCrossAppTests.al.
pageextension 61119 "LT UE XB PV Mid Ext" extends "LT BW XB Master Card"
{
    layout
    {
        addlast(Content)
        {
            field(UeMidField; UeMidText)
            {
                Caption = 'UE Mid';
                ApplicationArea = All;
                Visible = UeShow;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UeTrace += 'mid(' + Format(UeShow) + ')';
        UeMidText := 'from B';
        UeShow := true;
    end;

    protected var
        UeShow: Boolean;
        UeTrace: Text;
        UeMidText: Text;
}
