// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74262, codeunit 74263 (log), page 74264, codeunit 74265
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reasons 24-27): "Page.SetSelectionFilter into a record that has filters (not pinned)".
// Facts: CurrPage.SetSelectionFilter(Sel) from an action of a list page positioned on a row, where Sel already carries a filter: on another field (compatible and conflicting), on the same field (containing and excluding the row), a text filter, a filter in filter group 2, a marked-only record, a record with field content but no filter, a second call on the same record, and a record with a secondary key; the count, GetFilters and per field filters afterwards.
// BC versions: 29 (27 and 28 by CI)

table 74262 "LT P135 Sel Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Grp, Name) { }
    }
}

codeunit 74263 "LT P135 Sel Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

page 74264 "LT P135 Sel List"
{
    PageType = List;
    SourceTable = "LT P135 Sel Row";
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
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
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
            action(ActNone)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(0);
                end;
            }
            action(ActGrpCompatible)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(1);
                end;
            }
            action(ActGrpConflict)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(2);
                end;
            }
            action(ActIdContains)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(3);
                end;
            }
            action(ActIdExcludes)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(4);
                end;
            }
            action(ActNameText)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(5);
                end;
            }
            action(ActFilterGroup)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(6);
                end;
            }
            action(ActMarked)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(7);
                end;
            }
            action(ActPreset)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(8);
                end;
            }
            action(ActTwice)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(9);
                end;
            }
            action(ActKeyed)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Probe(10);
                end;
            }
        }
    }

    local procedure Describe(var Sel: Record "LT P135 Sel Row"): Text
    var
        G2: Text;
        Fg: Integer;
    begin
        Fg := Sel.FilterGroup();
        Sel.FilterGroup(2);
        G2 := Sel.GetFilters();
        Sel.FilterGroup(0);
        exit('count=' + Format(Sel.Count()) + ' filters=[' + Sel.GetFilters() + '] id=[' + Sel.GetFilter(Sel.Id) + '] grp=[' + Sel.GetFilter(Sel.Grp) + '] name=[' + Sel.GetFilter(Sel.Name) + '] g2=[' + G2 + '] has=' + Format(Sel.HasFilter()) + ' markedonly=' + Format(Sel.MarkedOnly()) + ' fg=' + Format(Fg) + ' key=' + Sel.CurrentKey());
    end;

    local procedure Probe(Which: Integer)
    var
        Sel: Record "LT P135 Sel Row";
        Log: Codeunit "LT P135 Sel Log";
    begin
        case Which of
            1:
                Sel.SetRange(Sel.Grp, 1);
            2:
                Sel.SetRange(Sel.Grp, 2);
            3:
                Sel.SetRange(Sel.Id, 1, 3);
            4:
                Sel.SetRange(Sel.Id, 3, 4);
            5:
                Sel.SetFilter(Sel.Name, 'B*');
            6:
                begin
                    Sel.FilterGroup(2);
                    Sel.SetRange(Sel.Grp, 1);
                    Sel.FilterGroup(0);
                end;
            7:
                begin
                    Sel.Get(4);
                    Sel.Mark(true);
                    Sel.MarkedOnly(true);
                end;
            8:
                begin
                    Sel.Id := 99;
                    Sel.Name := 'preset';
                end;
            10:
                Sel.SetCurrentKey(Sel.Grp, Sel.Name);
        end;
        Log.Add('before ' + Describe(Sel));
        CurrPage.SetSelectionFilter(Sel);
        Log.Add('after ' + Describe(Sel));
        if Which = 9 then begin
            CurrPage.SetSelectionFilter(Sel);
            Log.Add('again ' + Describe(Sel));
        end;
    end;
}

codeunit 74265 "LT P135 Sel Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P135 Sel Row";
    begin
        R.DeleteAll();
        Add(1, 1, 'A1');
        Add(2, 1, 'B2');
        Add(3, 2, 'B3');
        Add(4, 2, 'C4');
    end;

    local procedure Add(Id: Integer; Grp: Integer; Name: Text[20])
    var
        R: Record "LT P135 Sel Row";
    begin
        R.Id := Id;
        R.Grp := Grp;
        R.Name := Name;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryRun(var P: TestPage "LT P135 Sel List"; Which: Integer)
    begin
        case Which of
            0: P.ActNone.Invoke();
            1: P.ActGrpCompatible.Invoke();
            2: P.ActGrpConflict.Invoke();
            3: P.ActIdContains.Invoke();
            4: P.ActIdExcludes.Invoke();
            5: P.ActNameText.Invoke();
            6: P.ActFilterGroup.Invoke();
            7: P.ActMarked.Invoke();
            8: P.ActPreset.Invoke();
            9: P.ActTwice.Invoke();
            10: P.ActKeyed.Invoke();
        end;
    end;

    local procedure Run(var P: TestPage "LT P135 Sel List"; Which: Integer): Text
    var
        Log: Codeunit "LT P135 Sel Log";
    begin
        ClearLastError();
        Log.Take();
        if TryRun(P, Which) then
            exit(Log.Take());
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode() + ' log=' + Log.Take());
    end;

    [Test]
    procedure P135_SelFilter_FreshRecord_AndOtherFieldFilters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P135 Sel List";
    begin
        Seed();
        P.OpenView();
        P.GoToKey(2);
        Observer.Observe('fresh', Run(P, 0));
        Observer.Observe('grp filter containing the row', Run(P, 1));
        Observer.Observe('grp filter excluding the row', Run(P, 2));
        Observer.Observe('name text filter', Run(P, 5));
        Observer.Observe('keyed', Run(P, 10));
        P.Close();
        Observer.Expect('fresh', 'before count=4 filters=[] id=[] grp=[] name=[] g2=[] has=No markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('grp filter containing the row', 'before count=2 filters=[Grp: 1] id=[] grp=[1] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('grp filter excluding the row', 'before count=2 filters=[Grp: 2] id=[] grp=[2] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('name text filter', 'before count=2 filters=[Name: B*] id=[] grp=[] name=[B*] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('keyed', 'before count=4 filters=[] id=[] grp=[] name=[] g2=[] has=No markedonly=No fg=0 key=Grp,Name;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Grp,Name;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_SelFilter_SameFieldFilters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P135 Sel List";
    begin
        Seed();
        P.OpenView();
        P.GoToKey(2);
        Observer.Observe('id range containing the row', Run(P, 3));
        Observer.Observe('id range excluding the row', Run(P, 4));
        P.GoToKey(4);
        Observer.Observe('id range excluding the row, on row 4', Run(P, 3));
        Observer.Observe('id range containing row 4', Run(P, 4));
        P.Close();
        Observer.Expect('id range containing the row', 'before count=3 filters=[Id: 1..3] id=[1..3] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('id range excluding the row', 'before count=2 filters=[Id: 3..4] id=[3..4] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('id range excluding the row, on row 4', 'before count=3 filters=[Id: 1..3] id=[1..3] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 4] id=[4] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('id range containing row 4', 'before count=2 filters=[Id: 3..4] id=[3..4] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;after count=1 filters=[Id: 4] id=[4] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Verify();
    end;

    [Test]
    procedure P135_SelFilter_GroupMarkedPresetTwice()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P135 Sel List";
    begin
        Seed();
        P.OpenView();
        P.GoToKey(2);
        Observer.Observe('filter group 2', Run(P, 6));
        Observer.Observe('marked only', Run(P, 7));
        Observer.Observe('preset content', Run(P, 8));
        Observer.Observe('twice', Run(P, 9));
        P.Close();
        Observer.Expect('filter group 2', 'before count=2 filters=[] id=[] grp=[] name=[] g2=[Grp: 1] has=No markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('marked only', 'before count=1 filters=[Marked: Yes] id=[] grp=[] name=[] g2=[Marked: Yes] has=No markedonly=Yes fg=0 key=Id;after count=1 filters=[Marked: Yes, Id: 2] id=[2] grp=[] name=[] g2=[Marked: Yes] has=Yes markedonly=Yes fg=0 key=Id;');
        Observer.Expect('preset content', 'before count=4 filters=[] id=[] grp=[] name=[] g2=[] has=No markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Expect('twice', 'before count=4 filters=[] id=[] grp=[] name=[] g2=[] has=No markedonly=No fg=0 key=Id;after count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;again count=1 filters=[Id: 2] id=[2] grp=[] name=[] g2=[] has=Yes markedonly=No fg=0 key=Id;');
        Observer.Verify();
    end;
}
