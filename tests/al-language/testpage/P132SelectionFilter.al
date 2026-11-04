// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73716, log 73718 (used only by test codeunit 73719), page 73717
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73716 "LT P132 Sel Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Qty; Integer) { }
        field(3; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73718 "LT P132 Sel Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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

page 73717 "LT P132 Sel List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P132 Sel Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActPlain)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('plain', Sel);
                end;
            }
            action(ActOtherField)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.SetFilter(Qty, '>=2');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('otherfield', Sel);
                end;
            }
            action(ActOtherFieldMiss)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.SetFilter(Qty, '>=100');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('otherfieldmiss', Sel);
                end;
            }
            action(ActKeyField)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.SetFilter(Id, 'B|C');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('keyfield', Sel);
                end;
            }
            action(ActRange)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.SetRange(Name, 'Beta');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('range', Sel);
                end;
            }
            action(ActGroup2)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                    Log: Codeunit "LT P132 Sel Log";
                begin
                    Sel.FilterGroup(2);
                    Sel.SetFilter(Qty, '>=2');
                    Sel.FilterGroup(0);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('group2', Sel);
                    Sel.FilterGroup(2);
                    Log.Add('group2.inGroup2=' + Sel.GetFilters());
                    Sel.FilterGroup(0);
                end;
            }
            action(ActPositioned)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.Get('D');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('positioned', Sel);
                end;
            }
            action(ActTwice)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('twice1', Sel);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('twice2', Sel);
                end;
            }
            action(ActSameKeyFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P132 Sel Row";
                begin
                    Sel.SetFilter(Id, 'A..Z');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('samekey', Sel);
                end;
            }
        }
    }

    local procedure LogSel(Tag: Text; var Sel: Record "LT P132 Sel Row")
    var
        Log: Codeunit "LT P132 Sel Log";
        Ids: Text;
        Probe: Record "LT P132 Sel Row";
    begin
        Probe.Copy(Sel);
        if Probe.FindSet() then
            repeat
                Ids += Probe.Id;
            until Probe.Next() = 0;
        Log.Add(Tag + '.ids=' + Ids + ' filters=' + Sel.GetFilters() + ' idfilter=' + Sel.GetFilter(Id) + ' qtyfilter=' + Sel.GetFilter(Qty) + ' namefilter=' + Sel.GetFilter(Name));
    end;
}

codeunit 73719 "LT P132 Selection Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P132 Sel Row";
        Log: Codeunit "LT P132 Sel Log";
    begin
        R.DeleteAll();
        R.Id := 'A';
        R.Qty := 1;
        R.Name := 'Alpha';
        R.Insert();
        R.Id := 'B';
        R.Qty := 2;
        R.Name := 'Beta';
        R.Insert();
        R.Id := 'C';
        R.Qty := 3;
        R.Name := 'Gamma';
        R.Insert();
        R.Id := 'D';
        R.Qty := 4;
        R.Name := 'Delta';
        R.Insert();
        Log.Take();
    end;

    [Test]
    procedure P132_Selection_PlainControl()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P132 Sel Log";
        List: TestPage "LT P132 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('B');
        List.ActPlain.Invoke();
        Observer.Observe('log', Log.Take());
        List.Close();
        Observer.Expect('log', 'plain.ids=B filters=Id: B idfilter=B qtyfilter= namefilter=;');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Selection_OtherFieldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P132 Sel Log";
        List: TestPage "LT P132 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('B');
        List.ActOtherField.Invoke();
        Observer.Observe('selected_B_filter_qty_ge_2', Log.Take());
        List.GoToKey('A');
        List.ActOtherField.Invoke();
        Observer.Observe('selected_A_filter_qty_ge_2', Log.Take());
        List.GoToKey('B');
        List.ActOtherFieldMiss.Invoke();
        Observer.Observe('selected_B_filter_qty_ge_100', Log.Take());
        List.Close();
        Observer.Expect('selected_B_filter_qty_ge_2', 'otherfield.ids=B filters=Id: B idfilter=B qtyfilter= namefilter=;');
        Observer.Expect('selected_A_filter_qty_ge_2', 'otherfield.ids=A filters=Id: A idfilter=A qtyfilter= namefilter=;');
        Observer.Expect('selected_B_filter_qty_ge_100', 'otherfieldmiss.ids=B filters=Id: B idfilter=B qtyfilter= namefilter=;');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Selection_KeyFieldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P132 Sel Log";
        List: TestPage "LT P132 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('A');
        List.ActKeyField.Invoke();
        Observer.Observe('selected_A_filter_id_B_or_C', Log.Take());
        List.GoToKey('C');
        List.ActKeyField.Invoke();
        Observer.Observe('selected_C_filter_id_B_or_C', Log.Take());
        List.GoToKey('C');
        List.ActSameKeyFilter.Invoke();
        Observer.Observe('selected_C_filter_id_A_to_Z', Log.Take());
        List.Close();
        Observer.Expect('selected_A_filter_id_B_or_C', 'keyfield.ids=A filters=Id: A idfilter=A qtyfilter= namefilter=;');
        Observer.Expect('selected_C_filter_id_B_or_C', 'keyfield.ids=C filters=Id: C idfilter=C qtyfilter= namefilter=;');
        Observer.Expect('selected_C_filter_id_A_to_Z', 'samekey.ids=C filters=Id: C idfilter=C qtyfilter= namefilter=;');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Selection_RangeAndGroupFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P132 Sel Log";
        List: TestPage "LT P132 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('A');
        List.ActRange.Invoke();
        Observer.Observe('selected_A_range_name_Beta', Log.Take());
        List.GoToKey('B');
        List.ActRange.Invoke();
        Observer.Observe('selected_B_range_name_Beta', Log.Take());
        List.GoToKey('C');
        List.ActGroup2.Invoke();
        Observer.Observe('selected_C_group2_qty_ge_2', Log.Take());
        List.Close();
        Observer.Expect('selected_A_range_name_Beta', 'range.ids=A filters=Id: A idfilter=A qtyfilter= namefilter=;');
        Observer.Expect('selected_B_range_name_Beta', 'range.ids=B filters=Id: B idfilter=B qtyfilter= namefilter=;');
        Observer.Expect('selected_C_group2_qty_ge_2', 'group2.ids=C filters=Id: C idfilter=C qtyfilter= namefilter=;group2.inGroup2=;');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Selection_PositionedAndRepeated()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P132 Sel Log";
        List: TestPage "LT P132 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('B');
        List.ActPositioned.Invoke();
        Observer.Observe('selected_B_positioned_D', Log.Take());
        List.GoToKey('C');
        List.ActTwice.Invoke();
        Observer.Observe('selected_C_twice', Log.Take());
        List.Close();
        Observer.Expect('selected_B_positioned_D', 'positioned.ids=B filters=Id: B idfilter=B qtyfilter= namefilter=;');
        Observer.Expect('selected_C_twice', 'twice1.ids=C filters=Id: C idfilter=C qtyfilter= namefilter=;twice2.ids=C filters=Id: C idfilter=C qtyfilter= namefilter=;');
        Observer.Verify();
    end;
}
