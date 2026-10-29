// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-integer-table-fieldref-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 90326, pages 90327-90329, codeunit 90330 (state), test codeunit 90331
// Probe (outside issue 6162): an UNQUALIFIED call `RunModal(Page::"X", MyRec)` inside a page trigger (field OnDrillDown, action OnAction, page OnOpenPage), without the `Page.` prefix.
//   alc resolves it to Page.RunModal. Which page opens, whether the row passed in reaches the modal page, the return value (OK after the handler's OK, Cancel otherwise), also
//   the one-argument form `RunModal(Page::"X")` and the call as a statement. The qualified forms are in pages/lt-be-runmodal-onlookup.
// BC versions: 27-29

table 90326 "LT UF Rm Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90330 "LT UF Rm State"
{
    SingleInstance = true;

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

    var
        Lines: Text;
}

page 90327 "LT UF Rm Target"
{
    PageType = List;
    SourceTable = "LT UF Rm Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        State: Codeunit "LT UF Rm State";
    begin
        State.Add('target open rows=' + Format(Rec.Count()) + ' lookup=' + Format(CurrPage.LookupMode));
    end;
}

page 90328 "LT UF Rm Caller"
{
    PageType = Card;
    SourceTable = "LT UF Rm Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnDrillDown()
                var
                    Row: Record "LT UF Rm Row";
                    State: Codeunit "LT UF Rm State";
                    Act: Action;
                begin
                    Row.SetRange(Id, 2);
                    Act := RunModal(Page::"LT UF Rm Target", Row);
                    State.Add('drilldown action=' + Format(Act));
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    State: Codeunit "LT UF Rm State";
                    Row: Record "LT UF Rm Row";
                begin
                    RunModal(Page::"LT UF Rm Target", Row);
                    State.Add('statement form done');
                end;
            }
            action(NoRecord)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    State: Codeunit "LT UF Rm State";
                    Act: Action;
                begin
                    Act := RunModal(Page::"LT UF Rm Target");
                    State.Add('one argument action=' + Format(Act));
                end;
            }
        }
    }
}

codeunit 90331 "LT UF Unqualified RunModal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT UF Rm Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('TargetOk')]
    procedure DrillDown_HandlerOk()
    var
        State: Codeunit "LT UF Rm State";
        Row: Record "LT UF Rm Row";
        Caller: TestPage "LT UF Rm Caller";
    begin
        Seed();
        State.Take();
        Row.Get(1);
        Caller.OpenView();
        Caller.GoToRecord(Row);
        Caller.Name.DrillDown();
        Observer.Observe('log', State.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TargetCancel')]
    procedure DrillDown_HandlerCancel()
    var
        State: Codeunit "LT UF Rm State";
        Row: Record "LT UF Rm Row";
        Caller: TestPage "LT UF Rm Caller";
    begin
        Seed();
        State.Take();
        Row.Get(1);
        Caller.OpenView();
        Caller.GoToRecord(Row);
        Caller.Name.DrillDown();
        Observer.Observe('log', State.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TargetOk')]
    procedure Action_StatementForm()
    var
        State: Codeunit "LT UF Rm State";
        Row: Record "LT UF Rm Row";
        Caller: TestPage "LT UF Rm Caller";
    begin
        Seed();
        State.Take();
        Row.Get(1);
        Caller.OpenView();
        Caller.GoToRecord(Row);
        Caller.Plain.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TargetOk')]
    procedure Action_OneArgumentForm()
    var
        State: Codeunit "LT UF Rm State";
        Row: Record "LT UF Rm Row";
        Caller: TestPage "LT UF Rm Caller";
    begin
        Seed();
        State.Take();
        Row.Get(1);
        Caller.OpenView();
        Caller.GoToRecord(Row);
        Caller.NoRecord.Invoke();
        Observer.Observe('log', State.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure TargetOk(var Target: TestPage "LT UF Rm Target")
    var
        State: Codeunit "LT UF Rm State";
    begin
        Target.First();
        State.Add('handler first id=' + Target.Id.Value);
        Target.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TargetCancel(var Target: TestPage "LT UF Rm Target")
    var
        State: Codeunit "LT UF Rm State";
    begin
        Target.First();
        State.Add('handler first id=' + Target.Id.Value);
        Target.Cancel().Invoke();
    end;
}
