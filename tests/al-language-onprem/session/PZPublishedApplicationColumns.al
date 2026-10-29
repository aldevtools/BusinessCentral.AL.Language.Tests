// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Published Application is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61262
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions are checked by the CI matrix.
//
// Published Application FlowFields and the Description Blob of well-known apps: the app of this test run, Base Application, System Application and Application all read "Tenant Visible" Yes,
// Installed Yes, "PerTenant Or Installed" Yes and a Description with a value. The Description of this app is the description text of its app.json (it starts "Ground-up test suite covering the in-sco").
// Not measured: an app that is published but not installed (the test container has none), and the platform System app (no row under the id 8874ed3a-0643-4247-9ced-7a7002f7135d).
// BC versions: 29.0
codeunit 61262 "PZ Published App Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(AppId: Text): Text
    var
        App: Record "Published Application";
        Id: Guid;
        Size: Integer;
    begin
        Evaluate(Id, AppId);
        App.SetRange(ID, Id);
        if not App.FindFirst() then
            exit('no row');
        App.CalcFields("Tenant Visible", Installed, "PerTenant Or Installed", Description);
        exit('tenant visible=' + Format(App."Tenant Visible") + ' installed=' + Format(App.Installed) + ' per tenant or installed=' + Format(App."PerTenant Or Installed") + ' description has value=' + Format(App.Description.HasValue()));
    end;

    local procedure DescriptionStart(AppId: Text): Text
    var
        App: Record "Published Application";
        Id: Guid;
        InS: InStream;
        Text: Text;
    begin
        Evaluate(Id, AppId);
        App.SetRange(ID, Id);
        App.FindFirst();
        App.CalcFields(Description);
        App.Description.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Text, 40);
        exit('[' + Text + ']');
    end;

    [Test]
    procedure TenantVisible_Installed_AndDescription_OfWellKnownApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('this app', Describe('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Observe('base application', Describe('437dbf0e-84ff-417a-965d-ed2bb9650972'));
        Observer.Observe('system application', Describe('63ca2fa4-4f03-4f2b-a480-172fef340d3f'));
        Observer.Observe('application', Describe('c1335042-3002-4257-bf8a-75c898ccb1b8'));
        Observer.Observe('this app description text', DescriptionStart('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Expect('this app', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('base application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('system application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('application', 'tenant visible=Yes installed=Yes per tenant or installed=Yes description has value=Yes');
        Observer.Expect('this app description text', '[Ground-up test suite covering the in-sco]');
        Observer.Verify();
    end;

    // "Tenant ID" (field 12) of the corpus apps and of Microsoft's apps (writer BX, 2026-10-19; CI runs 39236990456, 39237024989,
    // 39237057632 on BC 27.5, 28.5, 29.0, same values on all three). Microsoft code only filters it with '' | TenantId(), which a
    // blank also passes. The corpus apps carry TenantId() ('default'): they are published through the dev endpoint, which publishes
    // a per-tenant app. Microsoft's apps are global and carry a blank. Like "Runtime Package ID" (see TestPublishedApplicationSysTable),
    // the corpus apps' value may depend on the publish route; it is queued for the Windows check.
    local procedure TenantIdOf(AppId: Guid): Text
    var
        App: Record "Published Application";
    begin
        App.SetRange(ID, AppId);
        if not App.FindFirst() then
            exit('no row');
        exit('[' + App."Tenant ID" + '] rows=' + Format(App.Count()));
    end;

    [Test]
    procedure TenantId_OfCorpusAndMicrosoftApps()
    var
        App: Record "Published Application";
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
        Id: Guid;
        NonBlank: Integer;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Observer.Observe('TenantId()', TenantId());
        Observer.Observe('this onprem app', TenantIdOf(ThisModule.Id()));
        Evaluate(Id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
        Observer.Observe('cloud coverage app', TenantIdOf(Id));
        Evaluate(Id, '437dbf0e-84ff-417a-965d-ed2bb9650972');
        Observer.Observe('base application', TenantIdOf(Id));
        Evaluate(Id, '63ca2fa4-4f03-4f2b-a480-172fef340d3f');
        Observer.Observe('system application', TenantIdOf(Id));
        // How many apps carry a tenant id depends on how many corpus apps the leg publishes (8 on 27.5, 6 on 28.5 and 29.0),
        // so only the relation is asserted: every non-blank tenant id is TenantId().
        App.SetFilter("Tenant ID", '<>%1', '');
        NonBlank := App.Count();
        Observer.Observe('some rows carry a tenant id', Format(NonBlank > 0));
        App.SetRange("Tenant ID", TenantId());
        Observer.Observe('every non-blank tenant id is TenantId()', Format(App.Count() = NonBlank));
        App.SetFilter("Tenant ID", '%1|%2', '', TenantId());
        Observer.Observe('rows passing blank or TenantId() equals all rows', Format(App.Count() = AllRows()));
        Observer.Expect('TenantId()', 'default');
        Observer.Expect('this onprem app', '[default] rows=1');
        Observer.Expect('cloud coverage app', '[default] rows=1');
        Observer.Expect('base application', '[] rows=1');
        Observer.Expect('system application', '[] rows=1');
        Observer.Expect('some rows carry a tenant id', 'Yes');
        Observer.Expect('every non-blank tenant id is TenantId()', 'Yes');
        Observer.Expect('rows passing blank or TenantId() equals all rows', 'Yes');
        Observer.Verify();
    end;

    local procedure AllRows(): Integer
    var
        App: Record "Published Application";
    begin
        exit(App.Count());
    end;

    // Outside issue 6148 (writer UG, 2026-10-29): Microsoft's Guided Experience Impl. (System Application) reads the Logo (a Media field, column 20) of the
    // Published Application row of an app: SetRange(ID, AppId) + SetRange("Tenant Visible", true) + FindFirst, then Media.SetRange(ID, Logo.MediaId()) + FindFirst
    // + CalcFields(Content). The helper repeats that sequence step by step.
    local procedure LogoSteps(AppId: Text): Text
    var
        App: Record "Published Application";
        Media: Record Media;
        Id: Guid;
        Result: Text;
    begin
        Evaluate(Id, AppId);
        App.SetRange(ID, Id);
        App.SetRange("Tenant Visible", true);
        if not App.FindFirst() then
            exit('no visible row');
        Result := 'row found';
        Result += '|logo has value=' + Format(App.Logo.HasValue());
        Result += '|media id null=' + Format(IsNullGuid(App.Logo.MediaId()));
        Media.SetRange(ID, App.Logo.MediaId());
        if not Media.FindFirst() then
            exit(Result + '|media row=none');
        Media.CalcFields(Content);
        exit(Result + '|media row=found|content has value=' + Format(Media.Content.HasValue()));
    end;

    [Test]
    procedure Logo_GuidedExperienceSequence_OfThisAppAndMicrosoftApps()
    var
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Observer.Observe('this onprem app', LogoSteps(ThisModule.Id()));
        Observer.Observe('cloud coverage app', LogoSteps('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Observe('base application', LogoSteps('437dbf0e-84ff-417a-965d-ed2bb9650972'));
        Observer.Observe('system application', LogoSteps('63ca2fa4-4f03-4f2b-a480-172fef340d3f'));
        Observer.Observe('application', LogoSteps('c1335042-3002-4257-bf8a-75c898ccb1b8'));
        Observer.Observe('no such app', LogoSteps('00000000-0000-0000-0000-000000000001'));
        Observer.Finish();
    end;
}
