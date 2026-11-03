// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Microsoft's page 9022 "Business Manager Role Center", page 1310 "O365 Activities" (Base Application), codeunit 1907 Camera and page 1908 Camera (System Application); self-contained codeunits 81351 and 81352
// Probe: pages and modules that ask the client for a device feature (RunOnClient DotNet: UserTours.IsAvailable in page 1310 OnInit, CameraProvider.IsAvailable in the Camera module) in a test session.
// The test client answers like Microsoft's web client for a session without these features. Before MsDyn365Bc.On.Linux PR #130 the Linux test runner answered such calls with a null handle,
// and opening the Business Manager Role Center ended with a NullReferenceException.
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 81351 "LT BG Role Center Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOpenBusinessManager()
    var
        RC: TestPage "Business Manager Role Center";
    begin
        RC.OpenView();
        RC.Close();
    end;

    [TryFunction]
    local procedure TryOpenActivities()
    var
        Activities: TestPage "O365 Activities";
    begin
        Activities.OpenView();
        Activities.Close();
    end;

    [Test]
    procedure BG_TestPage_BusinessManagerRoleCenter_Opens()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryOpenBusinessManager() then
            Observer.Observe('open business manager rc', 'ok')
        else
            Observer.ObserveError('open business manager rc');
        Observer.Expect('open business manager rc', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure BG_TestPage_O365Activities_Opens()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryOpenActivities() then
            Observer.Observe('open o365 activities', 'ok')
        else
            Observer.ObserveError('open o365 activities');
        Observer.Expect('open o365 activities', 'ok');
        Observer.Verify();
    end;
}

codeunit 81352 "LT BG Camera Availability"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryIsAvailable(var R: Boolean)
    var
        Camera: Codeunit Camera;
    begin
        R := Camera.IsAvailable();
    end;

    [TryFunction]
    local procedure TryGetPicture(var R: Boolean; var PictureName: Text)
    var
        Camera: Codeunit Camera;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        R := Camera.GetPicture(InS, PictureName);
    end;

    [TryFunction]
    local procedure TryOpenCameraPage()
    var
        CameraPage: TestPage Camera;
    begin
        CameraPage.OpenView();
        CameraPage.Close();
    end;

    [Test]
    procedure BG_Camera_IsAvailable_InTestSession()
    var
        Observer: Codeunit "Probe Observer";
        R: Boolean;
        PictureName: Text;
    begin
        Observer.Observe('guiallowed', Format(GuiAllowed()));
        R := true;
        if TryIsAvailable(R) then
            Observer.Observe('isavailable', 'ok ret=' + Format(R))
        else
            Observer.ObserveError('isavailable');
        R := true;
        PictureName := 'untouched';
        if TryGetPicture(R, PictureName) then
            Observer.Observe('getpicture', 'ok ret=' + Format(R) + ' name=[' + PictureName + ']')
        else
            Observer.ObserveError('getpicture');
        if TryOpenCameraPage() then
            Observer.Observe('open camera page', 'ok')
        else
            Observer.ObserveError('open camera page');
        Observer.Expect('guiallowed', 'Yes');
        Observer.Expect('isavailable', 'ok ret=No');
        Observer.Expect('getpicture', 'ok ret=No name=[untouched]');
        Observer.Expect('open camera page', 'ok');
        Observer.Verify();
    end;
}
