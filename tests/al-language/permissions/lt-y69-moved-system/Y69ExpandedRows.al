// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y69PermSets.al (sets 93700-93708, 93720-93731, extensions 93707 and 93732, helper 93735).
// Probe (writer Y69, al-runner issues 6716 and 6717 by SShadowS): the Expanded Permission rows of the Y69 permission sets, which need no Permissions Mock
//   (so they run on the SaaS sandbox, a Windows server). 6716: which table a set that names a table BC 29 ships twice under one id (the Base Application's
//   ObsoleteState = Moved copy and the Business Foundation target) binds to: the row's object id; one row per table, also with the table grant and the
//   tabledata grant of the same name, through an included set, an excluded set and a permission set extension. 6717: the rows a named system grant
//   `system "<name>" = X` makes (object type System, the system object's id) and what the included and the excluded sets leave of them.
//   Row format: <object type ordinal>:<object id>:<R I M D X letters; lower case = indirect; - = none>.
// BC versions: 27, 28, 29
codeunit 93713 "LT Y69 Expanded Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y69 Helper";

    [Test]
    procedure Y69_MV_ExpandedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name', Helper.Expanded('LT Y69 MV NAME'));
        Observer.Observe('plain', Helper.Expanded('LT Y69 MV PLAIN'));
        Observer.Observe('all', Helper.Expanded('LT Y69 MV ALL'));
        Observer.Observe('outer', Helper.Expanded('LT Y69 MV OUTER'));
        Observer.Observe('excl', Helper.Expanded('LT Y69 MV EXCL'));
        Observer.Observe('ext_base', Helper.Expanded('LT Y69 MV EXT BASE'));
        Observer.Observe('indirect', Helper.Expanded('LT Y69 MV INDIRECT'));
        Observer.Finish();
    end;


    [Test]
    procedure Y69_SY_ExpandedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('basic', Helper.Expanded('LT Y69 SY BASIC'));
        Observer.Observe('outer', Helper.Expanded('LT Y69 SY OUTER'));
        Observer.Observe('many', Helper.Expanded('LT Y69 SY MANY'));
        Observer.Observe('only', Helper.Expanded('LT Y69 SY ONLY'));
        Observer.Observe('indirect', Helper.Expanded('LT Y69 SY INDIRECT'));
        Observer.Observe('wild', Helper.Expanded('LT Y69 SY WILD'));
        Observer.Observe('mid', Helper.Expanded('LT Y69 SY MID'));
        Observer.Observe('excl', Helper.Expanded('LT Y69 SY EXCL'));
        Observer.Observe('plain', Helper.Expanded('LT Y69 SY PLAIN'));
        Observer.Finish();
    end;
}
