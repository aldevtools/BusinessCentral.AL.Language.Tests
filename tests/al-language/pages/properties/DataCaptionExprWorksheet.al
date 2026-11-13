// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76420-76428 (DCW Row, DCW Row WS, DCW Log, DCW Worksheet DI, DCW Worksheet,
//   DCW Card, DCW Opener, DCW Subscriber, DCW Tests)
// Probe: from al-runner issue 6924 (an outside reporter's suite). An event subscriber does Reset, SetRange on one field and Page.Run(0, Rec)
//   on a table whose LookupPageId is a Worksheet with DelayedInsert; the view is empty. The page's DataCaptionExpression calls a procedure
//   that fills page globals from Rec.GetFilter (only when Rec.GetFilters is not empty); header controls show those globals; the page has no
//   OnAfterGetRecord or OnAfterGetCurrRecord and its OnOpenPage sets CurrPage.Editable. The PageHandler reads the controls once.
//   DataCaptionExprOrder.al measured a Card page without DelayedInsert; this file adds the Worksheet, DelayedInsert on and off, the Card
//   twin with DelayedInsert, Page.Run(0, Rec) against Page.Run(Page::X, Rec), the subscriber against a direct call, an empty view against
//   one row, a filter on another field, CurrPage.Editable true, false or not set, and Page.RunModal(0, Rec).
// Log: OnInit, OnOpenPage, every evaluation of the expression ("DC", with Rec.GetFilters and the key of Rec), what the handler reads ("H":
//   caption, both filter controls), OnQueryClosePage, and "after run" once Page.Run returned.
// local object: the page shapes are what the test checks.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0

table 76420 "DCW Row"
{
    DataClassification = CustomerContent;
    LookupPageId = "DCW Worksheet DI";

    fields
    {
        field(1; "Item No."; Code[20]) { }
        field(2; "Vendor No."; Code[20]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Item No.", "Vendor No.") { Clustered = true; }
    }
}

table 76421 "DCW Row WS"
{
    DataClassification = CustomerContent;
    LookupPageId = "DCW Worksheet";

    fields
    {
        field(1; "Item No."; Code[20]) { }
        field(2; "Vendor No."; Code[20]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Item No.", "Vendor No.") { Clustered = true; }
    }
}

codeunit 76422 "DCW Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        EditableMode: Text;

    procedure Wipe()
    begin
        Clear(Lines);
        EditableMode := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure SetEditableMode(NewMode: Text)
    begin
        EditableMode := NewMode;
    end;

    procedure GetEditableMode(): Text
    begin
        exit(EditableMode);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

page 76423 "DCW Worksheet DI"
{
    PageType = Worksheet;
    SourceTable = "DCW Row";
    Caption = 'DCW WS DI';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(VendNoFilterCtl; VendNoFilter) { ApplicationArea = All; }
                field(ItemNoFilterCtl; ItemNoFilter) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(ItemNoCtl; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNoCtl; Rec."Vendor No.") { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCW Log";
        VendNoFilter: Text[250];
        ItemNoFilter: Text[250];

    local procedure GetCaption(): Text[250]
    begin
        GetRecFilters();
        Log.Add('DC(filters=' + Rec.GetFilters + ' rec=' + Rec."Item No." + '/' + Rec."Vendor No." + ')');
        exit('Cap ' + ItemNoFilter + '/' + VendNoFilter);
    end;

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters <> '' then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
        end;
    end;

    trigger OnInit()
    begin
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage(item=' + ItemNoFilter + ')');
        case Log.GetEditableMode() of
            'true':
                CurrPage.Editable := true;
            'false':
                CurrPage.Editable := false;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('OnQueryClosePage');
        exit(true);
    end;
}

page 76424 "DCW Worksheet"
{
    PageType = Worksheet;
    SourceTable = "DCW Row WS";
    Caption = 'DCW WS';
    DataCaptionExpression = GetCaption();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(VendNoFilterCtl; VendNoFilter) { ApplicationArea = All; }
                field(ItemNoFilterCtl; ItemNoFilter) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(ItemNoCtl; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNoCtl; Rec."Vendor No.") { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCW Log";
        VendNoFilter: Text[250];
        ItemNoFilter: Text[250];

    local procedure GetCaption(): Text[250]
    begin
        GetRecFilters();
        Log.Add('DC(filters=' + Rec.GetFilters + ' rec=' + Rec."Item No." + '/' + Rec."Vendor No." + ')');
        exit('Cap ' + ItemNoFilter + '/' + VendNoFilter);
    end;

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters <> '' then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
        end;
    end;

    trigger OnInit()
    begin
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage(item=' + ItemNoFilter + ')');
        case Log.GetEditableMode() of
            'true':
                CurrPage.Editable := true;
            'false':
                CurrPage.Editable := false;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('OnQueryClosePage');
        exit(true);
    end;
}

page 76425 "DCW Card"
{
    PageType = Card;
    SourceTable = "DCW Row";
    Caption = 'DCW Card';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(VendNoFilterCtl; VendNoFilter) { ApplicationArea = All; }
                field(ItemNoFilterCtl; ItemNoFilter) { ApplicationArea = All; }
            }
            group(General)
            {
                field(ItemNoCtl; Rec."Item No.") { ApplicationArea = All; }
                field(VendorNoCtl; Rec."Vendor No.") { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCW Log";
        VendNoFilter: Text[250];
        ItemNoFilter: Text[250];

    local procedure GetCaption(): Text[250]
    begin
        GetRecFilters();
        Log.Add('DC(filters=' + Rec.GetFilters + ' rec=' + Rec."Item No." + '/' + Rec."Vendor No." + ')');
        exit('Cap ' + ItemNoFilter + '/' + VendNoFilter);
    end;

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters <> '' then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
        end;
    end;

    trigger OnInit()
    begin
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage(item=' + ItemNoFilter + ')');
        case Log.GetEditableMode() of
            'true':
                CurrPage.Editable := true;
            'false':
                CurrPage.Editable := false;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('OnQueryClosePage');
        exit(true);
    end;
}

codeunit 76426 "DCW Opener"
{
    // Raises the event the subscriber answers by opening a page; Target: 'WSDI0' Page.Run(0) on DCW Row, 'WSDIX' Page.Run(Page::"DCW Worksheet DI"),
    // 'WSX' Page.Run(Page::"DCW Worksheet") on DCW Row WS, 'CARDX' Page.Run(Page::"DCW Card"), 'WSDIM0' Page.RunModal(0).
    procedure Open(Target: Text; FieldName: Text; FilterValue: Code[20])
    var
        Handled: Boolean;
    begin
        OnOpenLines(Target, FieldName, FilterValue, Handled);
        if not Handled then
            Error('not handled');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenLines(Target: Text; FieldName: Text; FilterValue: Code[20]; var Handled: Boolean)
    begin
    end;
}

codeunit 76427 "DCW Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DCW Opener", 'OnOpenLines', '', false, false)]
    local procedure OpenLines(Target: Text; FieldName: Text; FilterValue: Code[20]; var Handled: Boolean)
    var
        Row: Record "DCW Row";
        RowWs: Record "DCW Row WS";
    begin
        Handled := true;
        if Target = 'WSX' then begin
            RowWs.Reset();
            if FieldName = 'Item' then
                RowWs.SetRange("Item No.", FilterValue)
            else
                RowWs.SetRange("Vendor No.", FilterValue);
            Page.Run(Page::"DCW Worksheet", RowWs);
            exit;
        end;
        Row.Reset();
        if FieldName = 'Item' then
            Row.SetRange("Item No.", FilterValue)
        else
            Row.SetRange("Vendor No.", FilterValue);
        case Target of
            'WSDI0':
                Page.Run(0, Row);
            'WSDIX':
                Page.Run(Page::"DCW Worksheet DI", Row);
            'CARDX':
                Page.Run(Page::"DCW Card", Row);
            'WSDIM0':
                Page.RunModal(0, Row);
        end;
    end;
}

codeunit 76428 "DCW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "DCW Log";

    local procedure Seed(WithRow: Boolean)
    var
        Row: Record "DCW Row";
        RowWs: Record "DCW Row WS";
    begin
        Row.DeleteAll();
        RowWs.DeleteAll();
        Log.Wipe();
        if not WithRow then
            exit;
        Row."Item No." := 'I1';
        Row."Vendor No." := 'V1';
        Row.Amount := 5;
        Row.Insert();
        RowWs."Item No." := 'I1';
        RowWs."Vendor No." := 'V1';
        RowWs.Amount := 5;
        RowWs.Insert();
    end;

    local procedure RunOpener(Target: Text; FieldName: Text; FilterValue: Code[20]): Text
    var
        Opener: Codeunit "DCW Opener";
    begin
        Opener.Open(Target, FieldName, FilterValue);
        Log.Add('after run');
        exit(Log.Joined());
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The reported shape: empty view, SetRange on Item No., Page.Run(0, Rec) from a subscriber, OnOpenPage sets CurrPage.Editable := true.
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDI0', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_EmptyView_VendorFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDI0', 'Vendor', 'V9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_OneRow_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDI0', 'Item', 'I1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_EmptyView_EditableFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Log.SetEditableMode('false');
        Observer.Observe('log', RunOpener('WSDI0', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_OneRow_EditableFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Log.SetEditableMode('false');
        Observer.Observe('log', RunOpener('WSDI0', 'Item', 'I1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsHandler')]
    procedure Ws_RunPageId_Subscriber_EmptyView_EditableFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Log.SetEditableMode('false');
        Observer.Observe('log', RunOpener('WSX', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_RunPageId_Subscriber_EmptyView_EditableNotSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Observer.Observe('log', RunOpener('CARDX', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Subscriber_EmptyView_EditableNotSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Observer.Observe('log', RunOpener('WSDI0', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_RunPageId_Subscriber_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDIX', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_RunPageId_Subscriber_OneRow_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDIX', 'Item', 'I1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiHandler')]
    procedure WsDi_Run0_Direct_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCW Row";
    begin
        // The same page opened by the test itself, no subscriber in between.
        Seed(false);
        Log.SetEditableMode('true');
        Row.SetRange("Item No.", 'I9');
        Page.Run(0, Row);
        Log.Add('after run');
        Observer.Observe('log', Log.Joined());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsDiModalHandler')]
    procedure WsDi_RunModal0_Subscriber_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSDIM0', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsHandler')]
    procedure Ws_RunPageId_Subscriber_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Worksheet without DelayedInsert.
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSX', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsHandler')]
    procedure Ws_RunPageId_Subscriber_OneRow_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('WSX', 'Item', 'I1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_RunPageId_Subscriber_EmptyView_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Card with DelayedInsert, same globals and caption procedure.
        Seed(false);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('CARDX', 'Item', 'I9'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_RunPageId_Subscriber_OneRow_ItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Log.SetEditableMode('true');
        Observer.Observe('log', RunOpener('CARDX', 'Item', 'I1'));
        Observer.Finish();
    end;

    [PageHandler]
    procedure WsDiHandler(var P: TestPage "DCW Worksheet DI")
    begin
        Log.Add('H cap=' + P.Caption() + ' item=' + P.ItemNoFilterCtl.Value + ' vend=' + P.VendNoFilterCtl.Value);
    end;

    [ModalPageHandler]
    procedure WsDiModalHandler(var P: TestPage "DCW Worksheet DI")
    begin
        Log.Add('H cap=' + P.Caption() + ' item=' + P.ItemNoFilterCtl.Value + ' vend=' + P.VendNoFilterCtl.Value);
    end;

    [PageHandler]
    procedure WsHandler(var P: TestPage "DCW Worksheet")
    begin
        Log.Add('H cap=' + P.Caption() + ' item=' + P.ItemNoFilterCtl.Value + ' vend=' + P.VendNoFilterCtl.Value);
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "DCW Card")
    begin
        Log.Add('H cap=' + P.Caption() + ' item=' + P.ItemNoFilterCtl.Value + ' vend=' + P.VendNoFilterCtl.Value);
    end;
}
