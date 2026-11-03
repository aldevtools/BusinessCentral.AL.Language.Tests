// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-add-ins
// Scope: in-scope
// Fixtures used: self-contained (71239-71241)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: control add-in without scripts may not compile in the Cloud app. DECLARED ONLY, NOT OBSERVABLE: a test cannot raise a client side add-in event; the page declares a usercontrol with a trigger for each event of the issue and the test only opens it.
// BC versions: 29 (27 and 28 by CI)

controladdin "LT P118 Addin"
{
    RequestedHeight = 100;
    RequestedWidth = 100;

    event AddInReady();
    event ControlAddInReady();
    event ControlReady();
    event Ready();
    event Refresh();
    event DataPointClicked(Point: JsonObject);
    event DataPointDoubleClicked(Point: JsonObject);
    event Callback(Name: Text; Payload: Text);
    event ResponseReceived(Response: Text);
    event ErrorOccurred(Error: Text);
    event AuthorizationCodeRetrieved(Code: Text);
    event AuthorizationErrorOccurred(Error: Text; Description: Text);
    event DashboardLoaded();
    event DashboardTileLoaded();
    event ReportLoaded();
    event ReportPageChanged(NewPage: Text);
    event ReportVisualLoaded();
    event DocumentReady();
    event BarcodeAvailable();
    event BarcodeFailure();
    event BarcodeReceived(Barcode: Text);
    event OnAcceptAction();
    event OnProfileSelected(ProfileId: Text);
    event ThumbnailClicked(Index: Integer);

    procedure Init(Value: Text);
}

codeunit 71239 "LT P118 Addin Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Total(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}

page 71240 "LT P118 Addin Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            usercontrol(Host; "LT P118 Addin")
            {
                ApplicationArea = All;

                trigger AddInReady()
                var
                    Log: Codeunit "LT P118 Addin Log";
                begin
                    Log.Add('AddInReady');
                end;

                trigger ControlAddInReady()
                var
                    Log: Codeunit "LT P118 Addin Log";
                begin
                    Log.Add('ControlAddInReady');
                end;

                trigger ControlReady()
                begin
                end;

                trigger Ready()
                begin
                end;

                trigger Refresh()
                begin
                end;

                trigger DataPointClicked(Point: JsonObject)
                begin
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger Callback(Name: Text; Payload: Text)
                begin
                end;

                trigger ResponseReceived(Response: Text)
                begin
                end;

                trigger ErrorOccurred(Error: Text)
                begin
                end;

                trigger AuthorizationCodeRetrieved(Code: Text)
                begin
                end;

                trigger AuthorizationErrorOccurred(Error: Text; Description: Text)
                begin
                end;

                trigger DashboardLoaded()
                begin
                end;

                trigger DashboardTileLoaded()
                begin
                end;

                trigger ReportLoaded()
                begin
                end;

                trigger ReportPageChanged(NewPage: Text)
                begin
                end;

                trigger ReportVisualLoaded()
                begin
                end;

                trigger DocumentReady()
                begin
                end;

                trigger BarcodeAvailable()
                begin
                end;

                trigger BarcodeFailure()
                begin
                end;

                trigger BarcodeReceived(Barcode: Text)
                begin
                end;

                trigger OnAcceptAction()
                begin
                end;

                trigger OnProfileSelected(ProfileId: Text)
                begin
                end;

                trigger ThumbnailClicked(Index: Integer)
                begin
                end;
            }
        }
    }
}

codeunit 71241 "LT P118 Addin Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P118_UserControlPage_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Addin Log";
        Card: TestPage "LT P118 Addin Page";
    begin
        Log.Reset();
        Card.OpenView();
        Observer.Observe('opened', 'yes');
        Observer.Observe('events-logged', Format(Log.Total()));
        Card.Close();
        Observer.Expect('opened', 'yes');
        Observer.Expect('events-logged', '0');
        Observer.Verify();
    end;
}
