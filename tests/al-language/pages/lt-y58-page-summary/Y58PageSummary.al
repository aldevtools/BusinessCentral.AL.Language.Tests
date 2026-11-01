// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-summary-provider
// Scope: in-scope (System Application codeunit 2718 "Page Summary Provider", Access = Public, callable from a Cloud app)
// Fixtures used: Probe Observer (69160); self-contained table 93700, 93701, pages 93700-93703, codeunit 93700
// Probe: GetPageSummary(PageId), GetPageSummary(PageId, Bookmark) and GetPageSummaryBySystemID(PageId, SystemId) on own pages. The
//   field lists and values come from the server class Microsoft.Dynamics.Nav.Runtime.PageSummary.NavPageSummaryALFunctions
//   (GetSummaryFields = the Brick field group of the source table, GetAvailableTableFields = the visible page fields, GetSummary =
//   their captions, formatted values, field types and tooltips). The result is JSON text; the members "url" (server address) and
//   "version" (System Application API version) are removed before it is observed.
//   Cases: a card page with a Brick field group (value types Code, Text, Decimal, Date, Boolean, Option, Integer, Blob, a
//   hidden field), a list page with CardPageId, a page whose table has no Brick, no bookmark, an invalid bookmark, the bookmark
//   of a deleted record, an unknown SystemId, an unknown page id.
// BC versions: 27, 28, 29
table 93700 "LT Y58 Summary Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; Description; Text[50]) { Caption = 'Description'; }
        field(3; Amount; Decimal) { Caption = 'Amount'; }
        field(4; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(5; Blocked; Boolean) { Caption = 'Blocked'; }
        field(6; Kind; Option) { Caption = 'Kind'; OptionMembers = " ",Small,Large; }
        field(7; Quantity; Integer) { Caption = 'Quantity'; }
        field(8; Notes; Blob) { Caption = 'Notes'; }
        field(9; Hidden; Text[30]) { Caption = 'Hidden'; }
        field(10; "Not On Page"; Text[30]) { Caption = 'Not On Page'; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description) { }
        fieldgroup(Brick; "No.", Description, Amount, "Posting Date", Blocked, Notes) { }
    }
}

table 93701 "LT Y58 Summary Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id'; }
        field(2; Name; Text[50]) { Caption = 'Name'; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 93700 "LT Y58 Summary Card"
{
    PageType = Card;
    SourceTable = "LT Y58 Summary Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y58 Summary Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ToolTip = 'Specifies the number.'; }
                field(Description; Rec.Description) { ToolTip = 'Specifies the description.'; }
                field(Amount; Rec.Amount) { ToolTip = 'Specifies the amount.'; }
                field("Posting Date"; Rec."Posting Date") { }
                field(Blocked; Rec.Blocked) { ToolTip = 'Specifies if blocked.'; }
                field(Kind; Rec.Kind) { ToolTip = 'Specifies the kind.'; }
                field(Quantity; Rec.Quantity) { ToolTip = 'Specifies the quantity.'; }
                field(Hidden; Rec.Hidden) { Visible = false; ToolTip = 'Specifies a hidden value.'; }
                field(Computed; StrSubstNo('%1-%2', Rec."No.", Rec.Quantity)) { Caption = 'Computed'; ToolTip = 'Specifies a computed value.'; }
            }
        }
    }
}

page 93701 "LT Y58 Summary List"
{
    PageType = List;
    SourceTable = "LT Y58 Summary Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y58 Summary List';
    CardPageId = "LT Y58 Summary Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ToolTip = 'Specifies the number.'; }
                field(Description; Rec.Description) { ToolTip = 'Specifies the description.'; }
            }
        }
    }
}

page 93702 "LT Y58 Summary Plain Card"
{
    PageType = Card;
    SourceTable = "LT Y58 Summary Plain";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Y58 Summary Plain Card';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ToolTip = 'Specifies the id.'; }
            field(Name; Rec.Name) { ToolTip = 'Specifies the name.'; }
        }
    }
}

page 93703 "LT Y58 Summary No Caption"
{
    PageType = Card;
    SourceTable = "LT Y58 Summary Plain";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ToolTip = 'Specifies the name.'; }
        }
    }
}

codeunit 93700 "LT Y58 Page Summary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(Summary: Text): Text
    var
        JObject: JsonObject;
        Result: Text;
    begin
        if not JObject.ReadFrom(Summary) then
            exit('not json: ' + Summary);
        if JObject.Contains('url') then begin
            JObject.Remove('url');
            JObject.Add('url', 'present');
        end;
        if JObject.Contains('version') then begin
            JObject.Remove('version');
            JObject.Add('version', 'present');
        end;
        JObject.WriteTo(Result);
        exit(Result);
    end;

    local procedure InsertRow(var Row: Record "LT Y58 Summary Row")
    var
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'Y58-1';
        Row.Description := 'First row';
        Row.Amount := 1234.5;
        Row."Posting Date" := DMY2Date(15, 1, 2024);
        Row.Blocked := true;
        Row.Kind := Row.Kind::Large;
        Row.Quantity := 7;
        Row.Hidden := 'secret';
        Row."Not On Page" := 'elsewhere';
        Row.Notes.CreateOutStream(OutS);
        OutS.WriteText('blob text');
        Row.Insert();
    end;

    local procedure Part(Summary: Text; Name: Text): Text
    var
        JObject: JsonObject;
        JToken: JsonToken;
        Result: Text;
    begin
        if not JObject.ReadFrom(Summary) then
            exit('not json');
        if not JObject.Get(Name, JToken) then
            exit('missing');
        JToken.WriteTo(Result);
        exit(Result);
    end;

    local procedure Header(Summary: Text): Text
    var
        JObject: JsonObject;
        Result: Text;
    begin
        JObject.ReadFrom(Clean(Summary));
        if JObject.Contains('fields') then
            JObject.Remove('fields');
        if JObject.Contains('recordFields') then
            JObject.Remove('recordFields');
        JObject.WriteTo(Result);
        exit(Result);
    end;

    local procedure CardSummary(): Text
    var
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Row: Record "LT Y58 Summary Row";
    begin
        InsertRow(Row);
        exit(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", Format(Row.RecordId, 0, 10)));
    end;

    [Test]
    procedure PageSummary_Card_Header()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('card header', Header(CardSummary()));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_Card_Fields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('card fields', Part(CardSummary(), 'fields'));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_Card_RecordFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('card recordFields', Part(CardSummary(), 'recordFields'));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_Card_SystemId()
    var
        Observer: Codeunit "Probe Observer";
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Row: Record "LT Y58 Summary Row";
        ByBookmark: Text;
        BySystemId: Text;
    begin
        InsertRow(Row);
        ByBookmark := Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", Format(Row.RecordId, 0, 10)));
        BySystemId := Clean(PageSummaryProvider.GetPageSummaryBySystemID(Page::"LT Y58 Summary Card", Row.SystemId));
        Observer.Observe('by systemid equals by bookmark', Format(ByBookmark = BySystemId));
        Observer.Observe('by systemid header', Header(BySystemId));
        Observer.Observe('unknown systemid', Clean(PageSummaryProvider.GetPageSummaryBySystemID(Page::"LT Y58 Summary Card", CreateGuid())));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_List_Bookmark()
    var
        Observer: Codeunit "Probe Observer";
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Row: Record "LT Y58 Summary Row";
    begin
        InsertRow(Row);
        Observer.Observe('list', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary List", Format(Row.RecordId, 0, 10))));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_EmptyValues()
    var
        Observer: Codeunit "Probe Observer";
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Row: Record "LT Y58 Summary Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'Y58-E';
        Row.Insert();
        Observer.Observe('card empty values', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", Format(Row.RecordId, 0, 10))));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_NoBrick()
    var
        Observer: Codeunit "Probe Observer";
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Plain: Record "LT Y58 Summary Plain";
    begin
        Plain.DeleteAll();
        Plain.Id := 5;
        Plain.Name := 'Plain five';
        Plain.Insert();
        Observer.Observe('plain card', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Plain Card", Format(Plain.RecordId, 0, 10))));
        Observer.Observe('page without caption', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary No Caption", Format(Plain.RecordId, 0, 10))));
        Observer.Finish();
    end;

    [Test]
    procedure PageSummary_HeaderOnly_And_BadBookmarks()
    var
        Observer: Codeunit "Probe Observer";
        PageSummaryProvider: Codeunit "Page Summary Provider";
        Row: Record "LT Y58 Summary Row";
        Bookmark: Text;
    begin
        InsertRow(Row);
        Observer.Observe('no bookmark', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card")));
        Observer.Observe('empty bookmark', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", '')));
        Observer.Observe('invalid bookmark', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", 'not a bookmark')));
        Bookmark := Format(Row.RecordId, 0, 10);
        Row.Delete();
        Observer.Observe('deleted record bookmark', Clean(PageSummaryProvider.GetPageSummary(Page::"LT Y58 Summary Card", Bookmark)));
        Observer.Observe('unknown page, no bookmark', Clean(PageSummaryProvider.GetPageSummary(99999999)));
        Observer.Finish();
    end;
}
