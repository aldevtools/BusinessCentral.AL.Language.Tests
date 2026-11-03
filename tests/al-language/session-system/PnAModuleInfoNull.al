// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getmoduleinfo-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: ModuleInfo: GetModuleInfo of the null app id is true
// Facts: NavApp.GetModuleInfo of the null app id: result, Name, Publisher, Id (no versions are asserted)
// BC versions: 29 (27 and 28 by CI)

codeunit 70121 "LT PnA ModuleInfo Null"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NullAppId()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        Empty: Guid;
    begin
        Observer.Observe('result', Format(NavApp.GetModuleInfo(Empty, Info)));
        Observer.Observe('name', Info.Name());
        Observer.Observe('publisher', Info.Publisher());
        Observer.Observe('id-is-null', Format(IsNullGuid(Info.Id())));
        Observer.Observe('app-version-major-positive', Format(Info.AppVersion().Major() > 0));
        Observer.Observe('data-version-major-positive', Format(Info.DataVersion().Major() > 0));
        Observer.Observe('data-version-minor-nonnegative', Format(Info.DataVersion().Minor() >= 0));
        Observer.Observe('dependencies', Format(Info.Dependencies().Count()));
        Observer.Observe('package-id-is-null', Format(IsNullGuid(Info.PackageId())));
        Observer.Expect('result', 'Yes');
        Observer.Expect('name', 'W1');
        Observer.Expect('publisher', 'Microsoft');
        Observer.Expect('id-is-null', 'Yes');
        Observer.Expect('app-version-major-positive', 'Yes');
        Observer.Expect('data-version-major-positive', 'Yes');
        Observer.Expect('data-version-minor-nonnegative', 'Yes');
        Observer.Expect('dependencies', '0');
        Observer.Expect('package-id-is-null', 'Yes');
        Observer.Verify();
    end;
}
