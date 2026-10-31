// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of Y17ExtSetTableViewObjects.al
// Probe: gap cycle 1, G10 (corpus writer Y17). Report.SetTableView with a record whose table only a data item added by a reportextension uses:
// does the view reach the added item, how it combines with the item's DataItemLink and DataItemTableView, with no rows, a filter on the link
// field, the key of the view, and a temporary record (an item added at the top level does not compile: must-not-compile case 2340). Log: pre <item> [GetFilters] and <item>:<key> per row.
// BC versions: 27-29

codeunit 91849 "LT Y17 Ext SetTableView Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y17 Ext Log";

    local procedure Seed()
    var
        H: Record "LT Y17 Ext H";
        PH: Record "LT Y17 Ext PH";
        PL: Record "LT Y17 Ext PL";
        BL: Record "LT Y17 Ext BL";
    begin
        H.DeleteAll();
        PH.DeleteAll();
        PL.DeleteAll();
        BL.DeleteAll();
        AddH('B');
        AddH('A');
        AddPH(1, 'B', 'C1');
        AddPH(2, 'A', 'C1');
        AddPH(1, 'A', 'C2');
        BL."No." := 'A';
        BL."Line No." := 1;
        BL.Insert();
        BL."No." := 'B';
        BL.Insert();
        Log.Take();
    end;

    local procedure AddH(No: Code[20])
    var
        H: Record "LT Y17 Ext H";
    begin
        H."No." := No;
        H.Insert();
    end;

    local procedure AddPH(Subtype: Integer; No: Code[20]; Cust: Code[20])
    var
        PH: Record "LT Y17 Ext PH";
        PL: Record "LT Y17 Ext PL";
    begin
        PH.Subtype := Subtype;
        PH."No." := No;
        PH.Cust := Cust;
        PH.Insert();
        PL.Subtype := Subtype;
        PL."Doc No." := No;
        PL."Line No." := 10000;
        PL.Item := 'I1';
        PL.Insert();
        PL."Line No." := 20000;
        PL.Item := 'I2';
        PL.Insert();
    end;

    [TryFunction]
    local procedure TryRun(var Rpt: Report "LT Y17 Ext RB")
    begin
        Rpt.Run();
    end;

    local procedure RunAndObserve(var Observer: Codeunit "Probe Observer"; var Rpt: Report "LT Y17 Ext RB")
    begin
        ClearLastError();
        Observer.Observe('run ok', Format(TryRun(Rpt)));
        Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
    end;

    [Test]
    procedure ExtItem_SetTableView_Header()
    var
        Observer: Codeunit "Probe Observer";
        PH: Record "LT Y17 Ext PH";
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PH.SetFilter(Cust, 'C1');
        Rpt.SetTableView(PH);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;

    [Test]
    procedure ExtItem_SetTableView_HeaderAndLine()
    var
        Observer: Codeunit "Probe Observer";
        PH: Record "LT Y17 Ext PH";
        PL: Record "LT Y17 Ext PL";
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PH.SetFilter(Cust, 'C1');
        Rpt.SetTableView(PH);
        PL.SetRange(Item, 'I1');
        Rpt.SetTableView(PL);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;

    [Test]
    procedure ExtItem_SetTableView_NoMatchingRows()
    var
        Observer: Codeunit "Probe Observer";
        PH: Record "LT Y17 Ext PH";
        PL: Record "LT Y17 Ext PL";
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PH.DeleteAll();
        PL.DeleteAll();
        PH.SetFilter(Cust, 'C1');
        Rpt.SetTableView(PH);
        PL.SetRange(Item, 'I1');
        Rpt.SetTableView(PL);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;

    [Test]
    procedure ExtItem_SetTableView_FilterOnLinkField()
    var
        Observer: Codeunit "Probe Observer";
        PH: Record "LT Y17 Ext PH";
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PH.SetRange("No.", 'B');
        Rpt.SetTableView(PH);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;

    [Test]
    procedure ExtItem_SetTableView_KeyOfView()
    var
        Observer: Codeunit "Probe Observer";
        PH: Record "LT Y17 Ext PH";
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PH.SetCurrentKey(Cust);
        PH.SetFilter(Cust, 'C1|C2');
        Rpt.SetTableView(PH);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;

    [Test]
    procedure ExtItem_SetTableView_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        PHTemp: Record "LT Y17 Ext PH" temporary;
        Rpt: Report "LT Y17 Ext RB";
    begin
        Seed();
        PHTemp.Subtype := 9;
        PHTemp."No." := 'A';
        PHTemp.Cust := 'C1';
        PHTemp.Insert();
        PHTemp.SetFilter(Cust, 'C1');
        Rpt.SetTableView(PHTemp);
        RunAndObserve(Observer, Rpt);
        Observer.Finish();
    end;
}
