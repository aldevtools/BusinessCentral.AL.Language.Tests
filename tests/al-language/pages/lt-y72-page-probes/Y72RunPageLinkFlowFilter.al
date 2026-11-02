// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); tables 93862-93863, pages 93866-93868, test codeunit 93858
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what a RunPageLink that links a FlowFilter field of the host record (field("Dim Filter") on a Code FlowFilter, field("Int Filter")
//   on an Integer one, field("Date Filter") on a Date one) gives the target page: its Rec filters in OnOpenPage (GetFilters,
//   GetFilter per FlowFilter, HasFilter) and the FlowField Amount it shows. The host has no filter on the FlowFilter, a single value, an
//   expression ('D1|D2', '<>D1'), a range, or the filter is set on the TestPage. Dates are in the format of the CI (en-US).
//   Entries (Id, Code, Dim, D, Amount): 1 P1 D1 01/10/24 10; 2 P1 D2 02/10/24 20; 3 P1 blank 03/10/24 40; 4 P1 D1 03/15/24 80;
//   5 P2 D1 01/10/24 1000.
// Neighbours: pages/lt-y61-page-probes/Y61RunPageLinkCopyFilter.al (a Date FlowFilter whose host filter is a range), pages/lt-y41-page-probes/Y41RunPageLinkOnOpen.al:344.
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostUnfiltered_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostUnfiltered_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostUnfiltered_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostOneValue_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostOneValue_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostOneValue_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostExpression_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostExpression_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_CodeFlowFilter_HostExpression_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_IntegerFlowFilter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_IntegerFlowFilter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_IntegerFlowFilter_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_DateFlowFilter_HostUnfiltered_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_DateFlowFilter_HostUnfiltered_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_DateFlowFilter_HostUnfiltered_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Link_FlowFilter_SetOnTestPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_FlowFilter_SetOnTestPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Link_FlowFilter_SetOnTestPage_More3()
    begin
        Observer.More();
    end;
}
