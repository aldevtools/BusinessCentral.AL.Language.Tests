// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 89170 - 89178 (writer SJ)
// Probe: what Rec itself answers to Find(), FindFirst(), FindLast(), Count(), CurrentKey() and Ascending() in the OnOpenPage of a page an
//   action opens through RunPageLink, and which rows the opened page then shows (al-runner issue 5860). The reporter's shape is Base App
//   page 38 "Item Ledger Entries": SourceTableView = sorting("Entry No.") order(descending), and OnOpenPage runs
//   `if (Rec.GetFilters() <> '') and not Rec.Find() then if Rec.FindFirst() then;`. The targets here copy that trigger and log each answer.
//   Neighbours: no matching row, a const link, a target without SourceTableView, a view with a where filter, a target whose OnOpenPage
//   calls FindLast(), and a Card on the linked table's own primary key (Find() can find the row there). Routes: PageHandler and TestPage Trap.
//   Rec.GetFilter/GetFilters in OnOpenPage are pinned already (pages/lt-outside-worksheet-2/RtLinkRange.al); the by-value copy of Rec in
//   handlers/TestActionRunPageLinkFilterGroup.al (QZ_*). The log repeats them only as context of the Find answers.
//   Entries: 1 I1 +5, 2 I2 +3, 3 I1 -2, 4 I1 +1, 5 I2 -1. Items I1, I2, I3 (no entries).
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
