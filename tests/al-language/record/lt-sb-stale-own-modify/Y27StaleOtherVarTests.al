// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y27StaleOtherVarObjects.al; test codeunit 92252
// BC versions: 27+

/// <summary>
/// Writer Y27, AL Runner issue 6522 (follow-up to 5954; the SB, SF, SH, TE, TH and Y2 shapes are in SbStaleOwnModify.al). There the write
/// that makes the buffer stale happens in the transaction of the buffer's own Insert. Here it happens LATER: the test inserts row A through
/// its own variable and commits; the poster codeunit (another variable) lowers Remaining Quantity and commits (N - 1 times); in the new
/// transaction the poster writes row A once more (Remaining Quantity, or Description, or a Delete), or inserts row B, or does nothing; then
/// the test validates Description on its stale copy and calls Modify(true). N is the number of Commits since the Insert (1, 2 or 3).
/// The row's triggers count into the row: OnValidate of Description adds 1 to "Validate Count"; OnModify adds 1 to "Modify Count" and copies
/// xRec."Remaining Quantity" and xRec.Description. 'stored' is Description|Remaining Quantity|Validate Count|Modify Count|xRec Remaining
/// Quantity|xRec Description of the row read back; 'buffer' the same fields of the stale variable after its write.
/// Measured (BC 29 SaaS sandbox and the CI legs): after 1, 2 or 3 Commits, when the new transaction Modified the row through the other
/// variable (another field, the same field, an unchanged Modify, two Modifies) or inserted another row, the stale Modify(true) is ACCEPTED and
/// writes the whole stale copy: the other variable's change is lost (Remaining Quantity 100). OnValidate and OnModify run once; xRec in OnModify
/// holds the buffer's own values. When the other variable Deleted the row, the stale Modify fails with DB:RecordNotFound. When the new
/// transaction did nothing, it fails with DB:RecordChanged, as in SbStaleOwnModify.al.
/// </summary>
codeunit 92252 "LT Y27 Stale Other Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Poster: Codeunit "LT Y27 Stale Row Poster";

    local procedure Y27InsertStale(var Row: Record "LT Y27 Stale Row"; Commits: Integer)
    var
        i: Integer;
    begin
        Y27Cleanup();
        Row.Init();
        Row."No." := 'A';
        Row.Description := 'Original';
        Row."Remaining Quantity" := 100;
        Row.Insert(true);
        Commit();
        for i := 2 to Commits do
            Poster.PostAndCommit('A', 10);
    end;

    local procedure Y27Fields(Row: Record "LT Y27 Stale Row"): Text
    begin
        exit(Row.Description + '|' + Format(Row."Remaining Quantity") + '|' + Format(Row."Validate Count") + '|' +
            Format(Row."Modify Count") + '|' + Format(Row."xRec Remaining Quantity") + '|' + Row."xRec Description");
    end;

    local procedure Y27ObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "LT Y27 Stale Row";
    begin
        if Stored.Get('A') then
            Observer.Observe('stored', Y27Fields(Stored))
        else
            Observer.Observe('stored', 'missing');
        Observer.Observe('rows', Format(Stored.Count()));
    end;

    local procedure Y27StaleWrite(var Row: Record "LT Y27 Stale Row"; var Observer: Codeunit "Probe Observer")
    begin
        Row.Validate(Description, 'Changed');
        Row.Modify(true);
        Observer.Observe('write', 'ok');
        Observer.Observe('buffer', Y27Fields(Row));
        Y27ObserveStored(Observer);
        Y27Cleanup();
    end;

    local procedure Y27StaleWriteError(var Row: Record "LT Y27 Stale Row"; var Observer: Codeunit "Probe Observer")
    begin
        Row.Validate(Description, 'Changed');
        asserterror Row.Modify(true);
        Observer.ObserveError('write');
        Observer.Observe('buffer', Y27Fields(Row));
        Y27ObserveStored(Observer);
        Y27Cleanup();
    end;

    local procedure Y27Cleanup()
    var
        Rows: Record "LT Y27 Stale Row";
    begin
        Rows.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Y27_1C_OtherModifiesQuantity()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 1);
        Poster.Post('A', 5);
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_1C_OtherModifiesDescription()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 1);
        Poster.PostDescription('A', 'Other');
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_1C_OtherDeletes()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 1);
        Poster.DeleteRow('A');
        Y27StaleWriteError(Row, Observer);
        Observer.Expect('write|text', 'The LT Y27 Stale Row does not exist. Identification fields and values: No.=''A''');
        Observer.Expect('write|code', 'DB:RecordNotFound');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Original|100|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherModifiesQuantity()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.Post('A', 5);
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherModifiesDescription()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.PostDescription('A', 'Other');
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherDeletes()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.DeleteRow('A');
        Y27StaleWriteError(Row, Observer);
        Observer.Expect('write|text', 'The LT Y27 Stale Row does not exist. Identification fields and values: No.=''A''');
        Observer.Expect('write|code', 'DB:RecordNotFound');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Original|90|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_3C_OtherModifiesQuantity()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 3);
        Poster.Post('A', 5);
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_3C_OtherModifiesDescription()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 3);
        Poster.PostDescription('A', 'Other');
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_3C_OtherDeletes()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 3);
        Poster.DeleteRow('A');
        Y27StaleWriteError(Row, Observer);
        Observer.Expect('write|text', 'The LT Y27 Stale Row does not exist. Identification fields and values: No.=''A''');
        Observer.Expect('write|code', 'DB:RecordNotFound');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Original|80|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherInsertsAnotherRow()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.InsertAnotherRow('B');
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherUnchangedModify()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.Post('A', 0);
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_Nothing()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Y27StaleWriteError(Row, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27 Stale Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Original|90|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_3C_Nothing()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 3);
        Y27StaleWriteError(Row, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27 Stale Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Original|80|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherModifiesQuantity_ModifyFalse()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.Post('A', 5);
        Row.Description := 'Changed';
        Row.Modify(false);
        Observer.Observe('write', 'ok');
        Observer.Observe('buffer', Y27Fields(Row));
        Y27ObserveStored(Observer);
        Y27Cleanup();
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|0|0|0|');
        Observer.Expect('stored', 'Changed|100|0|0|0|');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27_2C_OtherModifiesQuantityTwice()
    var
        Row: Record "LT Y27 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27InsertStale(Row, 2);
        Poster.Post('A', 5);
        Poster.Post('A', 1);
        Y27StaleWrite(Row, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}
