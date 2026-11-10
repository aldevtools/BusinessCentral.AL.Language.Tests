// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Base Application codeunit PeriodPageManagement and the virtual table Date; own tables
//   62650 62651, log codeunit 62652, part pages 62653..62655, host page 62656, test codeunit 62657
// Probe: observe-only. Area: what a ListPart shows after TestPart.Filter.SetFilter, for a control over a record field, a control
//   over an expression that calls a codeunit, and a control over a page variable that OnAfterGetRecord sets.
//   TestTestFilter.al (TestPart filter, record field after First) pins the record field of a plain part. Not pinned (al-runner issue
//   7476): the expression and variable controls; a part over the virtual table Date that walks periods in OnFindRecord and
//   OnNextRecord through PeriodPageManagement (the Base Application period pages), which the host hands its row in OnAfterGetRecord;
//   reading without First after the filter; Next inside the filter; a filter that admits no row; the host moving to another row
//   while the part filter is set; a filter that is cleared again.
// The three parts: Periods (Date, OnFindRecord and OnNextRecord, no link), Entries (own table, SubPageLink, no find triggers),
//   EntriesFind (the same with OnFindRecord = Rec.Find(Which) and OnNextRecord = Rec.Next(Steps)).
// Entries (item: date = quantity): I1: 15 March 2025 = 5; I2: 15 = 120, 16 = 7, 17 = 11; I3: 15 = 9, 16 = 13.
// Observed: the values the part row shows and how often each part trigger ran since the last observation (log).
// local object: the find triggers of the parts and the expression controls are what the test checks
// BC versions: 27, 28, 29

table 62650 "TP PF Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 62651 "TP PF Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Posting Date"; Date) { DataClassification = SystemMetadata; }
        field(3; Qty; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Item No.", "Posting Date") { Clustered = true; }
    }
}

codeunit 62652 "TP PF Calc"
{
    SingleInstance = true;

    var
        Counts: Dictionary of [Text, Integer];

    procedure Add(Name: Text)
    begin
        if Counts.ContainsKey(Name) then
            Counts.Set(Name, Counts.Get(Name) + 1)
        else
            Counts.Add(Name, 1);
    end;

    procedure Take() Result: Text
    var
        Name: Text;
    begin
        foreach Name in Counts.Keys() do
            Result += Name + '=' + Format(Counts.Get(Name)) + ' ';
        Clear(Counts);
        Result := '[' + Result + ']';
    end;

    procedure PeriodQty(ItemNo: Code[10]; FromDate: Date; ToDate: Date) Result: Integer
    var
        Entry: Record "TP PF Entry";
    begin
        Add('calc');
        Entry.SetRange("Item No.", ItemNo);
        Entry.SetRange("Posting Date", FromDate, ToDate);
        if Entry.FindSet() then
            repeat
                Result += Entry.Qty;
            until Entry.Next() = 0;
    end;

    procedure Twice(Qty: Integer): Integer
    begin
        Add('calc');
        exit(2 * Qty);
    end;
}

page 62653 "TP PF Period Part"
{
    PageType = ListPart;
    SourceTable = Date;
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Period Start"; Rec."Period Start") { ApplicationArea = All; }
                field(ExprQty; Calc.PeriodQty(ItemNo, Rec."Period Start", NormalDate(Rec."Period End"))) { ApplicationArea = All; }
                field(VarQty; RowQty) { ApplicationArea = All; }
                field(ItemShown; ItemNo) { ApplicationArea = All; }
            }
        }
    }

    var
        Calc: Codeunit "TP PF Calc";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        PeriodType: Enum "Analysis Period Type";
        ItemNo: Code[10];
        RowQty: Integer;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Calc.Add('P.open');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Calc.Add('P.find(' + Which + ')');
        exit(PeriodPageManagement.FindDate(CopyStr(Which, 1, 3), Rec, PeriodType));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        Calc.Add('P.next');
        exit(PeriodPageManagement.NextDate(Steps, Rec, PeriodType));
    end;

    trigger OnAfterGetRecord()
    begin
        Calc.Add('P.agr');
        RowQty := Calc.PeriodQty(ItemNo, Rec."Period Start", NormalDate(Rec."Period End"));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Calc.Add('P.agcr');
    end;

    procedure Initialize(NewItemNo: Code[10])
    begin
        ItemNo := NewItemNo;
    end;
}

page 62654 "TP PF Entry Part"
{
    PageType = ListPart;
    SourceTable = "TP PF Entry";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
                field(ExprQty; Calc.Twice(Rec.Qty)) { ApplicationArea = All; }
                field(VarQty; RowQty) { ApplicationArea = All; }
            }
        }
    }

    var
        Calc: Codeunit "TP PF Calc";
        RowQty: Integer;

    trigger OnAfterGetRecord()
    begin
        Calc.Add('E.agr');
        RowQty := 3 * Rec.Qty;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Calc.Add('E.agcr');
    end;
}

page 62655 "TP PF Entry Find Part"
{
    PageType = ListPart;
    SourceTable = "TP PF Entry";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
                field(ExprQty; Calc.Twice(Rec.Qty)) { ApplicationArea = All; }
                field(VarQty; RowQty) { ApplicationArea = All; }
            }
        }
    }

    var
        Calc: Codeunit "TP PF Calc";
        RowQty: Integer;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Calc.Add('F.find(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        Calc.Add('F.next');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        Calc.Add('F.agr');
        RowQty := 3 * Rec.Qty;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Calc.Add('F.agcr');
    end;
}

page 62656 "TP PF Host"
{
    PageType = ListPlus;
    SourceTable = "TP PF Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Periods; "TP PF Period Part")
            {
                ApplicationArea = All;
            }
            part(Entries; "TP PF Entry Part")
            {
                ApplicationArea = All;
                SubPageLink = "Item No." = field("No.");
            }
            part(EntriesFind; "TP PF Entry Find Part")
            {
                ApplicationArea = All;
                SubPageLink = "Item No." = field("No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrPage.Periods.Page.Initialize(Rec."No.");
    end;
}

codeunit 62657 "TP PF Part Filter Expression"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Calc: Codeunit "TP PF Calc";

    local procedure Day(DayNo: Integer): Date
    begin
        exit(DMY2Date(DayNo, 3, 2025));
    end;

    local procedure Seed()
    var
        Item: Record "TP PF Item";
        Entry: Record "TP PF Entry";
    begin
        Entry.DeleteAll();
        Item.DeleteAll();
        AddItem('I1');
        AddItem('I2');
        AddItem('I3');
        AddEntry('I1', 15, 5);
        AddEntry('I2', 15, 120);
        AddEntry('I2', 16, 7);
        AddEntry('I2', 17, 11);
        AddEntry('I3', 15, 9);
        AddEntry('I3', 16, 13);
    end;

    local procedure AddItem(No: Code[10])
    var
        Item: Record "TP PF Item";
    begin
        Item."No." := No;
        Item.Insert();
    end;

    local procedure AddEntry(ItemNo: Code[10]; DayNo: Integer; Qty: Integer)
    var
        Entry: Record "TP PF Entry";
    begin
        Entry."Item No." := ItemNo;
        Entry."Posting Date" := Day(DayNo);
        Entry.Qty := Qty;
        Entry.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "TP PF Host")
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('I2');
        Calc.Take();
    end;

    local procedure SayPeriods(Name: Text; var Host: TestPage "TP PF Host")
    begin
        Observer.Observe(Name, 'start=' + Host.Periods."Period Start".Value + ' expr=' + Host.Periods.ExprQty.Value + ' var=' + Host.Periods.VarQty.Value + ' item=' + Host.Periods.ItemShown.Value);
        Observer.Observe(Name + ' log', Calc.Take());
    end;

    // The quantity controls only: the row a part over Date opens on depends on the work date.
    local procedure SayPeriodQty(Name: Text; var Host: TestPage "TP PF Host")
    begin
        Observer.Observe(Name, 'expr=' + Host.Periods.ExprQty.Value + ' var=' + Host.Periods.VarQty.Value + ' item=' + Host.Periods.ItemShown.Value);
        Observer.Observe(Name + ' log', Calc.Take());
    end;

    [Test]
    procedure Periods_FilterOneDay_First_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(15)));
        Observer.Observe('filter log', Calc.Take());
        Observer.Observe('First', Format(Host.Periods.First()));
        SayPeriods('row', Host);
        Observer.Observe('filter text', Host.Periods.Filter.GetFilter("Period Start"));
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_FilterOneDay_ReadWithoutFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(15)));
        Observer.Observe('filter log', Calc.Take());
        SayPeriods('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_ReadBeforeFilter_ThenFilter_ThenFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        SayPeriodQty('before', Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(16)));
        SayPeriods('after filter', Host);
        Observer.Observe('First', Format(Host.Periods.First()));
        SayPeriods('after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_FilterThreeDays_FirstNextNextNext()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(15)) + '..' + Format(Day(17)));
        Observer.Observe('First', Format(Host.Periods.First()));
        SayPeriods('row 1', Host);
        Observer.Observe('Next 1', Format(Host.Periods.Next()));
        SayPeriods('row 2', Host);
        Observer.Observe('Next 2', Format(Host.Periods.Next()));
        SayPeriods('row 3', Host);
        Observer.Observe('Next 3', Format(Host.Periods.Next()));
        SayPeriods('row after end', Host);
        Observer.Observe('Last', Format(Host.Periods.Last()));
        SayPeriods('last row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_FilterOneDay_HostMovesToNextItem()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(15)));
        Host.Periods.First();
        SayPeriods('I2', Host);
        Observer.Observe('host Next', Format(Host.Next()));
        SayPeriods('I3 no move', Host);
        Observer.Observe('filter text', Host.Periods.Filter.GetFilter("Period Start"));
        Observer.Observe('First', Format(Host.Periods.First()));
        SayPeriods('I3 after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_FilterDayWithoutEntries_First_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(20)));
        Observer.Observe('First', Format(Host.Periods.First()));
        SayPeriods('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Periods_FilterThenClearFilter_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Periods.Filter.SetFilter("Period Start", Format(Day(15)));
        Host.Periods.First();
        SayPeriods('filtered', Host);
        Host.Periods.Filter.SetFilter("Period Start", '');
        SayPeriods('cleared', Host);
        Observer.Observe('filter text', '[' + Host.Periods.Filter.GetFilter("Period Start") + ']');
        Host.Close();
        Observer.Finish();
    end;

    local procedure SayEntries(Name: Text; var Host: TestPage "TP PF Host")
    begin
        Observer.Observe(Name, 'date=' + Host.Entries."Posting Date".Value + ' qty=' + Host.Entries.Qty.Value + ' expr=' + Host.Entries.ExprQty.Value + ' var=' + Host.Entries.VarQty.Value);
        Observer.Observe(Name + ' log', Calc.Take());
    end;

    [Test]
    procedure Entries_FilterOneDay_First_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(16)));
        Observer.Observe('filter log', Calc.Take());
        Observer.Observe('First', Format(Host.Entries.First()));
        SayEntries('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_FilterOneDay_ReadWithoutFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(16)));
        Observer.Observe('filter log', Calc.Take());
        SayEntries('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_ReadBeforeFilter_ThenFilter_ThenFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        SayEntries('before', Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(17)));
        SayEntries('after filter', Host);
        Observer.Observe('First', Format(Host.Entries.First()));
        SayEntries('after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_FilterTwoDays_FirstNextNext()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(16)) + '..' + Format(Day(17)));
        Observer.Observe('First', Format(Host.Entries.First()));
        SayEntries('row 1', Host);
        Observer.Observe('Next 1', Format(Host.Entries.Next()));
        SayEntries('row 2', Host);
        Observer.Observe('Next 2', Format(Host.Entries.Next()));
        SayEntries('row after end', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_FilterOneDay_HostMovesToNextItem()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(16)));
        Host.Entries.First();
        SayEntries('I2', Host);
        Observer.Observe('host Next', Format(Host.Next()));
        SayEntries('I3 no move', Host);
        Observer.Observe('filter text', Host.Entries.Filter.GetFilter("Posting Date"));
        Observer.Observe('First', Format(Host.Entries.First()));
        SayEntries('I3 after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_FilterAdmitsNoRow_First()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(20)));
        Observer.Observe('filter log', Calc.Take());
        Observer.Observe('First', Format(Host.Entries.First()));
        Observer.Observe('First log', Calc.Take());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Entries_FilterThenClearFilter_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.Entries.Filter.SetFilter("Posting Date", Format(Day(17)));
        Host.Entries.First();
        SayEntries('filtered', Host);
        Host.Entries.Filter.SetFilter("Posting Date", '');
        SayEntries('cleared', Host);
        Observer.Observe('First', Format(Host.Entries.First()));
        SayEntries('cleared after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    local procedure SayEntriesFind(Name: Text; var Host: TestPage "TP PF Host")
    begin
        Observer.Observe(Name, 'date=' + Host.EntriesFind."Posting Date".Value + ' qty=' + Host.EntriesFind.Qty.Value + ' expr=' + Host.EntriesFind.ExprQty.Value + ' var=' + Host.EntriesFind.VarQty.Value);
        Observer.Observe(Name + ' log', Calc.Take());
    end;

    [Test]
    procedure EntriesFind_FilterOneDay_First_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(16)));
        Observer.Observe('filter log', Calc.Take());
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        SayEntriesFind('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_FilterOneDay_ReadWithoutFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(16)));
        Observer.Observe('filter log', Calc.Take());
        SayEntriesFind('row', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_ReadBeforeFilter_ThenFilter_ThenFirst()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        SayEntriesFind('before', Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(17)));
        SayEntriesFind('after filter', Host);
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        SayEntriesFind('after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_FilterTwoDays_FirstNextNext()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(16)) + '..' + Format(Day(17)));
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        SayEntriesFind('row 1', Host);
        Observer.Observe('Next 1', Format(Host.EntriesFind.Next()));
        SayEntriesFind('row 2', Host);
        Observer.Observe('Next 2', Format(Host.EntriesFind.Next()));
        SayEntriesFind('row after end', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_FilterOneDay_HostMovesToNextItem()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(16)));
        Host.EntriesFind.First();
        SayEntriesFind('I2', Host);
        Observer.Observe('host Next', Format(Host.Next()));
        SayEntriesFind('I3 no move', Host);
        Observer.Observe('filter text', Host.EntriesFind.Filter.GetFilter("Posting Date"));
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        SayEntriesFind('I3 after First', Host);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_FilterAdmitsNoRow_First()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(20)));
        Observer.Observe('filter log', Calc.Take());
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        Observer.Observe('First log', Calc.Take());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EntriesFind_FilterThenClearFilter_Read()
    var
        Host: TestPage "TP PF Host";
    begin
        OpenHost(Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", Format(Day(17)));
        Host.EntriesFind.First();
        SayEntriesFind('filtered', Host);
        Host.EntriesFind.Filter.SetFilter("Posting Date", '');
        SayEntriesFind('cleared', Host);
        Observer.Observe('First', Format(Host.EntriesFind.First()));
        SayEntriesFind('cleared after First', Host);
        Host.Close();
        Observer.Finish();
    end;

}
