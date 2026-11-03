// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer, and an assembly probing path that finds Microsoft.Dynamics.Nav.ClientExtensions
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained pages 99132-99136 and codeunit 99130
// RISKY (compile, runtime): client add-in types on a page run on the client; a test has no client. What a test sees is observed.
//
// The client triggers PageNotifier::PageReady, UserTours::IsTourInProgressResultReady, UserTours::ShowTourWizard, Tour::TourEnded, Tour::SpotlightTourEnded, CameraProvider::PictureAvailable and
// LocationProvider::LocationChanged: whether any of them fires when a test opens the page, and what a page does that declares the variables without handlers.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.PageNotifier"; LtAlPageNotifier) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.UserTours"; LtAlUserTours) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Tour"; LtAlTour) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.SpotlightTour"; LtAlSpotlightTour) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraProvider"; LtAlCameraProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.LocationProvider"; LtAlLocationProvider) { }
        type("Microsoft.Dynamics.Nav.Client.Capabilities.Location"; LtAlLocation) { }
    }
}

codeunit 99130 "LT AL Client Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;
}

page 99132 "LT AL Notifier Tours Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet LtAlUserTours;
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet LtAlPageNotifier;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('open tours available=' + Format(UserTours.IsAvailable()));
    end;

    trigger UserTours::ShowTourWizard(hasTourCompleted: Boolean)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('ShowTourWizard ' + Format(hasTourCompleted));
    end;

    trigger UserTours::IsTourInProgressResultReady(isInProgress: Boolean)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('IsTourInProgressResultReady ' + Format(isInProgress));
    end;

    trigger PageNotifier::PageReady()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('PageReady');
    end;
}

page 99133 "LT AL Tour Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        Tour: DotNet LtAlTour;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('open tour available=' + Format(Tour.IsAvailable()));
    end;

    trigger Tour::TourEnded(PageId: Integer; Completed: Boolean; Data: Text)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add(StrSubstNo('TourEnded %1 %2 %3', PageId, Completed, Data));
    end;

    trigger Tour::SpotlightTourEnded(PageId: Integer; SpotlightTour: DotNet LtAlSpotlightTour; Completed: Boolean; Data: Text)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add(StrSubstNo('SpotlightTourEnded %1 %2 %3', PageId, Completed, Data));
    end;
}

page 99134 "LT AL Camera Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        CameraProvider: DotNet LtAlCameraProvider;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('open camera available=' + Format(CameraProvider.IsAvailable()));
    end;

    trigger CameraProvider::PictureAvailable(PictureName: Text; PictureFilePath: Text)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('PictureAvailable ' + PictureName);
    end;
}

page 99135 "LT AL Location Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        LocationProvider: DotNet LtAlLocationProvider;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('open location available=' + Format(LocationProvider.IsAvailable()));
    end;

    trigger LocationProvider::LocationChanged(NewLocation: DotNet LtAlLocation)
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('LocationChanged');
    end;
}

page 99136 "LT AL Client No Handler Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                Caption = 'G';
            }
        }
    }

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet LtAlPageNotifier;
        [RunOnClient]
        [WithEvents]
        Tour: DotNet LtAlTour;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AL Client Log";
    begin
        Log.Add('open without handlers');
    end;
}
