// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-opennew-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 91430, pages 91430-91434, log 91431 (used only by test codeunit 91432)
// Probe: TestPage.OpenNew on page types other than Card and List (al-runtime-rs docs/probes-needed.md row "Whether OnInit/OnOpenPage run before the
// NotSupportedPageViewMode error of a Worksheet OpenNew; other page types in Create mode"; the Worksheet error itself is pinned in
// ImplicitCreation.al:308). A Worksheet with OnInit, OnOpenPage and OnNewRecord that log, and a ListPart, CardPart, Document and ListPlus with the
// same triggers: the error text and code (page ids masked to <id>), else which triggers ran and whether the page is editable.
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).
// Facts (BC 29 SaaS): the Worksheet raises NotSupportedPageViewMode before OnInit or OnOpenPage run (empty log). ListPart, CardPart, Document and
// ListPlus open in Create mode, editable, running OnInit, OnOpenPage, OnNewRecord in that order.

table 91430 "LT Y8 OpenNew Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 91430 "LT Y8 OpenNew Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y8 OpenNew Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Init');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('New');
    end;
}

page 91431 "LT Y8 OpenNew ListPart"
{
    PageType = ListPart;
    SourceTable = "LT Y8 OpenNew Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Init');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('New');
    end;
}

page 91432 "LT Y8 OpenNew CardPart"
{
    PageType = CardPart;
    SourceTable = "LT Y8 OpenNew Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Init');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('New');
    end;
}

page 91433 "LT Y8 OpenNew Document"
{
    PageType = Document;
    SourceTable = "LT Y8 OpenNew Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Init');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('New');
    end;
}

page 91434 "LT Y8 OpenNew ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT Y8 OpenNew Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Init');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('Open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        Log.Add('New');
    end;
}

codeunit 91431 "LT Y8 OpenNew Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 91432 "LT Y8 OpenNew Page Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Masked(Text: Text): Text
    var
        Id: Integer;
    begin
        foreach Id in Ids() do
            Text := Text.Replace('''' + Format(Id) + '''', '''<id>''');
        exit(Text);
    end;

    local procedure Ids() Result: List of [Integer]
    begin
        Result.Add(Page::"LT Y8 OpenNew Worksheet");
        Result.Add(Page::"LT Y8 OpenNew ListPart");
        Result.Add(Page::"LT Y8 OpenNew CardPart");
        Result.Add(Page::"LT Y8 OpenNew Document");
        Result.Add(Page::"LT Y8 OpenNew ListPlus");
    end;

    [TryFunction]
    local procedure TryWorksheet(var Pg: TestPage "LT Y8 OpenNew Worksheet")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryListPart(var Pg: TestPage "LT Y8 OpenNew ListPart")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryCardPart(var Pg: TestPage "LT Y8 OpenNew CardPart")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryDocument(var Pg: TestPage "LT Y8 OpenNew Document")
    begin
        Pg.OpenNew();
    end;

    [TryFunction]
    local procedure TryListPlus(var Pg: TestPage "LT Y8 OpenNew ListPlus")
    begin
        Pg.OpenNew();
    end;

    local procedure Outcome(Ok: Boolean; Editable: Text): Text
    var
        Log: Codeunit "LT Y8 OpenNew Log";
    begin
        if Ok then
            exit('ok editable=' + Editable + ' log=' + Log.Take());
        exit('ERR:' + Masked(GetLastErrorText()) + '/' + GetLastErrorCode() + ' log=' + Log.Take());
    end;

    [Test]
    procedure Y8_OpenNew_Worksheet_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y8 OpenNew Log";
        Pg: TestPage "LT Y8 OpenNew Worksheet";
        Ok: Boolean;
    begin
        Log.Take();
        Ok := TryWorksheet(Pg);
        Observer.Observe('worksheet', Outcome(Ok, ''));
        Observer.Expect('worksheet', 'ERR:The view mode ''Create'' is not supported by the page ID ''<id>''./NotSupportedPageViewMode log=');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_OpenNew_ListPart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y8 OpenNew Log";
        Pg: TestPage "LT Y8 OpenNew ListPart";
        Ok: Boolean;
        Editable: Text;
    begin
        Log.Take();
        Ok := TryListPart(Pg);
        if Ok then
            Editable := Format(Pg.Editable());
        Observer.Observe('listpart', Outcome(Ok, Editable));
        Observer.Expect('listpart', 'ok editable=Yes log=Init;Open;New;');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_OpenNew_CardPart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y8 OpenNew Log";
        Pg: TestPage "LT Y8 OpenNew CardPart";
        Ok: Boolean;
        Editable: Text;
    begin
        Log.Take();
        Ok := TryCardPart(Pg);
        if Ok then
            Editable := Format(Pg.Editable());
        Observer.Observe('cardpart', Outcome(Ok, Editable));
        Observer.Expect('cardpart', 'ok editable=Yes log=Init;Open;New;');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_OpenNew_Document()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y8 OpenNew Log";
        Pg: TestPage "LT Y8 OpenNew Document";
        Ok: Boolean;
        Editable: Text;
    begin
        Log.Take();
        Ok := TryDocument(Pg);
        if Ok then
            Editable := Format(Pg.Editable());
        Observer.Observe('document', Outcome(Ok, Editable));
        Observer.Expect('document', 'ok editable=Yes log=Init;Open;New;');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_OpenNew_ListPlus()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y8 OpenNew Log";
        Pg: TestPage "LT Y8 OpenNew ListPlus";
        Ok: Boolean;
        Editable: Text;
    begin
        Log.Take();
        Ok := TryListPlus(Pg);
        if Ok then
            Editable := Format(Pg.Editable());
        Observer.Observe('listplus', Outcome(Ok, Editable));
        Observer.Expect('listplus', 'ok editable=Yes log=Init;Open;New;');
        Observer.Verify();
    end;
}
