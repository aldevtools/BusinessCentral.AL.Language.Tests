// A profile whose RoleCenter page is declared in a DEPENDENCY app (AL Internals
// Test Fixture -- see ALTProfileRoleCenterDep.Page.al). This is the shape that
// actually broke AL Runner's compile pipeline (issue #2238 in
// StefanMaron/BusinessCentral.AL.Runner): resolving a profile's RoleCenter
// reference to a page declared ONLY in a dependency module requires cross-module
// symbol lookup, and the runner's own resolution for that lookup differed from a
// service tier's. A profile whose page lives in the same app (see
// ALTProfileSameApp.Profile.al) would have passed even before that fix. See
// TestProfileDepAppCoexistence.al for the claim actually under test here.
profile "ALT Profile DepApp"
{
    Caption = 'ALT Profile DepApp';
    Description = 'Coverage fixture: RoleCenter page lives in a dependency app.';
    Enabled = true;
    RoleCenter = "ALT Profile RC DepApp";
}
