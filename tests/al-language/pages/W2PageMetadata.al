// Probe: the Page Metadata, Page Control Field and Page Action virtual tables for page types beyond the thirteen named ones, SourceTableView shapes, declared Visible / Enabled / Editable, and the numbering and nesting of actions.
// Settles: md:350 (other page types, SourceTableView with sorting, order, several conditions), md:351 (spelling of declared Visible / Enabled / Editable, expressions), md:359 (Action Index, Action ID, Parent Action ID, containers, actionrefs, system actions).

table 68738 "W2 Meta Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; F1; Integer) { }
        field(2; F2; Integer) { }
        field(3; F3; Text[10]) { }
    }

    keys
    {
        key(PK; F1) { Clustered = true; }
        key(K2; F3) { }
    }
}

page 68739 "W2 Meta View A"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = sorting(F1) order(descending) where(F2 = const(1));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68740 "W2 Meta View B"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = where(F2 = const(1), F3 = const('x'));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68741 "W2 Meta View C"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = sorting(F3);
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68742 "W2 Meta View D"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = order(descending);
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68743 "W2 Meta View E"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = where(F2 = filter(1 .. 5));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68744 "W2 Meta View F"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    SourceTableView = sorting(F3) where(F3 = const('a b'));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(F1; Rec.F1) { ApplicationArea = All; }
            }
        }
    }
}

page 68745 "W2 Meta Api Page"
{
    PageType = API;
    APIPublisher = 'w2probe';
    APIGroup = 'w2';
    APIVersion = 'v1.0';
    EntityName = 'w2Row';
    EntitySetName = 'w2Rows';
    SourceTable = "W2 Meta Src";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { }
                field(f1; Rec.F1) { }
            }
        }
    }
}

page 68746 "W2 Meta Card Reference"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(F1; Rec.F1) { ApplicationArea = All; }
        }
    }
}

// Controls with declared Visible / Enabled / Editable, constants and expressions.
page 68747 "W2 Meta Controls"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(VisTrue; Rec.F1) { ApplicationArea = All; Visible = true; }
            field(VisFalse; Rec.F2) { ApplicationArea = All; Visible = false; }
            field(EnTrue; Rec.F3) { ApplicationArea = All; Enabled = true; }
            field(EnFalse; Rec.F1) { ApplicationArea = All; Enabled = false; }
            field(EdTrue; Rec.F2) { ApplicationArea = All; Editable = true; }
            field(EdFalse; Rec.F3) { ApplicationArea = All; Editable = false; }
            field(VisVar; Rec.F1) { ApplicationArea = All; Visible = VisFlag; }
            field(VisNot; Rec.F2) { ApplicationArea = All; Visible = not VisFlag; }
            field(EnVar; Rec.F3) { ApplicationArea = All; Enabled = EnFlag; }
            field(EdVar; Rec.F1) { ApplicationArea = All; Editable = EdFlag; }
            field(AllThree; Rec.F2) { ApplicationArea = All; Visible = false; Enabled = false; Editable = false; }
        }
    }

    var
        VisFlag: Boolean;
        EnFlag: Boolean;
        EdFlag: Boolean;
}

page 68748 "W2 Meta Actions"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(F1; Rec.F1) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(A1)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
            group(G)
            {
                action(A2)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(A3)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
            }
            action(A4)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
        area(Navigation)
        {
            action(N1)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
        area(Creation)
        {
            action(C1)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 68749 "W2 Meta Action Refs"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(F1; Rec.F1) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(P1)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
            action(P2)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
        area(Promoted)
        {
            actionref(P1Ref; P1) { }
            group(Category_Process)
            {
                actionref(P2Ref; P2) { }
            }
        }
    }
}

page 68750 "W2 Meta No Actions"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Meta Src";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(F1; Rec.F1) { ApplicationArea = All; }
        }
    }
}

codeunit 68751 "W2 Meta Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:350 ----

    [Test]
    procedure PageType_ApiPage()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Page Metadata";
        Card: Record "Page Metadata";
        Ordinal: Integer;
    begin
        Observer.Observe('api_row_exists', Format(Meta.Get(Page::"W2 Meta Api Page")));
        Ordinal := Meta.PageType;
        Observer.Observe('api_page_type_ordinal', Format(Ordinal));
        Observer.Observe('api_page_type_text', Format(Meta.PageType));
        Observer.Observe('api_source_table_is_src', Format(Meta.SourceTable = Database::"W2 Meta Src"));
        Observer.Observe('card_row_exists', Format(Card.Get(Page::"W2 Meta Card Reference")));
        Ordinal := Card.PageType;
        Observer.Observe('card_page_type_ordinal', Format(Ordinal));
        Observer.Expect('api_row_exists', 'Yes');
        Observer.Expect('api_page_type_ordinal', '11');
        Observer.Expect('api_page_type_text', 'API');
        Observer.Expect('api_source_table_is_src', 'Yes');
        Observer.Expect('card_row_exists', 'Yes');
        Observer.Expect('card_page_type_ordinal', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SourceTableView_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveView(Observer, 'A_sorting_order_where', Page::"W2 Meta View A");
        ObserveView(Observer, 'B_two_conditions', Page::"W2 Meta View B");
        ObserveView(Observer, 'C_sorting_only', Page::"W2 Meta View C");
        ObserveView(Observer, 'D_order_only', Page::"W2 Meta View D");
        ObserveView(Observer, 'E_filter_range', Page::"W2 Meta View E");
        ObserveView(Observer, 'F_sorting_and_text_with_space', Page::"W2 Meta View F");
        Observer.Expect('A_sorting_order_where', 'SORTING(Field1) ORDER(1) WHERE(Field2=CONST(1))');
        Observer.Expect('B_two_conditions', 'WHERE(Field2=CONST(1),Field3=CONST(x))');
        Observer.Expect('C_sorting_only', 'SORTING(Field3) ');
        Observer.Expect('D_order_only', 'ORDER(1) ');
        Observer.Expect('E_filter_range', 'WHERE(Field2=FILTER(1..5))');
        Observer.Expect('F_sorting_and_text_with_space', 'SORTING(Field3) WHERE(Field3=CONST(a b))');
        Observer.Verify();
    end;

    local procedure ObserveView(var Observer: Codeunit "Probe Observer"; Name: Text; PageId: Integer)
    var
        Meta: Record "Page Metadata";
    begin
        if Meta.Get(PageId) then
            Observer.Observe(Name, Meta.SourceTableView)
        else
            Observer.Observe(Name, '<no row>');
    end;

    // ---- md:351 ----

    [Test]
    procedure ControlFields_DeclaredVisibleEnabledEditable()
    var
        Observer: Codeunit "Probe Observer";
        Field: Record "Page Control Field";
    begin
        Field.SetRange(PageNo, Page::"W2 Meta Controls");
        if Field.FindSet() then
            repeat
                if Field.ControlName <> '' then
                    Observer.Observe('control|' + Field.ControlName, 'Visible=' + Field.Visible + ' Enabled=' + Field.Enabled + ' Editable=' + Field.Editable);
            until Field.Next() = 0;
        Observer.Expect('control|EnTrue', 'Visible=true Enabled=true Editable=True');
        Observer.Expect('control|VisTrue', 'Visible=true Enabled=true Editable=True');
        Observer.Expect('control|EnFalse', 'Visible=true Enabled=false Editable=True');
        Observer.Expect('control|VisFalse', 'Visible=false Enabled=true Editable=True');
        Observer.Expect('control|EdFalse', 'Visible=true Enabled=true Editable=false');
        Observer.Expect('control|VisVar', 'Visible=p68747p68747VisFlag Enabled=true Editable=True');
        Observer.Expect('control|EdTrue', 'Visible=true Enabled=true Editable=true');
        Observer.Expect('control|EdVar', 'Visible=true Enabled=true Editable=p68747p68747EdFlag');
        Observer.Expect('control|EnVar', 'Visible=true Enabled=p68747p68747EnFlag Editable=True');
        Observer.Expect('control|AllThree', 'Visible=false Enabled=false Editable=false');
        Observer.Expect('control|VisNot', 'Visible=not p68747p68747VisFlag Enabled=true Editable=True');
        Observer.Verify();
    end;

    // ---- md:359 ----


    // One row per action: [Action Index|Action ID|Parent Action ID|Indentation|Action Type|Name]
    local procedure DumpActions(PageId: Integer): Text
    var
        Act: Record "Page Action";
        Result: Text;
    begin
        Act.SetRange("Page ID", PageId);
        if Act.FindSet() then
            repeat
                Result += '[' + Format(Act."Action Index") + '|' + Format(Act."Action ID") + '|' + Format(Act."Parent Action ID") + '|' + Format(Act.Indentation) + '|' + Format(Act."Action Type") + '|' + Act.Name + ']';
            until Act.Next() = 0;
        exit(Result);
    end;

    // Writer RP (al-runner issue 5758): codeunit 700 "Page Management".GetDefaultCardPageID reads the Page Metadata row of the
    // table's lookup page; here that page has SourceTableView = sorting(<secondary key>) and a CardPageId.
    [Test]
    procedure RP_LookupPageSortedBySecondaryKey_CardPageId()
    var
        Observer: Codeunit "Probe Observer";
        PageManagement: Codeunit "Page Management";
        Meta: Record "Page Metadata";
        TableMeta: Record "Table Metadata";
    begin
        RpObserveMeta(Observer, 'one', Page::"LT RP Meta Sorted List");
        RpObserveMeta(Observer, 'two', Page::"LT RP Meta Sorted Two");
        RpObserveMeta(Observer, 'card', Page::"LT RP Meta Card");
        TableMeta.Get(Database::"LT RP Meta Row");
        Observer.Observe('one_table_lookup', Format(TableMeta.LookupPageID, 0, 9));
        TableMeta.Get(Database::"LT RP Meta Row Two");
        Observer.Observe('two_table_lookup', Format(TableMeta.LookupPageID, 0, 9));
        Observer.Observe('one_default_card', Format(PageManagement.GetDefaultCardPageID(Database::"LT RP Meta Row"), 0, 9));
        Observer.Observe('two_default_card', Format(PageManagement.GetDefaultCardPageID(Database::"LT RP Meta Row Two"), 0, 9));
        Observer.Observe('one_default_lookup', Format(PageManagement.GetDefaultLookupPageID(Database::"LT RP Meta Row"), 0, 9));
        Meta.SetRange(ID, Page::"LT RP Meta Sorted List");
        Observer.Observe('one_filtered_find', Format(Meta.FindFirst()) + '/' + Format(Meta.CardPageID, 0, 9));
        Observer.Expect('one_view', 'SORTING(Field2) ');
        Observer.Expect('one_card', '88387');
        Observer.Expect('one_source', '88385');
        Observer.Expect('one_type', 'List');
        Observer.Expect('one_editable', 'No');
        Observer.Expect('two_view', 'SORTING(Field2,Field1) ORDER(1) ');
        Observer.Expect('two_card', '88390');
        Observer.Expect('two_source', '88389');
        Observer.Expect('two_type', 'List');
        Observer.Expect('two_editable', 'No');
        Observer.Expect('card_view', '');
        Observer.Expect('card_card', '0');
        Observer.Expect('card_source', '88385');
        Observer.Expect('card_type', 'Card');
        Observer.Expect('card_editable', 'Yes');
        Observer.Expect('one_table_lookup', '88386');
        Observer.Expect('two_table_lookup', '88388');
        Observer.Expect('one_default_card', '88387');
        Observer.Expect('two_default_card', '88390');
        Observer.Expect('one_default_lookup', '88386');
        Observer.Expect('one_filtered_find', 'Yes/88387');
        Observer.Verify();
    end;

    local procedure RpObserveMeta(var Observer: Codeunit "Probe Observer"; Name: Text; PageId: Integer)
    var
        Meta: Record "Page Metadata";
    begin
        if not Meta.Get(PageId) then begin
            Observer.Observe(Name, '<no row>');
            exit;
        end;
        Observer.Observe(Name + '_view', Meta.SourceTableView);
        Observer.Observe(Name + '_card', Format(Meta.CardPageID, 0, 9));
        Observer.Observe(Name + '_source', Format(Meta.SourceTable, 0, 9));
        Observer.Observe(Name + '_type', Format(Meta.PageType));
        Observer.Observe(Name + '_editable', Format(Meta.Editable));
    end;
}

// Writer RP (al-runner issue 5758): tables whose LookupPageId is a List with SourceTableView = sorting(<secondary key>) and a CardPageId.
table 88385 "LT RP Meta Row"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT RP Meta Sorted List";

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; SortOrder; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(BySortOrder; SortOrder) { }
    }
}

table 88389 "LT RP Meta Row Two"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT RP Meta Sorted Two";

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; SortOrder; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(ByBoth; SortOrder, "Code") { }
    }
}

page 88386 "LT RP Meta Sorted List"
{
    PageType = List;
    SourceTable = "LT RP Meta Row";
    SourceTableView = sorting(SortOrder);
    CardPageId = "LT RP Meta Card";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(SortOrder; Rec.SortOrder) { ApplicationArea = All; }
            }
        }
    }
}

page 88388 "LT RP Meta Sorted Two"
{
    PageType = List;
    SourceTable = "LT RP Meta Row Two";
    SourceTableView = sorting(SortOrder, "Code") order(descending);
    CardPageId = "LT RP Meta Card Two";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(SortOrder; Rec.SortOrder) { ApplicationArea = All; }
            }
        }
    }
}

page 88387 "LT RP Meta Card"
{
    PageType = Card;
    SourceTable = "LT RP Meta Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(SortOrder; Rec.SortOrder) { ApplicationArea = All; }
        }
    }
}

page 88390 "LT RP Meta Card Two"
{
    PageType = Card;
    SourceTable = "LT RP Meta Row Two";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }
}
