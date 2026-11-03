// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P133 Row (74032) from P133PageTypedHandlers.al; declares log codeunit 74040 and page 74041
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetSelectionFilter / Page.SetSelectionFilter into a record that already has filters (same field, another field, a filter group, marks, a current key): what filters the record ends with, which rows it finds, whether the old filters survive
// BC versions: 29 (27 and 28 by CI)

codeunit 74040 "LT P133 Sel Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ModeValue: Integer;

    procedure Mode(): Integer
    begin
        exit(ModeValue);
    end;

    procedure SetMode(NewMode: Integer)
    begin
        ModeValue := NewMode;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 74041 "LT P133 Sel List"
{
    PageType = List;
    SourceTable = "LT P133 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActSel)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P133 Row";
                    Log: Codeunit "LT P133 Sel Log";
                    Ids: Text;
                    Group2: Text;
                begin
                    case Log.Mode() of
                        1:
                            Sel.SetRange(Grp, 'G1');
                        2:
                            Sel.SetRange(Id, 3);
                        3:
                            Sel.SetFilter(Id, '1..2');
                        4:
                            Sel.SetRange(Id, 2);
                        5:
                            begin
                                Sel.Get(1);
                                Sel.Mark(true);
                                Sel.Reset();
                            end;
                        6:
                            Sel.SetCurrentKey(Name);
                        7:
                            begin
                                Sel.FilterGroup(2);
                                Sel.SetRange(Grp, 'G2');
                                Sel.FilterGroup(0);
                            end;
                        8:
                            begin
                                Sel.SetRange(Grp, 'G1');
                                Sel.SetFilter(Id, '>1');
                            end;
                        9:
                            Sel.SetRange(Id, 2, 3);
                        10:
                            begin
                                Sel.Get(1);
                                Sel.Mark(true);
                                Sel.MarkedOnly(true);
                            end;
                    end;
                    CurrPage.SetSelectionFilter(Sel);
                    if Sel.FindSet() then
                        repeat
                            Ids += Format(Sel.Id) + ',';
                        until Sel.Next() = 0;
                    Sel.FilterGroup(2);
                    Group2 := Sel.GetFilters();
                    Sel.FilterGroup(0);
                    Log.Add('filters=[' + Sel.GetFilters() + '] group2=[' + Group2 + '] ids=' + Ids + ' count=' + Format(Sel.Count()) + ' markedonly=' + Format(Sel.MarkedOnly()));
                end;
            }
        }
    }
}

codeunit 74042 "LT P133 Selection Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P133 Row";
        Log: Codeunit "LT P133 Sel Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'c-one';
        Row.Grp := 'G1';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'b-two';
        Row.Grp := 'G2';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'a-three';
        Row.Grp := 'G1';
        Row.Insert();
        Log.Take();
    end;

    local procedure SelectRow(Mode: Integer; KeyToSelect: Integer): Text
    var
        Pg: TestPage "LT P133 Sel List";
        Log: Codeunit "LT P133 Sel Log";
    begin
        Log.SetMode(Mode);
        Pg.OpenView();
        Pg.GoToKey(KeyToSelect);
        Pg.ActSel.Invoke();
        Pg.Close();
        Log.SetMode(0);
        exit(Log.Take());
    end;

    [Test]
    procedure P133_SetSelectionFilter_ControlWithoutPriorFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('row 1', SelectRow(0, 1));
        Observer.Observe('row 2', SelectRow(0, 2));
        Observer.Observe('row 3', SelectRow(0, 3));
        Observer.Expect('row 1', 'filters=[Id: 1] group2=[] ids=1, count=1 markedonly=No;');
        Observer.Expect('row 2', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('row 3', 'filters=[Id: 3] group2=[] ids=3, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_SetSelectionFilter_PriorFilterOnOtherField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('grp G1 selecting 1 (inside)', SelectRow(1, 1));
        Observer.Observe('grp G1 selecting 3 (inside)', SelectRow(1, 3));
        Observer.Expect('grp G1 selecting 1 (inside)', 'filters=[Id: 1] group2=[] ids=1, count=1 markedonly=No;');
        Observer.Expect('grp G1 selecting 3 (inside)', 'filters=[Id: 3] group2=[] ids=3, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_SetSelectionFilter_PriorFilterOnSameField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('id 3 selecting 2 (outside)', SelectRow(2, 2));
        Observer.Observe('id 1..2 selecting 2 (inside)', SelectRow(3, 2));
        Observer.Observe('id 2 selecting 2 (same)', SelectRow(4, 2));
        Observer.Observe('id 2..3 selecting 1 (outside)', SelectRow(9, 1));
        Observer.Expect('id 3 selecting 2 (outside)', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('id 1..2 selecting 2 (inside)', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('id 2 selecting 2 (same)', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('id 2..3 selecting 1 (outside)', 'filters=[Id: 1] group2=[] ids=1, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_SetSelectionFilter_PriorFiltersOnTwoFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('grp G1 and id >1 selecting 3', SelectRow(8, 3));
        Observer.Observe('grp G1 and id >1 selecting 1', SelectRow(8, 1));
        Observer.Expect('grp G1 and id >1 selecting 3', 'filters=[Id: 3] group2=[] ids=3, count=1 markedonly=No;');
        Observer.Expect('grp G1 and id >1 selecting 1', 'filters=[Id: 1] group2=[] ids=1, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_SetSelectionFilter_PriorFilterInFilterGroup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('group 2 grp G2 selecting 2', SelectRow(7, 2));
        Observer.Observe('group 2 grp G2 selecting 1', SelectRow(7, 1));
        Observer.Expect('group 2 grp G2 selecting 2', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('group 2 grp G2 selecting 1', 'filters=[Id: 1] group2=[] ids=1, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_SetSelectionFilter_PriorMarksAndKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('mark on row 1 then reset, selecting 2', SelectRow(5, 2));
        Observer.Observe('marked only row 1, selecting 2', SelectRow(10, 2));
        Observer.Observe('current key Name, selecting 3', SelectRow(6, 3));
        Observer.Expect('mark on row 1 then reset, selecting 2', 'filters=[Id: 2] group2=[] ids=2, count=1 markedonly=No;');
        Observer.Expect('marked only row 1, selecting 2', 'filters=[Marked: Yes, Id: 2] group2=[Marked: Yes] ids=2, count=1 markedonly=Yes;');
        Observer.Expect('current key Name, selecting 3', 'filters=[Id: 3] group2=[] ids=3, count=1 markedonly=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_PageVariable_SetSelectionFilter_IntoFilteredRecord()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT P133 Sel List";
        Sel: Record "LT P133 Row";
    begin
        Seed();
        Sel.SetRange(Grp, 'G1');
        Pg.SetSelectionFilter(Sel);
        Observer.Observe('page not run: filters', Sel.GetFilters());
        Observer.Observe('page not run: count', Format(Sel.Count()));
        Clear(Sel);
        Pg.SetSelectionFilter(Sel);
        Observer.Observe('page not run, unfiltered: filters', Sel.GetFilters());
        Observer.Observe('page not run, unfiltered: count', Format(Sel.Count()));
        Observer.Expect('page not run: filters', 'Id: 0');
        Observer.Expect('page not run: count', '0');
        Observer.Expect('page not run, unfiltered: filters', 'Id: 0');
        Observer.Expect('page not run, unfiltered: count', '0');
        Observer.Verify();
    end;
}
