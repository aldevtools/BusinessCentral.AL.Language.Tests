// Batch 5, md:70 (GetModuleInfo of the null app id: Name, Publisher, AppVersion, Id, DataVersion minor) and md:245 (PackageId derivation, unknown-id text, dependency outside the workspace).
// Fixtures used: self-contained (see the object ids below)

codeunit 67063 "W5 ModuleInfo Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // md:70
    [Test]
    procedure ModuleInfo_NullId_Properties()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        NullId: Guid;
        Ok: Boolean;
    begin
        Ok := NavApp.GetModuleInfo(NullId, Info);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('name', Info.Name());
        Observer.Observe('publisher', Info.Publisher());
        Observer.Observe('id_is_null', Format(Info.Id() = NullId));
        Observer.Observe('package_id_is_null', Format(Info.PackageId() = NullId));
        Observer.Observe('app_major_ge_27', Format(Info.AppVersion().Major() >= 27));
        Observer.Observe('app_build_is_zero', Format(Info.AppVersion().Build() = 0));
        Observer.Observe('app_revision_is_zero', Format(Info.AppVersion().Revision() = 0));
        Observer.Observe('data_major_ge_27', Format(Info.DataVersion().Major() >= 27));
        Observer.Observe('data_build_is_zero', Format(Info.DataVersion().Build() = 0));
        Observer.Observe('data_revision_is_zero', Format(Info.DataVersion().Revision() = 0));
        Observer.Observe('app_minor_equals_data_minor', Format(Info.AppVersion().Minor() = Info.DataVersion().Minor()));
        Observer.Observe('app_equals_data', Format(Info.AppVersion() = Info.DataVersion()));
        Observer.Observe('dependencies_count', Format(Info.Dependencies().Count()));
        Observer.Expect('result', 'Yes');
        Observer.Expect('name', 'W1');
        Observer.Expect('publisher', 'Microsoft');
        Observer.Expect('id_is_null', 'Yes');
        Observer.Expect('package_id_is_null', 'Yes');
        Observer.Expect('app_major_ge_27', 'Yes');
        Observer.Expect('app_build_is_zero', 'No');
        Observer.Expect('app_revision_is_zero', 'No');
        Observer.Expect('data_major_ge_27', 'Yes');
        Observer.Expect('data_build_is_zero', 'No');
        Observer.Expect('data_revision_is_zero', 'No');
        Observer.Expect('app_minor_equals_data_minor', 'Yes');
        Observer.Expect('app_equals_data', 'Yes');
        Observer.Expect('dependencies_count', '0');
        Observer.Verify();
    end;

    // md:245: the relation between Id and PackageId of the app under test.
    [Test]
    procedure ModuleInfo_PackageId_ComparedToId()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        NullId: Guid;
        IdText: Text;
        PackageText: Text;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        IdText := Format(Info.Id());
        PackageText := Format(Info.PackageId());
        Observer.Observe('package_id_not_null', Format(Info.PackageId() <> NullId));
        Observer.Observe('package_id_differs_from_id', Format(Info.PackageId() <> Info.Id()));
        Observer.Observe('text_length_equal', Format(StrLen(IdText) = StrLen(PackageText)));
        Observer.Observe('first_34_chars_equal', Format(CopyStr(IdText, 1, 34) = CopyStr(PackageText, 1, 34)));
        Observer.Observe('first_9_chars_equal', Format(CopyStr(IdText, 1, 9) = CopyStr(PackageText, 1, 9)));
        Observer.Observe('data_version_equals_app_version', Format(Info.DataVersion() = Info.AppVersion()));
        Observer.Expect('package_id_not_null', 'Yes');
        Observer.Expect('package_id_differs_from_id', 'Yes');
        Observer.Expect('text_length_equal', 'Yes');
        Observer.Expect('first_34_chars_equal', 'No');
        Observer.Expect('first_9_chars_equal', 'No');
        Observer.Expect('data_version_equals_app_version', 'Yes');
        Observer.Verify();
    end;

    // md:245: an id nobody installed, result captured.
    // md:245: the same id with the result dropped. Unsure whether this raises: Try wrapper.
    [Test]
    procedure ModuleInfo_UnknownId_ResultDropped()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        UnknownId: Guid;
        Ok: Boolean;
    begin
        Evaluate(UnknownId, '{1B2C3D4E-1111-4222-8333-444455556666}');
        ClearLastError();
        Ok := TryGetDropped(UnknownId, Info);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('dropped');
        Observer.Expect('ok', 'No');
        Observer.Expect('dropped|text', 'No installed extension was found with ID ''1b2c3d4e-1111-4222-8333-444455556666''.');
        Observer.Expect('dropped|code', 'App');
        Observer.Verify();
    end;

    // md:245 / md:158: a dependency outside the workspace (System Application, Base Application, Application).
    [Test]
    procedure ModuleInfo_DependencyOutsideWorkspace()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        Id: Guid;
        Ok: Boolean;
    begin
        Evaluate(Id, '{63ca2fa4-4f03-4f2b-a480-172fef340d3f}');
        Ok := NavApp.GetModuleInfo(Id, Info);
        Observer.Observe('sysapp_result', Format(Ok));
        Observer.Observe('sysapp_name', Info.Name());
        Observer.Observe('sysapp_publisher', Info.Publisher());
        Observer.Observe('sysapp_major_ge_27', Format(Info.AppVersion().Major() >= 27));
        Clear(Info);
        Evaluate(Id, '{437dbf0e-84ff-417a-965d-ed2bb9650972}');
        Ok := NavApp.GetModuleInfo(Id, Info);
        Observer.Observe('baseapp_result', Format(Ok));
        Observer.Observe('baseapp_name', Info.Name());
        Observer.Observe('baseapp_publisher', Info.Publisher());
        Observer.Observe('baseapp_major_ge_27', Format(Info.AppVersion().Major() >= 27));
        Observer.Expect('sysapp_result', 'Yes');
        Observer.Expect('sysapp_name', 'System Application');
        Observer.Expect('sysapp_publisher', 'Microsoft');
        Observer.Expect('sysapp_major_ge_27', 'Yes');
        Observer.Expect('baseapp_result', 'Yes');
        Observer.Expect('baseapp_name', 'Base Application');
        Observer.Expect('baseapp_publisher', 'Microsoft');
        Observer.Expect('baseapp_major_ge_27', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetDropped(AppId: Guid; var Info: ModuleInfo)
    begin
        NavApp.GetModuleInfo(AppId, Info);
    end;
}
