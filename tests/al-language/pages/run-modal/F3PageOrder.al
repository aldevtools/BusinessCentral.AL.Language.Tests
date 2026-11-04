// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Log Mgt (67077); own objects 67129 - 67131
// Probe: Page.Run(Page, Rec) on a list page whose SourceTableView has ORDER: sorting(Grp, Qty) order(descending) where(Qty = filter('>=2')). With no record, an empty record, a record with SetCurrentKey(Grp, Qty) and Ascending(true) or Ascending(false), a record with SetCurrentKey(Qty) and a record with its own Qty filter: filters per group, current key, direction and view seen in OnOpenPage, and the rows a TestPage handler reads in order.
// The page and its table are copies of the ones in types/lt-code-digits-page-run-view (written for the same question) so that no earlier test of another codeunit can have touched them.

table 67129 "LT F3 Ord"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Qty) { }
        key(K3; Grp, Qty) { }
    }
}

page 67130 "LT F3 Ord List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT F3 Ord";
    SourceTableView = sorting(Grp, Qty) order(descending) where(Qty = filter('>=2'));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Log Mgt";
        Old: Integer;
        G0: Text;
        G1: Text;
        G2: Text;
        G3: Text;
    begin
        Old := Rec.FilterGroup();
        Rec.FilterGroup(0);
        G0 := Rec.GetFilters();
        Rec.FilterGroup(1);
        G1 := Rec.GetFilters();
        Rec.FilterGroup(2);
        G2 := Rec.GetFilters();
        Rec.FilterGroup(3);
        G3 := Rec.GetFilters();
        Rec.FilterGroup(Old);
        Log.Add('open: group-at-open=' + Format(Old) + ' g0=[' + G0 + '] g1=[' + G1 + '] g2=[' + G2 + '] g3=[' + G3 + ']');
        Log.Add('key=' + Rec.CurrentKey() + ' asc=' + Format(Rec.Ascending()) + ' view=[' + Rec.GetView() + ']');
    end;
}

codeunit 67131 "LT F3 Ord Page Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT F3 Ord";
        Data: List of [Text];
        Item: Text;
        Parts: List of [Text];
        Qty: Integer;
    begin
        Row.DeleteAll();
        Data.Add('R1;A;3');
        Data.Add('R2;A;1');
        Data.Add('R3;B;2');
        Data.Add('R4;B;5');
        Data.Add('R5;C;4');
        Data.Add('R6;A;6');
        foreach Item in Data do begin
            Parts := Item.Split(';');
            Evaluate(Qty, Parts.Get(3));
            Row.Init();
            Row."No." := CopyStr(Parts.Get(1), 1, 20);
            Row.Grp := CopyStr(Parts.Get(2), 1, 10);
            Row.Qty := Qty;
            Row.Insert();
        end;
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT F3 Ord List")
    var
        Log: Codeunit "LT F3 Log Mgt";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('rows=' + Rows);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_NoRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT F3 Ord List");
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R3,R6,R1,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R3,R6,R1,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_RecKeyGrpQtyAscending()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(true);
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R3,R6,R1,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_RecKeyGrpQtyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(false);
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R3,R6,R1,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_RecOwnQtyFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Row.SetFilter(Qty, '>=4');
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[Qty: >=4] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending) WHERE(Qty=FILTER(>=4))] | rows=R5,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_RecKeyQtyOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Qty);
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R3,R6,R1,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Order_RecFilterInGroupOne()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Ord";
    begin
        Seed();
        Log.Clear();
        Row.FilterGroup(1);
        Row.SetFilter(Qty, '>=3');
        Row.FilterGroup(0);
        Page.Run(Page::"LT F3 Ord List", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'open: group-at-open=0 g0=[] g1=[Qty: >=3] g2=[Qty: >=2] g3=[] | key=Grp,Qty asc=No view=[VERSION(1) SORTING(Grp,Qty) ORDER(Descending)] | rows=R5,R4,R6,R1,, | ');
        Observer.Verify();
    end;
}
