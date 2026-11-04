// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-integer-table-fieldref-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 81151, tables 81153-81156, pages 81154-81160, test codeunit 81162
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Page.RunModal(PageId, Rec) on a plain list page (no Editable property) called from
//   (a) a table field's OnLookup trigger, reached through TestPage <field>.Lookup() on a list page opened with OpenEdit,
//   (b) the same, the list page opened with Trap + Page.Run(id, Rec) (the shape of Microsoft's T001_LookupItemUnitOfMeasure, codeunits 134123/134198),
//   (c) a page field's OnLookup trigger, reached through Lookup(),
//   (d) a page action's OnAction, reached through Invoke(),
//   (e) test code directly (only CurrPage.LookupMode and the action; the rows are pinned in handlers/TestPageModalNewRowLine_Tests.al).
//   The modal page records CurrPage.LookupMode in OnOpenPage. Its handler walks from First() until Next() answers false (one row per filter
//   value, like Microsoft's item with one unit of measure, and two rows for comparison), then Last() and Next(), then First() and OK().
//   Afterwards: the action RunModal returned and the field value after the lookup.
//   Direct calls that separate the inputs: a table with no LookupPageId (the list above), a table whose LookupPageId is the page run, and a
//   table whose LookupPageId is another page; a filter on a key field, on a non-key field and none; LookupMode(false) + RunModal(); and a
//   handler that only walks the rows (as handlers/TestPageModalNewRowLine_Tests.al does) next to one that also invokes OK(); the same list
//   without its OnOpenPage trigger, and with only one field and no trigger (the shape of the pages in TestPageModalNewRowLine_Objects.al).
// Measured (BC 27.5, 28.5, 29.0): every Page.RunModal(PageId, Rec) here whose return value is used opens the page in lookup mode
//   (CurrPage.LookupMode = Yes, TestPage.Editable() = No, no new-row line, Next() at the last row = No), from an OnLookup trigger, from an
//   action and from test code alike, whatever the table's LookupPageId, the filter or the page's triggers; RunModal returns LookupOK after OK()
//   and LookupCancel when the handler only walks. Only LookupMode(false) + RunModal() shows the new-row line (and returns OK).
// Measured (BC 29.0, the Shape_* tests): the deciding input is whether the caller uses the return value of Page.RunModal(PageId, Rec) or
//   Page.RunModal(0, Rec). Used (assigned, passed to Format, compared in an if): lookup mode as above. Called as a statement: not lookup mode
//   (CurrPage.LookupMode = No, Editable() = Yes, new-row line), as handlers/TestPageModalNewRowLine_Tests.al Plain_RunModalById_HasTheNewRowLine
//   measures (it calls it as a statement; its own page 60299 with the return value used is in lookup mode here). DataClassification
//   (CustomerContent or SystemMetadata) and a LookupPageId naming an Editable = false page change nothing. A Page variable's RunModal() with no
//   LookupMode call is not lookup mode whether its return value is used or not.
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660 item 3.
// BC versions: all (CI)

table 81153 "LT BE Lk Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; "Code"; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Grp, "Code") { Clustered = true; } }
}

table 81154 "LT BE Lk Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; TableLk; Code[10])
        {
            trigger OnLookup()
            var
                Row: Record "LT BE Lk Row";
                Log: Codeunit "LT BE Lk Log";
                Act: Action;
            begin
                Row.SetRange(Grp, Rec.Grp);
                Act := Page.RunModal(Page::"LT BE Lk List", Row);
                Log.Add('action=' + Format(Act));
                if Act = Action::LookupOK then
                    Rec.Validate(TableLk, Row."Code");
            end;
        }
        field(4; PageLk; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 81154 "LT BE Lk List"
{
    PageType = List;
    SourceTable = "LT BE Lk Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT BE Lk Log";
    begin
        Log.Add('lookupMode=' + Format(CurrPage.LookupMode));
    end;
}

page 81155 "LT BE Lk Doc List"
{
    PageType = List;
    SourceTable = "LT BE Lk Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(TableLk; Rec.TableLk) { ApplicationArea = All; }
                field(PageLk; Rec.PageLk)
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Row: Record "LT BE Lk Row";
                        Act: Action;
                    begin
                        Row.SetRange(Grp, Rec.Grp);
                        Act := Page.RunModal(Page::"LT BE Lk List", Row);
                        Log.Add('action=' + Format(Act));
                        if Act = Action::LookupOK then begin
                            Text := Row."Code";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PickRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "LT BE Lk Row";
                    Act: Action;
                begin
                    Row.SetRange(Grp, Rec.Grp);
                    Act := Page.RunModal(Page::"LT BE Lk List", Row);
                    Log.Add('action=' + Format(Act));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Lk Log";
}

codeunit 81151 "LT BE Lk Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

table 81155 "LT BE Lk Row Self"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT BE Lk List Self";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 81156 "LT BE Lk Row Other"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT BE Lk Other Lookup";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 81156 "LT BE Lk List Self"
{
    PageType = List;
    SourceTable = "LT BE Lk Row Self";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT BE Lk Log";
    begin
        Log.Add('lookupMode=' + Format(CurrPage.LookupMode));
    end;
}

page 81157 "LT BE Lk List Other"
{
    PageType = List;
    SourceTable = "LT BE Lk Row Other";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT BE Lk Log";
    begin
        Log.Add('lookupMode=' + Format(CurrPage.LookupMode));
    end;
}

page 81158 "LT BE Lk Other Lookup"
{
    PageType = List;
    SourceTable = "LT BE Lk Row Other";
    ApplicationArea = All;
    UsageCategory = None;

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
}

page 81159 "LT BE Lk List NoOpen"
{
    PageType = List;
    SourceTable = "LT BE Lk Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 81160 "LT BE Lk List OneField"
{
    PageType = List;
    SourceTable = "LT BE Lk Row";
    ApplicationArea = All;
    UsageCategory = None;

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
}

// Shapes of handlers/TestPageModalNewRowLine_Objects.al that the lists above do not have: a CustomerContent table, and a table whose
// LookupPageId is a page with Editable = false. Both lists have one field and no trigger, as page 60299 there.
table 81157 "LT BE Lk Row CC"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 81158 "LT BE Lk Row NE"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT BE Lk NE Lookup";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 81161 "LT BE Lk List CC"
{
    PageType = List;
    SourceTable = "LT BE Lk Row CC";
    ApplicationArea = All;
    UsageCategory = None;

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
}

page 81162 "LT BE Lk List NE"
{
    PageType = List;
    SourceTable = "LT BE Lk Row NE";
    ApplicationArea = All;
    UsageCategory = None;

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
}

page 81163 "LT BE Lk NE Lookup"
{
    PageType = List;
    SourceTable = "LT BE Lk Row NE";
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
            }
        }
    }
}

codeunit 81162 "LT BE RunModal OnLookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT BE Lk Log";

    // Group G1 has one row (U1), group G2 two rows (U2, U3). Doc 1 is in G1, doc 2 in G2.
    local procedure Seed()
    var
        Row: Record "LT BE Lk Row";
        Doc: Record "LT BE Lk Doc";
        SelfRow: Record "LT BE Lk Row Self";
        OtherRow: Record "LT BE Lk Row Other";
    begin
        Row.DeleteAll();
        Doc.DeleteAll();
        AddRow('G1', 'U1', 1);
        AddRow('G2', 'U2', 2);
        AddRow('G2', 'U3', 3);
        AddRow('G3', 'U4', 4);
        AddDoc(1, 'G1');
        AddDoc(2, 'G2');
        SelfRow.DeleteAll();
        OtherRow.DeleteAll();
        SelfRow."Code" := 'S1';
        SelfRow.Qty := 1;
        SelfRow.Insert();
        SelfRow."Code" := 'S2';
        SelfRow.Qty := 2;
        SelfRow.Insert();
        OtherRow."Code" := 'O1';
        OtherRow.Qty := 1;
        OtherRow.Insert();
        OtherRow."Code" := 'O2';
        OtherRow.Qty := 2;
        OtherRow.Insert();
        Log.Take();
    end;

    local procedure AddRow(Group: Code[10]; RowCode: Code[10]; Qty: Integer)
    var
        Row: Record "LT BE Lk Row";
    begin
        Row.Init();
        Row.Grp := Group;
        Row."Code" := RowCode;
        Row.Qty := Qty;
        Row.Insert();
    end;

    local procedure AddDoc(Id: Integer; Group: Code[10])
    var
        Doc: Record "LT BE Lk Doc";
    begin
        Doc.Init();
        Doc.Id := Id;
        Doc.Grp := Group;
        Doc.Insert();
    end;

    local procedure OpenAt(var TP: TestPage "LT BE Lk Doc List"; Id: Integer)
    var
        Doc: Record "LT BE Lk Doc";
    begin
        TP.OpenEdit();
        Doc.Get(Id);
        TP.GoToRecord(Doc);
    end;

    local procedure StoredTableLk(Id: Integer): Text
    var
        Doc: Record "LT BE Lk Doc";
    begin
        Doc.Get(Id);
        exit(Doc.TableLk);
    end;

    // a: table field OnLookup, host opened with OpenEdit.
    local procedure TableLookupCase(var Observer: Codeunit "Probe Observer"; Id: Integer)
    var
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, Id);
        TP.TableLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.TableLk.Value());
        TP.Close();
        Observer.Observe('stored', StoredTableLk(Id));
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TableLookupCase(Observer, 1);
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U1,rows=[U1],last=Yes,atLast=U1,nextAfterLast=No,afterNext=U1,backAtFirst=U1,action=LookupOK');
        Observer.Expect('value', 'U1');
        Observer.Expect('stored', 'U1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_TwoRows_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TableLookupCase(Observer, 2);
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U2,rows=[U2][U3],last=Yes,atLast=U3,nextAfterLast=No,afterNext=U3,backAtFirst=U2,action=LookupOK');
        Observer.Expect('value', 'U2');
        Observer.Expect('stored', 'U2');
        Observer.Verify();
    end;

    // b: table field OnLookup, host opened with Trap + Page.Run(id, Rec).
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure TableOnLookup_OneRow_TrapPageRun()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "LT BE Lk Doc";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        Doc.Get(1);
        TP.Trap();
        Page.Run(Page::"LT BE Lk Doc List", Doc);
        Observer.Observe('at', TP.Id.Value());
        TP.TableLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.TableLk.Value());
        TP.Close();
        Observer.Observe('stored', StoredTableLk(1));
        Observer.Expect('at', '1');
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U1,rows=[U1],last=Yes,atLast=U1,nextAfterLast=No,afterNext=U1,backAtFirst=U1,action=LookupOK');
        Observer.Expect('value', 'U1');
        Observer.Expect('stored', 'U1');
        Observer.Verify();
    end;

    // c: page field OnLookup.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure PageOnLookup_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, 1);
        TP.PageLk.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('value', TP.PageLk.Value());
        TP.Close();
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U1,rows=[U1],last=Yes,atLast=U1,nextAfterLast=No,afterNext=U1,backAtFirst=U1,action=LookupOK');
        Observer.Expect('value', 'U1');
        Observer.Verify();
    end;

    // d: page action.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure ActionRunModal_OneRow_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Lk Doc List";
    begin
        Seed();
        OpenAt(TP, 1);
        TP.PickRow.Invoke();
        Observer.Observe('log', Log.Take());
        TP.Close();
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U1,rows=[U1],last=Yes,atLast=U1,nextAfterLast=No,afterNext=U1,backAtFirst=U1,action=LookupOK');
        Observer.Verify();
    end;

    // e: test code directly.
    [Test]
    [HandlerFunctions('WalkHandler')]
    procedure DirectRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        Act: Action;
    begin
        Seed();
        Row.SetRange(Grp, 'G1');
        Act := Page.RunModal(Page::"LT BE Lk List", Row);
        Log.Add('action=' + Format(Act));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,firstValue=U1,rows=[U1],last=Yes,atLast=U1,nextAfterLast=No,afterNext=U1,backAtFirst=U1,action=LookupOK');
        Observer.Verify();
    end;

    // ---- Direct calls that separate the inputs ----------------------------------------------

    [Test]
    [HandlerFunctions('WalkOnlyHandler')]
    procedure Direct_NoLookupPageId_KeyFilter_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[U2][U3],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkOnlyHandler')]
    procedure Direct_NoLookupPageId_NonKeyFilter_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetFilter(Qty, '2|3');
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[U2][U3],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkOnlyHandler')]
    procedure Direct_NoLookupPageId_NoFilter_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[U1][U2][U3][U4],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkOnlyHandler')]
    procedure Direct_NoLookupPageId_LookupModeFalse_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        LkList: Page "LT BE Lk List";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        LkList.SetTableView(Row);
        LkList.LookupMode(false);
        Log.Add('action=' + Format(LkList.RunModal()));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=No,editable=Yes,rows=[U2][U3][],action=OK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SelfWalkOnlyHandler')]
    procedure Direct_LookupPageIdIsThePage_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Self";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List Self", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[S1][S2],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SelfWalkOkHandler')]
    procedure Direct_LookupPageIdIsThePage_WalkAndOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Self";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List Self", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[S1][S2],action=LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OtherWalkOnlyHandler')]
    procedure Direct_LookupPageIdIsAnotherPage_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Other";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List Other", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[O1][O2],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OtherWalkOkHandler')]
    procedure Direct_LookupPageIdIsAnotherPage_WalkAndOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Other";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List Other", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[O1][O2],action=LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoOpenWalkOnlyHandler')]
    procedure Direct_NoOnOpenPage_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List NoOpen", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=No,rows=[U2][U3],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Direct_OneFieldNoTrigger_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List OneField", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=No,rows=[U2][U3],action=LookupCancel');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure NoOpenWalkOnlyHandler(var LkList: TestPage "LT BE Lk List NoOpen")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure OneFieldWalkOnlyHandler(var LkList: TestPage "LT BE Lk List OneField")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure WalkOnlyHandler(var LkList: TestPage "LT BE Lk List")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure SelfWalkOnlyHandler(var LkList: TestPage "LT BE Lk List Self")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure SelfWalkOkHandler(var LkList: TestPage "LT BE Lk List Self")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
        LkList.First();
        LkList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure OtherWalkOnlyHandler(var LkList: TestPage "LT BE Lk List Other")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure OtherWalkOkHandler(var LkList: TestPage "LT BE Lk List Other")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
        LkList.First();
        LkList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WalkHandler(var LkList: TestPage "LT BE Lk List")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        Log.Add('firstValue=' + LkList."Code".Value());
        repeat
            Seen += '[' + LkList."Code".Value() + ']';
            Steps += 1;
        until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
        Log.Add('last=' + Format(LkList.Last()));
        Log.Add('atLast=' + LkList."Code".Value());
        Log.Add('nextAfterLast=' + Format(LkList.Next()));
        Log.Add('afterNext=' + LkList."Code".Value());
        LkList.First();
        Log.Add('backAtFirst=' + LkList."Code".Value());
        LkList.OK().Invoke();
    end;

    // ---- What decides the new-row line of Page.RunModal(id, Rec): the shapes of handlers/TestPageModalNewRowLine_Tests.al ----

    local procedure SeedShapes()
    var
        CCRow: Record "LT BE Lk Row CC";
        NERow: Record "LT BE Lk Row NE";
    begin
        CCRow.DeleteAll();
        NERow.DeleteAll();
        CCRow."Code" := 'C1';
        CCRow.Insert();
        CCRow."Code" := 'C2';
        CCRow.Insert();
        NERow."Code" := 'N1';
        NERow.Insert();
        NERow."Code" := 'N2';
        NERow.Insert();
        Log.Take();
    end;

    // The call as a statement: the return value is not used (as Plain_RunModalById_HasTheNewRowLine calls it).
    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Shape_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        Page.RunModal(Page::"LT BE Lk List OneField", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[U2][U3][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Shape_ReturnAssigned_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        Act: Action;
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        Act := Page.RunModal(Page::"LT BE Lk List OneField", Row);
        Observer.Observe('log', Log.Take());
        Observer.Observe('action', Format(Act));
        Observer.Expect('log', 'editable=No,rows=[U2][U3]');
        Observer.Expect('action', 'LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Shape_ReturnInIf_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        if Page.RunModal(Page::"LT BE Lk List OneField", Row) = Action::LookupOK then
            Observer.Observe('if', 'LookupOK')
        else
            Observer.Observe('if', 'other');
        Observer.Observe('log', Log.Take());
        Observer.Expect('if', 'other');
        Observer.Expect('log', 'editable=No,rows=[U2][U3]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CCWalkOnlyHandler')]
    procedure Shape_CustomerContent_ReturnUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row CC";
    begin
        SeedShapes();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List CC", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=No,rows=[C1][C2],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CCWalkOnlyHandler')]
    procedure Shape_CustomerContent_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row CC";
    begin
        SeedShapes();
        Page.RunModal(Page::"LT BE Lk List CC", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[C1][C2][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NEWalkOnlyHandler')]
    procedure Shape_LookupPageIdNotEditable_ReturnUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row NE";
    begin
        SeedShapes();
        Log.Add('action=' + Format(Page.RunModal(Page::"LT BE Lk List NE", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=No,rows=[N1][N2],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NEWalkOnlyHandler')]
    procedure Shape_LookupPageIdNotEditable_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row NE";
    begin
        SeedShapes();
        Page.RunModal(Page::"LT BE Lk List NE", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[N1][N2][]');
        Observer.Verify();
    end;

    // The page of Plain_RunModalById_HasTheNewRowLine itself (page 60299 over table 60297), its return value used.
    [Test]
    [HandlerFunctions('NrlPlainWalkOnlyHandler')]
    procedure Shape_NrlPlainPage_ReturnUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "Test Modal NRL Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
        Row."No." := 'B';
        Row.Insert();
        Row.Reset();
        Log.Take();
        Log.Add('action=' + Format(Page.RunModal(Page::"Test Modal NRL Plain", Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=No,rows=[A][B],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NrlPlainWalkOnlyHandler')]
    procedure Shape_NrlPlainPage_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "Test Modal NRL Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
        Row."No." := 'B';
        Row.Insert();
        Row.Reset();
        Log.Take();
        Page.RunModal(Page::"Test Modal NRL Plain", Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[A][B][]');
        Observer.Verify();
    end;

    // A Page variable with no LookupMode call, and Page.RunModal(0, Rec), each with the return value used and not used.
    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Shape_PageVar_ReturnUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        LkList: Page "LT BE Lk List OneField";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        LkList.SetTableView(Row);
        Log.Add('action=' + Format(LkList.RunModal()));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[U2][U3][],action=OK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneFieldWalkOnlyHandler')]
    procedure Shape_PageVar_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row";
        LkList: Page "LT BE Lk List OneField";
    begin
        Seed();
        Row.SetRange(Grp, 'G2');
        LkList.SetTableView(Row);
        LkList.RunModal();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'editable=Yes,rows=[U2][U3][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SelfWalkOnlyHandler')]
    procedure Shape_RunModalZero_ReturnUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Self";
    begin
        Seed();
        Log.Add('action=' + Format(Page.RunModal(0, Row)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=Yes,editable=No,rows=[S1][S2],action=LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SelfWalkOnlyHandler')]
    procedure Shape_RunModalZero_ReturnNotUsed_WalkOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BE Lk Row Self";
    begin
        Seed();
        Page.RunModal(0, Row);
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'lookupMode=No,editable=Yes,rows=[S1][S2][]');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CCWalkOnlyHandler(var LkList: TestPage "LT BE Lk List CC")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure NEWalkOnlyHandler(var LkList: TestPage "LT BE Lk List NE")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(LkList.Editable()));
        if LkList.First() then
            repeat
                Seen += '[' + LkList."Code".Value() + ']';
                Steps += 1;
            until (not LkList.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;

    [ModalPageHandler]
    procedure NrlPlainWalkOnlyHandler(var TP: TestPage "Test Modal NRL Plain")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Log.Add('editable=' + Format(TP.Editable()));
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
                Steps += 1;
            until (not TP.Next()) or (Steps > 5);
        Log.Add('rows=' + Seen);
    end;
}
