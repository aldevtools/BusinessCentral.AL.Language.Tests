// @expect AL0378 | A page of type Role Center cannot have triggers. Remove all trigger implementations from this page.
// @expect AL0378 | A page of type Role Center cannot have triggers. Remove all trigger implementations from this page.
// A Role Center page cannot have triggers, so a Role Center has no page trigger to log (al-runner issue 7430). Its page trigger events
// still exist for subscribers: tests/al-language/events/page-events/NoSourcePageEvents.al.
page 50001 "MNC PNS Role Center"
{
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
        }
    }

    trigger OnOpenPage()
    begin
    end;

    trigger OnClosePage()
    begin
    end;
}
