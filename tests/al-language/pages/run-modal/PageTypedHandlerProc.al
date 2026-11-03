// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 71300, page 71301, log 71302
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a ModalPageHandler typed as the page (var P: Page X) that calls a procedure of the page: which page triggers run before/after the handler, and whether the handler's change to a page global survives to OnQueryClosePage and OnClosePage (observed through a log).

table 71300 "LT HandlerPage Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71302 "LT HandlerPage Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

page 71301 "LT HandlerPage List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT HandlerPage Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    var
        Marker: Text;
        CloseOk: Boolean;

    procedure SetMarker(NewMarker: Text)
    var
        Log: Codeunit "LT HandlerPage Log";
    begin
        Marker := NewMarker;
        Log.Add('SetMarker ' + NewMarker);
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetCloseOk(Value: Boolean)
    begin
        CloseOk := Value;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HandlerPage Log";
    begin
        Marker := 'open';
        CloseOk := true;
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT HandlerPage Log";
    begin
        Log.Add('OnAfterGetRecord ' + Rec.Name + ' marker=' + Marker);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT HandlerPage Log";
    begin
        Log.Add('OnQueryClosePage ' + Format(CloseAction) + ' marker=' + Marker);
        exit(CloseOk);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT HandlerPage Log";
    begin
        Log.Add('OnClosePage marker=' + Marker);
    end;
}

codeunit 71303 "LT HandlerPage Proc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT HandlerPage Log";
        Reply: Action;
        CloseOkInHandler: Boolean;
        MarkerSeenAfterCall: Text;

    local procedure Seed()
    var
        Row: Record "LT HandlerPage Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Take();
        MarkerSeenAfterCall := '';
    end;

    [ModalPageHandler]
    procedure SetMarkerHandler(var P: Page "LT HandlerPage List"; var Response: Action)
    begin
        Log.Add('handler start marker=' + P.GetMarker());
        P.SetMarker('fromHandler');
        P.SetCloseOk(CloseOkInHandler);
        MarkerSeenAfterCall := P.GetMarker();
        Log.Add('handler end');
        Response := Reply;
    end;

    [Test]
    [HandlerFunctions('SetMarkerHandler')]
    procedure RunModal_HandlerSetsMarkerAndOk_LogsTriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT HandlerPage List";
        Result: Action;
    begin
        Seed();
        Reply := Action::LookupOK;
        CloseOkInHandler := true;
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('markerInHandlerAfterCall', MarkerSeenAfterCall);
        Observer.Observe('markerAfterRunModal', P.GetMarker());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'handler start marker=;SetMarker fromHandler;handler end;');
        Observer.Expect('markerInHandlerAfterCall', 'fromHandler');
        Observer.Expect('markerAfterRunModal', 'fromHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetMarkerHandler')]
    procedure RunModal_HandlerCancels_LogsTriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT HandlerPage List";
        Result: Action;
    begin
        Seed();
        Reply := Action::LookupCancel;
        CloseOkInHandler := true;
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('markerAfterRunModal', P.GetMarker());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('log', 'handler start marker=;SetMarker fromHandler;handler end;');
        Observer.Expect('markerAfterRunModal', 'fromHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetMarkerHandler')]
    procedure RunModal_HandlerVetoesClose_LogsTriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT HandlerPage List";
        Result: Action;
    begin
        Seed();
        Reply := Action::OK;
        CloseOkInHandler := false;
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'OK');
        Observer.Expect('log', 'handler start marker=;SetMarker fromHandler;handler end;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetMarkerHandler')]
    procedure RunModal_EmptyTable_LogsTriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT HandlerPage List";
        Row: Record "LT HandlerPage Row";
        Result: Action;
    begin
        Seed();
        Row.DeleteAll();
        Reply := Action::LookupOK;
        CloseOkInHandler := true;
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'handler start marker=;SetMarker fromHandler;handler end;');
        Observer.Verify();
    end;
}
