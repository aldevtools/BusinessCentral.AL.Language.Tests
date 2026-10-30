// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

codeunit 90586 "LT WB Clear Marked Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure NameKeyWithPartClearRestoresUnmarkedRow()
    var
        Row: Record "LT WB Clear Filter Row";
        Page: TestPage "LT WB Clear Filter Name Part";
        Observed: Text;
    begin
        SeedRows();
        Row.Get(2);

        Page.OpenView();
        Page.Flagged.Drilldown();
        Observed := 'filtered=' + Format(Page.GoToRecord(Row), 0, 9) + '/' + Page.Id.Value();
        Page.ClearFilters.Invoke();
        Observed += ' cleared=' + Format(Page.GoToRecord(Row), 0, 9) + '/' + Page.Id.Value();
        Page.Close();
        Assert.AreEqual('filtered=false/1 cleared=true/2', Observed, 'A clear action after a marked DrillDown.');
    end;

    local procedure SeedRows()
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
        AddRow(1, 'N4', true);
        AddRow(2, 'N3', false);
        AddRow(3, 'N2', true);
        AddRow(4, 'N1', false);
    end;

    local procedure AddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Flag := Flag;
        Row.Insert();

        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;
}

codeunit 90587 "LT WB Clear Primary Ctrl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure PrimaryKeyWithPartClearRestoresUnmarkedRow()
    var
        Row: Record "LT WB Clear Filter Row";
        Page: TestPage "LT WB Clear Filter Id Part";
    begin
        SeedRows();
        Row.Get(4);

        Page.OpenView();
        Page.Flagged.Drilldown();
        Assert.IsFalse(Page.GoToRecord(Row), 'Unmarked row after DrillDown');
        Page.ClearFilters.Invoke();
        Assert.IsTrue(Page.GoToRecord(Row), 'Unmarked row after Clear Filters');
        Page.Close();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
        AddRow(1, 'N4', true);
        AddRow(2, 'N3', false);
        AddRow(3, 'N2', true);
        AddRow(4, 'N1', false);
    end;

    local procedure AddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Flag := Flag;
        Row.Insert();

        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;
}

codeunit 90588 "LT WB Clear NoTrigger Ctrls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure NameKeyWithPartWithoutRowTriggersRestoresUnmarkedRow()
    var
        Row: Record "LT WB Clear Filter Row";
        Page: TestPage "LT WB Clear Filter No Triggers";
    begin
        SeedRows();
        Row.Get(2);

        Page.OpenView();
        Page.Flagged.Drilldown();
        Assert.IsFalse(Page.GoToRecord(Row), 'Unmarked row after DrillDown');
        Page.ClearFilters.Invoke();
        Assert.IsTrue(Page.GoToRecord(Row), 'Unmarked row after Clear Filters');
        Page.Close();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
        AddRow(1, 'N4', true);
        AddRow(2, 'N3', false);
        AddRow(3, 'N2', true);
        AddRow(4, 'N1', false);
    end;

    local procedure AddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Row: Record "LT WB Clear Filter Row";
        Detail: Record "LT WB Clear Filter Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Flag := Flag;
        Row.Insert();

        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;
}
