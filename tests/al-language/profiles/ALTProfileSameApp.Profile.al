// A profile whose RoleCenter page is declared in the SAME app. This binds without
// trouble on any BC version -- it is the baseline case, not the interesting one.
// See TestProfileSameAppCoexistence.al for the actual claim under test: that this
// profile's presence does not stop the objects declared alongside it from
// compiling and running. Compare ALTProfileDepApp.Profile.al, whose RoleCenter
// page lives in a DEPENDENCY app instead -- the shape that actually broke a real
// compiler (see that file's header).
profile "ALT Profile SameApp"
{
    Caption = 'ALT Profile SameApp';
    Description = 'Coverage fixture: RoleCenter page lives in the same app.';
    Enabled = true;
    RoleCenter = "ALT Profile RC SameApp";
}
