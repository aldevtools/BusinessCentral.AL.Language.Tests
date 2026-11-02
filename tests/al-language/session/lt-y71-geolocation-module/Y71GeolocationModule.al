// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); System Application Test Library (Geolocation Test Library 135028); test codeunit 93836 (writer Y71, gap cycle 7 spec G7-09 steps LO2, LO3, LP1)
// Probe: the System Application Geolocation module in a test session, through its public codeunit only: the defaults and setters (high accuracy, timeout,
//        maximum age) with edge values, IsAvailable without a mock, and the module with the Geolocation Test Library bound as the Microsoft tests use it
//        (SetLocationAvailability, SetGeolocationStatus with every enum member, RequestGeolocation, HasGeolocation, GetGeolocation,
//        GetGeolocationStatus, GetMockGeolocation) including GetGeolocation before any request.
//        Per call: the returned value or the error text and code. The module builds the DotNet objects Location, Coordinate, LocationOptions and
//        LocationProvider on the server, so these values also pin that surface.

codeunit 93836 "LT Y71 Geolocation Module"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryRequest(var Geo: Codeunit Geolocation; var Answer: Boolean)
    begin
        Answer := Geo.RequestGeolocation();
    end;

    [TryFunction]
    local procedure TryIsAvailable(var Geo: Codeunit Geolocation; var Answer: Boolean)
    begin
        Answer := Geo.IsAvailable();
    end;

    [TryFunction]
    local procedure TryGet(var Geo: Codeunit Geolocation; var Latitude: Decimal; var Longitude: Decimal)
    begin
        Geo.GetGeolocation(Latitude, Longitude);
    end;

    local procedure Request(Name: Text; var Geo: Codeunit Geolocation)
    var
        Answer: Boolean;
    begin
        if TryRequest(Geo, Answer) then
            Obs.Observe(Name, Format(Answer))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    local procedure Available(Name: Text; var Geo: Codeunit Geolocation)
    var
        Answer: Boolean;
    begin
        if TryIsAvailable(Geo, Answer) then
            Obs.Observe(Name, Format(Answer))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    local procedure GetPosition(Name: Text; var Geo: Codeunit Geolocation)
    var
        Latitude: Decimal;
        Longitude: Decimal;
    begin
        if TryGet(Geo, Latitude, Longitude) then
            Obs.Observe(Name, StrSubstNo('%1/%2', Latitude, Longitude))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure Geolocation_Options_DefaultsAndSetters()
    var
        Geo: Codeunit Geolocation;
    begin
        Obs.Observe('default_high_accuracy', Format(Geo.GetHighAccuracy()));
        Obs.Observe('default_timeout', Format(Geo.GetTimeout()));
        Obs.Observe('default_maximum_age', Format(Geo.GetMaximumAge()));
        Geo.SetHighAccuracy(true);
        Obs.Observe('high_accuracy_true', Format(Geo.GetHighAccuracy()));
        Geo.SetHighAccuracy(false);
        Obs.Observe('high_accuracy_false', Format(Geo.GetHighAccuracy()));
        Geo.SetTimeout(600000);
        Obs.Observe('timeout_600000', Format(Geo.GetTimeout()));
        Geo.SetTimeout(0);
        Obs.Observe('timeout_0', Format(Geo.GetTimeout()));
        Geo.SetTimeout(-1);
        Obs.Observe('timeout_minus_1', Format(Geo.GetTimeout()));
        Geo.SetMaximumAge(1000);
        Obs.Observe('maximum_age_1000', Format(Geo.GetMaximumAge()));
        Geo.SetMaximumAge(0);
        Obs.Observe('maximum_age_0', Format(Geo.GetMaximumAge()));
        Geo.SetMaximumAge(-5);
        Obs.Observe('maximum_age_minus_5', Format(Geo.GetMaximumAge()));
        Obs.Finish();
    end;

    [Test]
    procedure Geolocation_WithoutMock_IsAvailableAndRequest()
    var
        Geo: Codeunit Geolocation;
    begin
        Available('is_available', Geo);
        Obs.Observe('has_geolocation', Format(Geo.HasGeolocation()));
        Obs.Observe('status', Format(Geo.GetGeolocationStatus()));
        Request('request', Geo);
        Obs.Observe('has_geolocation_after', Format(Geo.HasGeolocation()));
        GetPosition('get_geolocation', Geo);
        Obs.Finish();
    end;

    [Test]
    procedure Geolocation_WithMock_AvailableStatus()
    var
        Geo: Codeunit Geolocation;
        Lib: Codeunit "Geolocation Test Library";
        Latitude: Decimal;
        Longitude: Decimal;
    begin
        BindSubscription(Lib);
        Lib.SetLocationAvailability(true);
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::Available);
        Available('is_available', Geo);
        Obs.Observe('has_before', Format(Geo.HasGeolocation()));
        GetPosition('get_before_request', Geo);
        Request('request', Geo);
        Obs.Observe('has_after', Format(Geo.HasGeolocation()));
        Obs.Observe('status_after', Format(Geo.GetGeolocationStatus()));
        GetPosition('get_after_request', Geo);
        Lib.GetMockGeolocation(Latitude, Longitude);
        Obs.Observe('mock_position', StrSubstNo('%1/%2', Latitude, Longitude));
        UnbindSubscription(Lib);
        Obs.Finish();
    end;

    [Test]
    procedure Geolocation_WithMock_EveryStatus()
    var
        Geo: Codeunit Geolocation;
        Lib: Codeunit "Geolocation Test Library";
    begin
        BindSubscription(Lib);
        Lib.SetLocationAvailability(true);
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::"No Data");
        Request('no_data|request', Geo);
        Obs.Observe('no_data|has', Format(Geo.HasGeolocation()));
        Obs.Observe('no_data|status', Format(Geo.GetGeolocationStatus()));
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::"Timed Out");
        Request('timed_out|request', Geo);
        Obs.Observe('timed_out|has', Format(Geo.HasGeolocation()));
        Obs.Observe('timed_out|status', Format(Geo.GetGeolocationStatus()));
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::"Not Available");
        Request('not_available|request', Geo);
        Obs.Observe('not_available|has', Format(Geo.HasGeolocation()));
        Obs.Observe('not_available|status', Format(Geo.GetGeolocationStatus()));
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::Available);
        Request('available_again|request', Geo);
        Obs.Observe('available_again|has', Format(Geo.HasGeolocation()));
        UnbindSubscription(Lib);
        Obs.Finish();
    end;

    [Test]
    procedure Geolocation_WithMock_NotAvailable()
    var
        Geo: Codeunit Geolocation;
        Lib: Codeunit "Geolocation Test Library";
    begin
        BindSubscription(Lib);
        Lib.SetLocationAvailability(false);
        Lib.SetGeolocationStatus(Enum::"Geolocation Status"::Available);
        Available('is_available', Geo);
        Request('request', Geo);
        Obs.Observe('has_after', Format(Geo.HasGeolocation()));
        Obs.Observe('status_after', Format(Geo.GetGeolocationStatus()));
        GetPosition('get_after_request', Geo);
        UnbindSubscription(Lib);
        Obs.Finish();
    end;
}
