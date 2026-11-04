// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73148, page 73149, log 73150 (SingleInstance, used only by test codeunit 73151)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a [ModalPageHandler] whose first parameter is typed as the Page (not a TestPage) for a page that declares OnInit, OnOpenPage, OnAfterGetRecord, OnQueryClosePage and OnClosePage:
// which triggers have run when the handler starts, what the handler reads from the page object (a variable set in OnInit, a procedure), what runs after the handler returns,
// and the same for a TestPage-typed handler on the same page, and for Page.RunModal with a record.
// BC versions: 29 (27 and 28 by CI)

table 73148 "LT P128 Modal Row"
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

codeunit 73150 "LT P128 Modal Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Value: Text)
    begin
        Lines += Value + ';';
    end;

    procedure Joined(): Text
    begin
        exit(Lines);
    end;
}

page 73149 "LT P128 Modal List"
{
    PageType = List;
    SourceTable = "LT P128 Modal Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        InitRan: Boolean;
        OpenRan: Boolean;

    procedure InitFlag(): Boolean
    begin
        exit(InitRan);
    end;

    procedure OpenFlag(): Boolean
    begin
        exit(OpenRan);
    end;

    trigger OnInit()
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        InitRan := true;
        Log.Add('OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        OpenRan := true;
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        Log.Add('OnAfterGetRecord' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        Log.Add('OnQueryClosePage:' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        Log.Add('OnClosePage');
    end;
}

codeunit 73151 "LT P128 Modal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P128 Modal Row";
        Log: Codeunit "LT P128 Modal Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Reset();
    end;

    [ModalPageHandler]
    procedure TypedHandler(var P: Page "LT P128 Modal List"; var Response: Action)
    var
        Log: Codeunit "LT P128 Modal Log";
        Row: Record "LT P128 Modal Row";
    begin
        P.GetRecord(Row);
        Log.Add('typed handler: init=' + Format(P.InitFlag()) + ' open=' + Format(P.OpenFlag()) + ' rec=' + Format(Row.Id) + ' lookup=' + Format(P.LookupMode()));
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure TypedHandlerCancel(var P: Page "LT P128 Modal List"; var Response: Action)
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        Log.Add('typed cancel handler: init=' + Format(P.InitFlag()) + ' open=' + Format(P.OpenFlag()));
        Response := Action::Cancel;
    end;

    [ModalPageHandler]
    procedure TestPageHandler(var T: TestPage "LT P128 Modal List")
    var
        Log: Codeunit "LT P128 Modal Log";
    begin
        Log.Add('testpage handler: id=' + Format(T.Id.Value()));
        T.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TypedHandler')]
    procedure P128_TypedModalHandler_PageWithOnInit_RunModalWithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Modal Log";
        Row: Record "LT P128 Modal Row";
        Answer: Action;
    begin
        Seed();
        Row.Get(2);
        Answer := Page.RunModal(Page::"LT P128 Modal List", Row);
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('log', Log.Joined());
        Observer.Expect('answer', 'LookupOK');
        Observer.Expect('log', 'OnInit;typed handler: init=Yes open=No rec=2 lookup=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedHandler')]
    procedure P128_TypedModalHandler_PageWithOnInit_PageVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Modal Log";
        ListPage: Page "LT P128 Modal List";
        Answer: Action;
    begin
        Seed();
        Answer := ListPage.RunModal();
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('init after run', Format(ListPage.InitFlag()));
        Observer.Expect('answer', 'LookupOK');
        Observer.Expect('log', 'OnInit;typed handler: init=Yes open=No rec=0 lookup=No;');
        Observer.Expect('init after run', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedHandlerCancel')]
    procedure P128_TypedModalHandler_PageWithOnInit_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Modal Log";
        Answer: Action;
    begin
        Seed();
        Answer := Page.RunModal(Page::"LT P128 Modal List");
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('log', Log.Joined());
        Observer.Expect('answer', 'Cancel');
        Observer.Expect('log', 'OnInit;typed cancel handler: init=Yes open=No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageHandler')]
    procedure P128_TestPageModalHandler_PageWithOnInit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Modal Log";
        Answer: Action;
    begin
        Seed();
        Answer := Page.RunModal(Page::"LT P128 Modal List");
        Observer.Observe('answer', Format(Answer));
        Observer.Observe('log', Log.Joined());
        Observer.Expect('answer', 'LookupOK');
        Observer.Expect('log', 'OnInit;OnOpenPage;OnAfterGetRecord1;OnAfterGetRecord2;OnAfterGetRecord1;testpage handler: id=1;OnQueryClosePage:LookupOK;OnClosePage;');
        Observer.Verify();
    end;
}
