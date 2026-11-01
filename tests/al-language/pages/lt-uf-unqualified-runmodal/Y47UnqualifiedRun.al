// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-table-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 92906, pages 92906-92907, codeunit 92906 (state), test codeunit 92907
// Probe (al-runner issue 6590): an UNQUALIFIED call `Run(Page::"X", Rec)` in a page action, without the `Page.` prefix, next to the qualified
//   `Page.Run(Page::"X", Rec)`. Which page opens, whether the filtered record passed in reaches it, whether the PageHandler runs and the action
//   goes on after the call. Neighbours: `Run(Page::"X")`, `Run(Page::"X", Rec, FieldNo)`, `Run(<integer id>, Rec)`, and a bare `Run()` with no
//   argument in the page (the page's own Run). The bare form does not compile in a codeunit, table, report or xmlport, and Page.Run returns
//   nothing: must-not-compile cases 2543-2547. The modal counterpart is UfUnqualifiedRunModal.al next door.
// BC versions: 27, 28, 29

table 92906 "LT Y47 Run Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 92906 "LT Y47 Run State"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

page 92906 "LT Y47 Run List"
{
    PageType = List;
    SourceTable = "LT Y47 Run Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        State: Codeunit "LT Y47 Run State";
    begin
        State.Add('list open rows=' + Format(Rec.Count()) + ' filter=' + Rec.GetFilters() + ' lookup=' + Format(CurrPage.LookupMode));
    end;
}

page 92907 "LT Y47 Run Card"
{
    PageType = Card;
    SourceTable = "LT Y47 Run Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenBare)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT Y47 Run Row";
                    State: Codeunit "LT Y47 Run State";
                begin
                    Row.SetRange("Code", 'B');
                    Run(Page::"LT Y47 Run List", Row);
                    State.Add('bare done');
                end;
            }
            action(OpenQualified)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT Y47 Run Row";
                    State: Codeunit "LT Y47 Run State";
                begin
                    Row.SetRange("Code", 'B');
                    Page.Run(Page::"LT Y47 Run List", Row);
                    State.Add('qualified done');
                end;
            }
            action(OpenBareUnfiltered)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT Y47 Run Row";
                    State: Codeunit "LT Y47 Run State";
                begin
                    Row.Get('C');
                    Run(Page::"LT Y47 Run List", Row);
                    State.Add('bare unfiltered done');
                end;
            }
            action(OpenBareOneArg)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    State: Codeunit "LT Y47 Run State";
                begin
                    Run(Page::"LT Y47 Run List");
                    State.Add('one argument done');
                end;
            }
            action(OpenBareField)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT Y47 Run Row";
                    State: Codeunit "LT Y47 Run State";
                begin
                    Row.SetRange("Code", 'B');
                    Run(Page::"LT Y47 Run List", Row, Row.FieldNo(Name));
                    State.Add('field done');
                end;
            }
            action(OpenBareNumber)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT Y47 Run Row";
                    State: Codeunit "LT Y47 Run State";
                begin
                    Row.SetRange("Code", 'B');
                    Run(92906, Row);
                    State.Add('number done');
                end;
            }
            action(OpenSelf)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    State: Codeunit "LT Y47 Run State";
                begin
                    Run();
                    State.Add('self done');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        State: Codeunit "LT Y47 Run State";
    begin
        State.Add('card open code=' + Rec."Code" + ' rows=' + Format(Rec.Count()));
    end;
}

codeunit 92907 "LT Y47 Unqualified Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y47 Run Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'one';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'two';
        Row.Insert();
        Row."Code" := 'C';
        Row.Name := 'three';
        Row.Insert();
    end;

    local procedure OpenCard(var Card: TestPage "LT Y47 Run Card")
    var
        Row: Record "LT Y47 Run Row";
        State: Codeunit "LT Y47 Run State";
    begin
        Seed();
        Row.Get('A');
        Card.OpenView();
        Card.GoToRecord(Row);
        State.Take();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_BareRun_RecordFiltered()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenBare.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=1 filter=Code: B lookup=No|handler first=B|bare done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_QualifiedRun_RecordFiltered()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenQualified.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=1 filter=Code: B lookup=No|handler first=B|qualified done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_BareRun_RecordUnfiltered()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenBareUnfiltered.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=3 filter= lookup=No|handler first=A|bare unfiltered done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_BareRun_OneArgument()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenBareOneArg.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=3 filter= lookup=No|handler first=A|one argument done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_BareRun_WithFieldNo()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenBareField.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=1 filter=Code: B lookup=No|handler first=B|field done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y47_BareRun_IntegerId()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        Card.OpenBareNumber.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Expect('log', 'list open rows=1 filter=Code: B lookup=No|handler first=B|number done|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Y47_BareRun_NoArgument_Self()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT Y47 Run State";
        Card: TestPage "LT Y47 Run Card";
    begin
        OpenCard(Card);
        ClearLastError();
        if TryInvokeSelf(Card) then
            Observer.Observe('result', 'ok')
        else
            Observer.Observe('result', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('log', State.Take());
        Observer.Expect('result', 'error A page with the identical handle has previously been registered.|TestWrapped:InvalidFormHandle');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryInvokeSelf(var Card: TestPage "LT Y47 Run Card")
    begin
        Card.OpenSelf.Invoke();
    end;

    [PageHandler]
    procedure ListHandler(var List: TestPage "LT Y47 Run List")
    var
        State: Codeunit "LT Y47 Run State";
    begin
        if List.First() then
            State.Add('handler first=' + List."Code".Value)
        else
            State.Add('handler no row');
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT Y47 Run Card")
    var
        State: Codeunit "LT Y47 Run State";
    begin
        State.Add('card handler code=' + Card."Code".Value);
    end;
}
