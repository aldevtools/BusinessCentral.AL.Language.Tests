// The source profile for TestCopyProfile.al. Its values are declared here so the copy can be
// asserted against them instead of against Base Application demo content.
//
// Deliberately NOT Enabled: an enabled tenant profile is a role-centre candidate, and creating
// one makes the platform re-resolve the session's default role centre through Azure AD, which a
// test container has no directory for (TestAllProfileTable.al hit the same thing). The claim
// under test is the copy, not role-centre selection.
profile "ALT Profile Copy Source"
{
    Caption = 'ALT Profile Copy Source';
    ProfileDescription = 'Source fixture for Conf./Personalization Mgt. CopyProfile.';
    Enabled = false;
    RoleCenter = "ALT Profile RC SameApp";
}
