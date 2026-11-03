// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqltimestamp-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 87270, test codeunit 87271 (writer QR)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a TEMPORARY record of a table with a BigInteger field that has SQLTimestamp = true: the field and SystemRowVersion after Init,
//   Insert, Modify, Get, Rename, an assignment to the field, a copy of a database row (Copy and TransferFields), ModifyAll and a filter on
//   the field; Format of both. Values that are not a fixed number are written as zero, positive or negative, or as a relation to the
//   database row (same, other).
//   BC (27.5, 28.5, 29.0 alike): a temporary record never stamps: the field and SystemRowVersion stay 0 through Insert, Modify, Rename and
//   Get (Format gives 0), a value assigned to the field is kept by Insert, Modify, ModifyAll and filters, and a copy of a database row keeps
//   that row's values (equal to its SystemRowVersion) through Insert, Modify and Get.
// BC versions: 27, 28, 29

table 87270 "LT QR Stamp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
        field(3; Stamp; BigInteger) { SQLTimestamp = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 87271 "LT QR Temp Timestamp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Sign(Value: BigInteger): Text
    begin
        if Value = 0 then
            exit('zero');
        if Value > 0 then
            exit('positive');
        exit('negative');
    end;

    local procedure State(var Row: Record "LT QR Stamp Row"): Text
    begin
        exit('stamp ' + Sign(Row.Stamp) + ', rowversion ' + Sign(Row.SystemRowVersion));
    end;

    [Test]
    procedure QR_Temp_InsertModifyGet()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Stamp Row" temporary;
    begin
        Temp.Init();
        Temp.Id := 1;
        Temp.Note := 'a';
        Observer.Observe('after init', State(Temp));
        Temp.Insert();
        Observer.Observe('after insert', State(Temp));
        Observer.Observe('format stamp', Format(Temp.Stamp));
        Observer.Observe('format rowversion', Format(Temp.SystemRowVersion));
        Temp.Note := 'b';
        Temp.Modify();
        Observer.Observe('after modify', State(Temp));
        Temp.Init();
        Temp.Id := 2;
        Temp.Insert(true);
        Observer.Observe('after insert(true)', State(Temp));
        Temp.Get(1);
        Observer.Observe('after get', State(Temp));
        Observer.Observe('get format stamp', Format(Temp.Stamp, 0, 9));
        Temp.Rename(3);
        Observer.Observe('after rename', State(Temp));
        Temp.Get(3);
        Observer.Observe('get renamed', State(Temp) + ' note ' + Temp.Note);
        Observer.Expect('after init', 'stamp zero, rowversion zero');
        Observer.Expect('after insert', 'stamp zero, rowversion zero');
        Observer.Expect('format stamp', '0');
        Observer.Expect('format rowversion', '0');
        Observer.Expect('after modify', 'stamp zero, rowversion zero');
        Observer.Expect('after insert(true)', 'stamp zero, rowversion zero');
        Observer.Expect('after get', 'stamp zero, rowversion zero');
        Observer.Expect('get format stamp', '0');
        Observer.Expect('after rename', 'stamp zero, rowversion zero');
        Observer.Expect('get renamed', 'stamp zero, rowversion zero note b');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temp_AssignStamp()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Stamp Row" temporary;
    begin
        Temp.Init();
        Temp.Id := 1;
        Temp.Stamp := 5;
        Observer.Observe('assigned', Format(Temp.Stamp));
        Temp.Insert();
        Observer.Observe('after insert', Format(Temp.Stamp));
        Temp.Get(1);
        Observer.Observe('after get', Format(Temp.Stamp));
        Temp.Stamp := 7;
        Temp.Modify();
        Observer.Observe('after modify', Format(Temp.Stamp));
        Temp.Get(1);
        Observer.Observe('get after modify', Format(Temp.Stamp));
        Temp.Reset();
        Temp.SetRange(Stamp, 7);
        Observer.Observe('filter on 7 finds', Format(Temp.FindFirst()));
        Temp.SetRange(Stamp, 5);
        Observer.Observe('filter on 5 finds', Format(Temp.FindFirst()));
        Temp.SetFilter(Stamp, '>%1', 0);
        Observer.Observe('filter above zero count', Format(Temp.Count()));
        Observer.Expect('assigned', '5');
        Observer.Expect('after insert', '5');
        Observer.Expect('after get', '5');
        Observer.Expect('after modify', '7');
        Observer.Expect('get after modify', '7');
        Observer.Expect('filter on 7 finds', 'Yes');
        Observer.Expect('filter on 5 finds', 'No');
        Observer.Expect('filter above zero count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temp_CopyOfDatabaseRow()
    var
        Observer: Codeunit "Probe Observer";
        Db: Record "LT QR Stamp Row";
        Temp: Record "LT QR Stamp Row" temporary;
        DbStamp: BigInteger;
        DbVersion: BigInteger;
    begin
        Db.DeleteAll();
        Db.Init();
        Db.Id := 1;
        Db.Note := 'db';
        Db.Insert();
        Db.Get(1);
        DbStamp := Db.Stamp;
        DbVersion := Db.SystemRowVersion;
        Observer.Observe('db', State(Db));
        Observer.Observe('db stamp = db rowversion', Format(DbStamp = DbVersion));
        Temp := Db;
        Observer.Observe('assigned: stamp', Format(Temp.Stamp = DbStamp));
        Observer.Observe('assigned: rowversion', Format(Temp.SystemRowVersion = DbVersion));
        Temp.Insert();
        Observer.Observe('inserted: stamp same', Format(Temp.Stamp = DbStamp));
        Observer.Observe('inserted: rowversion same', Format(Temp.SystemRowVersion = DbVersion));
        Observer.Observe('inserted', State(Temp));
        Temp.Get(1);
        Observer.Observe('get: stamp same', Format(Temp.Stamp = DbStamp));
        Observer.Observe('get: rowversion same', Format(Temp.SystemRowVersion = DbVersion));
        Temp.Note := 'changed';
        Temp.Modify();
        Temp.Get(1);
        Observer.Observe('modified: stamp same', Format(Temp.Stamp = DbStamp));
        Observer.Observe('modified: rowversion same', Format(Temp.SystemRowVersion = DbVersion));
        Db.Get(1);
        Observer.Observe('db unchanged', Format((Db.Stamp = DbStamp) and (Db.Note = 'db')));
        Observer.Expect('db', 'stamp positive, rowversion positive');
        Observer.Expect('db stamp = db rowversion', 'Yes');
        Observer.Expect('assigned: stamp', 'Yes');
        Observer.Expect('assigned: rowversion', 'Yes');
        Observer.Expect('inserted: stamp same', 'Yes');
        Observer.Expect('inserted: rowversion same', 'Yes');
        Observer.Expect('inserted', 'stamp positive, rowversion positive');
        Observer.Expect('get: stamp same', 'Yes');
        Observer.Expect('get: rowversion same', 'Yes');
        Observer.Expect('modified: stamp same', 'Yes');
        Observer.Expect('modified: rowversion same', 'Yes');
        Observer.Expect('db unchanged', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temp_TransferFieldsAndCopy()
    var
        Observer: Codeunit "Probe Observer";
        Db: Record "LT QR Stamp Row";
        Temp: Record "LT QR Stamp Row" temporary;
        Temp2: Record "LT QR Stamp Row" temporary;
        DbStamp: BigInteger;
    begin
        Db.DeleteAll();
        Db.Init();
        Db.Id := 1;
        Db.Note := 'db';
        Db.Insert();
        Db.Get(1);
        DbStamp := Db.Stamp;
        Temp.Init();
        Temp.TransferFields(Db);
        Observer.Observe('transferfields: stamp', Format(Temp.Stamp = DbStamp) + ' ' + Sign(Temp.Stamp));
        Observer.Observe('transferfields: rowversion', Sign(Temp.SystemRowVersion));
        Temp.Insert();
        Temp.Get(1);
        Observer.Observe('transferfields inserted: stamp', Format(Temp.Stamp = DbStamp) + ' ' + Sign(Temp.Stamp));
        Temp2.Copy(Temp, true);
        Temp2.Get(1);
        Observer.Observe('shared copy: stamp', Format(Temp2.Stamp = Temp.Stamp));
        Temp2.Init();
        Temp2.Id := 2;
        Temp2.Insert();
        Observer.Observe('shared copy insert', State(Temp2));
        Temp.Reset();
        Observer.Observe('count', Format(Temp.Count()));
        Observer.Expect('transferfields: stamp', 'Yes positive');
        Observer.Expect('transferfields: rowversion', 'positive');
        Observer.Expect('transferfields inserted: stamp', 'Yes positive');
        Observer.Expect('shared copy: stamp', 'Yes');
        Observer.Expect('shared copy insert', 'stamp positive, rowversion positive');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temp_ModifyAllStamp()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Stamp Row" temporary;
    begin
        Temp.Init();
        Temp.Id := 1;
        Temp.Insert();
        Temp.Id := 2;
        Temp.Insert();
        Temp.ModifyAll(Stamp, 9);
        Temp.Get(1);
        Observer.Observe('row 1', Format(Temp.Stamp));
        Temp.Get(2);
        Observer.Observe('row 2', Format(Temp.Stamp));
        Observer.Expect('row 1', '9');
        Observer.Expect('row 2', '9');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temp_CompareTwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Stamp Row" temporary;
        First: BigInteger;
    begin
        Temp.Init();
        Temp.Id := 1;
        Temp.Insert();
        First := Temp.Stamp;
        Temp.Init();
        Temp.Id := 2;
        Temp.Insert();
        Observer.Observe('second = first', Format(Temp.Stamp = First));
        Observer.Observe('second > first', Format(Temp.Stamp > First));
        Temp.Get(1);
        Temp.Note := 'x';
        Temp.Modify();
        Observer.Observe('modified = first', Format(Temp.Stamp = First));
        Temp.SetCurrentKey(Stamp);
        Observer.Observe('sorted by stamp first id', Format(Temp.FindFirst()) + ' ' + Format(Temp.Id));
        Observer.Expect('second = first', 'Yes');
        Observer.Expect('second > first', 'No');
        Observer.Expect('modified = first', 'Yes');
        Observer.Expect('sorted by stamp first id', 'Yes 1');
        Observer.Verify();
    end;
}
