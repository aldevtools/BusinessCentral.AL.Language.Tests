// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 92960, pages 92960 - 92962, codeunits 92960 - 92961 (writer Y50)
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-16: CurrPage.Update() WITHOUT an argument in a procedure of a Page variable that never ran (the pinned
//   neighbours, UnopenedCurrPage.al and P82PageVar.al, call Update(false) / Update(true) only). Shapes: a NavigatePage with no source
//   table whose procedure sets globals, calls CurrPage.Update(), then CurrPage.RunModal() and returns a global the page set (closed by an
//   EMPTY ModalPageHandler); a Card and a List whose procedure sets a filter on Rec and calls CurrPage.Update() before Run; Update()
//   from outside on a never-run variable; Update() and Update(true) after a modal run closed.
// BC versions: 27, 28, 29

table 92960 "LT Y50 UN Item"
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

codeunit 92960 "LT Y50 UN Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 92960 "LT Y50 UN Navigate"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            label(Intro)
            {
                ApplicationArea = All;
                Caption = 'Intro';
            }
            field(Shown; Shown)
            {
                ApplicationArea = All;
                Caption = 'Shown';
                Visible = Shown <> '';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open shown=' + Shown);
        Answer := 'set by page';
    end;

    trigger OnClosePage()
    begin
        Log.Add('close');
    end;

    procedure Ask(NewText: Text): Text
    begin
        Shown := NewText;
        Log.Add('before update');
        CurrPage.Update();
        Log.Add('after update');
        CurrPage.RunModal();
        exit(Answer);
    end;

    procedure UpdateOnly()
    begin
        Log.Add('before update');
        CurrPage.Update();
        Log.Add('after update');
    end;

    var
        Log: Codeunit "LT Y50 UN Log";
        Shown: Text;
        Answer: Text;
}

page 92961 "LT Y50 UN Card"
{
    PageType = Card;
    SourceTable = "LT Y50 UN Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr ' + Rec."No.");
    end;

    procedure SetFilterAndUpdate(F: Text)
    begin
        Rec.SetFilter("No.", F);
        Log.Add('before update');
        CurrPage.Update();
        Log.Add('after update');
    end;

    var
        Log: Codeunit "LT Y50 UN Log";
}

page 92962 "LT Y50 UN List"
{
    PageType = List;
    SourceTable = "LT Y50 UN Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
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

    trigger OnOpenPage()
    begin
        Log.Add('open ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr ' + Rec."No.");
    end;

    procedure SetFilterAndUpdate(F: Text)
    begin
        Rec.SetFilter("No.", F);
        Log.Add('before update');
        CurrPage.Update();
        Log.Add('after update');
    end;

    var
        Log: Codeunit "LT Y50 UN Log";
}

codeunit 92961 "LT Y50 UN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y50 UN Log";

    local procedure Seed()
    var
        Item: Record "LT Y50 UN Item";
    begin
        Item.DeleteAll();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Insert();
        Log.Take();
    end;

    [TryFunction]
    local procedure TryUpdateOnly(var Pg: Page "LT Y50 UN Navigate")
    begin
        Pg.UpdateOnly();
    end;

    [TryFunction]
    local procedure TryUpdateNoArg(var Pg: Page "LT Y50 UN Card")
    begin
        Pg.Update();
    end;

    [TryFunction]
    local procedure TryUpdateTrue(var Pg: Page "LT Y50 UN Card")
    begin
        Pg.Update(true);
    end;

    // T1, the SMTP shape: Update() then RunModal of the same never-run NavigatePage, closed by an empty ModalPageHandler.
    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure G516_NavigatePage_UpdateNoArg_ThenRunModal_EmptyHandler()
    var
        Pg: Page "LT Y50 UN Navigate";
        R: Text;
    begin
        Seed();
        R := Pg.Ask('hello');
        Observer.Observe('result', R);
        Observer.Observe('log', Log.Take());
        Observer.Observe('returned', 'Yes');
        Observer.Finish();
    end;

    // T2: Update() alone in a procedure of a never-run NavigatePage.
    [Test]
    procedure G516_NavigatePage_UpdateNoArg_Alone()
    var
        Pg: Page "LT Y50 UN Navigate";
        Ok: Boolean;
    begin
        Seed();
        Ok := TryUpdateOnly(Pg);
        Observer.Observe('try', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // T3, the Budget shape: a procedure of a never-run Card sets a filter and calls Update(), then Run.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G516_Card_UpdateNoArg_BeforeRun()
    var
        Pg: Page "LT Y50 UN Card";
    begin
        Seed();
        Pg.SetFilterAndUpdate('B');
        Observer.Observe('after call', Log.Take());
        Pg.Run();
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // T4: the same on a List, twice, a new local variable each time.
    [Test]
    [HandlerFunctions('ListHandler')]
    procedure G516_List_UpdateNoArg_BeforeRun_Twice()
    begin
        Seed();
        RunListOnce('B');
        Observer.Observe('first', Log.Take());
        RunListOnce('A');
        Observer.Observe('second', Log.Take());
        Observer.Finish();
    end;

    local procedure RunListOnce(F: Text)
    var
        Pg: Page "LT Y50 UN List";
    begin
        Pg.SetFilterAndUpdate(F);
        Pg.Run();
    end;

    // T5: Update() from outside on a never-run Page variable.
    [Test]
    procedure G516_PageVar_UpdateNoArg_FromOutside()
    var
        Pg: Page "LT Y50 UN Card";
        Ok: Boolean;
    begin
        Seed();
        Ok := TryUpdateNoArg(Pg);
        Observer.Observe('try', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // T6: Update() and Update(true) after a modal run of the same variable closed with OK.
    [Test]
    [HandlerFunctions('CardModalOkHandler')]
    procedure G516_PageVar_UpdateNoArg_AfterModalClosed()
    var
        Item: Record "LT Y50 UN Item";
        Pg: Page "LT Y50 UN Card";
        Ok: Boolean;
    begin
        Seed();
        Item.Get('A');
        Pg.SetRecord(Item);
        Observer.Observe('action', Format(Pg.RunModal()));
        Observer.Observe('modal log', Log.Take());
        Ok := TryUpdateNoArg(Pg);
        Observer.Observe('update try', Format(Ok));
        Observer.ObserveError('update error');
        Ok := TryUpdateTrue(Pg);
        Observer.Observe('update true try', Format(Ok));
        Observer.ObserveError('update true error');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure EmptyHandler(var P: TestPage "LT Y50 UN Navigate")
    begin
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT Y50 UN Card")
    begin
        Log.Add('handler ' + P."No.".Value());
        P.Close();
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT Y50 UN List")
    begin
        Log.Add('handler ' + P."No.".Value());
        P.Close();
    end;

    [ModalPageHandler]
    procedure CardModalOkHandler(var P: TestPage "LT Y50 UN Card")
    begin
        Log.Add('handler ' + P."No.".Value());
        P.OK().Invoke();
    end;
}
