// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74347 74348, reports 74349 74350 74351, codeunit 74352
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Report.SetTableView and the record argument of Report.Run with a record of a table that the report has no data item over, that two data items of the report read, and with a temporary, marked or re-sorted (key, descending) record; observed by the rows each data item visits
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 item 54): table 83863, report 83864 and BN3_Report_DataItemTableViewConstZeroDate (DataItemTableView where(D = const(0D))).

table 74347 "LT P136 Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByQty; Qty) { }
    }
}

table 74348 "LT P136 Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Add(Value: Text)
    var
        L: Record "LT P136 Log";
    begin
        L.Txt := CopyStr(Value, 1, 100);
        L.Insert();
    end;
}

report 74349 "LT P136 Rp One"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Items; "LT P136 Item")
        {
            trigger OnAfterGetRecord()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('I:' + Items.Name);
            end;
        }
    }
}

report 74350 "LT P136 Rp Two"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(First; "LT P136 Item")
        {
            trigger OnAfterGetRecord()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('A:' + First.Name);
            end;
        }
        dataitem(Second; "LT P136 Item")
        {
            trigger OnAfterGetRecord()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('B:' + Second.Name);
            end;
        }
    }
}

report 74351 "LT P136 Rp None"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Seen; "LT P136 Log")
        {
            DataItemTableView = where(Txt = const('never'));

            trigger OnAfterGetRecord()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('L:' + Seen.Txt);
            end;
        }
    }

    trigger OnPreReport()
    var
        L: Record "LT P136 Log";
    begin
        L.Add('pre');
    end;
}

codeunit 74352 "LT P136 Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P136 Item";
        L: Record "LT P136 Log";
    begin
        Item.DeleteAll();
        L.DeleteAll();
        AddItem(1, 'a', 30);
        AddItem(2, 'b', 20);
        AddItem(3, 'c', 10);
    end;

    local procedure AddItem(Id: Integer; Name: Text; Qty: Integer)
    var
        Item: Record "LT P136 Item";
    begin
        Item.Id := Id;
        Item.Name := CopyStr(Name, 1, 30);
        Item.Qty := Qty;
        Item.Insert();
    end;

    local procedure Visited(): Text
    var
        L: Record "LT P136 Log";
        R: Text;
    begin
        if L.FindSet() then
            repeat
                R += L.Txt + ';';
            until L.Next() = 0;
        exit(R);
    end;

    [TryFunction]
    local procedure TryRunOne(var Item: Record "LT P136 Item")
    var
        Rp: Report "LT P136 Rp One";
    begin
        Rp.SetTableView(Item);
        Rp.UseRequestPage(false);
        Rp.Run();
    end;

    [TryFunction]
    local procedure TryRunTwo(var Item: Record "LT P136 Item")
    var
        Rp: Report "LT P136 Rp Two";
    begin
        Rp.SetTableView(Item);
        Rp.UseRequestPage(false);
        Rp.Run();
    end;

    [TryFunction]
    local procedure TryRunNone(var Item: Record "LT P136 Item")
    var
        Rp: Report "LT P136 Rp None";
    begin
        Rp.SetTableView(Item);
        Rp.UseRequestPage(false);
        Rp.Run();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok|' + Visited());
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Visited());
    end;

    [Test]
    procedure P136_Report_ViewOverTableWithoutDataItem()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        L: Record "LT P136 Log";
    begin
        Seed();
        Item.SetFilter(Id, '1..2');
        L.DeleteAll();
        Observer.Observe('setTableViewNone', Outcome(TryRunNone(Item)));
        L.DeleteAll();
        Item.Reset();
        Observer.Observe('unfilteredNone', Outcome(TryRunNone(Item)));
        L.DeleteAll();
        Item.SetRange(Id, 99);
        Observer.Observe('emptyViewNone', Outcome(TryRunNone(Item)));
        L.DeleteAll();
        asserterror Report.Run(Report::"LT P136 Rp None", false, false, Item);
        Observer.ObserveError('af219');
        Observer.Observe('staticRunNone', Visited());
        Observer.Expect('setTableViewNone', 'error|The LT P136 Rp None report does not have a DataItem that uses the table (Table 74347 LT P136 Item) specified in the function SetTableView.|ReportNoDataItem|');
        Observer.Expect('unfilteredNone', 'error|The LT P136 Rp None report does not have a DataItem that uses the table (Table 74347 LT P136 Item) specified in the function SetTableView.|ReportNoDataItem|');
        Observer.Expect('emptyViewNone', 'error|The LT P136 Rp None report does not have a DataItem that uses the table (Table 74347 LT P136 Item) specified in the function SetTableView.|ReportNoDataItem|');
        Observer.Expect('af219|text', 'The LT P136 Rp None report does not have a DataItem that uses the table (Table 74347 LT P136 Item) specified in the function SetTableView.');
        Observer.Expect('af219|code', 'ReportNoDataItem');
        Observer.Expect('staticRunNone', '');
        Observer.Verify();
    end;

    [Test]
    procedure P136_Report_ViewWithTwoDataItemsOverTheTable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        L: Record "LT P136 Log";
    begin
        Seed();
        L.DeleteAll();
        Observer.Observe('unfilteredTwo', Outcome(TryRunTwo(Item)));
        L.DeleteAll();
        Item.SetFilter(Id, '1..2');
        Observer.Observe('filteredTwo', Outcome(TryRunTwo(Item)));
        L.DeleteAll();
        Report.Run(Report::"LT P136 Rp Two", false, false, Item);
        Observer.Observe('staticRunTwo', Visited());
        Observer.Expect('unfilteredTwo', 'ok|A:a;A:b;A:c;B:a;B:b;B:c;');
        Observer.Expect('filteredTwo', 'ok|A:a;A:b;B:a;B:b;B:c;');
        Observer.Expect('staticRunTwo', 'A:a;A:b;B:a;B:b;B:c;');
        Observer.Verify();
    end;

    [Test]
    procedure P136_Report_ViewTemporaryMarkedAndSorted()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P136 Item";
        Temp: Record "LT P136 Item" temporary;
        L: Record "LT P136 Log";
    begin
        Seed();
        // temporary record
        Temp.Id := 7;
        Temp.Name := 'tmp7';
        Temp.Qty := 1;
        Temp.Insert();
        Temp.Id := 8;
        Temp.Name := 'tmp8';
        Temp.Qty := 2;
        Temp.Insert();
        L.DeleteAll();
        Observer.Observe('temporary', Outcome(TryRunOne(Temp)));
        L.DeleteAll();
        Temp.SetRange(Id, 8);
        Observer.Observe('temporaryFiltered', Outcome(TryRunOne(Temp)));
        // marked only
        L.DeleteAll();
        Item.Get(1);
        Item.Mark(true);
        Item.Get(3);
        Item.Mark(true);
        Item.MarkedOnly(true);
        Observer.Observe('markedOnly', Outcome(TryRunOne(Item)));
        Item.MarkedOnly(false);
        Item.ClearMarks();
        // a mark without MarkedOnly
        L.DeleteAll();
        Item.Reset();
        Item.Get(2);
        Item.Mark(true);
        Observer.Observe('markedNotOnly', Outcome(TryRunOne(Item)));
        Item.Reset();
        Item.ClearMarks();
        // re-sorted
        L.DeleteAll();
        Item.SetCurrentKey(Qty);
        Observer.Observe('keyQty', Outcome(TryRunOne(Item)));
        L.DeleteAll();
        Item.SetCurrentKey(Qty);
        Item.Ascending(false);
        Observer.Observe('keyQtyDescending', Outcome(TryRunOne(Item)));
        L.DeleteAll();
        Item.Reset();
        Item.Ascending(false);
        Observer.Observe('descendingPrimary', Outcome(TryRunOne(Item)));
        L.DeleteAll();
        Item.Reset();
        Item.SetCurrentKey(Qty);
        Item.SetRange(Qty, 10, 20);
        Observer.Observe('keyQtyFiltered', Outcome(TryRunOne(Item)));
        Observer.Expect('temporary', 'ok|I:a;I:b;I:c;');
        Observer.Expect('temporaryFiltered', 'ok|');
        Observer.Expect('markedOnly', 'ok|I:a;I:c;');
        Observer.Expect('markedNotOnly', 'ok|I:a;I:b;I:c;');
        Observer.Expect('keyQty', 'ok|I:c;I:b;I:a;');
        Observer.Expect('keyQtyDescending', 'ok|I:a;I:b;I:c;');
        Observer.Expect('descendingPrimary', 'ok|I:c;I:b;I:a;');
        Observer.Expect('keyQtyFiltered', 'ok|I:c;I:b;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BN3_TryRunZeroDate()
    begin
        Report.Run(Report::"LT BN3 Rp ZeroDate", false);
    end;

    // Corpus #664 item 54: DataItemTableView = where(D = const(0D)) compiles; which rows the data item visits and the filter text it sees.
    [Test]
    procedure BN3_Report_DataItemTableViewConstZeroDate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN3 Dated";
        L: Record "LT P136 Log";
    begin
        Row.DeleteAll();
        L.DeleteAll();
        Row.Id := 1;
        Row.D := 0D;
        Row.Insert();
        Row.Id := 2;
        Row.D := DMY2Date(1, 1, 2020);
        Row.Insert();
        Row.Id := 3;
        Row.D := 0D;
        Row.Insert();
        Observer.Observe('run', Outcome(BN3_TryRunZeroDate()));
        Observer.Expect('run', 'error|The format of the Date '''''''' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate|');
        Observer.Verify();
    end;
}

// Corpus #664 item 54 (microsoft/AL issue 6898): a report data item whose DataItemTableView filters a Date field with const(0D).
table 83863 "LT BN3 Dated"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 83864 "LT BN3 Rp ZeroDate"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Rows; "LT BN3 Dated")
        {
            DataItemTableView = where(D = const(0D));

            trigger OnPreDataItem()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('filters=' + Rows.GetFilters());
            end;

            trigger OnAfterGetRecord()
            var
                L: Record "LT P136 Log";
            begin
                L.Add('row ' + Format(Rows.Id));
            end;
        }
    }
}
