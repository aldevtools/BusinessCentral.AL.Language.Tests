// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 76606 and 76607
// Probe: the SystemRowVersion a re-read of a row gives after the open transaction inserted the row and something later sent it to the
// database, for the shapes next to the one RowVersionWrites.al pins (a Get re-read after a Get of another table). Each test inserts row 1
// of "RVR Row" into an emptied, committed table and keeps Before := the SystemRowVersion of the Insert buffer. Then one send step
// (another table's Insert and Modify as in AL Runner issue 8993, the same with only an Insert or with a Commit after it, a Commit alone,
// a Modify of another committed row of the same table, or nothing), then one re-read (Get, FindFirst, FindSet, Find('-'), Next,
// RecordRef.Open + FindFirst + Field(0).Value as in the issue, Get then RecordRef.GetTable + Field(0).Value, an assignment copy and a Copy
// of a Get buffer). Only one re-read per test: a read of the table sends a pending Insert itself. The OwnBuffer tests read the record's
// own buffer after its Insert and Modify, and copies of an Insert buffer, with no re-read.
// Only relations are asserted (same, greater, less): row version numbers differ per database.
// Observation names: before/0 is Before against 0, read/0 and read/before the re-read (or buffer) value against 0 and against Before.
// BC versions: 27+

table 76606 "RVR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 76607 "RVR Other Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// local object: the shared steps of the re-read tests.
codeunit 76608 "RVR Steps"
{
    procedure Rel(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value = Other then
            exit('same');
        if Value > Other then
            exit('greater');
        exit('less');
    end;

    procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Before: BigInteger; Value: BigInteger)
    begin
        Observer.Observe('before/0', Rel(Before, 0));
        Observer.Observe('read/0', Rel(Value, 0));
        Observer.Observe('read/before', Rel(Value, Before));
    end;

    procedure Clean()
    var
        Row: Record "RVR Row";
        Other: Record "RVR Other Row";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Commit();
    end;

    procedure Run(var Observer: Codeunit "Probe Observer"; Send: Text; Read: Text)
    var
        Row: Record "RVR Row";
        First: Record "RVR Row";
        Row2: Record "RVR Row";
        Other: Record "RVR Other Row";
        Before: BigInteger;
    begin
        Clean();
        if Read = 'next' then begin
            First.Id := 0;
            First.Insert();
        end;
        if Send = 'same' then begin
            Row2.Id := 2;
            Row2.Insert();
        end;
        Commit();
        if Send = 'same' then
            Row2.Get(2);
        Row.Id := 1;
        Row.Insert();
        Before := Row.SystemRowVersion;
        case Send of
            'other', 'othercommit':
                begin
                    Other.Id := 1;
                    Other.Insert();
                    Other.Name := 'changed';
                    Other.Modify();
                    if Send = 'othercommit' then
                        Commit();
                end;
            'otherinsert':
                begin
                    Other.Id := 1;
                    Other.Insert();
                end;
            'commit':
                Commit();
            'same':
                begin
                    Row2.Name := 'changed';
                    Row2.Modify();
                end;
        end;
        ObserveAll(Observer, Before, ReRead(Read));
        Clean();
    end;

    local procedure ReRead(Read: Text): BigInteger
    var
        Rd: Record "RVR Row";
        Rd2: Record "RVR Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        case Read of
            'get':
                Rd.Get(1);
            'findfirst':
                Rd.FindFirst();
            'findset':
                Rd.FindSet();
            'findminus':
                Rd.Find('-');
            'next':
                begin
                    Rd.FindSet();
                    Rd.Next();
                end;
            'recref':
                begin
                    RecRef.Open(Database::"RVR Row");
                    RecRef.FindFirst();
                    FldRef := RecRef.Field(0);
                    exit(FldRef.Value());
                end;
            'getrecref':
                begin
                    Rd.Get(1);
                    RecRef.GetTable(Rd);
                    FldRef := RecRef.Field(0);
                    exit(FldRef.Value());
                end;
            'assign':
                begin
                    Rd.Get(1);
                    Rd2 := Rd;
                    exit(Rd2.SystemRowVersion);
                end;
            'copy':
                begin
                    Rd.Get(1);
                    Rd2.Copy(Rd);
                    exit(Rd2.SystemRowVersion);
                end;
        end;
        exit(Rd.SystemRowVersion);
    end;

    procedure Own(var Observer: Codeunit "Probe Observer"; Shape: Text)
    var
        Row: Record "RVR Row";
        Row2: Record "RVR Row";
        Before: BigInteger;
        Value: BigInteger;
    begin
        Clean();
        Row.Id := 1;
        Row.Insert();
        Before := Row.SystemRowVersion;
        case Shape of
            'insert':
                Value := Row.SystemRowVersion;
            'assign':
                begin
                    Row2 := Row;
                    Value := Row2.SystemRowVersion;
                end;
            'copy':
                begin
                    Row2.Copy(Row);
                    Value := Row2.SystemRowVersion;
                end;
            'modify':
                begin
                    Row.Name := 'changed';
                    Row.Modify();
                    Value := Row.SystemRowVersion;
                end;
            'commitmodify':
                begin
                    Commit();
                    Row.Name := 'changed';
                    Row.Modify();
                    Value := Row.SystemRowVersion;
                end;
        end;
        ObserveAll(Observer, Before, Value);
        Clean();
    end;
}

codeunit 76609 "RVR ReRead Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReRead_OtherInsertModify_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_FindSet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'findset');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_FindMinus()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'findminus');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_Next()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'next');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_GetThenRecRef()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'getrecref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_AssignOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModify_CopyOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'other', 'copy');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_FindSet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'findset');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_FindMinus()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'findminus');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_Next()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'next');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_GetThenRecRef()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'getrecref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_AssignOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_Commit_CopyOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'commit', 'copy');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_FindSet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'findset');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_FindMinus()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'findminus');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_Next()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'next');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_GetThenRecRef()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'getrecref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_AssignOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_SameTableModify_CopyOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'same', 'copy');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_FindSet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'findset');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_FindMinus()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'findminus');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_Next()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'next');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_GetThenRecRef()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'getrecref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_AssignOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_NoSend_CopyOfGet()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'none', 'copy');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertOnly_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'otherinsert', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertOnly_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'otherinsert', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertOnly_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'otherinsert', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModifyCommit_Get()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'othercommit', 'get');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModifyCommit_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'othercommit', 'findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure ReRead_OtherInsertModifyCommit_RecRefFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Run(Observer, 'othercommit', 'recref');
        Observer.Finish();
    end;

    [Test]
    procedure OwnBuffer_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Own(Observer, 'insert');
        Observer.Finish();
    end;

    [Test]
    procedure OwnBuffer_AssignOfInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Own(Observer, 'assign');
        Observer.Finish();
    end;

    [Test]
    procedure OwnBuffer_CopyOfInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Own(Observer, 'copy');
        Observer.Finish();
    end;

    [Test]
    procedure OwnBuffer_ModifyUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Own(Observer, 'modify');
        Observer.Finish();
    end;

    [Test]
    procedure OwnBuffer_ModifyAfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVR Steps";
    begin
        Steps.Own(Observer, 'commitmodify');
        Observer.Finish();
    end;
}
