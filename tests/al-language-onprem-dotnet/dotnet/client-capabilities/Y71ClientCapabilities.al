// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; test codeunit 99310 (writer Y71, gap cycle 7 spec G7-09 steps CO1, LO1, LO3, LP1, LP2)
// Probe: the client capability classes of Microsoft.Dynamics.Nav.Client.Capabilities used as plain server-side objects in a test session (no client):
//        CameraOptions (constructor, defaults and setters of AllowEdit, EncodingType, Quality, SourceType, MediaType), Location with Coordinate and LocationStatus (a mock
//        built the way the System Application's Geolocation Test Library builds it), LocationOptions (EnableHighAccuracy, Timeout, MaximumAge as properties and
//        as method calls), and LocationProvider and CameraProvider that were never created or created without a client (IsAvailable, Create,
//        RequestLocationAsync, RequestPictureAsync).
//        Per step: Format of each property after each set, or the error text and code.
// Values: measured on the Linux CI containers 27.5, 28.5, 29.0 (identical on all three). Not yet checked on a Windows container (queued as a Linux-suspect check).
// BC versions: 27, 28, 29

dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraOptions"; LtY71CameraOptions) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider"; LtY71CameraProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Location"; LtY71Location) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationStatus"; LtY71LocationStatus) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Coordinate"; LtY71Coordinate) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider"; LtY71LocationProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationOptions"; LtY71LocationOptions) { }
    }
}

codeunit 99310 "LT Y71 Client Capabilities"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        GlobalLocationProvider: DotNet LtY71LocationProvider;
        GlobalCameraProvider: DotNet LtY71CameraProvider;

    [TryFunction]
    local procedure TrySetCamera(var O: DotNet LtY71CameraOptions; Which: Integer)
    begin
        case Which of
            1:
                O.AllowEdit := true;
            2:
                O.EncodingType := 'JPEG';
            3:
                O.EncodingType := 'PNG';
            4:
                O.EncodingType := 'GIF';
            5:
                O.EncodingType := '';
            6:
                O.Quality := 0;
            7:
                O.Quality := 50;
            8:
                O.Quality := 100;
            9:
                O.Quality := 101;
            10:
                O.Quality := -1;
            11:
                O.SourceType := 'PhotoLibrary';
            12:
                O.SourceType := 'SavedPhotoAlbum';
            13:
                O.SourceType := 'Camera';
            14:
                O.SourceType := 'x';
            15:
                O.MediaType := 'AllMedia';
            16:
                O.MediaType := 'Picture';
            17:
                O.MediaType := 'Video';
            18:
                O.MediaType := 'x';
            19:
                O.AllowEdit := false;
        end;
    end;

    local procedure CameraState(O: DotNet LtY71CameraOptions): Text
    begin
        exit(StrSubstNo('AllowEdit=%1 EncodingType=[%2] Quality=%3 SourceType=[%4] MediaType=[%5]', O.AllowEdit, O.EncodingType, O.Quality, O.SourceType, O.MediaType));
    end;

    local procedure SetCamera(Name: Text; var O: DotNet LtY71CameraOptions; Which: Integer)
    begin
        if TrySetCamera(O, Which) then
            Obs.Observe(Name, CameraState(O))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure CameraOptions_NewAndProperties()
    var
        O: DotNet LtY71CameraOptions;
    begin
        Obs.Observe('null_before', Format(IsNull(O)));
        O := O.CameraOptions();
        Obs.Observe('null_after', Format(IsNull(O)));
        Obs.Observe('defaults', CameraState(O));
        Obs.Observe('to_string', O.ToString());
        Obs.Observe('format', Format(O));
        SetCamera('allow_edit_true', O, 1);
        SetCamera('encoding_jpeg', O, 2);
        SetCamera('encoding_png', O, 3);
        SetCamera('encoding_gif', O, 4);
        SetCamera('encoding_empty', O, 5);
        SetCamera('quality_0', O, 6);
        SetCamera('quality_50', O, 7);
        SetCamera('quality_100', O, 8);
        SetCamera('quality_101', O, 9);
        SetCamera('quality_minus_1', O, 10);
        SetCamera('source_photo_library', O, 11);
        SetCamera('source_saved_album', O, 12);
        SetCamera('source_camera', O, 13);
        SetCamera('source_x', O, 14);
        SetCamera('media_all', O, 15);
        SetCamera('media_picture', O, 16);
        SetCamera('media_video', O, 17);
        SetCamera('media_x', O, 18);
        SetCamera('allow_edit_false', O, 19);
        Obs.Expect('null_before', 'Yes');
        Obs.Expect('null_after', 'No');
        Obs.Expect('defaults', 'AllowEdit=No EncodingType=[JPEG] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('to_string', 'Microsoft.Dynamics.Nav.Client.Capabilities.CameraOptions');
        Obs.Expect('format', 'Microsoft.Dynamics.Nav.Client.Capabilities.CameraOptions');
        Obs.Expect('allow_edit_true', 'AllowEdit=Yes EncodingType=[JPEG] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('encoding_jpeg', 'AllowEdit=Yes EncodingType=[JPEG] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('encoding_png', 'AllowEdit=Yes EncodingType=[PNG] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('encoding_gif', 'AllowEdit=Yes EncodingType=[GIF] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('encoding_empty', 'AllowEdit=Yes EncodingType=[] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('quality_0', 'AllowEdit=Yes EncodingType=[] Quality=0 SourceType=[] MediaType=[]');
        Obs.Expect('quality_50', 'AllowEdit=Yes EncodingType=[] Quality=50 SourceType=[] MediaType=[]');
        Obs.Expect('quality_100', 'AllowEdit=Yes EncodingType=[] Quality=100 SourceType=[] MediaType=[]');
        Obs.Expect('quality_101', 'AllowEdit=Yes EncodingType=[] Quality=101 SourceType=[] MediaType=[]');
        Obs.Expect('quality_minus_1', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[] MediaType=[]');
        Obs.Expect('source_photo_library', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[PhotoLibrary] MediaType=[]');
        Obs.Expect('source_saved_album', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[SavedPhotoAlbum] MediaType=[]');
        Obs.Expect('source_camera', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[Camera] MediaType=[]');
        Obs.Expect('source_x', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[x] MediaType=[]');
        Obs.Expect('media_all', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[x] MediaType=[AllMedia]');
        Obs.Expect('media_picture', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[x] MediaType=[Picture]');
        Obs.Expect('media_video', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[x] MediaType=[Video]');
        Obs.Expect('media_x', 'AllowEdit=Yes EncodingType=[] Quality=-1 SourceType=[x] MediaType=[x]');
        Obs.Expect('allow_edit_false', 'AllowEdit=No EncodingType=[] Quality=-1 SourceType=[x] MediaType=[x]');
        Obs.Verify();
    end;


    [TryFunction]
    local procedure TryLocation(Which: Integer; var Answer: Text)
    var
        Location: DotNet LtY71Location;
        Coordinate: DotNet LtY71Coordinate;
        LocationStatus: DotNet LtY71LocationStatus;
        Status: Integer;
    begin
        Location := Location.Location();
        case Which of
            1:
                begin
                    Coordinate := Coordinate.Coordinate();
                    Location.Coordinate := Coordinate;
                    Location.Coordinate.Latitude := 1.5;
                    Location.Coordinate.Longitude := 2.5;
                    Answer := StrSubstNo('%1/%2', Location.Coordinate.Latitude, Location.Coordinate.Longitude);
                end;
            2:
                begin
                    Coordinate := Coordinate.Coordinate();
                    Location.Coordinate := Coordinate;
                    Location.Coordinate.Latitude := -90;
                    Location.Coordinate.Longitude := 180;
                    Answer := StrSubstNo('%1/%2', Location.Coordinate.Latitude, Location.Coordinate.Longitude);
                end;
            3:
                begin
                    Coordinate := Coordinate.Coordinate();
                    Location.Coordinate := Coordinate;
                    Answer := StrSubstNo('%1/%2', Location.Coordinate.Latitude, Location.Coordinate.Longitude);
                end;
            4:
                Answer := Format(IsNull(Location.Coordinate));
            5:
                begin
                    Coordinate := Coordinate.Coordinate();
                    Location.Coordinate := Coordinate;
                    Location.Coordinate.Latitude := 91;
                    Location.Coordinate.Longitude := 181;
                    Answer := StrSubstNo('%1/%2', Location.Coordinate.Latitude, Location.Coordinate.Longitude);
                end;
            6 .. 11:
                begin
                    Status := Which - 6;
                    LocationStatus := Status;
                    Location.Status := LocationStatus;
                    Answer := StrSubstNo('%1|%2', Format(Location.Status), Format(Location.Status.GetHashCode()));
                end;
            12:
                begin
                    Status := 9;
                    LocationStatus := Status;
                    Location.Status := LocationStatus;
                    Answer := Format(Location.Status);
                end;
            13:
                Answer := Format(Location.Status);
            14:
                Answer := Location.ToString();
        end;
    end;

    local procedure LocationCase(Name: Text; Which: Integer)
    var
        Answer: Text;
    begin
        if TryLocation(Which, Answer) then
            Obs.Observe(Name, Answer)
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure Location_Mock_Build()
    begin
        LocationCase('lat_long_1_5_2_5', 1);
        LocationCase('lat_long_minus_90_180', 2);
        LocationCase('lat_long_default', 3);
        LocationCase('coordinate_never_set_is_null', 4);
        LocationCase('lat_long_out_of_range', 5);
        LocationCase('status_0', 6);
        LocationCase('status_1', 7);
        LocationCase('status_2', 8);
        LocationCase('status_3', 9);
        LocationCase('status_4', 10);
        LocationCase('status_5', 11);
        LocationCase('status_9', 12);
        LocationCase('status_default', 13);
        LocationCase('to_string', 14);
        Obs.Expect('lat_long_1_5_2_5', '1.5/2.5');
        Obs.Expect('lat_long_minus_90_180', '-90/180');
        Obs.Expect('lat_long_default', '0/0');
        Obs.Expect('coordinate_never_set_is_null', 'Yes');
        Obs.Expect('lat_long_out_of_range', '91/181');
        Obs.Expect('status_0', 'Available|0');
        Obs.Expect('status_1', 'NoData|1');
        Obs.Expect('status_2', 'TimedOut|2');
        Obs.Expect('status_3', 'NotAvailable|3');
        Obs.Expect('status_4', '4|4');
        Obs.Expect('status_5', '5|5');
        Obs.Expect('status_9', '9');
        Obs.Expect('status_default', 'Available');
        Obs.Expect('to_string', 'Microsoft.Dynamics.Nav.Client.Capabilities.Location');
        Obs.Verify();
    end;


    [TryFunction]
    local procedure TryOptions(var O: DotNet LtY71LocationOptions; Which: Integer)
    begin
        case Which of
            1:
                O.EnableHighAccuracy := true;
            2:
                O.Timeout := 600000;
            3:
                O.Timeout := 0;
            4:
                O.Timeout := -1;
            5:
                O.MaximumAge := 1000;
            6:
                O.MaximumAge := 0;
            7:
                O.EnableHighAccuracy(false);
            8:
                O.Timeout(300000);
            9:
                O.MaximumAge(2000);
            10:
                O.EnableHighAccuracy(true);
        end;
    end;

    local procedure OptionsState(O: DotNet LtY71LocationOptions): Text
    begin
        exit(StrSubstNo('EnableHighAccuracy=%1 Timeout=%2 MaximumAge=%3', O.EnableHighAccuracy, O.Timeout, O.MaximumAge));
    end;

    local procedure SetOptions(Name: Text; var O: DotNet LtY71LocationOptions; Which: Integer)
    begin
        if TryOptions(O, Which) then
            Obs.Observe(Name, OptionsState(O))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure LocationOptions_Properties()
    var
        O: DotNet LtY71LocationOptions;
    begin
        O := O.LocationOptions();
        Obs.Observe('defaults', OptionsState(O));
        SetOptions('high_accuracy_true', O, 1);
        SetOptions('timeout_600000', O, 2);
        SetOptions('timeout_0', O, 3);
        SetOptions('timeout_minus_1', O, 4);
        SetOptions('maximum_age_1000', O, 5);
        SetOptions('maximum_age_0', O, 6);
        SetOptions('high_accuracy_method_false', O, 7);
        SetOptions('timeout_method_300000', O, 8);
        SetOptions('maximum_age_method_2000', O, 9);
        SetOptions('high_accuracy_method_true', O, 10);
        Obs.Expect('defaults', 'EnableHighAccuracy=No Timeout=0 MaximumAge=0');
        Obs.Expect('high_accuracy_true', 'EnableHighAccuracy=Yes Timeout=0 MaximumAge=0');
        Obs.Expect('timeout_600000', 'EnableHighAccuracy=Yes Timeout=600000 MaximumAge=0');
        Obs.Expect('timeout_0', 'EnableHighAccuracy=Yes Timeout=0 MaximumAge=0');
        Obs.Expect('timeout_minus_1', 'EnableHighAccuracy=Yes Timeout=-1 MaximumAge=0');
        Obs.Expect('maximum_age_1000', 'EnableHighAccuracy=Yes Timeout=-1 MaximumAge=1000');
        Obs.Expect('maximum_age_0', 'EnableHighAccuracy=Yes Timeout=-1 MaximumAge=0');
        Obs.Expect('high_accuracy_method_false', 'EnableHighAccuracy=No Timeout=-1 MaximumAge=0');
        Obs.Expect('timeout_method_300000', 'EnableHighAccuracy=No Timeout=300000 MaximumAge=0');
        Obs.Expect('maximum_age_method_2000', 'EnableHighAccuracy=No Timeout=300000 MaximumAge=2000');
        Obs.Expect('high_accuracy_method_true', 'EnableHighAccuracy=Yes Timeout=300000 MaximumAge=2000');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryProvider(Which: Integer; var Answer: Text)
    var
        LocalOptions: DotNet LtY71LocationOptions;
        CameraOptions: DotNet LtY71CameraOptions;
    begin
        case Which of
            1:
                Answer := Format(GlobalLocationProvider.IsAvailable());
            2:
                Answer := Format(GlobalCameraProvider.IsAvailable());
            3:
                begin
                    GlobalLocationProvider := GlobalLocationProvider.Create();
                    Answer := Format(IsNull(GlobalLocationProvider));
                end;
            4:
                begin
                    GlobalLocationProvider := GlobalLocationProvider.Create();
                    Answer := Format(GlobalLocationProvider.IsAvailable());
                end;
            5:
                begin
                    GlobalCameraProvider := GlobalCameraProvider.Create();
                    Answer := Format(IsNull(GlobalCameraProvider));
                end;
            6:
                begin
                    GlobalCameraProvider := GlobalCameraProvider.Create();
                    Answer := Format(GlobalCameraProvider.IsAvailable());
                end;
            7:
                begin
                    LocalOptions := LocalOptions.LocationOptions();
                    GlobalLocationProvider := GlobalLocationProvider.Create();
                    GlobalLocationProvider.RequestLocationAsync(LocalOptions);
                    Answer := 'requested';
                end;
            8:
                begin
                    CameraOptions := CameraOptions.CameraOptions();
                    GlobalCameraProvider := GlobalCameraProvider.Create();
                    GlobalCameraProvider.RequestPictureAsync(CameraOptions);
                    Answer := 'requested';
                end;
        end;
    end;

    local procedure ProviderCase(Name: Text; Which: Integer)
    var
        Answer: Text;
    begin
        if TryProvider(Which, Answer) then
            Obs.Observe(Name, Answer)
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure LocationProvider_IsAvailable_NotCreated()
    begin
        ProviderCase('location_provider_is_available', 1);
        ProviderCase('camera_provider_is_available', 2);
        Obs.Expect('location_provider_is_available', 'No');
        Obs.Expect('camera_provider_is_available', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure Providers_Create_NotRunOnClient()
    begin
        ProviderCase('location_create', 3);
        ProviderCase('location_create_is_available', 4);
        ProviderCase('camera_create', 5);
        ProviderCase('camera_create_is_available', 6);
        ProviderCase('location_request_async', 7);
        ProviderCase('camera_request_async', 8);
        Obs.Expect('location_create', 'Yes');
        Obs.Expect('location_create_is_available', 'No');
        Obs.Expect('camera_create', 'Yes');
        Obs.Expect('camera_create_is_available', 'No');
        Obs.Expect('location_request_async', 'error');
        Obs.Expect('location_request_async|text', 'A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider.RequestLocationAsync in CodeUnit LT Y71 Client Capabilities: TryProvider');
        Obs.Expect('location_request_async|code', 'DotNetVariableNotCreated');
        Obs.Expect('camera_request_async', 'error');
        Obs.Expect('camera_request_async|text', 'A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider.RequestPictureAsync in CodeUnit LT Y71 Client Capabilities: TryProvider');
        Obs.Expect('camera_request_async|code', 'DotNetVariableNotCreated');
        Obs.Verify();
    end;
}
