// @expect AL0783 | A page extension is only allowed to access control add-ins defined within its own extension scope.
// A page extension action calls a procedure of a usercontrol that the base page declares (CurrPage.<base usercontrol>.<procedure>). A usercontrol
// the page extension adds itself can be called: tests/al-language/lt-ac/ACControlAddIn.al (TZ tests).
controladdin "MNC TZ Addin 2261"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
}

page 50000 "MNC TZ Page 2261"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Ctl; "MNC TZ Addin 2261")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 50001 "MNC TZ Page Ext 2261" extends "MNC TZ Page 2261"
{
    actions
    {
        addlast(Processing)
        {
            action(CallBase)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Ctl.Say('from ext');
                end;
            }
        }
    }
}
