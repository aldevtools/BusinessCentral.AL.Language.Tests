// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 89170 - 89179 (writer SJ)
// Probe: what Rec itself answers to Find(), FindFirst(), FindLast(), Count(), CurrentKey() and Ascending() in the OnOpenPage of a page an
//   action opens through RunPageLink, and which rows the opened page then shows (al-runner issue 5860). The reporter's shape is Base App
//   page 38 "Item Ledger Entries": SourceTableView = sorting("Entry No.") order(descending), and OnOpenPage runs
//   `if (Rec.GetFilters() <> '') and not Rec.Find() then if Rec.FindFirst() then;`. The targets here copy that trigger and log each answer.
//   Neighbours: no matching row, a const link, a target without SourceTableView, a view with a where filter, a target whose OnOpenPage
//   calls FindLast(), and a Card on the linked table's own primary key (Find() can find the row there). Routes: PageHandler and TestPage Trap.
//   Rec.GetFilter/GetFilters in OnOpenPage are pinned already (pages/lt-outside-worksheet-2/RtLinkRange.al); the by-value copy of Rec in
//   handlers/TestActionRunPageLinkFilterGroup.al (QZ_*). The log repeats them only as context of the Find answers.
//   Entries: 1 I1 +5, 2 I2 +3, 3 I1 -2, 4 I1 +1, 5 I2 -1. Items I1, I2, I3 (no entries).
// Result (BC 27.5, 28.5, 29.0 alike; corpus CI runs 40234630661, 40234651819, 40234671184): in OnOpenPage Rec holds the link as a
//   filter, its primary key fields are blank and the linked field is filled (row=0|I1); CurrentKey and Ascending are the view's
//   ('Entry No.', No) and Count() counts the linked rows only (3). Rec.Find() answers No (no row has the blank key); FindFirst() then
//   answers Yes and moves Rec to the first linked row in the view's order (4 descending, 1 ascending, 4 on the where view). The page
//   opens on that row and lists only the linked rows in the view's order (4,3,1). No linked row: Count 0, Find and FindFirst No, the
//   page is empty. FindLast() in OnOpenPage opens the page on the last row of the view (1); First/Next still list 4,3,1. A Card
//   linked on the primary key: Rec holds only the key (I2, no description), Find() answers Yes and reads the row (I2|two), and the
//   card shows it. Through a PageHandler, OnAfterGetCurrRecord runs again for each row the handler moves to.
// Log codeunit 89172 is SingleInstance and used only by codeunit 89178.
// BC versions: 27, 28, 29

table 89170 "LT SJ Link Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 89171 "LT SJ Link Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item Code"; Code[20]) { }
        field(3; Quantity; Decimal) { }
        field(4; Positive; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByItem; "Item Code", Positive) { }
    }
}

codeunit 89172 "LT SJ Link Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Value: Text)
    begin
        Entries += Value + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

page 89173 "LT SJ Link Items"
{
    PageType = List;
    SourceTable = "LT SJ Link Item";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(DescFind)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Entries Desc Find";
                RunPageLink = "Item Code" = field("Code");
            }
            action(DescFindConst)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Entries Desc Find";
                RunPageLink = "Item Code" = const('I2');
            }
            action(PlainFind)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Entries Plain Find";
                RunPageLink = "Item Code" = field("Code");
            }
            action(PositiveDescFind)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Entries Pos Desc Find";
                RunPageLink = "Item Code" = field("Code");
            }
            action(DescFindLast)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Entries Desc FindLast";
                RunPageLink = "Item Code" = field("Code");
            }
            action(ItemCard)
            {
                ApplicationArea = All;
                RunObject = page "LT SJ Link Item Card";
                RunPageLink = "Code" = field("Code");
            }
        }
    }
}

// The reporter's shape (Base App page 38): descending view, Find() then FindFirst() in OnOpenPage.
page 89174 "LT SJ Entries Desc Find"
{
    PageType = List;
    SourceTable = "LT SJ Link Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT SJ Link Log";
        Found: Boolean;
    begin
        Log.Add('open filters=' + Rec.GetFilters() + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
        Log.Add('open key=' + Rec.CurrentKey() + ' ascending=' + Format(Rec.Ascending()) + ' count=' + Format(Rec.Count()));
        Found := Rec.Find();
        Log.Add('open find=' + Format(Found) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
        if (Rec.GetFilters() <> '') and not Found then
            Log.Add('open findfirst=' + Format(Rec.FindFirst()) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('agcr row=' + Format(Rec."Entry No."));
    end;
}

// No SourceTableView: the primary key in ascending order.
page 89175 "LT SJ Entries Plain Find"
{
    PageType = List;
    SourceTable = "LT SJ Link Entry";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT SJ Link Log";
        Found: Boolean;
    begin
        Log.Add('open filters=' + Rec.GetFilters() + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
        Log.Add('open key=' + Rec.CurrentKey() + ' ascending=' + Format(Rec.Ascending()) + ' count=' + Format(Rec.Count()));
        Found := Rec.Find();
        Log.Add('open find=' + Format(Found) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
        if (Rec.GetFilters() <> '') and not Found then
            Log.Add('open findfirst=' + Format(Rec.FindFirst()) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('agcr row=' + Format(Rec."Entry No."));
    end;
}

// A view on a secondary key with a where filter, descending.
page 89176 "LT SJ Entries Pos Desc Find"
{
    PageType = List;
    SourceTable = "LT SJ Link Entry";
    SourceTableView = sorting("Item Code", Positive) order(descending) where(Positive = const(true));
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT SJ Link Log";
        Found: Boolean;
    begin
        Log.Add('open filters=' + Rec.GetFilters() + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code" + '|' + Format(Rec.Positive));
        Log.Add('open key=' + Rec.CurrentKey() + ' ascending=' + Format(Rec.Ascending()) + ' count=' + Format(Rec.Count()));
        Found := Rec.Find();
        Log.Add('open find=' + Format(Found) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
        if (Rec.GetFilters() <> '') and not Found then
            Log.Add('open findfirst=' + Format(Rec.FindFirst()) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('agcr row=' + Format(Rec."Entry No."));
    end;
}

// Descending view; OnOpenPage moves Rec with FindLast() (the last row in descending order is the lowest entry).
page 89177 "LT SJ Entries Desc FindLast"
{
    PageType = List;
    SourceTable = "LT SJ Link Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('open findlast=' + Format(Rec.FindLast()) + ' row=' + Format(Rec."Entry No.") + '|' + Rec."Item Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('agcr row=' + Format(Rec."Entry No."));
    end;
}

codeunit 89178 "LT SJ RunPageLink Open Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Global so the handlers can record; every test starts with Discard (a failed test leaves no pairs behind).
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SJ Link Log";

    [Test]
    procedure SJ_DescFind_Trap_I1()
    var
        Items: TestPage "LT SJ Link Items";
        Entries: TestPage "LT SJ Entries Desc Find";
    begin
        OpenOn(Items, 'I1');
        Entries.Trap();
        Items.DescFind.Invoke();
        Observer.Observe('log', Log.Get());
        Observer.Observe('item filter', Entries.Filter.GetFilter("Item Code"));
        Observer.Observe('current', Entries."Entry No.".Value());
        Observer.Observe('rows', DescRows(Entries));
        Entries.Close();
        Items.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I1 row=0|I1;open key=Entry No. ascending=No count=3;open find=No row=0|I1;open findfirst=Yes row=4|I1;agcr row=4;');
        Observer.Expect('item filter', 'I1');
        Observer.Expect('current', '4');
        Observer.Expect('rows', '4,3,1,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescFindHandler')]
    procedure SJ_DescFind_Handler_I1()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I1');
        Items.DescFind.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I1 row=0|I1;open key=Entry No. ascending=No count=3;open find=No row=0|I1;open findfirst=Yes row=4|I1;agcr row=4;agcr row=3;agcr row=1;handler filter=I1 current=4 rows=4,3,1,;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescFindHandler')]
    procedure SJ_DescFind_Handler_I3_NoRows()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I3');
        Items.DescFind.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I3 row=0|I3;open key=Entry No. ascending=No count=0;open find=No row=0|I3;open findfirst=No row=0|I3;handler filter=I3 current= rows=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescFindHandler')]
    procedure SJ_DescFind_Const_I2()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I1');
        Items.DescFindConst.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I2 row=0|I2;open key=Entry No. ascending=No count=2;open find=No row=0|I2;open findfirst=Yes row=5|I2;agcr row=5;agcr row=2;handler filter=I2 current=5 rows=5,2,;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainFindHandler')]
    procedure SJ_PlainFind_Handler_I1()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I1');
        Items.PlainFind.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I1 row=0|I1;open key=Entry No. ascending=Yes count=3;open find=No row=0|I1;open findfirst=Yes row=1|I1;agcr row=1;agcr row=3;agcr row=4;handler filter=I1 current=1 rows=1,3,4,;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PositiveDescFindHandler')]
    procedure SJ_PositiveDescFind_Handler_I1()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I1');
        Items.PositiveDescFind.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Item Code: I1 row=0|I1|No;open key=Item Code,Positive ascending=No count=2;open find=No row=0|I1;open findfirst=Yes row=4|I1;agcr row=4;agcr row=1;handler filter=I1 current=4 rows=4,1,;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescFindLastHandler')]
    procedure SJ_DescFindLast_Handler_I1()
    var
        Items: TestPage "LT SJ Link Items";
    begin
        OpenOn(Items, 'I1');
        Items.DescFindLast.Invoke();
        Items.Close();
        Observer.Observe('log', Log.Get());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open findlast=Yes row=1|I1;agcr row=1;agcr row=4;agcr row=3;agcr row=1;handler filter=I1 current=1 rows=4,3,1,;');
        Observer.Verify();
    end;

    [Test]
    procedure SJ_ItemCard_Find_Trap_I2()
    var
        Items: TestPage "LT SJ Link Items";
        Card: TestPage "LT SJ Link Item Card";
    begin
        OpenOn(Items, 'I2');
        Card.Trap();
        Items.ItemCard.Invoke();
        Observer.Observe('log', Log.Get());
        Observer.Observe('card', Card."Code".Value() + '|' + Card.Description.Value());
        Card.Close();
        Items.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log', 'open filters=Code: I2 row=I2|;open find=Yes row=I2|two;agcr row=I2|two;');
        Observer.Expect('card', 'I2|two');
        Observer.Verify();
    end;

    local procedure OpenOn(var Items: TestPage "LT SJ Link Items"; ItemCode: Code[20])
    begin
        Observer.Discard();
        Setup();
        Items.OpenView();
        Observer.Observe('goto', Format(Items.GoToKey(ItemCode)));
        Log.Clear();
    end;

    local procedure DescRows(var Entries: TestPage "LT SJ Entries Desc Find") Result: Text
    begin
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
    end;

    [PageHandler]
    procedure DescFindHandler(var Entries: TestPage "LT SJ Entries Desc Find")
    begin
        Log.Add('handler filter=' + Entries.Filter.GetFilter("Item Code") + ' current=' + Entries."Entry No.".Value() + ' rows=' + DescRows(Entries));
    end;

    [PageHandler]
    procedure PlainFindHandler(var Entries: TestPage "LT SJ Entries Plain Find")
    var
        Result: Text;
    begin
        Result := 'handler filter=' + Entries.Filter.GetFilter("Item Code") + ' current=' + Entries."Entry No.".Value() + ' rows=';
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Log.Add(Result);
    end;

    [PageHandler]
    procedure PositiveDescFindHandler(var Entries: TestPage "LT SJ Entries Pos Desc Find")
    var
        Result: Text;
    begin
        Result := 'handler filter=' + Entries.Filter.GetFilter("Item Code") + ' current=' + Entries."Entry No.".Value() + ' rows=';
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Log.Add(Result);
    end;

    [PageHandler]
    procedure DescFindLastHandler(var Entries: TestPage "LT SJ Entries Desc FindLast")
    var
        Result: Text;
    begin
        Result := 'handler filter=' + Entries.Filter.GetFilter("Item Code") + ' current=' + Entries."Entry No.".Value() + ' rows=';
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Log.Add(Result);
    end;

    local procedure Setup()
    var
        Item: Record "LT SJ Link Item";
        Entry: Record "LT SJ Link Entry";
    begin
        Entry.DeleteAll();
        Item.DeleteAll();
        AddItem('I1', 'one');
        AddItem('I2', 'two');
        AddItem('I3', 'three');
        AddEntry(1, 'I1', 5);
        AddEntry(2, 'I2', 3);
        AddEntry(3, 'I1', -2);
        AddEntry(4, 'I1', 1);
        AddEntry(5, 'I2', -1);
    end;

    local procedure AddItem(ItemCode: Code[20]; Description: Text[30])
    var
        Item: Record "LT SJ Link Item";
    begin
        Item."Code" := ItemCode;
        Item.Description := Description;
        Item.Insert();
    end;

    local procedure AddEntry(EntryNo: Integer; ItemCode: Code[20]; Qty: Decimal)
    var
        Entry: Record "LT SJ Link Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry."Item Code" := ItemCode;
        Entry.Quantity := Qty;
        Entry.Positive := Qty > 0;
        Entry.Insert();
    end;
}

// A Card on the linked table itself: the link is on the primary key, so Rec.Find() has a key to find.
page 89179 "LT SJ Link Item Card"
{
    PageType = Card;
    SourceTable = "LT SJ Link Item";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Description; Rec.Description) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT SJ Link Log";
        Found: Boolean;
    begin
        Log.Add('open filters=' + Rec.GetFilters() + ' row=' + Rec."Code" + '|' + Rec.Description);
        Found := Rec.Find();
        Log.Add('open find=' + Format(Found) + ' row=' + Rec."Code" + '|' + Rec.Description);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SJ Link Log";
    begin
        Log.Add('agcr row=' + Rec."Code" + '|' + Rec.Description);
    end;
}
