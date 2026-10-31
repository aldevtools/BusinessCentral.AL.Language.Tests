// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: DotNet aliases LtBgCameraProvider and LtBgStringBuilder from BgRunOnClient.al; self-contained page 99475 (never opened: the tests call its procedures, as Microsoft code calls Camera.IsAvailable() on a page variable) and codeunit 99476 (not test codeunits; the tests are in
// codeunit 99490 "LT BG RunOnClient", BgRunOnClient.al, procedures Y16_*)
// Probe: the shapes Microsoft's apps use with [RunOnClient] DotNet variables, run in a test session (no client):
//   - [RunOnClient] [WithEvents] compiles only on a page (a codeunit gives AL0460, must-not-compile case 2335).
//   - System Application Camera page (Camera.Page.al, CameraPageImpl.Codeunit.al): a global [RunOnClient] [WithEvents] CameraProvider with an event trigger,
//     handed by value to an implementation codeunit's IsAvailable(CameraProvider: DotNet CameraProvider) and by var to CameraInteractionOnOpenPage, which calls
//     IsAvailable() and, when available, CameraProvider.Create(). Neither parameter carries [RunOnClient].
//   - the host keeps the attribute only on its own variable: the probe also forces Create() through the var parameter.
//   - Base Application File Management (FileManagement.Codeunit.al): a global [RunOnClient] System.IO.Directory, static Exists(Path) and GetFiles(Path).Length.
// Expected values: corpus CI run 41187321466 (jobs BC OnPrem DotNet 27.5, 28.5 and 29.0, Linux BC containers), the same on all three except the .NET runtime version
// named in the serialize error (8.0.0.0 on BC 27 and 28, 10.0.0.0 on BC 29). Not yet checked on a Windows container (queued in the Windows check list).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.Directory"; LtY16Directory) { }
    }
}

page 99475 "LT Y16 RoC Camera Host"
{
    PageType = Card;
    UsageCategory = None;

    var
        Impl: Codeunit "LT Y16 RoC Camera Impl";
        [RunOnClient]
        [WithEvents]
        CameraProvider: DotNet LtBgCameraProvider;
        [RunOnClient]
        DirectoryHelper: DotNet LtY16Directory;
        PictureCount: Integer;

    [TryFunction]
    procedure TryIsAvailable(var Available: Boolean)
    begin
        Available := Impl.IsAvailable(CameraProvider);
    end;

    [TryFunction]
    procedure TryOpen(var Available: Boolean)
    begin
        Impl.OnOpen(CameraProvider, Available);
    end;

    [TryFunction]
    procedure TryForceCreate(var Step: Text)
    begin
        Impl.ForceCreate(CameraProvider, Step);
    end;

    [TryFunction]
    procedure TryDirectoryExists(var Step: Text)
    begin
        Step := 'exists';
        Step := 'exists=' + Format(DirectoryHelper.Exists('C:\'));
    end;

    [TryFunction]
    procedure TryDirectoryIsEmpty(var Step: Text)
    begin
        Step := 'getfiles';
        Step := 'empty=' + Format(DirectoryHelper.GetFiles('C:\').Length = 0);
    end;

    procedure ProviderIsNull(): Boolean
    begin
        exit(IsNull(CameraProvider));
    end;

    procedure Pictures(): Integer
    begin
        exit(PictureCount);
    end;

    trigger CameraProvider::PictureAvailable(PictureName: Text; PictureFilePath: Text)
    begin
        PictureCount += 1;
    end;
}

codeunit 99476 "LT Y16 RoC Camera Impl"
{
    procedure IsAvailable(CameraProvider: DotNet LtBgCameraProvider): Boolean
    begin
        exit(CameraProvider.IsAvailable());
    end;

    procedure OnOpen(var CameraProvider: DotNet LtBgCameraProvider; var Available: Boolean)
    begin
        Available := IsAvailable(CameraProvider);
        if not Available then
            exit;
        CameraProvider := CameraProvider.Create();
    end;

    procedure ForceCreate(var CameraProvider: DotNet LtBgCameraProvider; var Step: Text)
    begin
        Step := 'create';
        CameraProvider := CameraProvider.Create();
        Step := 'created isnull=' + Format(IsNull(CameraProvider));
    end;

    // The same static call on a variable without [RunOnClient]: the call runs on the service tier.
    [TryFunction]
    procedure TryServerIsAvailable(var Available: Boolean)
    var
        ServerCamera: DotNet LtBgCameraProvider;
    begin
        Available := ServerCamera.IsAvailable();
    end;

    [TryFunction]
    procedure TryServerCreate(var Step: Text)
    var
        ServerCamera: DotNet LtBgCameraProvider;
    begin
        Step := 'create';
        ServerCamera := ServerCamera.Create();
        Step := 'created isnull=' + Format(IsNull(ServerCamera));
    end;
}
