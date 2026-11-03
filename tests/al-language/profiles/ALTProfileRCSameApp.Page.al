// Minimal RoleCenter page used only as a binding target for the profile fixtures in
// this folder. The Role Center itself is not what's under test -- only that a
// codeunit compiled alongside a profile pointing at this page still compiles and
// runs. See ALTProfileSameApp.Profile.al and TestProfileSameAppCoexistence.al.
page 60904 "ALT Profile RC SameApp"
{
    PageType = RoleCenter;
    Caption = 'ALT Profile RC SameApp';

    layout
    {
        area(RoleCenter)
        {
        }
    }
}
