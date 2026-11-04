// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 70113/70114
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: System fields: Temporary records are NOT stamped; rows re-keyed by a rename of another table get the modified pair stamped; the stamp is made strictly later than the previous one; Modify stamps when a stored field differs (Blob by content)
// Facts: SystemId/SystemCreatedAt/SystemModifiedAt (and the By fields) of temporary records, of Modify with and without changes (Blob by content), of two writes in a row, of rows re-keyed by a rename
// BC versions: 29 (27 and 28 by CI)

table 70113 "LT PnA SF P"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Val; Integer) { }
        field(3; Data; Blob) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 70114 "LT PnA SF C"
{
    fields
    {
        field(1; Entry; Integer) { }
        field(2; PRef; Code[10]) { TableRelation = "LT PnA SF P".Code; }
    }
    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

codeunit 70115 "LT PnA SF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetBlob(var P: Record "LT PnA SF P"; Txt: Text)
    var
        OutS: OutStream;
    begin
        P.Data.CreateOutStream(OutS);
        OutS.WriteText(Txt);
    end;

    [Test]
    procedure TemporaryRecord_IsNotStamped()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnA SF P" temporary;
    begin
        T.Code := 'A';
        T.Insert();
        Observer.Observe('insert-systemid-null', Format(IsNullGuid(T.SystemId)));
        Observer.Observe('insert-createdat-empty', Format(T.SystemCreatedAt = 0DT));
        Observer.Observe('insert-createdby-null', Format(IsNullGuid(T.SystemCreatedBy)));
        Observer.Observe('insert-modifiedat-empty', Format(T.SystemModifiedAt = 0DT));
        Observer.Observe('insert-modifiedby-null', Format(IsNullGuid(T.SystemModifiedBy)));
        T.Val := 1;
        T.Modify();
        Observer.Observe('modify-systemid-null', Format(IsNullGuid(T.SystemId)));
        Observer.Observe('modify-modifiedat-empty', Format(T.SystemModifiedAt = 0DT));
        T.Get('A');
        Observer.Observe('get-systemid-null', Format(IsNullGuid(T.SystemId)));
        Observer.Observe('get-createdat-empty', Format(T.SystemCreatedAt = 0DT));
        Observer.Observe('get-modifiedat-empty', Format(T.SystemModifiedAt = 0DT));
        Observer.Expect('insert-systemid-null', 'Yes');
        Observer.Expect('insert-createdat-empty', 'Yes');
        Observer.Expect('insert-createdby-null', 'Yes');
        Observer.Expect('insert-modifiedat-empty', 'Yes');
        Observer.Expect('insert-modifiedby-null', 'Yes');
        Observer.Expect('modify-systemid-null', 'Yes');
        Observer.Expect('modify-modifiedat-empty', 'Yes');
        Observer.Expect('get-systemid-null', 'Yes');
        Observer.Expect('get-createdat-empty', 'Yes');
        Observer.Expect('get-modifiedat-empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRecord_IsStamped_Reference()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT PnA SF P";
    begin
        P.DeleteAll();
        P.Code := 'A';
        P.Insert();
        P.Get('A');
        Observer.Observe('systemid-set', Format(not IsNullGuid(P.SystemId)));
        Observer.Observe('createdat-set', Format(P.SystemCreatedAt <> 0DT));
        Observer.Observe('modifiedat-set', Format(P.SystemModifiedAt <> 0DT));
        Observer.Observe('createdat-equals-modifiedat-after-insert', Format(P.SystemCreatedAt = P.SystemModifiedAt));
        Observer.Observe('createdby-set', Format(not IsNullGuid(P.SystemCreatedBy)));
        Observer.Observe('modifiedby-set', Format(not IsNullGuid(P.SystemModifiedBy)));
        P.DeleteAll();
        Observer.Expect('systemid-set', 'Yes');
        Observer.Expect('createdat-set', 'Yes');
        Observer.Expect('modifiedat-set', 'Yes');
        Observer.Expect('createdat-equals-modifiedat-after-insert', 'Yes');
        Observer.Expect('createdby-set', 'Yes');
        Observer.Expect('modifiedby-set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_StampsOnlyWhenStoredFieldDiffers()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT PnA SF P";
        At1: DateTime;
        Created1: DateTime;
        Id1: Guid;
    begin
        P.DeleteAll();
        P.Code := 'A';
        P.Val := 1;
        SetBlob(P, 'abc');
        P.Insert();
        P.Get('A');
        At1 := P.SystemModifiedAt;
        Created1 := P.SystemCreatedAt;
        Id1 := P.SystemId;
        Sleep(30);

        P.Modify();
        P.Get('A');
        Observer.Observe('unchanged-modify-keeps-stamp', Format(P.SystemModifiedAt = At1));

        P.Val := 2;
        P.Modify();
        P.Get('A');
        Observer.Observe('changed-int-restamps', Format(P.SystemModifiedAt > At1));
        Observer.Observe('changed-int-createdat-same', Format(P.SystemCreatedAt = Created1));
        Observer.Observe('changed-int-systemid-same', Format(P.SystemId = Id1));
        At1 := P.SystemModifiedAt;
        Sleep(30);

        P.Get('A');
        P.Val := 2;
        P.Modify();
        P.Get('A');
        Observer.Observe('same-value-assigned-keeps-stamp', Format(P.SystemModifiedAt = At1));

        P.CalcFields(Data);
        SetBlob(P, 'abc');
        P.Modify();
        P.Get('A');
        Observer.Observe('same-blob-content-keeps-stamp', Format(P.SystemModifiedAt = At1));

        P.CalcFields(Data);
        SetBlob(P, 'abd');
        P.Modify();
        P.Get('A');
        Observer.Observe('other-blob-content-restamps', Format(P.SystemModifiedAt > At1));
        P.DeleteAll();
        Observer.Expect('unchanged-modify-keeps-stamp', 'Yes');
        Observer.Expect('changed-int-restamps', 'Yes');
        Observer.Expect('changed-int-createdat-same', 'Yes');
        Observer.Expect('changed-int-systemid-same', 'Yes');
        Observer.Expect('same-value-assigned-keeps-stamp', 'Yes');
        Observer.Expect('same-blob-content-keeps-stamp', 'No');
        Observer.Expect('other-blob-content-restamps', 'Yes');
        Observer.Verify();
    end;


    [Test]
    procedure RenameOfAnotherTable_ReStampsPropagatedRows()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT PnA SF P";
        C: Record "LT PnA SF C";
        PAt: DateTime;
        CAt: DateTime;
        CCreated: DateTime;
        PId: Guid;
    begin
        P.DeleteAll();
        C.DeleteAll();
        P.Code := 'A';
        P.Insert();
        C.Entry := 1;
        C.PRef := 'A';
        C.Insert();
        C.Entry := 2;
        C.PRef := 'Z';
        C.Insert();
        P.Get('A');
        PAt := P.SystemModifiedAt;
        PId := P.SystemId;
        C.Get(1);
        CAt := C.SystemModifiedAt;
        CCreated := C.SystemCreatedAt;
        Sleep(30);
        P.Rename('B');
        P.Get('B');
        Observer.Observe('renamed-row-systemid-same', Format(P.SystemId = PId));
        Observer.Observe('renamed-row-restamped', Format(P.SystemModifiedAt > PAt));
        C.Get(1);
        Observer.Observe('child-propagated', C.PRef);
        Observer.Observe('child-restamped', Format(C.SystemModifiedAt > CAt));
        Observer.Observe('child-createdat-same', Format(C.SystemCreatedAt = CCreated));
        C.Get(2);
        Observer.Observe('unrelated-child-untouched', C.PRef);
        Observer.Observe('unrelated-child-stamp-untouched', Format(C.SystemModifiedAt = C.SystemCreatedAt));
        P.DeleteAll();
        C.DeleteAll();
        Observer.Expect('renamed-row-systemid-same', 'Yes');
        Observer.Expect('renamed-row-restamped', 'Yes');
        Observer.Expect('child-propagated', 'B');
        Observer.Expect('child-restamped', 'Yes');
        Observer.Expect('child-createdat-same', 'Yes');
        Observer.Expect('unrelated-child-untouched', 'Z');
        Observer.Expect('unrelated-child-stamp-untouched', 'Yes');
        Observer.Verify();
    end;
}
