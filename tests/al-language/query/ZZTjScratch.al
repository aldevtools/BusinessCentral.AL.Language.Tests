table 89924, codeunit 89923 "LT TJ Scratch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RowsShared(): Integer
    var
        Q: Query "LT TJ ReadState Shared";
        Count: Integer;
    begin
        Q.Open();
        while Q.Read() do
            Count += 1;
        Q.Close();
        exit(Count);
    end;

    local procedure RowsCommitted(): Integer
    var
        Q: Query "LT TJ ReadState Committed";
        Count: Integer;
    begin
        Q.Open();
        while Q.Read() do
            Count += 1;
        Q.Close();
        exit(Count);
    end;

    local procedure RowsNoLocks(): Integer
    var
        Q: Query "LT TJ ReadState NoLocks";
        Count: Integer;
    begin
        Q.Open();
        while Q.Read() do
            Count += 1;
        Q.Close();
        exit(Count);
    end;

    [Test]
    procedure ReadStateValues_SeeTheSessionsOwnUncommittedRow_AndTheCommittedOne()
    var
        Observer: Codeunit "Probe Observer";
        RsRec: Record "LT TJ RS Table";
    begin
        RsRec.DeleteAll();
        Commit();
        RsRec.Id := 1;
        RsRec.Insert();

        Observer.Observe('shared_uncommitted', Format(RowsShared()));
        Observer.Observe('committed_uncommitted', Format(RowsCommitted()));
        Observer.Observe('nolocks_uncommitted', Format(RowsNoLocks()));
        Commit();
        Observer.Observe('shared_after', Format(RowsShared()));
        Observer.Observe('committed_after', Format(RowsCommitted()));
        Observer.Observe('nolocks_after', Format(RowsNoLocks()));
        Observer.Finish();
    end;
}
