// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88630 - 88636 (writer RT)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: what Rec itself answers in the OnOpenPage of a page an action opens through RunPageLink: GetFilter of each linked field,
//   GetFilters, GetRangeMin and GetRangeMax of each linked field (the shape of page 99000817 "Prod. Order Routing", which compares
//   GetRangeMin and GetRangeMax of "Prod. Order No." to set a column's Visible), and the column's Visible() on the TestPage. Links: an
//   Option field and a Code field (the reporter's action), a Code field only, const(..), filter(..) with a range. Targets: a List and a Card;
//   routes: TestPage Trap and a PageHandler; a header row with steps and one without. The by-value copy of Rec and GetFilter in
//   FilterGroup 0 are pinned in handlers/TestActionRunPageLinkFilterGroup.al (QZ_* and RunPageLink_FilterLandsInGroup0_NotTheLinkGroup).
//   Log (written in OnOpenPage): F:<GetFilter Order No.>|<GetFilter Status>, A:<GetFilters>, Min:/Max: of Order No., SMin:/SMax: of Status
//   (only when the field has a filter; ERR:<text> when the call fails), Visible:<Order No. column visible>.
// Result (BC 27.5, 28.5, 29.0 alike): in OnOpenPage Rec holds the link as filters: GetFilter("Order No.") = H1, GetFilter(Status) =
//   Released, GetFilters = 'Order No.: H1, Status: Released'; GetRangeMin and GetRangeMax answer the linked value (H1, Released), so the
//   column is hidden. Same on a Card target, through a PageHandler, and for a header with no step rows (H2, Planned). A Code-only link and
//   const('H1') give F:H1| and 'Order No.: H1'. filter('H1..H2') gives GetFilter H1..H2, Min H1, Max H2, and the column stays visible.
// Source: al-runner issue 5811.
// BC versions: 27, 28, 29

table 88630 "LT RT Lr Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Status; Option) { OptionMembers = Planned,Released; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 88631 "LT RT Lr Step"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Order No."; Code[20]) { }
        field(2; "Step No."; Code[10]) { }
        field(3; Status; Option) { OptionMembers = Planned,Released; }
    }

    keys
    {
        key(PK; "Order No.", "Step No.") { Clustered = true; }
    }
}

codeunit 88632 "LT RT Lr Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        MinMax: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    // The OnOpenPage reads of both target pages; returns whether the Order No. column is to be visible (as page 99000817 decides it).
    procedure ReadOnOpen(var Step: Record "LT RT Lr Step") OrderNoVisible: Boolean
    begin
        OrderNoVisible := true;
        Add('F:' + Step.GetFilter("Order No.") + '|' + Step.GetFilter(Status));
        Add('A:' + Step.GetFilters());
        if Step.GetFilter("Order No.") <> '' then
            if TryOrderNoMinMax(Step) then begin
                Add(MinMax);
                OrderNoVisible := Step.GetRangeMin("Order No.") <> Step.GetRangeMax("Order No.");
            end else
                Add('ERR:' + GetLastErrorText());
        if Step.GetFilter(Status) <> '' then
            if TryStatusMinMax(Step) then
                Add(MinMax)
            else
                Add('ERR:' + GetLastErrorText());
        Add('Visible:' + Format(OrderNoVisible));
    end;

    [TryFunction]
    local procedure TryOrderNoMinMax(var Step: Record "LT RT Lr Step")
    begin
        MinMax := 'Min:' + Step.GetRangeMin("Order No.") + ';Max:' + Step.GetRangeMax("Order No.");
    end;

    [TryFunction]
    local procedure TryStatusMinMax(var Step: Record "LT RT Lr Step")
    begin
        MinMax := 'SMin:' + Format(Step.GetRangeMin(Status)) + ';SMax:' + Format(Step.GetRangeMax(Status));
    end;
}

page 88633 "LT RT Lr Steps"
{
    PageType = List;
    SourceTable = "LT RT Lr Step";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Steps)
            {
                field(OrderNoCtl; Rec."Order No.")
                {
                    ApplicationArea = All;
                    Visible = OrderNoVisible;
                }
                field(StepNoCtl; Rec."Step No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        OrderNoVisible := Log.ReadOnOpen(Rec);
    end;

    var
        Log: Codeunit "LT RT Lr Log";
        OrderNoVisible: Boolean;
}

page 88634 "LT RT Lr Step Card"
{
    PageType = Card;
    SourceTable = "LT RT Lr Step";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(OrderNoCtl; Rec."Order No.")
            {
                ApplicationArea = All;
                Visible = OrderNoVisible;
            }
            field(StepNoCtl; Rec."Step No.") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        OrderNoVisible := Log.ReadOnOpen(Rec);
    end;

    var
        Log: Codeunit "LT RT Lr Log";
        OrderNoVisible: Boolean;
}

page 88635 "LT RT Lr Head Card"
{
    PageType = Card;
    SourceTable = "LT RT Lr Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Steps)
            {
                ApplicationArea = All;
                RunObject = page "LT RT Lr Steps";
                RunPageLink = Status = field(Status),
                              "Order No." = field("No.");
            }
            action(StepsCodeOnly)
            {
                ApplicationArea = All;
                RunObject = page "LT RT Lr Steps";
                RunPageLink = "Order No." = field("No.");
            }
            action(StepsConst)
            {
                ApplicationArea = All;
                RunObject = page "LT RT Lr Steps";
                RunPageLink = "Order No." = const('H1');
            }
            action(StepsRange)
            {
                ApplicationArea = All;
                RunObject = page "LT RT Lr Steps";
                RunPageLink = "Order No." = filter('H1..H2');
            }
            action(StepCard)
            {
                ApplicationArea = All;
                RunObject = page "LT RT Lr Step Card";
                RunPageLink = Status = field(Status),
                              "Order No." = field("No.");
            }
        }
    }
}

codeunit 88636 "LT RT Lr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RT Lr Log";

    local procedure Seed()
    var
        Head: Record "LT RT Lr Head";
        Step: Record "LT RT Lr Step";
    begin
        Step.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Status := Head.Status::Released;
        Head.Insert();
        Head."No." := 'H2';
        Head.Status := Head.Status::Planned;
        Head.Insert();
        Step."Order No." := 'H1';
        Step."Step No." := '10';
        Step.Status := Step.Status::Released;
        Step.Insert();
        Log.Reset();
    end;

    local procedure OpenHead(var Card: TestPage "LT RT Lr Head Card"; HeadNo: Code[20])
    var
        Head: Record "LT RT Lr Head";
    begin
        Head.Get(HeadNo);
        Card.OpenView();
        Card.GoToRecord(Head);
    end;

    local procedure ReadSteps(var Steps: TestPage "LT RT Lr Steps")
    begin
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown', Steps.StepNoCtl.Value());
        Observer.Observe('order no visible', Format(Steps.OrderNoCtl.Visible()));
    end;

    // The reporter's test: the Status + Order No. link, trapped, on H1.
    [Test]
    procedure RT_Lr_StatusAndCode_Trap_H1()
    var
        Card: TestPage "LT RT Lr Head Card";
        Steps: TestPage "LT RT Lr Steps";
    begin
        Seed();
        OpenHead(Card, 'H1');
        Steps.Trap();
        Card.Steps.Invoke();
        ReadSteps(Steps);
        Steps.Close();
        Card.Close();
        Observer.Expect('log', 'F:H1|Released;A:Order No.: H1, Status: Released;Min:H1;Max:H1;SMin:Released;SMax:Released;Visible:No;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Lr_StatusAndCode_Trap_H2_NoSteps()
    var
        Card: TestPage "LT RT Lr Head Card";
        Steps: TestPage "LT RT Lr Steps";
    begin
        Seed();
        OpenHead(Card, 'H2');
        Steps.Trap();
        Card.Steps.Invoke();
        ReadSteps(Steps);
        Steps.Close();
        Card.Close();
        Observer.Expect('log', 'F:H2|Planned;A:Order No.: H2, Status: Planned;Min:H2;Max:H2;SMin:Planned;SMax:Planned;Visible:No;');
        Observer.Expect('shown', '');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StepsHandler')]
    procedure RT_Lr_StatusAndCode_Handler_H1()
    var
        Card: TestPage "LT RT Lr Head Card";
    begin
        Seed();
        OpenHead(Card, 'H1');
        Card.Steps.Invoke();
        Card.Close();
        Observer.Expect('log', 'F:H1|Released;A:Order No.: H1, Status: Released;Min:H1;Max:H1;SMin:Released;SMax:Released;Visible:No;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;

    [PageHandler]
    procedure StepsHandler(var Steps: TestPage "LT RT Lr Steps")
    begin
        ReadSteps(Steps);
    end;

    [Test]
    procedure RT_Lr_CodeOnly_Trap_H1()
    var
        Card: TestPage "LT RT Lr Head Card";
        Steps: TestPage "LT RT Lr Steps";
    begin
        Seed();
        OpenHead(Card, 'H1');
        Steps.Trap();
        Card.StepsCodeOnly.Invoke();
        ReadSteps(Steps);
        Steps.Close();
        Card.Close();
        Observer.Expect('log', 'F:H1|;A:Order No.: H1;Min:H1;Max:H1;Visible:No;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Lr_Const_Trap()
    var
        Card: TestPage "LT RT Lr Head Card";
        Steps: TestPage "LT RT Lr Steps";
    begin
        Seed();
        OpenHead(Card, 'H2');
        Steps.Trap();
        Card.StepsConst.Invoke();
        ReadSteps(Steps);
        Steps.Close();
        Card.Close();
        Observer.Expect('log', 'F:H1|;A:Order No.: H1;Min:H1;Max:H1;Visible:No;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Lr_RangeFilter_Trap()
    var
        Card: TestPage "LT RT Lr Head Card";
        Steps: TestPage "LT RT Lr Steps";
    begin
        Seed();
        OpenHead(Card, 'H1');
        Steps.Trap();
        Card.StepsRange.Invoke();
        ReadSteps(Steps);
        Steps.Close();
        Card.Close();
        Observer.Expect('log', 'F:H1..H2|;A:Order No.: H1..H2;Min:H1;Max:H2;Visible:Yes;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Lr_StepCard_Trap_H1()
    var
        Card: TestPage "LT RT Lr Head Card";
        StepCard: TestPage "LT RT Lr Step Card";
    begin
        Seed();
        OpenHead(Card, 'H1');
        StepCard.Trap();
        Card.StepCard.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown', StepCard.StepNoCtl.Value());
        Observer.Observe('order no visible', Format(StepCard.OrderNoCtl.Visible()));
        StepCard.Close();
        Card.Close();
        Observer.Expect('log', 'F:H1|Released;A:Order No.: H1, Status: Released;Min:H1;Max:H1;SMin:Released;SMax:Released;Visible:No;');
        Observer.Expect('shown', '10');
        Observer.Expect('order no visible', 'No');
        Observer.Verify();
    end;
}
