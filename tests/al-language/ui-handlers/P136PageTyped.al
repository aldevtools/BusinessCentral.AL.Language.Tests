// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74347 of P136Report.al; pages 74353 74354, codeunits 74355 74356
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a ModalPageHandler with a Page-typed parameter (not a TestPage) for pages that declare OnInit, OnOpenPage, OnAfterGetRecord, OnQueryClosePage and OnClosePage: which triggers have run when the handler starts, which run afterwards, and the result of RunModal for each Response
// BC versions: 29 (27 and 28 by CI)

codeunit 74355 "LT P136 TP Log"
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

page 74353 "LT P136 TP List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P136 Item";

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
        InitDone: Boolean;

    trigger OnInit()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        InitDone := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('OnOpenPage init=' + Format(InitDone));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('OnAfterGetRecord ' + Rec.Name);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('OnQueryClosePage ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('OnClosePage');
    end;
}

page 74354 "LT P136 TP Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P136 Item";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('card OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('card OnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('card OnNewRecord');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P136 TP Log";
    begin
        Log.Add('card OnClosePage');
    end;
}

codeunit 74356 "LT P136 TP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 TP Log";
        ResponseToGive: Action;

    local procedure Seed()
    var
        Item: Record "LT P136 Item";
    begin
        Item.DeleteAll();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Insert();
        Log.Take();
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: Page "LT P136 TP List"; var Response: Action)
    var
        Item: Record "LT P136 Item";
    begin
        Log.Add('handler start');
        P.GetRecord(Item);
        Log.Add('handler record=' + Format(Item.Id) + '/' + Item.Name);
        Log.Add('handler lookupmode=' + Format(P.LookupMode()));
        Log.Add('handler response=' + Format(Response));
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure CardHandler(var P: Page "LT P136 TP Card"; var Response: Action)
    var
        Item: Record "LT P136 Item";
    begin
        Log.Add('card handler start');
        P.GetRecord(Item);
        Log.Add('card handler record=' + Format(Item.Id));
        Response := ResponseToGive;
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P136_ModalHandler_TypedPage_OnInitList_LookupOK()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        ResponseToGive := Action::LookupOK;
        Result := Page.RunModal(Page::"LT P136 TP List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'OnInit;handler start;handler record=0/;handler lookupmode=Yes;handler response=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P136_ModalHandler_TypedPage_OnInitList_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        ResponseToGive := Action::Cancel;
        Result := Page.RunModal(Page::"LT P136 TP List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'Cancel');
        Observer.Expect('log', 'OnInit;handler start;handler record=0/;handler lookupmode=Yes;handler response=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P136_ModalHandler_TypedPage_OK_AndEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        Result: Action;
    begin
        Seed();
        ResponseToGive := Action::OK;
        Result := Page.RunModal(Page::"LT P136 TP List");
        Observer.Observe('resultOK', Format(Result));
        Observer.Observe('logOK', Log.Take());
        Item.DeleteAll();
        ResponseToGive := Action::LookupCancel;
        Result := Page.RunModal(Page::"LT P136 TP List");
        Observer.Observe('resultEmpty', Format(Result));
        Observer.Observe('logEmpty', Log.Take());
        Observer.Expect('resultOK', 'OK');
        Observer.Expect('logOK', 'OnInit;handler start;handler record=0/;handler lookupmode=Yes;handler response=None;');
        Observer.Expect('resultEmpty', 'LookupCancel');
        Observer.Expect('logEmpty', 'OnInit;handler start;handler record=0/;handler lookupmode=Yes;handler response=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P136_ModalHandler_TypedPage_WithRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        Result: Action;
    begin
        Seed();
        Item.Get(2);
        ResponseToGive := Action::LookupOK;
        Result := Page.RunModal(Page::"LT P136 TP List", Item);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'OnInit;handler start;handler record=2/two;handler lookupmode=Yes;handler response=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P136_ModalHandler_TypedPage_OnInitCard()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        Result: Action;
    begin
        Seed();
        ResponseToGive := Action::OK;
        Result := Page.RunModal(Page::"LT P136 TP Card");
        Observer.Observe('resultNew', Format(Result));
        Observer.Observe('logNew', Log.Take());
        Item.Get(1);
        Result := Page.RunModal(Page::"LT P136 TP Card", Item);
        Observer.Observe('resultRec', Format(Result));
        Observer.Observe('logRec', Log.Take());
        Observer.Expect('resultNew', 'OK');
        Observer.Expect('logNew', 'card OnInit;card handler start;card handler record=0;');
        Observer.Expect('resultRec', 'OK');
        Observer.Expect('logRec', 'card OnInit;card handler start;card handler record=1;');
        Observer.Verify();
    end;
}
