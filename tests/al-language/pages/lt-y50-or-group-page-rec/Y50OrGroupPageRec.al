// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 92967, pages 92977 - 92979, codeunits 92970 - 92971 (writer Y50)
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-21: what a list page's Rec holds and which rows it shows when FilterGroup(-1) (OR) filters, marks and
//   MarkedOnly reach it, and the page has code that runs later (row triggers, an action with SetSelectionFilter). The pinned neighbours
//   (CdTestPageLeads.al:772, Y41PageVarMarkedOnly.al:197) have no later code or no group -1 current. Three shapes: A, OnOpenPage marks
//   the rows where Approver or Sender = U1 with group -1 current and turns MarkedOnly on in group -1 (Approval Entries); B, the caller
//   builds such a record and runs Page.Run(Id, Rec, FieldNo) (General Posting Setup); C, SetTableView + SetRecord of a record whose
//   group -1 is current, then a lookup (Item PickItem). Rows (Id Approver Sender Grp): 1 U1 X G1, 2 X U1 G2, 3 X X G1, 4 U1 U1 G2, 5 Y Y G1.
//   Describe(R): g0 = GetFilters in group 0, gm1 = GetFilters in group -1, mo = MarkedOnly, n = Count, cur = FilterGroup().
//   Log: open from OnOpenPage, R: OnAfterGetRecord, C: OnAfterGetCurrRecord, act / sel from the action Show.
// BC versions: 27, 28, 29

table 92967 "LT Y50 OG Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Approver; Code[20]) { }
        field(3; Sender; Code[20]) { }
        field(4; Grp; Code[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92970 "LT Y50 OG Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    // Reads the filters of group 0 and group -1 and switches back to the group it found.
    procedure Describe(var R: Record "LT Y50 OG Entry"): Text
    var
        Cur: Integer;
        G0: Text;
        Gm1: Text;
    begin
        Cur := R.FilterGroup();
        R.FilterGroup(0);
        G0 := R.GetFilters();
        R.FilterGroup(-1);
        Gm1 := R.GetFilters();
        R.FilterGroup(Cur);
        exit('g0=' + G0 + ' gm1=' + Gm1 + ' mo=' + Format(R.MarkedOnly()) + ' n=' + Format(R.Count()) + ' cur=' + Format(R.FilterGroup()));
    end;
}

page 92977 "LT Y50 OG Marks"
{
    PageType = List;
    SourceTable = "LT Y50 OG Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Approver; Rec.Approver)
                {
                    ApplicationArea = All;
                }
                field(Sender; Rec.Sender)
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Caption = 'Show';

                trigger OnAction()
                var
                    Sel: Record "LT Y50 OG Entry";
                begin
                    Log.Add('act ' + Log.Describe(Rec));
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('sel ' + Log.Describe(Sel));
                end;
            }
        }
    }

    // The MarkAllWhereUserisApproverOrSender shape: marks set and MarkedOnly turned on while group -1 is current.
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(-1);
        Rec.SetRange(Approver, 'U1');
        Rec.SetRange(Sender, 'U1');
        if Rec.FindSet() then
            repeat
                Rec.Mark(true);
            until Rec.Next() = 0;
        Rec.MarkedOnly(true);
        Rec.FilterGroup(0);
        Log.Add('open ' + Log.Describe(Rec));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id) + ' ' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT Y50 OG Log";
}

page 92978 "LT Y50 OG Or Only"
{
    PageType = List;
    SourceTable = "LT Y50 OG Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Approver; Rec.Approver)
                {
                    ApplicationArea = All;
                }
                field(Sender; Rec.Sender)
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Caption = 'Show';

                trigger OnAction()
                var
                    Sel: Record "LT Y50 OG Entry";
                begin
                    Log.Add('act ' + Log.Describe(Rec));
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('sel ' + Log.Describe(Sel));
                end;
            }
        }
    }

    // Only the OR filter (no marks, no MarkedOnly), with code that runs later.
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(-1);
        Rec.SetRange(Approver, 'U1');
        Rec.SetRange(Sender, 'U1');
        Rec.FilterGroup(0);
        Log.Add('open ' + Log.Describe(Rec));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id) + ' ' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT Y50 OG Log";
}

page 92979 "LT Y50 OG Plain"
{
    PageType = List;
    SourceTable = "LT Y50 OG Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Approver; Rec.Approver)
                {
                    ApplicationArea = All;
                }
                field(Sender; Rec.Sender)
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                Caption = 'Show';

                trigger OnAction()
                var
                    Sel: Record "LT Y50 OG Entry";
                begin
                    Log.Add('act ' + Log.Describe(Rec));
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('sel ' + Log.Describe(Sel));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open ' + Log.Describe(Rec));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id) + ' ' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT Y50 OG Log";
}

codeunit 92971 "LT Y50 OG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y50 OG Log";

    local procedure Seed(WithU1: Boolean)
    var
        Entry: Record "LT Y50 OG Entry";
    begin
        Entry.DeleteAll();
        if WithU1 then begin
            AddEntry(1, 'U1', 'X', 'G1');
            AddEntry(2, 'X', 'U1', 'G2');
            AddEntry(4, 'U1', 'U1', 'G2');
        end;
        AddEntry(3, 'X', 'X', 'G1');
        AddEntry(5, 'Y', 'Y', 'G1');
        Log.Take();
    end;

    local procedure AddEntry(Id: Integer; Approver: Code[20]; Sender: Code[20]; Grp: Code[10])
    var
        Entry: Record "LT Y50 OG Entry";
    begin
        Entry.Id := Id;
        Entry.Approver := Approver;
        Entry.Sender := Sender;
        Entry.Grp := Grp;
        Entry.Insert();
    end;

    local procedure WalkMarks(var TP: TestPage "LT Y50 OG Marks"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if TP.First() then
            repeat
                Rows += TP.Id.Value() + ',';
                i += 1;
            until (not TP.Next()) or (i >= 10);
        exit(Rows);
    end;

    local procedure WalkOrOnly(var TP: TestPage "LT Y50 OG Or Only"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if TP.First() then
            repeat
                Rows += TP.Id.Value() + ',';
                i += 1;
            until (not TP.Next()) or (i >= 10);
        exit(Rows);
    end;

    // The walk with the result of each move: First, then Next until false.
    local procedure WalkPlain(var TP: TestPage "LT Y50 OG Plain"): Text
    var
        Rows: Text;
        i: Integer;
        Moved: Boolean;
    begin
        Moved := TP.First();
        Rows := 'first=' + Format(Moved) + '/' + TP.Id.Value();
        while Moved and (i < 10) do begin
            Moved := TP.Next();
            Rows += ',next=' + Format(Moved) + '/' + TP.Id.Value();
            i += 1;
        end;
        exit(Rows);
    end;

    [TryFunction]
    local procedure TryGetFilter(var TP: TestPage "LT Y50 OG Marks"; var Result: Text)
    begin
        Result := TP.Filter.GetFilter(Approver);
    end;

    [TryFunction]
    local procedure TrySetFilter(var TP: TestPage "LT Y50 OG Marks")
    begin
        TP.Filter.SetFilter(Grp, 'G1');
    end;

    // T1, shape A: OnOpenPage marks with group -1 current; the walk and the log.
    [Test]
    procedure G521_OnOpenPage_OrMarks_Walk()
    var
        TP: TestPage "LT Y50 OG Marks";
    begin
        Seed(true);
        TP.OpenView();
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', WalkMarks(TP));
        Observer.Observe('walk log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // T2: shape A, the action on a shown row.
    [Test]
    procedure G521_OnOpenPage_OrMarks_Action()
    var
        TP: TestPage "LT Y50 OG Marks";
    begin
        Seed(true);
        TP.OpenView();
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('gotokey', Format(TP.GoToKey(2)) + '/' + TP.Id.Value() + ':' + Log.Take());
        TP.Show.Invoke();
        Observer.Observe('action log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // T3, shape B: the caller builds the record (group -1, marks, FilterGroup(0), MarkedOnly) and runs Page.Run(Id, Rec, FieldNo).
    [Test]
    procedure G521_PageRunRec_OrMarks()
    var
        Entry: Record "LT Y50 OG Entry";
        TP: TestPage "LT Y50 OG Plain";
    begin
        Seed(true);
        Entry.FilterGroup(-1);
        Entry.SetRange(Approver, 'U1');
        Entry.SetRange(Sender, 'U1');
        if Entry.FindSet() then
            repeat
                Entry.Mark(true);
            until Entry.Next() = 0;
        Entry.FilterGroup(0);
        Entry.MarkedOnly(true);
        Observer.Observe('caller', Log.Describe(Entry));
        TP.Trap();
        Page.Run(Page::"LT Y50 OG Plain", Entry, Entry.FieldNo(Grp));
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', WalkPlain(TP));
        Observer.Observe('walk log', Log.Take());
        TP.First();
        Log.Take();
        TP.Show.Invoke();
        Observer.Observe('action log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // T4: only the OR filter in OnOpenPage, with code that runs later.
    [Test]
    procedure G521_OnOpenPage_OrOnly_LaterCode()
    var
        TP: TestPage "LT Y50 OG Or Only";
    begin
        Seed(true);
        TP.OpenView();
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', WalkOrOnly(TP));
        Observer.Observe('walk log', Log.Take());
        TP.First();
        Log.Take();
        TP.Show.Invoke();
        Observer.Observe('action log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // T5: shape A, then the TestPage Filter: GetFilter, SetFilter on Grp, the walk.
    [Test]
    procedure G521_OnOpenPage_OrMarks_TestPageFilter()
    var
        TP: TestPage "LT Y50 OG Marks";
        Result: Text;
        Ok: Boolean;
    begin
        Seed(true);
        TP.OpenView();
        Log.Take();
        Ok := TryGetFilter(TP, Result);
        Observer.Observe('getfilter', Format(Ok) + '/' + Result);
        if not Ok then
            Observer.ObserveError('getfilter error');
        Ok := TrySetFilter(TP);
        Observer.Observe('setfilter', Format(Ok) + '/' + TP.Id.Value() + ':' + Log.Take());
        if not Ok then
            Observer.ObserveError('setfilter error');
        Observer.Observe('walk', WalkMarks(TP));
        Observer.Observe('walk log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    // T6, shape C: SetTableView + SetRecord of a record whose group -1 is current, lookup, GetRecord.
    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure G521_SetTableView_GroupMinus1Current_Lookup()
    var
        Entry: Record "LT Y50 OG Entry";
        Entry2: Record "LT Y50 OG Entry";
        Pg: Page "LT Y50 OG Plain";
    begin
        Seed(true);
        Entry.FilterGroup(-1);
        Entry.SetFilter(Id, '2|4');
        Entry.FindFirst();
        Observer.Observe('caller', Format(Entry.Id) + ' ' + Log.Describe(Entry));
        Pg.SetTableView(Entry);
        Pg.SetRecord(Entry);
        Pg.LookupMode(true);
        Observer.Observe('action', Format(Pg.RunModal()));
        Pg.GetRecord(Entry2);
        Observer.Observe('getrecord', Format(Entry2.Id));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // T7: shape A with no row for U1 (the EmptyPage tests).
    [Test]
    procedure G521_OnOpenPage_OrMarks_Empty()
    var
        TP: TestPage "LT Y50 OG Marks";
    begin
        Seed(false);
        TP.OpenView();
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', WalkMarks(TP));
        Observer.Observe('walk log', Log.Take());
        TP.Close();
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LookupHandler(var P: TestPage "LT Y50 OG Plain")
    begin
        Observer.Observe('handler open', P.Id.Value() + ':' + Log.Take());
        Observer.Observe('handler walk', WalkPlain(P));
        Observer.Observe('handler last', Format(P.Last()) + '/' + P.Id.Value());
        Log.Take();
        P.OK().Invoke();
    end;
}
