// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); permission sets 91557-91559 and test codeunit 91560 (own)
// Probe (al-runner issue 6445, writer Y12): the 20-character name limit applies only to a permission set with Assignable = true
// (tests/must-not-compile/cases/2131-permissionset-name-21-characters.al). With Assignable = false, or with no Assignable property, a name of
// 21 to 30 characters compiles (AL 30.0.42.60748, runtimes 16.1 to 18.0); 31 characters do not (cases 2333, 2334). The test reads the
// rows the platform keeps for these sets.

permissionset 91557 "LT Y12 PS NotAssign21"
{
    Assignable = false;
    Caption = 'Y12 not assignable 21', Locked = true;
}

permissionset 91558 "LT Y12 PS NoProp 21ch"
{
    Caption = 'Y12 no Assignable 21', Locked = true;
}

permissionset 91559 "LT Y12 PS Not Assignable 30 ch"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Y12 not assignable 30', Locked = true;
}

codeunit 91560 "LT Y12 PermSet Name Length"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y12_NonAssignable_LongNames_Compile_AndAreListed()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        MetadataPermissionSet.SetFilter("Role ID", 'LT Y12 PS*');
        if MetadataPermissionSet.FindSet() then
            repeat
                Rows += '[' + MetadataPermissionSet."Role ID" + '|' + MetadataPermissionSet.Name + '|' + Format(MetadataPermissionSet.Assignable) + ']';
            until MetadataPermissionSet.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;
}
