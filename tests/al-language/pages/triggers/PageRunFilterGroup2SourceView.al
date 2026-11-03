// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: table 72910, log codeunit 72911 (SingleInstance, used by test codeunit 72914 only), pages 72912-72913, test codeunit 72914
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.Run(Page, Rec) / Page.RunModal where Rec has filters in filter group 2 (and 0) and the page's SourceTableView filters the same field or another field: which filters apply (rows), and Rec.GetFilter / GetFilters in each filter group 0 to 3 seen from OnOpenPage
// BC versions: 29 (27 and 28 by CI)

table 72910 "LT PRG2 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72911 "LT PRG2 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(What: Text)
    begin
        Entries += What + ' | ';
    end;

    procedure Take(): Text
    var
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

page 72912 "LT PRG2 List Grp"
{
    PageType = List;
    SourceTable = "LT PRG2 Row";
    SourceTableView = where(Grp = filter('A|B'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(GrpF; Rec.Grp) { ApplicationArea = All; }
                field(QtyF; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PRG2 Log";
        Line: Text;
        g: Integer;
    begin
        Line := 'open grp=' + Format(Rec.FilterGroup());
        for g := 0 to 3 do begin
            Rec.FilterGroup(g);
            Line += ' g' + Format(g) + '=[' + Rec.GetFilters() + ']{Grp=' + Rec.GetFilter(Grp) + ';Qty=' + Rec.GetFilter(Qty) + '}';
        end;
        Rec.FilterGroup(0);
        Line += ' view=[' + Rec.GetView() + ']';
        Log.Add(Line);
    end;
}

page 72913 "LT PRG2 List Qty"
{
    PageType = List;
    SourceTable = "LT PRG2 Row";
    SourceTableView = where(Qty = filter(>=3));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(GrpF; Rec.Grp) { ApplicationArea = All; }
                field(QtyF; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PRG2 Log";
        Line: Text;
        g: Integer;
    begin
        Line := 'open grp=' + Format(Rec.FilterGroup());
        for g := 0 to 3 do begin
            Rec.FilterGroup(g);
            Line += ' g' + Format(g) + '=[' + Rec.GetFilters() + ']{Grp=' + Rec.GetFilter(Grp) + ';Qty=' + Rec.GetFilter(Qty) + '}';
        end;
        Rec.FilterGroup(0);
        Line += ' view=[' + Rec.GetView() + ']';
        Log.Add(Line);
    end;
}

codeunit 72914 "LT PRG2 Page Run Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
    begin
        R.DeleteAll();
        Log.Clear();
        Add(1, 'A', 1);
        Add(2, 'A', 4);
        Add(3, 'B', 2);
        Add(4, 'B', 5);
        Add(5, 'C', 3);
        Add(6, 'C', 6);
    end;

    local procedure Add(Id: Integer; Grp: Code[10]; Qty: Integer)
    var
        R: Record "LT PRG2 Row";
    begin
        R.Init();
        R.Id := Id;
        R.Grp := Grp;
        R.Qty := Qty;
        R.Insert();
    end;

    // Grp view (A|B): record filters in group 2 on the same field and on the other field.

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group2SameField_Overlapping()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Observe('rec-g0', R.GetFilters());
        R.FilterGroup(2);
        Observer.Observe('rec-g2', R.GetFilters());
        R.FilterGroup(0);
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=1,2,3,4,0, | ');
        Observer.Expect('rec-g0', '');
        Observer.Expect('rec-g2', 'Grp: B');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group2SameField_Disjoint()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'C');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=1,2,3,4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group2SameField_Wider()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Grp, 'A|B|C');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=1,2,3,4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group2OtherField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Qty, '>=3');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B, Qty: >=3]{Grp=A|B;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=2,4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group0SameField_Group2SameField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(0);
        R.SetRange(Grp, 'A');
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[Grp: A]{Grp=A;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id) WHERE(Grp=FILTER(A))] | rows=1,2,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group0OtherField_Group2SameField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(0);
        R.SetFilter(Qty, '>=3');
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[Qty: >=3]{Grp=;Qty=>=3} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id) WHERE(Qty=FILTER(>=3))] | rows=2,4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group0SameField_Group2OtherField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Qty, '>=3');
        R.FilterGroup(0);
        R.SetRange(Grp, 'A');
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[Grp: A]{Grp=A;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B, Qty: >=3]{Grp=A|B;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id) WHERE(Grp=FILTER(A))] | rows=2,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpHandler')]
    procedure P197_RunGrpView_Group2And3SameField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(3);
        R.SetRange(Grp, 'A');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[Grp: A]{Grp=A;Qty=} view=[VERSION(1) SORTING(Id)] | rows=1,2,0, | ');
        Observer.Verify();
    end;

    // Qty view (>=3): record filters in group 2 on the same field and on the other field.

    [Test]
    [HandlerFunctions('QtyHandler')]
    procedure P197_RunQtyView_Group2SameField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Qty, '<=5');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Qty", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Qty: >=3]{Grp=;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=2,4,5,6,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtyHandler')]
    procedure P197_RunQtyView_Group2OtherField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(0);
        Page.Run(Page::"LT PRG2 List Qty", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: B, Qty: >=3]{Grp=B;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtyHandler')]
    procedure P197_RunQtyView_Group2SameField_Group0OtherField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Qty, 1, 4);
        R.FilterGroup(0);
        R.SetRange(Grp, 'A');
        Page.Run(Page::"LT PRG2 List Qty", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[Grp: A]{Grp=A;Qty=} g1=[]{Grp=;Qty=} g2=[Qty: >=3]{Grp=;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id) WHERE(Grp=FILTER(A))] | rows=2,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtyHandler')]
    procedure P197_RunQtyView_NoRecordFilter()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Page.Run(Page::"LT PRG2 List Qty", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Qty: >=3]{Grp=;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=2,4,5,6,0, | ');
        Observer.Verify();
    end;

    // RunModal with the same shapes.

    [Test]
    [HandlerFunctions('GrpModalHandler')]
    procedure P197_RunModalGrpView_Group2SameField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Grp, 'B');
        R.FilterGroup(0);
        Page.RunModal(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B]{Grp=A|B;Qty=} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=1,2,3,4,0, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('GrpModalHandler')]
    procedure P197_RunModalGrpView_Group2OtherField()
    var
        R: Record "LT PRG2 Row";
        Log: Codeunit "LT PRG2 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Qty, '>=3');
        R.FilterGroup(0);
        Page.RunModal(Page::"LT PRG2 List Grp", R);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'open grp=0 g0=[]{Grp=;Qty=} g1=[]{Grp=;Qty=} g2=[Grp: A|B, Qty: >=3]{Grp=A|B;Qty=>=3} g3=[]{Grp=;Qty=} view=[VERSION(1) SORTING(Id)] | rows=2,4,0, | ');
        Observer.Verify();
    end;

    local procedure WalkGrp(var P: TestPage "LT PRG2 List Grp")
    var
        Log: Codeunit "LT PRG2 Log";
        Seq: Text;
    begin
        if P.First() then
            repeat
                Seq += P.IdF.Value() + ',';
            until not P.Next();
        Log.Add('rows=' + Seq);
    end;

    [PageHandler]
    procedure GrpHandler(var P: TestPage "LT PRG2 List Grp")
    begin
        WalkGrp(P);
    end;

    [ModalPageHandler]
    procedure GrpModalHandler(var P: TestPage "LT PRG2 List Grp")
    begin
        WalkGrp(P);
    end;

    [PageHandler]
    procedure QtyHandler(var P: TestPage "LT PRG2 List Qty")
    var
        Log: Codeunit "LT PRG2 Log";
        Seq: Text;
    begin
        if P.First() then
            repeat
                Seq += P.IdF.Value() + ',';
            until not P.Next();
        Log.Add('rows=' + Seq);
    end;
}
