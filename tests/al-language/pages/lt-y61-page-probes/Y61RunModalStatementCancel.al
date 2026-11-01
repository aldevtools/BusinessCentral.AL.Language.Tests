// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-integer-table-fieldref-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); table 93254, page 93016, test codeunit 93250
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: the record G (a global of the test codeunit) after Page.RunModal(Page::Card, G) called as a STATEMENT, when the card is closed
//   other than by OK: Cancel on the same row, Cancel with G stale (another variable changed the stored row first), Next + Cancel and
//   Next + OK on a card that can move (G not filtered), a handler that invokes nothing (statement and expression form), an edit then
//   Cancel, and an action that calls CurrPage.Close() with G stale. Observed: G's Code, Name, Counter, GetFilters, Count; the stored rows;
//   each handler step's ok, error text and code (inside a TryFunction).
// Neighbours: pages/lt-y41-page-probes/Y41RunModalStatementRec.al (statement form closed with OK), pages/lt-page-runmodal-rec/PageRunModalRecAfterClose.al.
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): a Card run by Page.RunModal has no Cancel action ('The built-in action = Cancel is not
//   found on the page.', TestActionNotFound). In every shape the statement form leaves G with its own values (also when the stored row
//   changed before, when the page moved to B and closed with OK, when the handler did nothing, after CurrPage.Close()); an edit on the
//   page is stored. A handler that does nothing closes the page with LookupCancel (expression form).
// BC versions: all (CI)

table 93254 "LT Y61 RS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Counter; Integer) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

page 93016 "LT Y61 RS Card"
{
    PageType = Card;
    SourceTable = "LT Y61 RS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(CounterCtl; Rec.Counter) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetNameAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Name := 'edited';
                    Rec.Modify();
                end;
            }
            action(CloseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }
}

codeunit 93250 "LT Y61 RunModal Stmt Cancel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT Y61 RS Row";
        HandlerMode: Text;

    local procedure Seed()
    begin
        ClearLastError();
        Observer.Discard();
        G.Reset();
        G.DeleteAll();
        AddRow('A', 1);
        AddRow('B', 2);
        AddRow('C', 3);
        Clear(G);
    end;

    local procedure AddRow(C: Code[20]; N: Integer)
    var
        R: Record "LT Y61 RS Row";
    begin
        R.Init();
        R.Code := C;
        R.Name := 'name' + C;
        R.Counter := N;
        R.Insert();
    end;

    local procedure MakeStale()
    var
        R: Record "LT Y61 RS Row";
    begin
        R.Get('A');
        R.Name := 'stale';
        R.Modify();
    end;

    local procedure ObserveAll(Prefix: Text; var X: Record "LT Y61 RS Row")
    begin
        Observer.Observe(Prefix + 'rec', X.Code + '/' + X.Name + '/' + Format(X.Counter));
        Observer.Observe(Prefix + 'filters', X.GetFilters());
        Observer.Observe(Prefix + 'count', Format(X.Count()));
    end;

    local procedure StoredRows(): Text
    var
        R: Record "LT Y61 RS Row";
        Txt: Text;
    begin
        if R.FindSet() then
            repeat
                Txt += R.Code + '/' + R.Name + '/' + Format(R.Counter) + ',';
            until R.Next() = 0;
        exit(Txt);
    end;

    [TryFunction]
    local procedure TryStep(var P: TestPage "LT Y61 RS Card"; Which: Text)
    begin
        case Which of
            'ok':
                P.OK().Invoke();
            'cancel':
                P.Cancel().Invoke();
            'next':
                P.Next();
            'setname':
                P.NameCtl.SetValue('x');
            'closeact':
                P.CloseAct.Invoke();
        end;
    end;

    local procedure Step(var P: TestPage "LT Y61 RS Card"; Which: Text)
    begin
        Observer.Observe('h ' + Which + ' ok', Format(TryStep(P, Which)));
        Observer.ObserveError('h ' + Which);
    end;

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "LT Y61 RS Card")
    begin
        Observer.Observe('h shown', P.CodeCtl.Value() + '/' + P.NameCtl.Value());
        case HandlerMode of
            'cancel':
                Step(P, 'cancel');
            'nothing':
                ;
            'nextcancel':
                begin
                    Step(P, 'next');
                    Observer.Observe('h next shown', P.CodeCtl.Value());
                    Step(P, 'cancel');
                end;
            'nextok':
                begin
                    Step(P, 'next');
                    Observer.Observe('h next shown', P.CodeCtl.Value());
                    Step(P, 'ok');
                end;
            'editcancel':
                begin
                    Step(P, 'setname');
                    Step(P, 'cancel');
                end;
            'closeact':
                Step(P, 'closeact');
        end;
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_Cancel_SameRow()
    begin
        Seed();
        HandlerMode := 'cancel';
        G.Get('A');
        G.SetRecFilter();
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/nameA');
        Observer.Expect('h cancel ok', 'No');
        Observer.Expect('h cancel|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('h cancel|code', 'TestActionNotFound');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', 'Code: A');
        Observer.Expect('g count', '1');
        Observer.Expect('stored', 'A/nameA/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_Cancel_StaleRec()
    begin
        Seed();
        HandlerMode := 'cancel';
        G.Get('A');
        G.SetRecFilter();
        MakeStale();
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/stale');
        Observer.Expect('h cancel ok', 'No');
        Observer.Expect('h cancel|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('h cancel|code', 'TestActionNotFound');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', 'Code: A');
        Observer.Expect('g count', '1');
        Observer.Expect('stored', 'A/stale/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_NextCancel_OtherRow()
    begin
        Seed();
        HandlerMode := 'nextcancel';
        G.Get('A');
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/nameA');
        Observer.Expect('h next ok', 'Yes');
        Observer.Expect('h next|text', '');
        Observer.Expect('h next|code', '');
        Observer.Expect('h next shown', 'B');
        Observer.Expect('h cancel ok', 'No');
        Observer.Expect('h cancel|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('h cancel|code', 'TestActionNotFound');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', '');
        Observer.Expect('g count', '3');
        Observer.Expect('stored', 'A/nameA/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_NextOk_OtherRow()
    begin
        Seed();
        HandlerMode := 'nextok';
        G.Get('A');
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/nameA');
        Observer.Expect('h next ok', 'Yes');
        Observer.Expect('h next|text', '');
        Observer.Expect('h next|code', '');
        Observer.Expect('h next shown', 'B');
        Observer.Expect('h ok ok', 'Yes');
        Observer.Expect('h ok|text', '');
        Observer.Expect('h ok|code', '');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', '');
        Observer.Expect('g count', '3');
        Observer.Expect('stored', 'A/nameA/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_Nothing_Handler()
    begin
        Seed();
        HandlerMode := 'nothing';
        G.Get('A');
        G.SetRecFilter();
        MakeStale();
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        G.Get('B');
        G.SetRecFilter();
        Observer.Observe('expression action', Format(Page.RunModal(Page::"LT Y61 RS Card", G)));
        ObserveAll('g2 ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/stale');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', 'Code: A');
        Observer.Expect('g count', '1');
        Observer.Expect('h shown', 'B/nameB');
        Observer.Expect('expression action', 'LookupCancel');
        Observer.Expect('g2 rec', 'B/nameB/2');
        Observer.Expect('g2 filters', 'Code: B');
        Observer.Expect('g2 count', '1');
        Observer.Expect('stored', 'A/stale/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_EditCancel()
    begin
        Seed();
        HandlerMode := 'editcancel';
        G.Get('A');
        G.SetRecFilter();
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/nameA');
        Observer.Expect('h setname ok', 'Yes');
        Observer.Expect('h setname|text', '');
        Observer.Expect('h setname|code', '');
        Observer.Expect('h cancel ok', 'No');
        Observer.Expect('h cancel|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('h cancel|code', 'TestActionNotFound');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', 'Code: A');
        Observer.Expect('g count', '1');
        Observer.Expect('stored', 'A/x/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G618_Card_CloseAction_StaleRec()
    begin
        Seed();
        HandlerMode := 'closeact';
        G.Get('A');
        G.SetRecFilter();
        MakeStale();
        Page.RunModal(Page::"LT Y61 RS Card", G);
        ObserveAll('g ', G);
        Observer.Observe('stored', StoredRows());
        Observer.Expect('h shown', 'A/stale');
        Observer.Expect('h closeact ok', 'Yes');
        Observer.Expect('h closeact|text', '');
        Observer.Expect('h closeact|code', '');
        Observer.Expect('g rec', 'A/nameA/1');
        Observer.Expect('g filters', 'Code: A');
        Observer.Expect('g count', '1');
        Observer.Expect('stored', 'A/stale/1,B/nameB/2,C/nameC/3,');
        Observer.Verify();
    end;
}
