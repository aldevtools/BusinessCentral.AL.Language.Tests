// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73310, page 73311, SingleInstance log 73312 (used only by test codeunit 73313)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// so that only this probe is lost.
// Facts: a [PageHandler] with a Page parameter only for a page opened with Page.Run: whether the handler is called, what GetRecord and Caption of the Page give inside it, what happens to the page after the handler returns
// (triggers OnInit, OnOpenPage, OnAfterGetRecord, OnClosePage that run), and the value it leaves in Response (variant with a Response parameter only).
// BC versions: 29 (27 and 28 by CI)

table 73310 "LT P129 PHB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73312 "LT P129 PHB Log"
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

page 73311 "LT P129 PHB Card"
{
    PageType = Card;
    SourceTable = "LT P129 PHB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('card OnInit');
    end;

    trigger OnOpenPage()
    begin
        L.Add('card OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        L.Add('card AGR ' + Format(Rec.Id));
    end;

    trigger OnClosePage()
    begin
        L.Add('card OnClosePage');
    end;

    var
        L: Codeunit "LT P129 PHB Log";
}

codeunit 73313 "LT P129 PHB Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 PHB Log";

    [PageHandler]
    procedure TypedPageHandler(var P: Page "LT P129 PHB Card")
    var
        Row: Record "LT P129 PHB Row";
    begin
        P.GetRecord(Row);
        L.Add('handler id=' + Format(Row.Id) + ' name=' + Row.Name);

    end;

    [Test]
    [HandlerFunctions('TypedPageHandler')]
    procedure P129_PageHandler_PageTyped_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 PHB Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        L.Take();
        Page.Run(Page::"LT P129 PHB Card", Row);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'card OnInit;handler id=1 name=one;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedPageHandler')]
    procedure P129_PageHandler_PageTyped_PageRun_NoRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 PHB Row";
    begin
        Row.DeleteAll();
        L.Take();
        Page.Run(Page::"LT P129 PHB Card");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'card OnInit;handler id=0 name=;');
        Observer.Verify();
    end;
}
