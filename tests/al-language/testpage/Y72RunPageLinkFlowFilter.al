// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93862,93863; page 93866,93867; codeunit 93858
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what a RunPageLink that links a FlowFilter field of the host record (field("Dim Filter") on a Code FlowFilter, field("Int Filter")
//   on an Integer one, field("Date Filter") on a Date one) gives the target page: its Rec filters in OnOpenPage (GetFilters,
//   GetFilter per FlowFilter, HasFilter) and the FlowField Amount it shows. The host has no filter on the FlowFilter, a single value, an
//   expression ('D1|D2', '<>D1'), a range, or the filter is set on the TestPage. Dates are in the format of the CI (en-US).
//   Entries (Id, Code, Dim, D, Amount): 1 P1 D1 01/10/24 10; 2 P1 D2 02/10/24 20; 3 P1 blank 03/10/24 40; 4 P1 D1 03/15/24 80;
//   5 P2 D1 01/10/24 1000.
// Neighbours: pages/lt-y61-page-probes/Y61RunPageLinkCopyFilter.al (a Date FlowFilter whose host filter is a range), pages/lt-y41-page-probes/Y41RunPageLinkOnOpen.al:344.
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): a FlowFilter in the link is copied to the target's Rec only when the host has a filter on
//   it: with no filter the target's filters are only 'Code: P1' (HasFilter Yes, GetFilter of the FlowFilter empty) and the FlowField
//   Amount is the unfiltered sum (150); a single value, an expression ('D1|D2', '<>D1', a range, the blank filter '') or a Date range /
//   single date / expression arrives as the host's filter text and filters Amount accordingly (D1 90, D1|D2 110, <>D1 60, blank 40;
//   dates 03/01/24..03/31/24 120, 03/15/24 80, >02/01/24 140). An Integer FlowFilter arrives the same way (5, 1..9, <>5). A filter set
//   on the host TestPage with Filter.SetFilter reaches the target the same way.
// BC versions: all (CI)

table 93862 "LT Y72 Link H"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Dim Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(4; "Int Filter"; Integer) { FieldClass = FlowFilter; }
        field(5; Amount; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y72 Link E".Amount where(Code = field(Code), Dim = field("Dim Filter"), D = field("Date Filter")));
        }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 93863 "LT Y72 Link E"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Code; Code[10]) { }
        field(3; Dim; Code[10]) { }
        field(4; D; Date) { }
        field(5; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 93866 "LT Y72 Link Target"
{
    PageType = Card;
    SourceTable = "LT Y72 Link H";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('open filters=[' + Rec.GetFilters() + '] dim=[' + Rec.GetFilter("Dim Filter") + '] int=[' + Rec.GetFilter("Int Filter") + '] date=[' + Rec.GetFilter("Date Filter") + '] has=' + Format(Rec.HasFilter()));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Rec.CalcFields(Amount);
        Log.AddLine('agr ' + Rec.Code + ' amount=' + Format(Rec.Amount));
    end;
}

page 93867 "LT Y72 Link Host"
{
    PageType = Card;
    SourceTable = "LT Y72 Link H";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            field(AmountCtl; Rec.Amount) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenAll)
            {
                ApplicationArea = All;
                RunObject = page "LT Y72 Link Target";
                RunPageLink = Code = field(Code), "Dim Filter" = field("Dim Filter"), "Int Filter" = field("Int Filter");
            }
            action(OpenDate)
            {
                ApplicationArea = All;
                RunObject = page "LT Y72 Link Target";
                RunPageLink = Code = field(Code), "Date Filter" = field("Date Filter");
            }
            action(OpenDim)
            {
                ApplicationArea = All;
                RunObject = page "LT Y72 Link Target";
                RunPageLink = Code = field(Code), "Dim Filter" = field("Dim Filter");
            }
        }
    }
}

codeunit 93858 "LT Y72 RunPageLink FlowFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        H: Record "LT Y72 Link H";
        E: Record "LT Y72 Link E";
        Log: Record "LT Y61 Log";
    begin
        ClearLastError();
        Observer.Discard();
        H.DeleteAll();
        E.DeleteAll();
        Log.ClearLog();
        H.Code := 'P1';
        H.Insert();
        H.Code := 'P2';
        H.Insert();
        AddEntry(1, 'P1', 'D1', DMY2Date(10, 1, 2024), 10);
        AddEntry(2, 'P1', 'D2', DMY2Date(10, 2, 2024), 20);
        AddEntry(3, 'P1', '', DMY2Date(10, 3, 2024), 40);
        AddEntry(4, 'P1', 'D1', DMY2Date(15, 3, 2024), 80);
        AddEntry(5, 'P2', 'D1', DMY2Date(10, 1, 2024), 1000);
    end;

    local procedure AddEntry(Id: Integer; Code: Code[10]; Dim: Code[10]; D: Date; Amount: Decimal)
    var
        E: Record "LT Y72 Link E";
    begin
        E.Id := Id;
        E.Code := Code;
        E.Dim := Dim;
        E.D := D;
        E.Amount := Amount;
        E.Insert();
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y61 Log";
    begin
        exit(Log.Take());
    end;

    // Opens the host on P1 with the filters set on the record, invokes the action and observes the target.
    local procedure Probe(Name: Text; var H: Record "LT Y72 Link H"; Which: Integer)
    var
        Host: TestPage "LT Y72 Link Host";
        Target: TestPage "LT Y72 Link Target";
    begin
        TakeLog();
        Host.Trap();
        Page.Run(Page::"LT Y72 Link Host", H);
        Observer.Observe(Name + ' host amount', Host.AmountCtl.Value());
        TakeLog();
        Target.Trap();
        case Which of
            1:
                Host.OpenAll.Invoke();
            2:
                Host.OpenDate.Invoke();
            3:
                Host.OpenDim.Invoke();
        end;
        Observer.Observe(Name + ' log', TakeLog());
        Observer.Observe(Name + ' code', Target.CodeCtl.Value());
        Observer.Observe(Name + ' amount', Target.AmountCtl.Value());
        Target.Close();
        Host.Close();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostUnfiltered()
    var
        H: Record "LT Y72 Link H";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        Probe('all unfiltered', H, 1);
        Probe('dim only unfiltered', H, 3);
        Observer.Expect('all unfiltered host amount', '150.00');
        Observer.Expect('all unfiltered log', 'open filters=[Code: P1] dim=[] int=[] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('all unfiltered code', 'P1');
        Observer.Expect('all unfiltered amount', '150.00');
        Observer.Expect('dim only unfiltered host amount', '150.00');
        Observer.Expect('dim only unfiltered log', 'open filters=[Code: P1] dim=[] int=[] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('dim only unfiltered code', 'P1');
        Observer.Expect('dim only unfiltered amount', '150.00');
        Observer.Verify();
    end;




    [Test]
    procedure Link_CodeFlowFilter_HostOneValue()
    var
        H: Record "LT Y72 Link H";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        H.SetRange("Dim Filter", 'D1');
        Probe('D1 all', H, 1);
        Probe('D1 dim only', H, 3);
        H.SetRange("Dim Filter", 'ZZ');
        Probe('no match value', H, 1);
        Observer.Expect('D1 all host amount', '90.00');
        Observer.Expect('D1 all log', 'open filters=[Code: P1, Dim Filter: D1] dim=[D1] int=[] date=[] has=Yes;agr P1 amount=90');
        Observer.Expect('D1 all code', 'P1');
        Observer.Expect('D1 all amount', '90.00');
        Observer.Expect('D1 dim only host amount', '90.00');
        Observer.Expect('D1 dim only log', 'open filters=[Code: P1, Dim Filter: D1] dim=[D1] int=[] date=[] has=Yes;agr P1 amount=90');
        Observer.Expect('D1 dim only code', 'P1');
        Observer.Expect('D1 dim only amount', '90.00');
        Observer.Expect('no match value host amount', '0.00');
        Observer.Expect('no match value log', 'open filters=[Code: P1, Dim Filter: ZZ] dim=[ZZ] int=[] date=[] has=Yes;agr P1 amount=0');
        Observer.Expect('no match value code', 'P1');
        Observer.Expect('no match value amount', '0.00');
        Observer.Verify();
    end;




    [Test]
    procedure Link_CodeFlowFilter_HostExpression()
    var
        H: Record "LT Y72 Link H";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        H.SetFilter("Dim Filter", 'D1|D2');
        Probe('or', H, 1);
        H.SetFilter("Dim Filter", '<>D1');
        Probe('not equal', H, 1);
        H.SetFilter("Dim Filter", 'D1..D2');
        Probe('range', H, 3);
        H.SetFilter("Dim Filter", '''''');
        Probe('blank value', H, 3);
        Observer.Expect('or host amount', '110.00');
        Observer.Expect('or log', 'open filters=[Code: P1, Dim Filter: D1|D2] dim=[D1|D2] int=[] date=[] has=Yes;agr P1 amount=110');
        Observer.Expect('or code', 'P1');
        Observer.Expect('or amount', '110.00');
        Observer.Expect('not equal host amount', '60.00');
        Observer.Expect('not equal log', 'open filters=[Code: P1, Dim Filter: <>D1] dim=[<>D1] int=[] date=[] has=Yes;agr P1 amount=60');
        Observer.Expect('not equal code', 'P1');
        Observer.Expect('not equal amount', '60.00');
        Observer.Expect('range host amount', '110.00');
        Observer.Expect('range log', 'open filters=[Code: P1, Dim Filter: D1..D2] dim=[D1..D2] int=[] date=[] has=Yes;agr P1 amount=110');
        Observer.Expect('range code', 'P1');
        Observer.Expect('range amount', '110.00');
        Observer.Expect('blank value host amount', '40.00');
        Observer.Expect('blank value log', 'open filters=[Code: P1, Dim Filter: ''''] dim=[''''] int=[] date=[] has=Yes;agr P1 amount=40');
        Observer.Expect('blank value code', 'P1');
        Observer.Expect('blank value amount', '40.00');
        Observer.Verify();
    end;




    [Test]
    procedure Link_IntegerFlowFilter()
    var
        H: Record "LT Y72 Link H";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        H.SetRange("Int Filter", 5);
        Probe('int 5', H, 1);
        H.SetRange("Int Filter", 1, 9);
        Probe('int range', H, 1);
        H.SetFilter("Int Filter", '<>5');
        Probe('int expression', H, 1);
        Observer.Expect('int 5 host amount', '150.00');
        Observer.Expect('int 5 log', 'open filters=[Code: P1, Int Filter: 5] dim=[] int=[5] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('int 5 code', 'P1');
        Observer.Expect('int 5 amount', '150.00');
        Observer.Expect('int range host amount', '150.00');
        Observer.Expect('int range log', 'open filters=[Code: P1, Int Filter: 1..9] dim=[] int=[1..9] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('int range code', 'P1');
        Observer.Expect('int range amount', '150.00');
        Observer.Expect('int expression host amount', '150.00');
        Observer.Expect('int expression log', 'open filters=[Code: P1, Int Filter: <>5] dim=[] int=[<>5] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('int expression code', 'P1');
        Observer.Expect('int expression amount', '150.00');
        Observer.Verify();
    end;




    [Test]
    procedure Link_DateFlowFilter_HostUnfiltered()
    var
        H: Record "LT Y72 Link H";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        Probe('date unfiltered', H, 2);
        H.SetRange("Date Filter", DMY2Date(1, 3, 2024), DMY2Date(31, 3, 2024));
        Probe('date range', H, 2);
        H.SetRange("Date Filter", DMY2Date(15, 3, 2024));
        Probe('date single', H, 2);
        H.SetFilter("Date Filter", '>%1', DMY2Date(1, 2, 2024));
        Probe('date expression', H, 2);
        Observer.Expect('date unfiltered host amount', '150.00');
        Observer.Expect('date unfiltered log', 'open filters=[Code: P1] dim=[] int=[] date=[] has=Yes;agr P1 amount=150');
        Observer.Expect('date unfiltered code', 'P1');
        Observer.Expect('date unfiltered amount', '150.00');
        Observer.Expect('date range host amount', '120.00');
        Observer.Expect('date range log', 'open filters=[Code: P1, Date Filter: 03/01/24..03/31/24] dim=[] int=[] date=[03/01/24..03/31/24] has=Yes;agr P1 amount=120');
        Observer.Expect('date range code', 'P1');
        Observer.Expect('date range amount', '120.00');
        Observer.Expect('date single host amount', '80.00');
        Observer.Expect('date single log', 'open filters=[Code: P1, Date Filter: 03/15/24] dim=[] int=[] date=[03/15/24] has=Yes;agr P1 amount=80');
        Observer.Expect('date single code', 'P1');
        Observer.Expect('date single amount', '80.00');
        Observer.Expect('date expression host amount', '140.00');
        Observer.Expect('date expression log', 'open filters=[Code: P1, Date Filter: >02/01/24] dim=[] int=[] date=[>02/01/24] has=Yes;agr P1 amount=140');
        Observer.Expect('date expression code', 'P1');
        Observer.Expect('date expression amount', '140.00');
        Observer.Verify();
    end;




    [Test]
    procedure Link_FlowFilter_SetOnTestPage()
    var
        H: Record "LT Y72 Link H";
        Host: TestPage "LT Y72 Link Host";
        Target: TestPage "LT Y72 Link Target";
    begin
        Seed();
        H.SetRange(Code, 'P1');
        Host.Trap();
        Page.Run(Page::"LT Y72 Link Host", H);
        Host.Filter.SetFilter("Dim Filter", 'D1');
        TakeLog();
        Target.Trap();
        Host.OpenAll.Invoke();
        Observer.Observe('log', TakeLog());
        Observer.Observe('amount', Target.AmountCtl.Value());
        Target.Close();
        Host.Close();
        Observer.Expect('log', 'open filters=[Code: P1, Dim Filter: D1] dim=[D1] int=[] date=[] has=Yes;agr P1 amount=90');
        Observer.Expect('amount', '90.00');
        Observer.Verify();
    end;



}
