// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the first 8 rows (the count is not asserted: Count on this table takes minutes and ends the run), with every column, of the platform table License Permission on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78108.

codeunit 78108 "LT AD Plat Rows License"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Class() = FieldClass::Normal then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; TableName: Text; Skip: Integer; Take: Integer)
    var
        RR: RecordRef;
        Id: Integer;
        n: Integer;
    begin
        Id := TableIdByName(TableName);
        Observer.Observe(TableName + ' id', Format(Id));
        if Id < 0 then
            exit;
        RR.Open(Id);
                if RR.FindSet() then
            repeat
                n += 1;
                if (n > Skip) and (n <= Skip + Take) then
                    Observer.Observe(TableName + ' row ' + Format(n), RowText(RR));
            until (RR.Next() = 0) or (n >= Skip + Take);
    end;

    [Test]
    procedure Rows_LicensePermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'License Permission', 0, 8);
        Observer.Expect('License Permission id', '2000000043');
        Observer.Expect('License Permission row 1', 'Object Type=TableData|Object Number=0|Read Permission= |Insert Permission= |Modify Permission= |Delete Permission= |Execute Permission= |Limited Usage Permission= |');
        Observer.Expect('License Permission row 2', 'Object Type=TableData|Object Number=1|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 3', 'Object Type=TableData|Object Number=2|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 4', 'Object Type=TableData|Object Number=3|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 5', 'Object Type=TableData|Object Number=4|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 6', 'Object Type=TableData|Object Number=5|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 7', 'Object Type=TableData|Object Number=6|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Expect('License Permission row 8', 'Object Type=TableData|Object Number=7|Read Permission=Yes|Insert Permission=Yes|Modify Permission=Yes|Delete Permission=Yes|Execute Permission=Yes|Limited Usage Permission= |');
        Observer.Verify();
    end;
}
