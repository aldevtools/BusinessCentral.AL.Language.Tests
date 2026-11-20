// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the relation shapes of table 75924 "RFN Source" and its table extension 75925
//                (FieldRelationFieldNo.al, same folder); self-contained queries 75950, 75955, 75956, pages 75951, 75952,
//                codeunits 75954, 75957; Base Application table Item (field "Item Category Code")
// Probe: written against local BC 27.5, 28.5 and 29.0 service tiers (Windows); every literal asserted below is what those tiers produced.
//        Other builds are checked by the corpus CI matrix. Asked by al-runner issue 8249 (readers other than a Record variable).
// Facts (FieldRelationFieldNo.al pins the Record reads: Get and a filtered FindSet):
//  - RecordRef.Open(Field) reads RelationTableNo/RelationFieldNo through FieldRef.Value as a Record does: 0 for every TableRelation
//    that names no field (key on field 1, key on field 5, two-field key, with where, ValidateTableRelation = false, FlowFilter, Guid to
//    User, table extension field, Item."Item Category Code" 5722/0); the named field otherwise; 0/0 for conditional relations and for a
//    field without a relation. The same after FindFirst, FindSet over all rows of a table, Get(RecordId) and GetTable.
//  - FieldRef.SetRange/SetFilter on RelationFieldNo and a SetView WHERE on it select the same rows as the Record filter; Count agrees.
//  - A query over the Field table does not run: Open raises "A query cannot be based on a virtual table. Please contact your system
//    administrator." (GetLastErrorCode DB:Ok), with plain columns, a run-time filter on RelationFieldNo, a DataItemTableFilter or a
//    ColumnFilter on it.
//  - A List page and a Card page over Field show the same values (OpenView with a page filter, GoToKey, TestPage.Trap + Page.Run with a
//    Field record); Value of RelationFieldNo is '0' for a no-field relation; a page filter RelationFieldNo = 0 lists the same rows.
//  - Record.Relation() raises "No relationship has been associated with the field <field> in <table>." (code NoRelationship) for a
//    conditional relation no branch matches (record only assigned, or read back from a temporary table) and for a field without any
//    TableRelation; it gives the table of the matched branch otherwise.
// BC versions: 27.5, 28.5, 29.0

query 75950 "RFR Field Relations"
{
    QueryType = Normal;

    elements
    {
        dataitem(FieldRow; Field)
        {
            column(TableNo; TableNo) { }
            column(No; "No.") { }
            column(RelationTableNo; RelationTableNo) { }
            column(RelationFieldNo; RelationFieldNo) { }
        }
    }
}

// The filter on the relation columns sits in the query object (DataItemTableFilter).
query 75955 "RFR Field Relations No Field"
{
    QueryType = Normal;

    elements
    {
        dataitem(FieldRow; Field)
        {
            DataItemTableFilter = RelationTableNo = filter(<> 0), RelationFieldNo = const(0);
            column(TableNo; TableNo) { }
            column(No; "No.") { }
            column(RelationFieldNo; RelationFieldNo) { }
        }
    }
}

// The filter on RelationFieldNo sits on the column (ColumnFilter).
query 75956 "RFR Field Relations ColFilter"
{
    QueryType = Normal;

    elements
    {
        dataitem(FieldRow; Field)
        {
            column(TableNo; TableNo) { }
            column(No; "No.") { }
            column(RelationTableNo; RelationTableNo) { ColumnFilter = RelationTableNo = filter(<> 0); }
            column(RelationFieldNo; RelationFieldNo) { ColumnFilter = RelationFieldNo = const(0); }
        }
    }
}

page 75951 "RFR Field Relation List"
{
    PageType = List;
    SourceTable = Field;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TableNo; Rec.TableNo) { ApplicationArea = All; }
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(RelationTableNo; Rec.RelationTableNo) { ApplicationArea = All; }
                field(RelationFieldNo; Rec.RelationFieldNo) { ApplicationArea = All; }
            }
        }
    }
}

page 75952 "RFR Field Relation Card"
{
    PageType = Card;
    SourceTable = Field;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TableNo; Rec.TableNo) { ApplicationArea = All; }
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(RelationTableNo; Rec.RelationTableNo) { ApplicationArea = All; }
                field(RelationFieldNo; Rec.RelationFieldNo) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 75953 "RFR Relation Readers Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // RecordRef.Open(Field), filters on TableNo and No. through FieldRef, FindFirst, FieldRef.Value of RelationTableNo and RelationFieldNo.
    local procedure RefRow(WantedTable: Integer; WantedField: Integer): Text
    var
        FieldRec: Record Field;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Field);
        RecRef.Field(FieldRec.FieldNo(TableNo)).SetRange(WantedTable);
        RecRef.Field(FieldRec.FieldNo("No.")).SetRange(WantedField);
        if not RecRef.FindFirst() then
            exit('not found');
        exit(Format(RecRef.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(RecRef.Field(FieldRec.FieldNo(RelationFieldNo)).Value));
    end;

    local procedure RefSourceRow(FieldNo: Integer): Text
    begin
        exit(RefRow(Database::"RFN Source", FieldNo));
    end;

    [Test]
    procedure RecordRef_FindFirst_RelationWithoutField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('10 target one, no field', RefSourceRow(10));
        Observer.Observe('13 key is field 5, no field', RefSourceRow(13));
        Observer.Observe('15 two key fields, no field', RefSourceRow(15));
        Observer.Observe('18 no field, where', RefSourceRow(18));
        Observer.Observe('19 two key fields, no field, where', RefSourceRow(19));
        Observer.Observe('24 flowfilter, no field', RefSourceRow(24));
        Observer.Observe('25 guid to User, no field', RefSourceRow(25));
        Observer.Observe('27 no field, no validate', RefSourceRow(27));
        Observer.Observe('75925 table extension, no field', RefSourceRow(75925));
        Observer.Expect('10 target one, no field', '75920/0');
        Observer.Expect('13 key is field 5, no field', '75921/0');
        Observer.Expect('15 two key fields, no field', '75922/0');
        Observer.Expect('18 no field, where', '75920/0');
        Observer.Expect('19 two key fields, no field, where', '75922/0');
        Observer.Expect('24 flowfilter, no field', '75920/0');
        Observer.Expect('25 guid to User, no field', '2000000120/0');
        Observer.Expect('27 no field, no validate', '75920/0');
        Observer.Expect('75925 table extension, no field', '75920/0');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FindFirst_RelationWithFieldAndContrasts()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
    begin
        Observer.Observe('11 key field named', RefSourceRow(11));
        Observer.Observe('16 two keys, second named', RefSourceRow(16));
        Observer.Observe('75926 table extension, other field named', RefSourceRow(75926));
        Observer.Observe('20 conditional, no field', RefSourceRow(20));
        Observer.Observe('21 conditional, one branch', RefSourceRow(21));
        Observer.Observe('26 no relation', RefSourceRow(26));
        Observer.Observe('Item Item Category Code', RefRow(Database::Item, Item.FieldNo("Item Category Code")));
        Observer.Expect('11 key field named', '75920/1');
        Observer.Expect('16 two keys, second named', '75922/2');
        Observer.Expect('75926 table extension, other field named', '75920/2');
        Observer.Expect('20 conditional, no field', '0/0');
        Observer.Expect('21 conditional, one branch', '0/0');
        Observer.Expect('26 no relation', '0/0');
        Observer.Expect('Item Item Category Code', '5722/0');
        Observer.Verify();
    end;

    // RecordRef.Get(RecordId) and RecordRef.GetTable of a Field record.
    [Test]
    procedure RecordRef_GetRecordIdAndGetTable_RelationWithoutField()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        RecRef: RecordRef;
        ById: RecordRef;
    begin
        FieldRec.Get(Database::"RFN Source", 10);
        RecRef.GetTable(FieldRec);
        Observer.Observe('GetTable 10', Format(RecRef.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(RecRef.Field(FieldRec.FieldNo(RelationFieldNo)).Value));
        ById.Open(Database::Field);
        Observer.Observe('Get(RecordId) 13 found', Format(ById.Get(CreateRecordId(13))));
        Observer.Observe('Get(RecordId) 13', Format(ById.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(ById.Field(FieldRec.FieldNo(RelationFieldNo)).Value));
        Observer.Observe('Get(RecordId) 15 found', Format(ById.Get(CreateRecordId(15))));
        Observer.Observe('Get(RecordId) 15', Format(ById.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(ById.Field(FieldRec.FieldNo(RelationFieldNo)).Value));
        Observer.Observe('Get(RecordId) 11 found', Format(ById.Get(CreateRecordId(11))));
        Observer.Observe('Get(RecordId) 11', Format(ById.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(ById.Field(FieldRec.FieldNo(RelationFieldNo)).Value));
        Observer.Expect('GetTable 10', '75920/0');
        Observer.Expect('Get(RecordId) 13 found', 'Yes');
        Observer.Expect('Get(RecordId) 13', '75921/0');
        Observer.Expect('Get(RecordId) 15 found', 'Yes');
        Observer.Expect('Get(RecordId) 15', '75922/0');
        Observer.Expect('Get(RecordId) 11 found', 'Yes');
        Observer.Expect('Get(RecordId) 11', '75920/1');
        Observer.Verify();
    end;

    local procedure CreateRecordId(FieldNo: Integer): RecordId
    var
        FieldRec: Record Field;
    begin
        FieldRec.Get(Database::"RFN Source", FieldNo);
        exit(FieldRec.RecordId);
    end;

    // Every Field row of RFN Source, read in a RecordRef scan filtered on TableNo only: No.=RelationTableNo/RelationFieldNo.
    [Test]
    procedure RecordRef_ScanByTableNo_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        RecRef: RecordRef;
        Rows: Text;
    begin
        RecRef.Open(Database::Field);
        RecRef.Field(FieldRec.FieldNo(TableNo)).SetRange(Database::"RFN Source");
        if RecRef.FindSet() then
            repeat
                Rows += Format(RecRef.Field(FieldRec.FieldNo("No.")).Value) + '=' + Format(RecRef.Field(FieldRec.FieldNo(RelationTableNo)).Value) + '/' + Format(RecRef.Field(FieldRec.FieldNo(RelationFieldNo)).Value) + ',';
            until RecRef.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', '1=0/0,2=0/0,10=75920/0,11=75920/1,12=75920/2,13=75921/0,14=75921/5,15=75922/0,16=75922/2,17=75922/1,18=75920/0,19=75922/0,20=0/0,21=0/0,22=0/0,23=0/0,24=75920/0,25=2000000120/0,26=0/0,27=75920/0,75925=75920/0,75926=75920/2,2000000000=0/0,2000000001=0/0,2000000002=2000000120/0,2000000003=0/0,2000000004=2000000120/0,');
        Observer.Verify();
    end;

    // The same scan through a Record variable (contrast for the RecordRef scan).
    [Test]
    procedure Record_ScanByTableNo_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        Rows: Text;
    begin
        FieldRec.SetRange(TableNo, Database::"RFN Source");
        if FieldRec.FindSet() then
            repeat
                Rows += Format(FieldRec."No.") + '=' + Format(FieldRec.RelationTableNo) + '/' + Format(FieldRec.RelationFieldNo) + ',';
            until FieldRec.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', '1=0/0,2=0/0,10=75920/0,11=75920/1,12=75920/2,13=75921/0,14=75921/5,15=75922/0,16=75922/2,17=75922/1,18=75920/0,19=75922/0,20=0/0,21=0/0,22=0/0,23=0/0,24=75920/0,25=2000000120/0,26=0/0,27=75920/0,75925=75920/0,75926=75920/2,2000000000=0/0,2000000001=0/0,2000000002=2000000120/0,2000000003=0/0,2000000004=2000000120/0,');
        Observer.Verify();
    end;

    // FieldRef.SetRange / SetFilter on RelationFieldNo in a RecordRef scan, and Count.
    [Test]
    procedure RecordRef_FilterOnRelationFieldNo()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        RecRef: RecordRef;
        Numbers: Text;
    begin
        RecRef.Open(Database::Field);
        RecRef.Field(FieldRec.FieldNo(TableNo)).SetRange(Database::"RFN Source");
        RecRef.Field(FieldRec.FieldNo(RelationTableNo)).SetFilter('<>0');
        RecRef.Field(FieldRec.FieldNo(RelationFieldNo)).SetRange(0);
        Observer.Observe('related, field 0: count', Format(RecRef.Count()));
        if RecRef.FindSet() then
            repeat
                Numbers += Format(RecRef.Field(FieldRec.FieldNo("No.")).Value) + ',';
            until RecRef.Next() = 0;
        Observer.Observe('related, field 0', Numbers);
        RecRef.Field(FieldRec.FieldNo(RelationFieldNo)).SetFilter('<>0');
        Observer.Observe('related, field not 0: count', Format(RecRef.Count()));
        Numbers := '';
        if RecRef.FindSet() then
            repeat
                Numbers += Format(RecRef.Field(FieldRec.FieldNo("No.")).Value) + ',';
            until RecRef.Next() = 0;
        Observer.Observe('related, field not 0', Numbers);
        RecRef.Reset();
        RecRef.SetView('WHERE(TableNo=CONST(75924),RelationTableNo=CONST(75920),RelationFieldNo=CONST(0))');
        Numbers := '';
        if RecRef.FindSet() then
            repeat
                Numbers += Format(RecRef.Field(FieldRec.FieldNo("No.")).Value) + ',';
            until RecRef.Next() = 0;
        Observer.Observe('SetView target one, field 0', Numbers);
        Observer.Expect('related, field 0: count', '11');
        Observer.Expect('related, field 0', '10,13,15,18,19,24,25,27,75925,2000000002,2000000004,');
        Observer.Expect('related, field not 0: count', '6');
        Observer.Expect('related, field not 0', '11,12,14,16,17,75926,');
        Observer.Expect('SetView target one, field 0', '10,18,24,27,75925,');
        Observer.Verify();
    end;

    // Query objects over the Field table, opened and read through Codeunit.Run so a raise is observed as stage, text and code.
    // Query 75950: plain columns; 75955: DataItemTableFilter on RelationFieldNo; 75956: ColumnFilter on RelationFieldNo.
    [Test]
    procedure Query_OverFieldTable_OpenAndRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('75950 columns, filter TableNo', ReadQuery(1));
        Observer.Observe('75950 columns, filter RelationFieldNo 0', ReadQuery(2));
        Observer.Observe('75955 DataItemTableFilter', ReadQuery(3));
        Observer.Observe('75956 ColumnFilter', ReadQuery(4));
        Observer.Expect('75950 columns, filter TableNo', 'open  error: A query cannot be based on a virtual table. Please contact your system administrator. code: DB:Ok');
        Observer.Expect('75950 columns, filter RelationFieldNo 0', 'open  error: A query cannot be based on a virtual table. Please contact your system administrator. code: DB:Ok');
        Observer.Expect('75955 DataItemTableFilter', 'open  error: A query cannot be based on a virtual table. Please contact your system administrator. code: DB:Ok');
        Observer.Expect('75956 ColumnFilter', 'open  error: A query cannot be based on a virtual table. Please contact your system administrator. code: DB:Ok');
        Observer.Verify();
    end;

    local procedure ReadQuery(Which: Integer): Text
    var
        Reader: Codeunit "RFR Query Reader";
    begin
        ClearLastError();
        Reader.SetUp(Which);
        if Reader.Run() then
            exit(Reader.Result());
        exit(Reader.Result() + ' error: ' + GetLastErrorText() + ' code: ' + GetLastErrorCode());
    end;

    // List page over Field, OpenView, page filter on TableNo: every row as No.=RelationTableNo/RelationFieldNo (AsInteger).
    [Test]
    procedure TestPage_List_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: TestPage "RFR Field Relation List";
        Rows: Text;
    begin
        ListPage.OpenView();
        ListPage.Filter.SetFilter(TableNo, Format(Database::"RFN Source"));
        if ListPage.First() then
            repeat
                Rows += Format(ListPage."No.".AsInteger()) + '=' + Format(ListPage.RelationTableNo.AsInteger()) + '/' + Format(ListPage.RelationFieldNo.AsInteger()) + ',';
            until not ListPage.Next();
        ListPage.Close();
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', '1=0/0,2=0/0,10=75920/0,11=75920/1,12=75920/2,13=75921/0,14=75921/5,15=75922/0,16=75922/2,17=75922/1,18=75920/0,19=75922/0,20=0/0,21=0/0,22=0/0,23=0/0,24=75920/0,25=2000000120/0,26=0/0,27=75920/0,75925=75920/0,75926=75920/2,2000000000=0/0,2000000001=0/0,2000000002=2000000120/0,2000000003=0/0,2000000004=2000000120/0,');
        Observer.Verify();
    end;

    // List page: GoToKey on single rows, the field text (Value) and AsInteger.
    [Test]
    procedure TestPage_List_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: TestPage "RFR Field Relation List";
    begin
        ListPage.OpenView();
        Observer.Observe('10 found', Format(ListPage.GoToKey(Database::"RFN Source", 10)));
        Observer.Observe('10 RelationFieldNo Value', ListPage.RelationFieldNo.Value);
        Observer.Observe('10 RelationFieldNo AsInteger', Format(ListPage.RelationFieldNo.AsInteger()));
        Observer.Observe('10 RelationTableNo AsInteger', Format(ListPage.RelationTableNo.AsInteger()));
        Observer.Observe('19 found', Format(ListPage.GoToKey(Database::"RFN Source", 19)));
        Observer.Observe('19 RelationFieldNo AsInteger', Format(ListPage.RelationFieldNo.AsInteger()));
        Observer.Observe('25 found', Format(ListPage.GoToKey(Database::"RFN Source", 25)));
        Observer.Observe('25 RelationFieldNo AsInteger', Format(ListPage.RelationFieldNo.AsInteger()));
        Observer.Observe('16 found', Format(ListPage.GoToKey(Database::"RFN Source", 16)));
        Observer.Observe('16 RelationFieldNo Value', ListPage.RelationFieldNo.Value);
        ListPage.Close();
        Observer.Expect('10 found', 'Yes');
        Observer.Expect('10 RelationFieldNo Value', '0');
        Observer.Expect('10 RelationFieldNo AsInteger', '0');
        Observer.Expect('10 RelationTableNo AsInteger', '75920');
        Observer.Expect('19 found', 'Yes');
        Observer.Expect('19 RelationFieldNo AsInteger', '0');
        Observer.Expect('25 found', 'Yes');
        Observer.Expect('25 RelationFieldNo AsInteger', '0');
        Observer.Expect('16 found', 'Yes');
        Observer.Expect('16 RelationFieldNo Value', '2');
        Observer.Verify();
    end;

    // List page: page filter on RelationFieldNo.
    [Test]
    procedure TestPage_List_FilterOnRelationFieldNo()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: TestPage "RFR Field Relation List";
        Numbers: Text;
    begin
        ListPage.OpenView();
        ListPage.Filter.SetFilter(TableNo, Format(Database::"RFN Source"));
        ListPage.Filter.SetFilter(RelationTableNo, '<>0');
        ListPage.Filter.SetFilter(RelationFieldNo, '0');
        if ListPage.First() then
            repeat
                Numbers += Format(ListPage."No.".AsInteger()) + ',';
            until not ListPage.Next();
        ListPage.Close();
        Observer.Observe('related, field 0', Numbers);
        Observer.Expect('related, field 0', '10,13,15,18,19,24,25,27,75925,2000000002,2000000004,');
        Observer.Verify();
    end;

    // Card page over Field: OpenView + GoToKey, and TestPage.Trap + Page.Run with a Field record.
    [Test]
    procedure TestPage_Card_OpenViewAndTrap()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        CardPage: TestPage "RFR Field Relation Card";
        Trapped: TestPage "RFR Field Relation Card";
    begin
        CardPage.OpenView();
        Observer.Observe('OpenView 13 found', Format(CardPage.GoToKey(Database::"RFN Source", 13)));
        Observer.Observe('OpenView 13', Format(CardPage.RelationTableNo.AsInteger()) + '/' + Format(CardPage.RelationFieldNo.AsInteger()));
        Observer.Observe('OpenView 75925 found', Format(CardPage.GoToKey(Database::"RFN Source", 75925)));
        Observer.Observe('OpenView 75925', Format(CardPage.RelationTableNo.AsInteger()) + '/' + Format(CardPage.RelationFieldNo.AsInteger()));
        CardPage.Close();
        FieldRec.Get(Database::"RFN Source", 15);
        Trapped.Trap();
        Page.Run(Page::"RFR Field Relation Card", FieldRec);
        Observer.Observe('Trap Page.Run 15', Format(Trapped.RelationTableNo.AsInteger()) + '/' + Format(Trapped.RelationFieldNo.AsInteger()));
        Trapped.Close();
        Observer.Expect('OpenView 13 found', 'Yes');
        Observer.Expect('OpenView 13', '75921/0');
        Observer.Expect('OpenView 75925 found', 'Yes');
        Observer.Expect('OpenView 75925', '75920/0');
        Observer.Expect('Trap Page.Run 15', '75922/0');
        Observer.Verify();
    end;

    // Record.Relation() of field 21 (TableRelation = if (Kind = const(A)) "RFN Target One", no else) with Kind = B, through asserterror.
    [Test]
    procedure Record_Relation_UnmatchedCondition_AssertError()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "RFN Source";
        Target: Integer;
    begin
        Source.Kind := Source.Kind::B;
        asserterror Target := Source.Relation(Source.CondOneBranch);
        Observer.ObserveError('Kind B, 21 one branch');
        Observer.Expect('Kind B, 21 one branch|text', 'No relationship has been associated with the field CondOneBranch in RFN Source.');
        Observer.Expect('Kind B, 21 one branch|code', 'NoRelationship');
        Observer.Verify();
    end;

    // Record.Relation() neighbors, through Codeunit.Run so a raise is observed as its text: the record from a temporary Get, a field
    // without a relation, and conditional relations whose branches always match.
    [Test]
    procedure Record_Relation_Neighbors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('init B: 21 one branch', ReadRelation(1, 21, "RFN Kind"::B));
        Observer.Observe('temp Get B: 21 one branch', ReadRelation(2, 21, "RFN Kind"::B));
        Observer.Observe('temp Get A: 21 one branch', ReadRelation(2, 21, "RFN Kind"::A));
        Observer.Observe('init A: 26 no relation', ReadRelation(1, 26, "RFN Kind"::A));
        Observer.Observe('init A: 10 no field', ReadRelation(1, 10, "RFN Kind"::A));
        Observer.Observe('init A: 22 same target both', ReadRelation(1, 22, "RFN Kind"::A));
        Observer.Observe('init B: 22 same target both', ReadRelation(1, 22, "RFN Kind"::B));
        Observer.Observe('init B: 23 fields named', ReadRelation(1, 23, "RFN Kind"::B));
        Observer.Observe('init B: 20 two tables, no field', ReadRelation(1, 20, "RFN Kind"::B));
        Observer.Expect('init B: 21 one branch', 'error: No relationship has been associated with the field CondOneBranch in RFN Source.');
        Observer.Expect('temp Get B: 21 one branch', 'error: No relationship has been associated with the field CondOneBranch in RFN Source.');
        Observer.Expect('temp Get A: 21 one branch', '75920');
        Observer.Expect('init A: 26 no relation', 'error: No relationship has been associated with the field NoRelation in RFN Source.');
        Observer.Expect('init A: 10 no field', '75920');
        Observer.Expect('init A: 22 same target both', '75920');
        Observer.Expect('init B: 22 same target both', '75920');
        Observer.Expect('init B: 23 fields named', '75922');
        Observer.Expect('init B: 20 two tables, no field', '75922');
        Observer.Verify();
    end;

    local procedure ReadRelation(How: Integer; FieldNo: Integer; Kind: Enum "RFN Kind"): Text
    var
        Reader: Codeunit "RFR Record Relation Reader";
    begin
        ClearLastError();
        Reader.SetUp(How, FieldNo, Kind);
        if Reader.Run() then
            exit(Format(Reader.Result()));
        exit('error: ' + GetLastErrorText());
    end;
}

codeunit 75954 "RFR Record Relation Reader"
{
    var
        How: Integer;
        FieldNo: Integer;
        Kind: Enum "RFN Kind";
        Value: Integer;

    // How = 1: a record that was only given Kind; How = 2: a temporary record inserted with Kind and read back with Get.
    trigger OnRun()
    var
        Source: Record "RFN Source";
        TempSource: Record "RFN Source" temporary;
    begin
        if How = 2 then begin
            TempSource.Id := 1;
            TempSource.Kind := Kind;
            TempSource.Insert();
            TempSource.Get(1);
            Value := Read(TempSource);
        end else begin
            Source.Kind := Kind;
            Value := Read(Source);
        end;
    end;

    local procedure Read(var Source: Record "RFN Source"): Integer
    begin
        case FieldNo of
            10:
                exit(Source.Relation(Source.NoField));
            20:
                exit(Source.Relation(Source.CondNoField));
            21:
                exit(Source.Relation(Source.CondOneBranch));
            22:
                exit(Source.Relation(Source.CondSameTarget));
            23:
                exit(Source.Relation(Source.CondWithField));
            26:
                exit(Source.Relation(Source.NoRelation));
        end;
        Error('field %1 is not set up in the reader', FieldNo);
    end;

    procedure SetUp(NewHow: Integer; NewFieldNo: Integer; NewKind: Enum "RFN Kind")
    begin
        How := NewHow;
        FieldNo := NewFieldNo;
        Kind := NewKind;
    end;

    procedure Result(): Integer
    begin
        exit(Value);
    end;
}

codeunit 75957 "RFR Query Reader"
{
    var
        Which: Integer;
        Stage: Text;
        Rows: Text;

    trigger OnRun()
    var
        Relations: Query "RFR Field Relations";
        NoField: Query "RFR Field Relations No Field";
        ColFilter: Query "RFR Field Relations ColFilter";
    begin
        Stage := 'filter';
        case Which of
            1, 2:
                begin
                    Relations.SetRange(TableNo, Database::"RFN Source");
                    if Which = 2 then begin
                        Relations.SetFilter(RelationTableNo, '<>0');
                        Relations.SetRange(RelationFieldNo, 0);
                    end;
                    Stage := 'open';
                    Relations.Open();
                    Stage := 'read';
                    while Relations.Read() do
                        Rows += Format(Relations.No) + '=' + Format(Relations.RelationTableNo) + '/' + Format(Relations.RelationFieldNo) + ',';
                end;
            3:
                begin
                    NoField.SetRange(TableNo, Database::"RFN Source");
                    Stage := 'open';
                    NoField.Open();
                    Stage := 'read';
                    while NoField.Read() do
                        Rows += Format(NoField.No) + '=' + Format(NoField.RelationFieldNo) + ',';
                end;
            4:
                begin
                    ColFilter.SetRange(TableNo, Database::"RFN Source");
                    Stage := 'open';
                    ColFilter.Open();
                    Stage := 'read';
                    while ColFilter.Read() do
                        Rows += Format(ColFilter.No) + '=' + Format(ColFilter.RelationTableNo) + '/' + Format(ColFilter.RelationFieldNo) + ',';
                end;
        end;
        Stage := 'done';
    end;

    procedure SetUp(NewWhich: Integer)
    begin
        Which := NewWhich;
    end;

    procedure Result(): Text
    begin
        exit(Stage + ' ' + Rows);
    end;
}
