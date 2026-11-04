// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (table 73057, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: NavApp.GetArchiveVersion, GetArchiveRecordRef, DeleteArchiveData, RestoreArchiveData, LoadPackageData called outside install and upgrade (return values and errors), NavApp.IsUnlicensed
// BC versions: 29 (27 and 28 by CI)

codeunit 73083 "LT P94 NavApp Archive"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    [TryFunction]
    local procedure TryVersion(var Result: Text)
    begin
        Result := NavApp.GetArchiveVersion();
    end;

    [TryFunction]
    local procedure TryRecordRef(TableNo: Integer; var RecRef: RecordRef; var Result: Boolean)
    begin
        Result := NavApp.GetArchiveRecordRef(TableNo, RecRef);
    end;

    [Test]
    procedure GetArchiveVersion_OutsideUpgrade()
    var
        Version: Text;
    begin
        Version := 'preset';
        if TryVersion(Version) then
            Observer.Observe('version', '[' + Version + ']')
        else
            Observer.Observe('version', Helper.ErrText());
        Observer.Expect('version', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure GetArchiveRecordRef_OwnTable()
    var
        RecRef: RecordRef;
        Ok: Boolean;
    begin
        if TryRecordRef(Database::"LT P94 Item", RecRef, Ok) then begin
            Observer.Observe('ok', Format(Ok));
            Observer.Observe('isOpen', Format(RecRef.Number() <> 0));
        end else
            Observer.Observe('ok', Helper.ErrText());
        Observer.Expect('ok', 'No');
        Observer.Expect('isOpen', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetArchiveRecordRef_ZeroAndUnknownTable()
    var
        RecRef: RecordRef;
        Ok: Boolean;
    begin
        if TryRecordRef(0, RecRef, Ok) then
            Observer.Observe('zero', Format(Ok))
        else
            Observer.Observe('zero', Helper.ErrText());
        if TryRecordRef(73999, RecRef, Ok) then
            Observer.Observe('unknown', Format(Ok))
        else
            Observer.Observe('unknown', Helper.ErrText());
        if TryRecordRef(-1, RecRef, Ok) then
            Observer.Observe('negative', Format(Ok))
        else
            Observer.Observe('negative', Helper.ErrText());
        Observer.Expect('zero', 'No');
        Observer.Expect('unknown', 'No');
        Observer.Expect('negative', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteArchiveData_OwnTable()
    begin
        Helper.Wipe();
        NavApp.DeleteArchiveData(Database::"LT P94 Item");
        Observer.Observe('delete', 'no error');
        Observer.Expect('delete', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteArchiveData_ZeroTable()
    begin
        NavApp.DeleteArchiveData(0);
        Observer.Observe('delete0', 'no error');
        Observer.Expect('delete0', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteArchiveData_UnknownTable()
    begin
        NavApp.DeleteArchiveData(73999);
        Observer.Observe('deleteUnknown', 'no error');
        Observer.Expect('deleteUnknown', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RestoreArchiveData_OwnTable()
    begin
        Helper.Wipe();
        NavApp.RestoreArchiveData(Database::"LT P94 Item");
        Observer.Observe('restore', 'no error');
        Observer.Expect('restore', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RestoreArchiveData_OwnTableRunTriggerTrue()
    begin
        Helper.Wipe();
        NavApp.RestoreArchiveData(Database::"LT P94 Item", true);
        Observer.Observe('restoreTrue', 'no error');
        Observer.Expect('restoreTrue', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RestoreArchiveData_OwnTableRunTriggerFalse()
    begin
        Helper.Wipe();
        NavApp.RestoreArchiveData(Database::"LT P94 Item", false);
        Observer.Observe('restoreFalse', 'no error');
        Observer.Expect('restoreFalse', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RestoreArchiveData_ZeroTable()
    begin
        NavApp.RestoreArchiveData(0);
        Observer.Observe('restore0', 'no error');
        Observer.Expect('restore0', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RestoreArchiveData_UnknownTable()
    begin
        NavApp.RestoreArchiveData(73999);
        Observer.Observe('restoreUnknown', 'no error');
        Observer.Expect('restoreUnknown', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LoadPackageData_OwnTable()
    begin
        Helper.Wipe();
        NavApp.LoadPackageData(Database::"LT P94 Item");
        Observer.Observe('load', 'no error');
        Observer.Expect('load', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LoadPackageData_ZeroTable()
    begin
        NavApp.LoadPackageData(0);
        Observer.Observe('load0', 'no error');
        Observer.Expect('load0', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LoadPackageData_UnknownTable()
    begin
        NavApp.LoadPackageData(73999);
        Observer.Observe('loadUnknown', 'no error');
        Observer.Expect('loadUnknown', 'no error');
        Observer.Verify();
    end;
}

codeunit 73084 "LT P94 NavApp Info"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    [TryFunction]
    local procedure TryUnlicensed(AppId: Guid; var Result: Boolean)
    begin
        Result := NavApp.IsUnlicensed(AppId);
    end;

    [Test]
    procedure IsUnlicensed_NoArgument()
    begin
        Observer.Observe('unlicensed', Format(NavApp.IsUnlicensed()));
        Observer.Expect('unlicensed', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsUnlicensed_OwnApp()
    var
        Info: ModuleInfo;
        Result: Boolean;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if TryUnlicensed(Info.Id(), Result) then
            Observer.Observe('own', Format(Result))
        else
            Observer.Observe('own', Helper.ErrText());
        Observer.Observe('sameAsNoArgument', Format(Result = NavApp.IsUnlicensed()));
        Observer.Expect('own', 'No');
        Observer.Expect('sameAsNoArgument', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure IsUnlicensed_NullGuid()
    var
        Result: Boolean;
        Null: Guid;
    begin
        if TryUnlicensed(Null, Result) then
            Observer.Observe('null', Format(Result))
        else
            Observer.Observe('null', Helper.ErrText());
        Observer.Expect('null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsUnlicensed_UnknownApp()
    var
        Result: Boolean;
    begin
        if TryUnlicensed(CreateGuid(), Result) then
            Observer.Observe('unknown', Format(Result))
        else
            Observer.Observe('unknown', Helper.ErrText());
        Observer.Expect('unknown', 'No');
        Observer.Verify();
    end;

}
