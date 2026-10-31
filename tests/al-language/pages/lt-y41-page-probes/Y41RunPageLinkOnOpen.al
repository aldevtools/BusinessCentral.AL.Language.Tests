// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 92800 (Y41Log.al); tables 92813-92814, pages 92815-92819 and 92358-92359,
//   test codeunit 92360
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what Rec holds in the OnOpenPage (and the first OnAfterGetCurrRecord) of a page an action opens through RunPageLink, for the
//   shapes handlers/TestActionRunPageLinkFilterGroup.al (QZ_*) does not pin: a ListPlus, Document and Worksheet target with two
//   field(..) links; a FlowFilter link field (and the FlowField it filters, after CalcFields in OnOpenPage); a temporary source
//   table whose OnOpenPage inserts a row with Code '' and two more rows; an Option and a Date link field; a filter(..) entry; and
//   a RunPageView beside the link. Log line: <page> open|agcr code= number= kind= day= filters= gf0=<GetFilter(Code)> count= read=.
//   The page under test is caught with TestPage.Trap.
// BC versions: all (CI)

table 92813 "LT Y41 RPL Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Number; Integer) { }
        field(3; Kind; Option) { OptionMembers = A,B; }
        field(4; Day; Date) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 92814 "LT Y41 RPL Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Number; Integer) { }
        field(3; Kind; Option) { OptionMembers = A,B; }
        field(4; Day; Date) { }
        field(5; "Code Filter"; Code[20]) { FieldClass = FlowFilter; }
        field(6; "Host Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y41 RPL Host" where("Code" = field("Code Filter")));
        }
    }

    keys
    {
        key(PK; "Code", Number) { Clustered = true; }
        key(ByNumber; Number) { }
    }

    procedure Describe(): Text
    begin
        exit('code=' + Rec."Code" + ' number=' + Format(Rec.Number) + ' kind=' + Format(Rec.Kind) + ' day=' + Format(Rec.Day, 0, 9) +
            ' filters=' + Rec.GetFilters() + ' gf0=' + Rec.GetFilter("Code") + ' count=' + Format(Rec.Count()));
    end;
}

page 92815 "LT Y41 RPL ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT Y41 RPL Target";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('listplus open ' + Rec.Describe() + ' read=' + ReadCode());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('listplus agcr ' + Rec.Describe());
    end;

    local procedure ReadCode(): Text
    begin
        exit(Rec."Code" + '/' + Format(Rec.Number));
    end;
}

page 92816 "LT Y41 RPL Document"
{
    PageType = Document;
    SourceTable = "LT Y41 RPL Target";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('document open ' + Rec.Describe() + ' read=' + ReadCode());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('document agcr ' + Rec.Describe());
    end;

    local procedure ReadCode(): Text
    begin
        exit(Rec."Code" + '/' + Format(Rec.Number));
    end;
}

page 92817 "LT Y41 RPL Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y41 RPL Target";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('worksheet open ' + Rec.Describe() + ' read=' + ReadCode());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('worksheet agcr ' + Rec.Describe());
    end;

    local procedure ReadCode(): Text
    begin
        exit(Rec."Code" + '/' + Format(Rec.Number));
    end;
}

page 92818 "LT Y41 RPL Temp List"
{
    PageType = List;
    SourceTable = "LT Y41 RPL Target";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('temp open ' + Rec.Describe());
        Rec."Code" := '';
        Log.AddLine('temp insert blank=' + Format(Rec.Insert()) + ' ' + Rec.Describe());
        Rec.Init();
        Rec."Code" := 'T1';
        Rec.Number := 1;
        Rec.Insert();
        Rec.Init();
        Rec."Code" := 'P1';
        Rec.Number := 2;
        Rec.Insert();
        Log.AddLine('temp after inserts ' + Rec.Describe());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('temp agcr ' + Rec.Describe());
    end;
}

page 92819 "LT Y41 RPL List"
{
    PageType = List;
    SourceTable = "LT Y41 RPL Target";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Rec.CalcFields("Host Count");
        Log.AddLine('list open ' + Rec.Describe() + ' cf=' + Rec.GetFilter("Code Filter") + ' hostcount=' + Format(Rec."Host Count"));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Rec.CalcFields("Host Count");
        Log.AddLine('list agcr ' + Rec.Describe() + ' hostcount=' + Format(Rec."Host Count"));
    end;
}

page 92358 "LT Y41 RPL Card"
{
    PageType = Card;
    SourceTable = "LT Y41 RPL Target";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('card open ' + Rec.Describe());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('card agcr ' + Rec.Describe());
    end;
}

page 92359 "LT Y41 RPL Host Card"
{
    PageType = Card;
    SourceTable = "LT Y41 RPL Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NumberCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ToListPlus)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL ListPlus";
                RunPageLink = "Code" = field("Code"), Number = field(Number);
            }
            action(ToDocument)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Document";
                RunPageLink = "Code" = field("Code"), Number = field(Number);
            }
            action(ToWorksheet)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Worksheet";
                RunPageLink = "Code" = field("Code"), Number = field(Number);
            }
            action(ToFlowFilterList)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL List";
                RunPageLink = "Code Filter" = field("Code");
            }
            action(ToTempList)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Temp List";
                RunPageLink = "Code" = field("Code");
            }
            action(CardOption)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Card";
                RunPageLink = Kind = field(Kind);
            }
            action(CardDate)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Card";
                RunPageLink = Day = field(Day);
            }
            action(CardFilter)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Card";
                RunPageLink = "Code" = filter('P1');
            }
            action(CardLinkView)
            {
                ApplicationArea = All;
                RunObject = page "LT Y41 RPL Card";
                RunPageLink = "Code" = field("Code");
                RunPageView = sorting(Number) where(Number = const(7));
            }
        }
    }
}

codeunit 92360 "LT Y41 RunPageLink Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    // Host P1 (Number 7, Kind B, Day 2026-01-15) and P2; targets P1/7 (A, same day), P1/8 (B, day after), P2/7 (A, same day).
    local procedure Seed(var Host: TestPage "LT Y41 RPL Host Card")
    var
        H: Record "LT Y41 RPL Host";
        T: Record "LT Y41 RPL Target";
        Log: Record "LT Y41 Log";
    begin
        H.DeleteAll();
        T.DeleteAll();
        AddHost('P1', 7, 1, 20260115D);
        AddHost('P2', 9, 0, 20260116D);
        AddTarget('P1', 7, 0, 20260115D);
        AddTarget('P1', 8, 1, 20260116D);
        AddTarget('P2', 7, 0, 20260115D);
        Log.ClearLog();
        Host.OpenView();
        Host.GoToKey('P1');
    end;

    local procedure AddHost(NewCode: Code[20]; NewNumber: Integer; NewKind: Integer; NewDay: Date)
    var
        H: Record "LT Y41 RPL Host";
    begin
        H.Init();
        H."Code" := NewCode;
        H.Number := NewNumber;
        H.Kind := NewKind;
        H.Day := NewDay;
        H.Insert();
    end;

    local procedure AddTarget(NewCode: Code[20]; NewNumber: Integer; NewKind: Integer; NewDay: Date)
    var
        T: Record "LT Y41 RPL Target";
    begin
        T.Init();
        T."Code" := NewCode;
        T.Number := NewNumber;
        T.Kind := NewKind;
        T.Day := NewDay;
        T.Insert();
    end;

    local procedure LogNow(): Text
    var
        Log: Record "LT Y41 Log";
    begin
        exit(Log.Dump());
    end;

    [Test]
    procedure RPL_ListPlus_FieldLinks()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL ListPlus";
    begin
        Seed(Host);
        P.Trap();
        Host.ToListPlus.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_List_FlowFilterLink()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL List";
    begin
        Seed(Host);
        P.Trap();
        Host.ToFlowFilterList.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_TempList_InsertInOpen()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Temp List";
        Shown: Text;
    begin
        Seed(Host);
        P.Trap();
        Host.ToTempList.Invoke();
        Obs.Observe('log', LogNow());
        if P.First() then
            repeat
                Shown += P.CodeCtl.Value() + '/' + P.NumberCtl.Value() + ',';
            until not P.Next();
        Obs.Observe('shown rows', Shown);
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Card_OptionLink()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Card";
    begin
        Seed(Host);
        P.Trap();
        Host.CardOption.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Card_DateLink()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Card";
    begin
        Seed(Host);
        P.Trap();
        Host.CardDate.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Card_FilterEntry()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Card";
    begin
        Seed(Host);
        P.Trap();
        Host.CardFilter.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Card_LinkPlusView()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Card";
    begin
        Seed(Host);
        P.Trap();
        Host.CardLinkView.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Document_FieldLink()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Document";
    begin
        Seed(Host);
        P.Trap();
        Host.ToDocument.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;

    [Test]
    procedure RPL_Worksheet_FieldLink()
    var
        Host: TestPage "LT Y41 RPL Host Card";
        P: TestPage "LT Y41 RPL Worksheet";
    begin
        Seed(Host);
        P.Trap();
        Host.ToWorksheet.Invoke();
        Obs.Observe('log', LogNow());
        Obs.Observe('shown', P.CodeCtl.Value() + '/' + P.NumberCtl.Value());
        P.Close();
        Host.Close();
        Obs.Finish();
    end;
}
