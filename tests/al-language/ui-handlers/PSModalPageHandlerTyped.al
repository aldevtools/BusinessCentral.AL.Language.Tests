// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A [ModalPageHandler] whose first parameter is typed as the Page ("PS Modal List"), not as a TestPage, is accepted. It receives the page object the code ran with Page.RunModal:
// GetRecord gives the record RunModal was given (2/two; an empty record when none was given), LookupMode is Yes, SetRecord / GetRecord work on it, and Response arrives as
// None; the value the handler leaves in Response is what Page.RunModal answers (LookupOK, Cancel).
// Fixtures used: self-contained table 69545, codeunit 69556 (log), page 69551, codeunit 69557
// BC versions: 27.5

table 69545 "PS Modal Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69556 "PS Modal Log"
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
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 69551 "PS Modal List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "PS Modal Row";

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
}

codeunit 69557 "PS Modal Typed Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ResponseToGive: Action;

    local procedure Seed()
    var
        Row: Record "PS Modal Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('TypedHandler')]
    procedure ModalPageHandler_TypedPageParameter_LookupOK()
    var
        Row: Record "PS Modal Row";
        Log: Codeunit "PS Modal Log";
        Result: Action;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        ResponseToGive := Action::LookupOK;
        Row.Get(2);
        Result := Page.RunModal(Page::"PS Modal List", Row);
        Observer.Observe('run_modal_result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_modal_result', 'LookupOK');
        Observer.Expect('log', 'record=2/two;lookupmode=Yes;after setrecord=1;response_before=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedHandler')]
    procedure ModalPageHandler_TypedPageParameter_Cancel()
    var
        Row: Record "PS Modal Row";
        Log: Codeunit "PS Modal Log";
        Result: Action;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        ResponseToGive := Action::Cancel;
        Result := Page.RunModal(Page::"PS Modal List", Row);
        Observer.Observe('run_modal_result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_modal_result', 'Cancel');
        Observer.Expect('log', 'record=0/;lookupmode=Yes;after setrecord=1;response_before=None;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure TypedHandler(var P: Page "PS Modal List"; var Response: Action)
    var
        Row: Record "PS Modal Row";
        Log: Codeunit "PS Modal Log";
    begin
        P.GetRecord(Row);
        Log.Add('record=' + Format(Row.Id) + '/' + Row.Name);
        Log.Add('lookupmode=' + Format(P.LookupMode()));
        Row.Get(1);
        P.SetRecord(Row);
        P.GetRecord(Row);
        Log.Add('after setrecord=' + Format(Row.Id));
        Log.Add('response_before=' + Format(Response));
        Response := ResponseToGive;
    end;
}
