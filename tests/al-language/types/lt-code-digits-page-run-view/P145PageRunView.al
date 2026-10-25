// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P145 Row (74920), LT P145 Log Mgt (74922), LT P145 List A (74923), LT P145 List B (74924)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.Run(Page, Rec) on pages with SourceTableView: the filters of the page's Rec per filter group (0 to 3) seen from OnOpenPage, current key, direction and view, and the rows (order) a TestPage handler reads, with no record, an empty record and records that carry filters in several groups, keys and a view
// Writer SF (al-runtime-rs assumption page-run-record-view-order-applies): SF_ tests on List B and List C (page 89065, P145PageFixtures.al).
// BC versions: 29 (final facts are added after the measurement)

codeunit 74925 "LT P145 Page Run View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P145 Row";
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

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_NoRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT P145 List A");
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty)] | A rows=R2,R3,R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty)] | A rows=R2,R3,R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecFilterSameFieldAsView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetRange(Grp, 'C');
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[Grp: C] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty) WHERE(Grp=FILTER(C))] | A rows= | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecFilterOverlappingView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetRange(Grp, 'A');
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[Grp: A] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty) WHERE(Grp=FILTER(A))] | A rows=R2,R1,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecFilterOtherField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetFilter(Qty, '>=3');
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[Qty: >=3] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty) WHERE(Qty=FILTER(>=3))] | A rows=R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey(Qty);
        Row.Ascending(false);
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=No view=[VERSION(1) SORTING(Qty) ORDER(Descending)] | A rows=R6,R4,R1,R3,R2,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecKeyPrimary()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.SetCurrentKey("No.");
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty)] | A rows=R2,R3,R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecFilterInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.FilterGroup(2);
        Row.SetFilter(Qty, '>=3');
        Row.FilterGroup(0);
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[] g2=[Grp: A|B, Qty: >=3] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty)] | A rows=R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListAHandler')]
    procedure P145_A_RecFilterInGroup1()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P145 Log Mgt";
        Row: Record "LT P145 Row";
    begin
        Seed();
        Log.Clear();
        Row.FilterGroup(1);
        Row.SetFilter(Qty, '>=3');
        Row.FilterGroup(0);
        Page.Run(Page::"LT P145 List A", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'A open: group-at-open=0 g0=[] g1=[Qty: >=3] g2=[Grp: A|B] g3=[] | A key=Qty asc=Yes view=[VERSION(1) SORTING(Qty)] | A rows=R1,R4,R6,, | ');
        Observer.Verify();
    end;

    [PageHandler]
    procedure ListAHandler(var P: TestPage "LT P145 List A")
    var
        Log: Codeunit "LT P145 Log Mgt";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('A rows=' + Rows);
    end;

    [PageHandler]
    procedure ListBHandler(var P: TestPage "LT P145 List B")
    var
        Log: Codeunit "LT P145 Log Mgt";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('B rows=' + Rows);
    end;

    // ---- writer SF (al-runtime-rs assumption page-run-record-view-order-applies): Page.Run(Page, Rec) on List B (view sorting(Grp, Qty)
    //      order(descending)) and on List C (view sorting(Qty) order(ascending)) with records ascending and descending. ----

    local procedure SfRunB(var Row: Record "LT P145 Row"; WithRecord: Boolean): Text
    var
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Seed();
        Log.Clear();
        if WithRecord then
            Page.Run(Page::"LT P145 List B", Row)
        else
            Page.Run(Page::"LT P145 List B");
        exit(Log.Dump());
    end;

    local procedure SfRunC(var Row: Record "LT P145 Row"; WithRecord: Boolean): Text
    var
        Log: Codeunit "LT P145 Log Mgt";
    begin
        Seed();
        Log.Clear();
        if WithRecord then
            Page.Run(Page::"LT SF P145 List C", Row)
        else
            Page.Run(Page::"LT SF P145 List C");
        exit(Log.Dump());
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_NoRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Observer.Observe('log', SfRunB(Row, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Observer.Observe('log', SfRunB(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_RecViewKeyAscending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(true);
        Observer.Observe('log', SfRunB(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_RecViewKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(false);
        Observer.Observe('log', SfRunB(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_RecOtherKeyAscending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.SetCurrentKey(Qty);
        Row.Ascending(true);
        Observer.Observe('log', SfRunB(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListBHandler')]
    procedure SF_B_RecFilterAscending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.SetRange(Grp, 'A');
        Observer.Observe('log', SfRunB(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SfListCHandler')]
    procedure SF_C_NoRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Observer.Observe('log', SfRunC(Row, false));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SfListCHandler')]
    procedure SF_C_RecViewKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.SetCurrentKey(Qty);
        Row.Ascending(false);
        Observer.Observe('log', SfRunC(Row, true));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SfListCHandler')]
    procedure SF_C_RecPrimaryKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P145 Row";
    begin
        Row.Ascending(false);
        Observer.Observe('log', SfRunC(Row, true));
        Observer.Finish();
    end;

    [PageHandler]
    procedure SfListCHandler(var P: TestPage "LT SF P145 List C")
    var
        Log: Codeunit "LT P145 Log Mgt";
        Rows: Text;
        More: Boolean;
    begin
        Log.Add('C current=' + P.NoCtl.Value());
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('C rows=' + Rows);
    end;
}
