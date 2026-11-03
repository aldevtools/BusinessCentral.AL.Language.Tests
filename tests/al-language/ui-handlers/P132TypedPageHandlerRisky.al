// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73732, page 73733, log 73734 (used only by test codeunit 73735). RISKY: a non-modal [PageHandler] whose parameter is a Page, not a TestPage; the file is dropped when BC refuses that at compile time.
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73732 "LT P132 PH Row"
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

codeunit 73734 "LT P132 PH Log"
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

page 73733 "LT P132 PH Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P132 PH Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P132 PH Log";
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P132 PH Log";
    begin
        Log.Add('AGCR' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P132 PH Log";
    begin
        Log.Add('QueryClose(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P132 PH Log";
    begin
        Log.Add('OnClosePage');
    end;
}

codeunit 73735 "LT P132 Typed PageHandler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P132 PH Log";

    [PageHandler]
    procedure TypedCardHandler(var P: Page "LT P132 PH Card")
    var
        Row: Record "LT P132 PH Row";
    begin
        P.GetRecord(Row);
        Log.Add('handler(rec=' + Format(Row.Id) + ',lookup=' + Format(P.LookupMode()) + ',editable=' + Format(P.Editable()) + ')');
    end;

    [Test]
    [HandlerFunctions('TypedCardHandler')]
    procedure P132_TypedPageHandler_PageRun_WithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P132 PH Row";
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'five';
        Row.Insert();
        Log.Take();
        Page.Run(Page::"LT P132 PH Card", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'handler(rec=5,lookup=No,editable=Yes);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedCardHandler')]
    procedure P132_TypedPageHandler_PageRun_NoRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P132 PH Row";
    begin
        Row.DeleteAll();
        Log.Take();
        Page.Run(Page::"LT P132 PH Card");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'handler(rec=0,lookup=No,editable=Yes);');
        Observer.Verify();
    end;
}
