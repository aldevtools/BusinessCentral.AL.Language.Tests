// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

codeunit 90577 "LT WB External Reapply Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FirstAfterExternalRefreshReappliesMarks()
    var
        Row: Record "LT WB External Reapply Row";
        ExternalRefresh: Codeunit "LT WB External Refresh";
        ReapplyPage: TestPage "LT WB External Reapply List";
        Observed: Text;
    begin
        SeedRows();
        ReapplyPage.OpenView();
        ReapplyPage.FlaggedTile.Drilldown();
        Row.Get(2);
        Observed := 'before=' + Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value();

        ExternalRefresh.InvokeRefresh();
        ReapplyPage.First();

        Observed += ' after=' + Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value();
        ReapplyPage.Close();
        Assert.AreEqual('before=true/2 after=false/1', Observed, 'External refresh re-applies the marked view from OnAfterGetCurrRecord.');
    end;

    local procedure SeedRows()
    begin
        DeleteRows();
        AddRow(1, true);
        AddRow(2, true);
        AddRow(3, false);
    end;

    local procedure DeleteRows()
    var
        Row: Record "LT WB External Reapply Row";
        Detail: Record "LT WB External Reapply Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
    end;

    local procedure AddRow(Id: Integer; Flag: Boolean)
    var
        Row: Record "LT WB External Reapply Row";
        Detail: Record "LT WB External Reapply Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Flag := Flag;
        Row.Insert();
        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;
}

