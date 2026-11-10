// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-lookupmode-method
// Scope: in-scope (Cloud). ModalPageHandler with a TestPage.
// local object: the page type of each page is what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63450, pages 63451 to 63455, test codeunit 63459
// Probe (al-runner issue 5029): what TestPage.Editable(), a Rec-bound control's Editable() and a page-variable control's Editable() answer on a
//   page run modally from a Page variable with LookupMode(true) and with LookupMode(false), for the page types codeunit 68024 "CER Tests"
//   (testpage/TestPageControlEditableRoutes.al: List, Card, Worksheet, Document, ListPlus) did not measure: ListPart, CardPart, StandardDialog,
//   NavigatePage and ConfirmationDialog.
// BC versions: 27, 28, 29

table 63450 "PNL LE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 63451 "PNL LE List Part"
{
    PageType = ListPart;
    SourceTable = "PNL LE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }
    }

    var
        Note: Text[30];
}

page 63452 "PNL LE Card Part"
{
    PageType = CardPart;
    SourceTable = "PNL LE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }
    }

    var
        Note: Text[30];
}

page 63453 "PNL LE Dialog"
{
    PageType = StandardDialog;
    SourceTable = "PNL LE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }
    }

    var
        Note: Text[30];
}

page 63454 "PNL LE Navigate"
{
    PageType = NavigatePage;
    SourceTable = "PNL LE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }
    }

    var
        Note: Text[30];
}

page 63455 "PNL LE Confirm"
{
    PageType = ConfirmationDialog;
    SourceTable = "PNL LE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }
    }

    var
        Note: Text[30];
}

codeunit 63459 "PNL Lookup Editable Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Prefix: Text;

    local procedure Initialize()
    var
        Row: Record "PNL LE Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Row."Code" := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'bravo';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('ListPartHandler')]
    procedure ListPart_LookupModeTrueAndFalse_Editable()
    var
        LookupPage: Page "PNL LE List Part";
        PlainPage: Page "PNL LE List Part";
        Result: Action;
    begin
        Initialize();
        Prefix := 'lookup';
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('lookup action', Format(Result));
        Prefix := 'plain';
        PlainPage.LookupMode(false);
        Result := PlainPage.RunModal();
        Observer.Observe('plain action', Format(Result));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ListPartHandler(var P: TestPage "PNL LE List Part")
    begin
        Observer.Observe(Prefix, 'page=' + Format(P.Editable()) + ' rec control=' + Format(P.Name.Editable()) + ' variable control=' + Format(P.NoteCtl.Editable()) + ' row=' + P.Name.Value());
    end;

    [Test]
    [HandlerFunctions('CardPartHandler')]
    procedure CardPart_LookupModeTrueAndFalse_Editable()
    var
        LookupPage: Page "PNL LE Card Part";
        PlainPage: Page "PNL LE Card Part";
        Result: Action;
    begin
        Initialize();
        Prefix := 'lookup';
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('lookup action', Format(Result));
        Prefix := 'plain';
        PlainPage.LookupMode(false);
        Result := PlainPage.RunModal();
        Observer.Observe('plain action', Format(Result));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure CardPartHandler(var P: TestPage "PNL LE Card Part")
    begin
        Observer.Observe(Prefix, 'page=' + Format(P.Editable()) + ' rec control=' + Format(P.Name.Editable()) + ' variable control=' + Format(P.NoteCtl.Editable()) + ' row=' + P.Name.Value());
    end;

    [Test]
    [HandlerFunctions('StandardDialogHandler')]
    procedure StandardDialog_LookupModeTrueAndFalse_Editable()
    var
        LookupPage: Page "PNL LE Dialog";
        PlainPage: Page "PNL LE Dialog";
        Result: Action;
    begin
        Initialize();
        Prefix := 'lookup';
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('lookup action', Format(Result));
        Prefix := 'plain';
        PlainPage.LookupMode(false);
        Result := PlainPage.RunModal();
        Observer.Observe('plain action', Format(Result));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure StandardDialogHandler(var P: TestPage "PNL LE Dialog")
    begin
        Observer.Observe(Prefix, 'page=' + Format(P.Editable()) + ' rec control=' + Format(P.Name.Editable()) + ' variable control=' + Format(P.NoteCtl.Editable()) + ' row=' + P.Name.Value());
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    procedure NavigatePage_LookupModeTrueAndFalse_Editable()
    var
        LookupPage: Page "PNL LE Navigate";
        PlainPage: Page "PNL LE Navigate";
        Result: Action;
    begin
        Initialize();
        Prefix := 'lookup';
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('lookup action', Format(Result));
        Prefix := 'plain';
        PlainPage.LookupMode(false);
        Result := PlainPage.RunModal();
        Observer.Observe('plain action', Format(Result));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure NavigatePageHandler(var P: TestPage "PNL LE Navigate")
    begin
        Observer.Observe(Prefix, 'page=' + Format(P.Editable()) + ' rec control=' + Format(P.Name.Editable()) + ' variable control=' + Format(P.NoteCtl.Editable()) + ' row=' + P.Name.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmationDialogHandler')]
    procedure ConfirmationDialog_LookupModeTrueAndFalse_Editable()
    var
        LookupPage: Page "PNL LE Confirm";
        PlainPage: Page "PNL LE Confirm";
        Result: Action;
    begin
        Initialize();
        Prefix := 'lookup';
        LookupPage.LookupMode(true);
        Result := LookupPage.RunModal();
        Observer.Observe('lookup action', Format(Result));
        Prefix := 'plain';
        PlainPage.LookupMode(false);
        Result := PlainPage.RunModal();
        Observer.Observe('plain action', Format(Result));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ConfirmationDialogHandler(var P: TestPage "PNL LE Confirm")
    begin
        Observer.Observe(Prefix, 'page=' + Format(P.Editable()) + ' rec control=' + Format(P.Name.Editable()) + ' variable control=' + Format(P.NoteCtl.Editable()) + ' row=' + P.Name.Value());
    end;
}
