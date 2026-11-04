// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, with every column, of the platform table Tenant Report Layout Selection on the fresh tenant of a test container (read through RecordRef by
// table name). The rows are named by Layout Name; where a row differs between BC 27, 28 and 29 (or is missing in one), the expected text is guarded with BC28PLUS and BC29PLUS.
// Only the first five columns are read: BC 27 and 28 have fewer columns than BC 29.
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78109.

codeunit 78109 "LT AD Plat Rows Layout"
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

    local procedure RowText(var RR: RecordRef; MaxField: Integer): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class() = FieldClass::Normal) and ((MaxField = 0) or (FR.Number() <= MaxField)) then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure KeyText(var RR: RecordRef; KeyField: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = KeyField then
                exit(Format(FR.Value()));
        end;
    end;

    // Observes the rows whose KeyField value is in Keys (separated by ~), named by that value and not by position, because the rows of a platform
    // table differ between BC versions. A key without a row is observed as <absent>.
    local procedure DumpKeys(var Observer: Codeunit "Probe Observer"; TableName: Text; KeyField: Text; MaxField: Integer; Keys: Text)
    var
        RR: RecordRef;
        Rows: Dictionary of [Text, Text];
        RowKey: Text;
        Id: Integer;
    begin
        Id := TableIdByName(TableName);
        RR.Open(Id);
        if RR.FindSet() then
            repeat
                Rows.Set(KeyText(RR, KeyField), RowText(RR, MaxField));
            until RR.Next() = 0;
        foreach RowKey in Keys.Split('~') do
            if Rows.ContainsKey(RowKey) then
                Observer.Observe(TableName + ' row ' + RowKey, Rows.Get(RowKey))
            else
                Observer.Observe(TableName + ' row ' + RowKey, '<absent>');
    end;

    [Test]
    procedure Rows_TenantReportLayoutSelection_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Tenant Report Layout Selection', 'Layout Name', 5, 'StandardDraftSalesInvoiceBlue.docx~StandardSalesInvoiceBlueSimple.docx~StandardSalesProFormaInv.docx~StandardSalesQuoteBlue.docx');
        Observer.Expect('Tenant Report Layout Selection row StandardDraftSalesInvoiceBlue.docx', 'Report ID=1303|Company Name=|User ID={00000000-0000-0000-0000-000000000000}|Layout Name=StandardDraftSalesInvoiceBlue.docx|App ID={437DBF0E-84FF-417A-965D-ED2BB9650972}|');
        Observer.Expect('Tenant Report Layout Selection row StandardSalesInvoiceBlueSimple.docx', 'Report ID=1306|Company Name=|User ID={00000000-0000-0000-0000-000000000000}|Layout Name=StandardSalesInvoiceBlueSimple.docx|App ID={437DBF0E-84FF-417A-965D-ED2BB9650972}|');
        Observer.Expect('Tenant Report Layout Selection row StandardSalesProFormaInv.docx', 'Report ID=1302|Company Name=|User ID={00000000-0000-0000-0000-000000000000}|Layout Name=StandardSalesProFormaInv.docx|App ID={437DBF0E-84FF-417A-965D-ED2BB9650972}|');
        Observer.Expect('Tenant Report Layout Selection row StandardSalesQuoteBlue.docx', 'Report ID=1304|Company Name=|User ID={00000000-0000-0000-0000-000000000000}|Layout Name=StandardSalesQuoteBlue.docx|App ID={437DBF0E-84FF-417A-965D-ED2BB9650972}|');
        Observer.Verify();
    end;

    [Test]
    procedure Count_TenantReportLayoutSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(TableIdByName('Tenant Report Layout Selection'));
        Observer.Observe('count', Format(RR.Count()));
        Observer.Expect('count', '4');
        Observer.Verify();
    end;
}
