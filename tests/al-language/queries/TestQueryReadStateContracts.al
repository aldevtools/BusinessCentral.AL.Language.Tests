// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-readstate-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68952, query 68953, codeunit 68954
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins a query with ReadState = ReadUncommitted (the only value the app's runtime version 16.0 offers besides the
// default: ReadCommitted needs runtime 18.0, RepeatableRead and UpdLock are no values of the property): it returns
// a row the same session wrote and has not committed, and the same row after a Commit.
// Fixtures used (added): Probe Observer (69160); queries 89920-89921 (ReadCommitted needs runtime 18.0: BC29PLUS only; ReadShared compiles on 27.5, 28.5 and 29.0)
// BC versions: 27.5

table 68952 "Probe ReadState Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 68953 "Probe ReadState Query"
{
    QueryType = Normal;
    ReadState = ReadUncommitted;

    elements
    {
        dataitem(T; "Probe ReadState Table")
        {
            column(Id; Id) { }
        }
    }
}

query 89920 "LT TJ ReadState Shared"
{
    QueryType = Normal;
    ReadState = ReadShared;

    elements
    {
        dataitem(T; "Probe ReadState Table")
        {
            column(Id; Id) { }
        }
    }
}

#if BC29PLUS
query 89921 "LT TJ ReadState Committed"
{
    QueryType = Normal;
    ReadState = ReadCommitted;

    elements
    {
        dataitem(T; "Probe ReadState Table")
        {
            column(Id; Id) { }
        }
    }
}
#endif


codeunit 68954 "Probe Query ReadState"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Rows(var RsQuery: Query "Probe ReadState Query"): Integer
    var
        Count: Integer;
    begin
        RsQuery.Open();
        while RsQuery.Read() do
            Count += 1;
        RsQuery.Close();
        exit(Count);
    end;

    [Test]
    procedure ReadUncommitted_ReadsTheSessionsOwnUncommittedRow_AndTheCommittedOne()
    var
        RsRec: Record "Probe ReadState Table";
        RsQuery: Query "Probe ReadState Query";
    begin
        RsRec.DeleteAll();
        Commit();
        RsRec.Id := 1;
        RsRec.Insert();

        Assert.AreEqual(1, Rows(RsQuery), 'before Commit');
        Commit();
        Assert.AreEqual(1, Rows(RsQuery), 'after Commit');
    end;

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

#if BC29PLUS
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
#endif

    [Test]
    procedure ReadStateValues_SeeTheSessionsOwnUncommittedRow_AndTheCommittedOne()
    var
        Observer: Codeunit "Probe Observer";
        RsRec: Record "Probe ReadState Table";
    begin
        RsRec.DeleteAll();
        Commit();
        RsRec.Id := 1;
        RsRec.Insert();

        Observer.Observe('shared_uncommitted', Format(RowsShared()));
#if BC29PLUS
        Observer.Observe('committed_uncommitted', Format(RowsCommitted()));
#endif
        Commit();
        Observer.Observe('shared_after', Format(RowsShared()));
#if BC29PLUS
        Observer.Observe('committed_after', Format(RowsCommitted()));
#endif
        Observer.Expect('shared_uncommitted', '1');
#if BC29PLUS
        Observer.Expect('committed_uncommitted', '1');
#endif
        Observer.Expect('shared_after', '1');
#if BC29PLUS
        Observer.Expect('committed_after', '1');
#endif
        Observer.Verify();
    end;
}
