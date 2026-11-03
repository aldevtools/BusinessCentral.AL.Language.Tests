// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99490
// Probe: RunOnClient DotNet in a test session. The static IsAvailable() of the client feature types (camera, location, barcode scanners, device contacts, user tours, page notifier) and a RunOnClient
// variable of a type that is not a client feature (System.Text.StringBuilder: its constructor and a static call). Before MsDyn365Bc.On.Linux PR #130 the Linux test runner answered these calls with a null
// handle (BC 27.5: an uncatchable NullReferenceException; BC 28+: "A call to IsAvailable failed ... Object reference not set to an instance of an object.").
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider"; LtBgCameraProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider"; LtBgLocationProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.BarcodeScannerProvider"; LtBgBarcodeScannerProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraBarcodeScannerProvider"; LtBgCameraBarcodeScannerProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.DeviceContactProvider"; LtBgDeviceContactProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.UserTours"; LtBgUserTours) { }
        type("Microsoft.Dynamics.Nav.Client.PageNotifier"; LtBgPageNotifier) { }
    }
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; LtBgStringBuilder) { }
        type("System.Environment"; LtBgEnvironment) { }
    }
}

codeunit 99490 "LT BG RunOnClient"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        Camera: DotNet LtBgCameraProvider;
        [RunOnClient]
        Location: DotNet LtBgLocationProvider;
        [RunOnClient]
        Barcode: DotNet LtBgBarcodeScannerProvider;
        [RunOnClient]
        CameraBarcode: DotNet LtBgCameraBarcodeScannerProvider;
        [RunOnClient]
        Contacts: DotNet LtBgDeviceContactProvider;
        [RunOnClient]
        Tours: DotNet LtBgUserTours;
        [RunOnClient]
        Notifier: DotNet LtBgPageNotifier;
        [RunOnClient]
        Builder: DotNet LtBgStringBuilder;
        [RunOnClient]
        Env: DotNet LtBgEnvironment;

    [TryFunction]
    local procedure TryAvailable(Kind: Integer; var R: Boolean)
    begin
        case Kind of
            1:
                R := Camera.IsAvailable();
            2:
                R := Location.IsAvailable();
            3:
                R := Barcode.IsAvailable();
            4:
                R := CameraBarcode.IsAvailable();
            5:
                R := Contacts.IsAvailable();
            6:
                R := Tours.IsAvailable();
            7:
                R := Notifier.IsAvailable();
        end;
    end;

    local procedure AvailableCase(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer)
    var
        R: Boolean;
    begin
        R := true;
        if TryAvailable(Kind, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R))
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryBuild(var Result: Text)
    begin
        Builder := Builder.StringBuilder();
        Builder.Append('client');
        Result := Builder.ToString();
    end;

    [TryFunction]
    local procedure TryMachineName(var Result: Text)
    begin
        Result := Env.MachineName();
    end;

    [Test]
    procedure BG_RunOnClient_ClientFeatures_IsAvailable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AvailableCase(Observer, 'camera', 1);
        AvailableCase(Observer, 'location', 2);
        AvailableCase(Observer, 'barcode scanner', 3);
        AvailableCase(Observer, 'camera barcode scanner', 4);
        AvailableCase(Observer, 'device contacts', 5);
        AvailableCase(Observer, 'user tours', 6);
        AvailableCase(Observer, 'page notifier', 7);
        Observer.Expect('camera', 'ok ret=No');
        Observer.Expect('location', 'ok ret=No');
        Observer.Expect('barcode scanner', 'ok ret=No');
        Observer.Expect('camera barcode scanner', 'ok ret=No');
        Observer.Expect('device contacts', 'ok ret=No');
        Observer.Expect('user tours', 'ok ret=No');
        Observer.Expect('page notifier', 'ok ret=No');
        Observer.Verify();
    end;

    [Test]
    procedure BG_RunOnClient_OtherType_Constructor()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Result := 'untouched';
        if TryBuild(Result) then
            Observer.Observe('stringbuilder', 'ok [' + Result + ']')
        else
            Observer.ObserveError('stringbuilder');
        Observer.Expect('stringbuilder|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('stringbuilder|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    [Test]
    procedure BG_RunOnClient_OtherType_StaticCall()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Result := 'untouched';
        if TryMachineName(Result) then
            Observer.Observe('machinename', 'ok nonempty=' + Format(Result <> ''))
        else
            Observer.ObserveError('machinename');
        Observer.Expect('machinename|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('machinename|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    // Added by writer TY (2026-10-29): a local [RunOnClient] variable, client code guarded by GuiAllowed() as the System Application
    // does it (Camera Impl. IsAvailable, Camera Page Impl.: IsAvailable, then Create() and a member call), and the error
    // outside a TryFunction (asserterror). Expected values: corpus CI BC 27.5, 28.5 and 29.0 (batch runs 40840955706, 40840985427,
    // 40841014789), the same on all three; Windows check queued in windows-queue.md.
    [TryFunction]
    local procedure TyTryCameraCreate(var Result: Text)
    var
        [RunOnClient]
        LocalCamera: DotNet LtBgCameraProvider;
    begin
        LocalCamera := LocalCamera.Create();
        Result := 'created isnull=' + Format(IsNull(LocalCamera));
        Result += ' available=' + Format(LocalCamera.IsAvailable());
    end;

    [TryFunction]
    local procedure TyTryIsNullUnassigned(var Result: Text)
    var
        [RunOnClient]
        LocalBuilder: DotNet LtBgStringBuilder;
    begin
        Result := Format(IsNull(LocalBuilder));
    end;

    local procedure TyBuildUnguarded()
    var
        [RunOnClient]
        LocalBuilder: DotNet LtBgStringBuilder;
    begin
        LocalBuilder := LocalBuilder.StringBuilder();
    end;

    [Test]
    procedure TY_RunOnClient_GuiAllowedGuard_CameraCreate()
    var
        Observer: Codeunit "Probe Observer";
        [RunOnClient]
        LocalCamera: DotNet LtBgCameraProvider;
        Result: Text;
    begin
        Observer.Observe('guiallowed', Format(GuiAllowed()));
        Result := 'skipped';
        if GuiAllowed() then
            if TyTryCameraCreate(Result) then
                Observer.Observe('create', 'ok [' + Result + ']')
            else
                Observer.ObserveError('create')
        else
            Observer.Observe('create', Result);
        Observer.Observe('declared only isnull', Format(IsNull(LocalCamera)));
        Observer.Expect('guiallowed', 'Yes');
        Observer.Expect('create|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('create|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Expect('declared only isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TY_RunOnClient_Local_IsNullUnassigned()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Result := 'untouched';
        if TyTryIsNullUnassigned(Result) then
            Observer.Observe('isnull', 'ok ' + Result)
        else
            Observer.ObserveError('isnull');
        Observer.Expect('isnull', 'ok Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TY_RunOnClient_Local_Constructor_AssertError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror TyBuildUnguarded();
        Observer.ObserveError('asserterror');
        Observer.Expect('asserterror|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('asserterror|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    // Added by writer Y16 (2026-10-31): the shapes Microsoft's apps use (helper codeunits in Y16RunOnClientShapes.al): the Camera page hands its
    // [RunOnClient] [WithEvents] provider to an implementation codeunit by value and by var (no [RunOnClient] on the parameters), the static IsAvailable()
    // and Create() on a variable without [RunOnClient] (service tier), the role center PageNotifier guard, File Management's client System.IO.Directory,
    // and assigning between a [RunOnClient] variable and a service-tier variable, Clear and a Variant.
    // Expected values: corpus CI run 41187321466 (jobs BC OnPrem DotNet 27.5, 28.5 and 29.0, Linux BC containers), the same on all three except the .NET runtime version
    // named in the serialize error (8.0.0.0 on BC 27 and 28, 10.0.0.0 on BC 29). Not yet checked on a Windows container (queued in the Windows check list).
    [Test]
    procedure Y16_RunOnClient_CameraPageShape_ImplByValue()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT Y16 RoC Camera Host";
        Available: Boolean;
    begin
        Available := true;
        if Host.TryIsAvailable(Available) then
            Observer.Observe('isavailable', 'ok ret=' + Format(Available))
        else
            Observer.ObserveError('isavailable');
        Observer.Observe('provider isnull', Format(Host.ProviderIsNull()));
        Observer.Observe('pictures', Format(Host.Pictures()));
        Observer.Expect('isavailable', 'ok ret=No');
        Observer.Expect('provider isnull', 'Yes');
        Observer.Expect('pictures', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_RunOnClient_CameraPageShape_OnOpenByVar()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT Y16 RoC Camera Host";
        Available: Boolean;
    begin
        Available := true;
        if Host.TryOpen(Available) then
            Observer.Observe('onopen', 'ok available=' + Format(Available))
        else
            Observer.ObserveError('onopen');
        Observer.Observe('provider isnull', Format(Host.ProviderIsNull()));
        Observer.Expect('onopen', 'ok available=No');
        Observer.Expect('provider isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_RunOnClient_CreateThroughVarParameter()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT Y16 RoC Camera Host";
        Step: Text;
    begin
        Step := 'untouched';
        if Host.TryForceCreate(Step) then
            Observer.Observe('force create', 'ok [' + Step + ']')
        else begin
            Observer.Observe('force create step', Step);
            Observer.ObserveError('force create');
        end;
        Observer.Observe('provider isnull', Format(Host.ProviderIsNull()));
        Observer.Expect('force create step', 'create');
        Observer.Expect('force create|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('force create|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Expect('provider isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_ServerTier_CameraProvider_IsAvailableAndCreate()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "LT Y16 RoC Camera Impl";
        Available: Boolean;
        Step: Text;
    begin
        Available := true;
        if Impl.TryServerIsAvailable(Available) then
            Observer.Observe('server isavailable', 'ok ret=' + Format(Available))
        else
            Observer.ObserveError('server isavailable');
        Step := 'untouched';
        if Impl.TryServerCreate(Step) then
            Observer.Observe('server create', 'ok [' + Step + ']')
        else begin
            Observer.Observe('server create step', Step);
            Observer.ObserveError('server create');
        end;
        Observer.Expect('server isavailable', 'ok ret=No');
        Observer.Expect('server create', 'ok [created isnull=Yes]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Y16TryPageNotifierGuard(var Result: Text; var WasNull: Boolean)
    var
        [RunOnClient]
        LocalNotifier: DotNet LtBgPageNotifier;
    begin
        Result := 'start';
        if LocalNotifier.IsAvailable() then begin
            LocalNotifier := LocalNotifier.Create();
            LocalNotifier.NotifyPageReady();
            Result := 'notified';
        end else
            Result := 'not available';
        WasNull := IsNull(LocalNotifier);
    end;

    [Test]
    procedure Y16_RunOnClient_RoleCenterPageNotifierGuard()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        WasNull: Boolean;
    begin
        Result := 'untouched';
        if Y16TryPageNotifierGuard(Result, WasNull) then
            Observer.Observe('guard', 'ok [' + Result + '] isnull=' + Format(WasNull))
        else begin
            Observer.Observe('guard step', Result);
            Observer.ObserveError('guard');
        end;
        Observer.Expect('guard', 'ok [not available] isnull=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_RunOnClient_FileManagementDirectory()
    var
        Observer: Codeunit "Probe Observer";
        Host: Page "LT Y16 RoC Camera Host";
        Step: Text;
    begin
        Step := 'untouched';
        if Host.TryDirectoryExists(Step) then
            Observer.Observe('exists', 'ok [' + Step + ']')
        else begin
            Observer.Observe('exists step', Step);
            Observer.ObserveError('exists');
        end;
        Step := 'untouched';
        if Host.TryDirectoryIsEmpty(Step) then
            Observer.Observe('getfiles', 'ok [' + Step + ']')
        else begin
            Observer.Observe('getfiles step', Step);
            Observer.ObserveError('getfiles');
        end;
        Observer.Expect('exists step', 'exists');
        Observer.Expect('exists|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('exists|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Expect('getfiles step', 'getfiles');
        Observer.Expect('getfiles|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('getfiles|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Y16TryServerToClient(var Step: Text)
    var
        ServerBuilder: DotNet LtBgStringBuilder;
        [RunOnClient]
        ClientBuilder: DotNet LtBgStringBuilder;
    begin
        Step := 'construct';
        ServerBuilder := ServerBuilder.StringBuilder();
        ServerBuilder.Append('srv');
        Step := 'assign';
        ClientBuilder := ServerBuilder;
        Step := 'assigned isnull=' + Format(IsNull(ClientBuilder));
        ClientBuilder.Append('+client');
        Step += ' appended';
        Step += ' client=' + ClientBuilder.ToString() + ' server=' + ServerBuilder.ToString();
    end;

    [TryFunction]
    local procedure Y16TryClientToServer(var Step: Text)
    var
        ServerBuilder: DotNet LtBgStringBuilder;
        [RunOnClient]
        ClientBuilder: DotNet LtBgStringBuilder;
    begin
        Step := 'assign';
        ServerBuilder := ClientBuilder;
        Step := 'assigned isnull=' + Format(IsNull(ServerBuilder));
    end;

    [Test]
    procedure Y16_RunOnClient_AssignBetweenClientAndServerVariables()
    var
        Observer: Codeunit "Probe Observer";
        Step: Text;
    begin
        Step := 'untouched';
        if Y16TryServerToClient(Step) then
            Observer.Observe('server to client', 'ok [' + Step + ']')
        else begin
            Observer.Observe('server to client step', Step);
            Observer.ObserveError('server to client');
        end;
        Step := 'untouched';
        if Y16TryClientToServer(Step) then
            Observer.Observe('client to server', 'ok [' + Step + ']')
        else begin
            Observer.Observe('client to server step', Step);
            Observer.ObserveError('client to server');
        end;
        Observer.Expect('server to client step', 'assign');
#if BC29PLUS
        Observer.Expect('server to client|text', 'Cannot serialize an instance of the following .NET Framework object: assembly System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e, type System.Text.StringBuilder.');
#else
        Observer.Expect('server to client|text', 'Cannot serialize an instance of the following .NET Framework object: assembly System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e, type System.Text.StringBuilder.');
#endif
        Observer.Expect('server to client|code', 'DotNetCreate');
        Observer.Expect('client to server', 'ok [assigned isnull=Yes]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Y16TryClearAndVariant(var Step: Text)
    var
        [RunOnClient]
        ClientBuilder: DotNet LtBgStringBuilder;
        V: Variant;
    begin
        Step := 'clear';
        Clear(ClientBuilder);
        Step := 'cleared isnull=' + Format(IsNull(ClientBuilder));
        V := ClientBuilder;
        Step += ' variant isdotnet=' + Format(V.IsDotNet());
    end;

    [Test]
    procedure Y16_RunOnClient_ClearAndVariant()
    var
        Observer: Codeunit "Probe Observer";
        Step: Text;
    begin
        Step := 'untouched';
        if Y16TryClearAndVariant(Step) then
            Observer.Observe('clear', 'ok [' + Step + ']')
        else begin
            Observer.Observe('clear step', Step);
            Observer.ObserveError('clear');
        end;
        Observer.Expect('clear', 'ok [cleared isnull=Yes variant isdotnet=Yes]');
        Observer.Verify();
    end;
}
