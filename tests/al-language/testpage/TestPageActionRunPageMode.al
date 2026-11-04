// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagemode-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: ARPM Row (67014), ARPM Probe (67015), ARPM Card (67016), ARPM Host (67017),
//                Assert (60021) -- and Base Application pages 99000921 "Demand Forecast Names",
//                99000922 "Demand Forecast Entries", 1340 "Config Templates" and
//                8618 "Config. Template Header"
//
/// <summary>
/// Pins what an ACTION's RunPageMode (View / Edit / Create) does to the page it opens: whether
/// the opened page is editable, whether its fields are, and -- for Create -- whether it opens
/// on a new record rather than on an existing row.
///
/// RunPageMode sits beside RunPageView (TestPageActionRunPageView.al) and RunPageLink on the
/// same action. The corpus mentioned it nowhere.
///
/// Written by agent stma-auto-3, an automated implementation agent acting on the account
/// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4997, which
/// measured that the runner reads an action's RunPageMode nowhere.
///
/// The observing arms assert ONE string carrying what the [PageHandler] saw on the opened card
/// (TestPage.Editable(), the Name field's Editable(), the key the card stands on) and what the
/// card's own OnOpenPage saw (CurrPage.Editable and Rec."No."), so a failure prints everything
/// BC did rather than stopping at the first difference. Two rows are seeded, 'A' and 'B'; the
/// host stands on 'B' and no action declares RunPageOnRec, so an existing-row open lands on
/// the table's first row.
///
/// The writing arms then pin what the handler's typing does: in Create it inserts a new record,
/// in Edit it modifies the row the card opened on. (What typing into a View-mode card does is
/// not asserted here -- it is its own question, tracked by the AL Runner issue linked from this
/// file's pull request.)
///
/// The Triggers arms (AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5005, also by
/// stma-auto-3) record which of the card's own triggers ran, in order -- OnOpenPage as 'open',
/// OnNewRecord as 'new:no=<key>' -- for a Create-mode open answered by a handler, by
/// TestPage.Trap(), and by nothing at all, with an Edit-mode open answered by nothing as the
/// negative control.
///
/// The last codeunit reaches the same property on PRECOMPILED Base Application pages:
///     "Demand Forecast Names" action "Demand Forecast Entries"  RunPageMode = View
///     "Config Templates"      action "NewConfigTemplate"        RunPageMode = Create
/// </summary>

table 67014 "ARPM Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 67015 "ARPM Probe"
{
    SingleInstance = true;

    var
        OpenState: Text;
        Shown: Text;
        Trail: Text;

    procedure Reset()
    begin
        OpenState := '';
        Shown := '';
        Trail := '';
    end;

    procedure Note(TriggerName: Text)
    begin
        if Trail <> '' then
            Trail += ',';
        Trail += TriggerName;
    end;

    procedure Triggers(): Text
    begin
        exit(Trail);
    end;

    procedure RecordOpenState(NewState: Text)
    begin
        OpenState := NewState;
    end;

    procedure RecordShown(NewShown: Text)
    begin
        Shown := NewShown;
    end;

    procedure Observed(): Text
    begin
        exit(Shown + '|' + OpenState);
    end;
}

page 67016 "ARPM Card"
{
    PageType = Card;
    SourceTable = "ARPM Row";
    ApplicationArea = All;
    Caption = 'ARPM Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "ARPM Probe";
    begin
        Probe.RecordOpenState('open:ed=' + Format(CurrPage.Editable()) + ',no=' + Rec."No.");
        Probe.Note('open');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Probe: Codeunit "ARPM Probe";
    begin
        Probe.Note('new:no=' + Rec."No.");
    end;
}

page 67017 "ARPM Host"
{
    PageType = Card;
    SourceTable = "ARPM Row";
    ApplicationArea = All;
    Caption = 'ARPM Host';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDefault)
            {
                ApplicationArea = All;
                Caption = 'Open Default';
                RunObject = page "ARPM Card";
            }
            action(OpenView)
            {
                ApplicationArea = All;
                Caption = 'Open View';
                RunObject = page "ARPM Card";
                RunPageMode = View;
            }
            action(OpenEdit)
            {
                ApplicationArea = All;
                Caption = 'Open Edit';
                RunObject = page "ARPM Card";
                RunPageMode = Edit;
            }
            action(OpenCreate)
            {
                ApplicationArea = All;
                Caption = 'Open Create';
                RunObject = page "ARPM Card";
                RunPageMode = Create;
            }
        }
    }
}

codeunit 67018 "ARPM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "ARPM Row";
        Probe: Codeunit "ARPM Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        AddRow('A', 'Alpha');
        AddRow('B', 'Bravo');
    end;

    local procedure AddRow(No: Code[20]; NewName: Text[50])
    var
        Row: Record "ARPM Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "ARPM Host")
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey('B');
    end;

    local procedure Rows(): Text
    var
        Row: Record "ARPM Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row."No." + '=' + Row.Name;
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    [HandlerFunctions('ArpmCardObserveHandler')]
    procedure NoRunPageMode_OpensTheCardEditableOnAnExistingRow()
    // The control: no RunPageMode at all.
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenDefault.Invoke();
        Host.Close();

        Assert.AreEqual(
            'ed=Yes;nameEd=Yes;no=A|open:ed=Yes,no=', Probe.Observed(),
            'An action with no RunPageMode opens its card as the page declares it.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardObserveHandler')]
    procedure RunPageModeView_OpensTheCardReadOnly()
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenView.Invoke();
        Host.Close();

        Assert.AreEqual(
            'ed=No;nameEd=No;no=A|open:ed=No,no=', Probe.Observed(),
            'RunPageMode = View opens the card read-only.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardObserveHandler')]
    procedure RunPageModeEdit_OpensTheCardEditable()
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenEdit.Invoke();
        Host.Close();

        Assert.AreEqual(
            'ed=Yes;nameEd=Yes;no=A|open:ed=Yes,no=', Probe.Observed(),
            'RunPageMode = Edit opens the card editable.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardObserveHandler')]
    procedure RunPageModeCreate_OpensTheCardOnANewRecord()
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual(
            'ed=Yes;nameEd=Yes;no=|open:ed=Yes,no=', Probe.Observed(),
            'RunPageMode = Create opens the card on a new, blank record.');
        Assert.AreEqual('A=Alpha,B=Bravo', Rows(), 'Opening a card in Create mode and closing it untouched inserts nothing.');
    end;

    [Test]
    procedure RunPageModeView_NoHandlerBound_OnOpenPageSeesTheCardReadOnly()
    // Nothing is bound to answer the opened card. A RunObject action still opens it and runs its
    // OnOpenPage before BC finds no handler, and the invoke returns normally (codeunit 60285).
    // What that OnOpenPage sees is the mode: the handler never runs, so Shown stays empty.
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenView.Invoke();
        Host.Close();

        Assert.AreEqual(
            '|open:ed=No,no=', Probe.Observed(),
            'RunPageMode = View with no page handler bound: the card''s OnOpenPage still sees it read-only.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardObserveHandler')]
    procedure RunPageModeCreate_HandlerBound_OnNewRecordRuns()
    // The control for the no-handler arms below: with a handler bound, the card's triggers in
    // the order they ran. It is what shows the probe sees OnNewRecord at all.
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:no=', Probe.Triggers(),
            'RunPageMode = Create with a page handler bound: the card''s triggers, in order.');
    end;

    [Test]
    procedure RunPageModeCreate_NoHandlerBound_Triggers()
    // AL Runner issue #5005: nothing is bound to answer the card an action opens in Create mode.
    // Which of the card's triggers run, in order, and whether anything is inserted.
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('open,new:no=', Probe.Triggers(),
            'RunPageMode = Create with no page handler bound: the card''s triggers, in order.');
        Assert.AreEqual('A=Alpha,B=Bravo', Rows(),
            'RunPageMode = Create with no page handler bound inserts nothing.');
    end;

    [Test]
    procedure RunPageModeEdit_NoHandlerBound_Triggers()
    // The negative control for the arm above: Edit mode, nothing bound.
    var
        Host: TestPage "ARPM Host";
        Probe: Codeunit "ARPM Probe";
    begin
        OpenHost(Host);
        Host.OpenEdit.Invoke();
        Host.Close();

        Assert.AreEqual('open', Probe.Triggers(),
            'RunPageMode = Edit with no page handler bound: the card''s triggers, in order.');
    end;

    [Test]
    procedure RunPageModeCreate_Trapped_Triggers()
    // The card an action opens in Create mode, caught by TestPage.Trap() rather than a handler.
    var
        Host: TestPage "ARPM Host";
        Card: TestPage "ARPM Card";
        Probe: Codeunit "ARPM Probe";
        Shown: Text;
    begin
        OpenHost(Host);
        Card.Trap();
        Host.OpenCreate.Invoke();
        Shown := 'ed=' + Format(Card.Editable()) + ';no=' + Card."No.".Value();
        Card.Close();
        Host.Close();

        Assert.AreEqual('ed=Yes;no=|open,new:no=', Shown + '|' + Probe.Triggers(),
            'RunPageMode = Create caught by TestPage.Trap(): what the card shows, then its triggers in order.');
        Assert.AreEqual('A=Alpha,B=Bravo', Rows(),
            'RunPageMode = Create caught by TestPage.Trap() and closed untouched inserts nothing.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardTypeHandler')]
    procedure RunPageModeCreate_WhatTheHandlerTypesIsInserted()
    var
        Host: TestPage "ARPM Host";
    begin
        OpenHost(Host);
        Host.OpenCreate.Invoke();
        Host.Close();

        Assert.AreEqual('A=Alpha,B=Bravo,NEW=Typed', Rows(),
            'RunPageMode = Create: the key and name the handler types become a new row, and no existing row changes.');
    end;

    [Test]
    [HandlerFunctions('ArpmCardTypeNameHandler')]
    procedure RunPageModeEdit_WhatTheHandlerTypesModifiesTheOpenedRow()
    var
        Host: TestPage "ARPM Host";
    begin
        OpenHost(Host);
        Host.OpenEdit.Invoke();
        Host.Close();

        Assert.AreEqual('A=Typed,B=Bravo', Rows(),
            'RunPageMode = Edit: the name the handler types modifies the row the card opened on.');
    end;

    [PageHandler]
    procedure ArpmCardObserveHandler(var Card: TestPage "ARPM Card")
    var
        Probe: Codeunit "ARPM Probe";
    begin
        Probe.RecordShown(
            'ed=' + Format(Card.Editable()) + ';nameEd=' + Format(Card.Name.Editable()) +
            ';no=' + Card."No.".Value());
        Card.Close();
    end;

    [PageHandler]
    procedure ArpmCardTypeHandler(var Card: TestPage "ARPM Card")
    begin
        Card."No.".SetValue('NEW');
        Card.Name.SetValue('Typed');
        Card.Close();
    end;

    [PageHandler]
    procedure ArpmCardTypeNameHandler(var Card: TestPage "ARPM Card")
    begin
        Card.Name.SetValue('Typed');
        Card.Close();
    end;
}

codeunit 67019 "ARPM Precompiled Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Shown: Text;

    [Test]
    [HandlerFunctions('DemandForecastEntriesHandler')]
    procedure PrecompiledRunPageModeView_OpensTheTargetReadOnly()
    // Base Application page 99000921 "Demand Forecast Names", action "Demand Forecast Entries":
    //     RunObject = Page "Demand Forecast Entries"; RunPageLink = ...; RunPageMode = View;
    // Page 99000922 declares no Editable, so it is the action's mode alone that can make it
    // read-only.
    var
        ForecastName: Record "Production Forecast Name";
        Host: TestPage "Demand Forecast Names";
    begin
        Shown := '';
        if ForecastName.Get('ARPMDF') then
            ForecastName.Delete();
        ForecastName.Init();
        ForecastName.Name := 'ARPMDF';
        ForecastName.Insert();

        Host.OpenView();
        Host.GoToKey('ARPMDF');
        Host."Demand Forecast Entries".Invoke();
        Host.Close();

        Assert.AreEqual('ed=No', Shown,
            'The precompiled action''s RunPageMode = View opens Demand Forecast Entries read-only.');
    end;

    [Test]
    [HandlerFunctions('ConfigTemplateHeaderHandler')]
    procedure PrecompiledRunPageModeCreate_OpensTheTargetOnANewRecord()
    // Base Application page 1340 "Config Templates", action "NewConfigTemplate":
    //     RunObject = Page "Config. Template Header"; RunPageMode = Create;
    // An existing template is seeded, so an existing-row open would show its code.
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Host: TestPage "Config Templates";
    begin
        Shown := '';
        ConfigTemplateHeader.DeleteAll();
        ConfigTemplateHeader.Init();
        ConfigTemplateHeader.Code := 'ARPMCT';
        ConfigTemplateHeader.Insert();

        Host.OpenView();
        Host.NewConfigTemplate.Invoke();
        Host.Close();

        Assert.AreEqual('ed=Yes;code=', Shown,
            'The precompiled action''s RunPageMode = Create opens Config. Template Header on a new, blank record.');
    end;

    [PageHandler]
    procedure DemandForecastEntriesHandler(var Entries: TestPage "Demand Forecast Entries")
    begin
        Shown := 'ed=' + Format(Entries.Editable());
        Entries.Close();
    end;

    [PageHandler]
    procedure ConfigTemplateHeaderHandler(var Card: TestPage "Config. Template Header")
    begin
        Shown := 'ed=' + Format(Card.Editable()) + ';code=' + Card.Code.Value();
        Card.Close();
    end;
}
