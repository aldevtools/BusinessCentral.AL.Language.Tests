// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73260, SingleInstance log 73261 (used only by test codeunit 73264), pages 73262 (list) and 73263 (card)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (1) a [ModalPageHandler] whose first parameter is a Page (not a TestPage) for a page that declares OnInit, OnOpenPage, OnAfterGetRecord, OnAfterGetCurrRecord, OnQueryClosePage and OnClosePage:
// which of those triggers run, in which order, relative to the handler, and what Page.RunModal answers; the same page with a TestPage handler.
// (2) several ModalPage handlers named in one [HandlerFunctions] list (two Page-typed ones for different pages, a Page-typed and a TestPage-typed one, two TestPage-typed ones): which handler is bound to which page,
// including a second modal page opened from an action that the first handler invokes.
// BC versions: 29 (27 and 28 by CI)

table 73260 "LT P129 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73261 "LT P129 Log"
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

page 73262 "LT P129 List"
{
    PageType = List;
    SourceTable = "LT P129 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCard)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Result: Action;
                begin
                    L.Add('list action start id=' + Format(Rec.Id));
                    Result := Page.RunModal(Page::"LT P129 Card", Rec);
                    L.Add('list action result=' + Format(Result));
                end;
            }
        }
    }

    trigger OnInit()
    begin
        L.Add('list OnInit');
    end;

    trigger OnOpenPage()
    begin
        L.Add('list OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        L.Add('list AGR ' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('list AGCR ' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('list OnQueryClosePage ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('list OnClosePage');
    end;

    var
        L: Codeunit "LT P129 Log";
}

page 73263 "LT P129 Card"
{
    PageType = Card;
    SourceTable = "LT P129 Row";
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

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('card AGCR ' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        L.Add('card OnQueryClosePage ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        L.Add('card OnClosePage');
    end;

    var
        L: Codeunit "LT P129 Log";
}

codeunit 73264 "LT P129 Handlers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 Log";
        ListResponse: Action;
        CardResponse: Action;

    local procedure Seed()
    var
        Row: Record "LT P129 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        L.Take();
    end;

    [ModalPageHandler]
    procedure TypedListHandler(var P: Page "LT P129 List"; var Response: Action)
    var
        Row: Record "LT P129 Row";
    begin
        P.GetRecord(Row);
        L.Add('typed list handler id=' + Format(Row.Id) + ' lookup=' + Format(P.LookupMode()) + ' before=' + Format(Response));
        Response := ListResponse;
    end;

    [ModalPageHandler]
    procedure TypedCardHandler(var P: Page "LT P129 Card"; var Response: Action)
    var
        Row: Record "LT P129 Row";
    begin
        P.GetRecord(Row);
        L.Add('typed card handler id=' + Format(Row.Id) + ' name=' + Row.Name + ' before=' + Format(Response));
        Response := CardResponse;
    end;

    [ModalPageHandler]
    procedure TestListHandler(var P: TestPage "LT P129 List")
    begin
        L.Add('testpage list handler id=' + P.Id.Value());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TestCardHandler(var P: TestPage "LT P129 Card")
    begin
        L.Add('testpage card handler id=' + P.Id.Value() + ' name=' + P.Name.Value());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NestingListHandler(var P: TestPage "LT P129 List")
    begin
        L.Add('nesting list handler id=' + P.Id.Value());
        P.OpenCard.Invoke();
        L.Add('nesting list handler after action');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NestedCardHandler(var P: TestPage "LT P129 Card")
    begin
        L.Add('nested card handler id=' + P.Id.Value() + ' name=' + P.Name.Value());
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('TypedListHandler')]
    procedure P129_PageTypedHandler_List_RunsThePagesTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        ListResponse := Action::LookupOK;
        Result := Page.RunModal(Page::"LT P129 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'list OnInit;typed list handler id=0 lookup=Yes before=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedListHandler')]
    procedure P129_PageTypedHandler_List_Cancel_RunsThePagesTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        ListResponse := Action::Cancel;
        Result := Page.RunModal(Page::"LT P129 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'Cancel');
        Observer.Expect('log', 'list OnInit;typed list handler id=0 lookup=Yes before=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedCardHandler')]
    procedure P129_PageTypedHandler_Card_RunsThePagesTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        CardResponse := Action::OK;
        Result := Page.RunModal(Page::"LT P129 Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'OK');
        Observer.Expect('log', 'card OnInit;typed card handler id=2 name=two before=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestListHandler')]
    procedure P129_TestPageHandler_List_RunsThePagesTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P129 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'list OnInit;list OnOpenPage;list AGR 1;list AGR 2;list AGR 1;list AGR 1;list AGCR 1;testpage list handler id=1;list OnQueryClosePage LookupOK;list OnClosePage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestCardHandler')]
    procedure P129_TestPageHandler_Card_RunsThePagesTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Result := Page.RunModal(Page::"LT P129 Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'card OnInit;card OnOpenPage;card AGR 2;card AGCR 2;testpage card handler id=2 name=two;card OnQueryClosePage LookupOK;card OnClosePage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedListHandler,TypedCardHandler')]
    procedure P129_TwoPageTypedHandlers_DifferentPages_EachBoundToItsPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Row";
        ResultCard: Action;
        ResultList: Action;
    begin
        Seed();
        ListResponse := Action::LookupOK;
        CardResponse := Action::OK;
        Row.Get(1);
        ResultCard := Page.RunModal(Page::"LT P129 Card", Row);
        ResultList := Page.RunModal(Page::"LT P129 List");
        Observer.Observe('card result', Format(ResultCard));
        Observer.Observe('list result', Format(ResultList));
        Observer.Observe('log', L.Take());
        Observer.Expect('card result', 'OK');
        Observer.Expect('list result', 'LookupOK');
        Observer.Expect('log', 'card OnInit;typed card handler id=1 name=one before=None;list OnInit;typed list handler id=0 lookup=Yes before=None;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedListHandler,TestCardHandler')]
    procedure P129_PageTypedAndTestPageHandler_DifferentPages()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 Row";
        ResultCard: Action;
        ResultList: Action;
    begin
        Seed();
        ListResponse := Action::Cancel;
        Row.Get(1);
        ResultList := Page.RunModal(Page::"LT P129 List");
        ResultCard := Page.RunModal(Page::"LT P129 Card", Row);
        Observer.Observe('list result', Format(ResultList));
        Observer.Observe('card result', Format(ResultCard));
        Observer.Observe('log', L.Take());
        Observer.Expect('list result', 'Cancel');
        Observer.Expect('card result', 'LookupOK');
        Observer.Expect('log', 'list OnInit;typed list handler id=0 lookup=Yes before=None;card OnInit;card OnOpenPage;card AGR 1;card AGCR 1;testpage card handler id=1 name=one;card OnQueryClosePage LookupOK;card OnClosePage;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NestingListHandler,NestedCardHandler')]
    procedure P129_TwoTestPageHandlers_SecondPageOpenedByAnActionOfTheFirstHandler()
    var
        Observer: Codeunit "Probe Observer";
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P129 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'list OnInit;list OnOpenPage;list AGR 1;list AGR 2;list AGR 1;list AGR 1;list AGCR 1;nesting list handler id=1;list AGR 1;list action start id=1;card OnInit;card OnOpenPage;card AGR 1;card AGCR 1;nested card handler id=1 name=one;card AGR 1;card AGCR 1;card OnQueryClosePage LookupCancel;card OnClosePage;list action result=LookupCancel;list AGR 1;list AGR 1;list AGR 2;list AGR 1;list AGR 1;list AGCR 1;nesting list handler after action;list OnQueryClosePage LookupOK;list OnClosePage;');
        Observer.Verify();
    end;
}
