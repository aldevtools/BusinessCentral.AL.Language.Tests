table 89924 "LT TJ RS Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 89920 "LT TJ ReadState Shared"
{
    QueryType = Normal;
    ReadState = ReadShared;

    elements
    {
        dataitem(T; "LT TJ RS Table")
        {
            column(Id; Id) { }
        }
    }
}

query 89921 "LT TJ ReadState Committed"
{
    QueryType = Normal;
    ReadState = ReadCommitted;

    elements
    {
        dataitem(T; "LT TJ RS Table")
        {
            column(Id; Id) { }
        }
    }
}


codeunit 89923 "LT TJ Scratch"
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
        Commit();
        Observer.Observe('shared_after', Format(RowsShared()));
        Observer.Observe('committed_after', Format(RowsCommitted()));
        Observer.Finish();
    end;
}
