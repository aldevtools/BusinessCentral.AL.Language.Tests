// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71390, own reports 71392/71393, corpus report 60872; Base Application table 18/21 and report 1306 (read only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: values of Table Metadata.DataIsExternal, Report Metadata.DefaultLayoutName, Key.SumIndexFields and Field.IsPartOfPrimaryKey for own and Base Application objects.
// BC versions: 29 (27 and 28 by CI)

table 71390 "LT PM Values Table"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; A; Integer) { }
        field(2; B; Code[10]) { }
        field(3; C; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; Qty; Decimal) { }
    }

    keys
    {
        key(PK; A, B) { Clustered = true; }
        key(Sift; C) { SumIndexFields = Amount, Qty; }
        key(Plain; Qty) { }
    }
}

report 71392 "LT PM Values Proc Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

report 71393 "LT PM Values Data Report"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }
}

codeunit 71391 "LT PM Values Helper"
{
    procedure NamedValue(var RR: RecordRef; ColumnName: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name = ColumnName then
                exit(Format(FR.Value));
        end;
        exit('nofield');
    end;

    procedure KeyRows(var Observer: Codeunit "Probe Observer"; Prefix: Text; TableId: Integer; MaxRows: Integer)
    var
        K: Record "Key";
        RR: RecordRef;
        n: Integer;
    begin
        K.SetRange(TableNo, TableId);
        Observer.Observe(Prefix + 'rows > 0', Format(K.Count() > 0));
        if K.FindSet() then
            repeat
                n += 1;
                RR.GetTable(K);
                Observer.Observe(Prefix + 'key' + Format(n) + ' Key', NamedValue(RR, 'Key'));
                Observer.Observe(Prefix + 'key' + Format(n) + ' SumIndexFields', NamedValue(RR, 'SumIndexFields'));
                Observer.Observe(Prefix + 'key' + Format(n) + ' MaintainSIFTIndex', NamedValue(RR, 'MaintainSIFTIndex'));
            until (K.Next() = 0) or (n >= MaxRows);
    end;

    procedure FieldRows(var Observer: Codeunit "Probe Observer"; Prefix: Text; TableId: Integer; MaxRows: Integer)
    var
        F: Record "Field";
        RR: RecordRef;
        n: Integer;
    begin
        F.SetRange(TableNo, TableId);
        F.SetFilter("No.", '<2000000000');
        if F.FindSet() then
            repeat
                n += 1;
                RR.GetTable(F);
                Observer.Observe(Prefix + 'field' + Format(F."No.") + ' ' + F.FieldName, NamedValue(RR, 'IsPartOfPrimaryKey'));
            until (F.Next() = 0) or (n >= MaxRows);
    end;
}

codeunit 71394 "LT PM Values Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableMetadata_DataIsExternal_OwnAndBase()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
        T: Record "Table Metadata";
        RR: RecordRef;
    begin
        Observer.Observe('own found', Format(T.Get(71390)));
        RR.GetTable(T);
        Observer.Observe('own DataIsExternal', Helper.NamedValue(RR, 'DataIsExternal'));
        Observer.Observe('customer found', Format(T.Get(18)));
        RR.GetTable(T);
        Observer.Observe('customer DataIsExternal', Helper.NamedValue(RR, 'DataIsExternal'));
        Observer.Observe('item ledger entry found', Format(T.Get(32)));
        RR.GetTable(T);
        Observer.Observe('item ledger entry DataIsExternal', Helper.NamedValue(RR, 'DataIsExternal'));
        Observer.Observe('corpus table found', Format(T.Get(60872)));
        RR.GetTable(T);
        Observer.Observe('corpus table DataIsExternal', Helper.NamedValue(RR, 'DataIsExternal'));
        Observer.Expect('own found', 'Yes');
        Observer.Expect('own DataIsExternal', 'No');
        Observer.Expect('customer found', 'Yes');
        Observer.Expect('customer DataIsExternal', 'No');
        Observer.Expect('item ledger entry found', 'Yes');
        Observer.Expect('item ledger entry DataIsExternal', 'No');
        Observer.Expect('corpus table found', 'No');
        Observer.Expect('corpus table DataIsExternal', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReportMetadata_DefaultLayoutName_OwnAndBase()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
        R: Record "Report Metadata";
        RR: RecordRef;
    begin
        Observer.Observe('own processing found', Format(R.Get(71392)));
        RR.GetTable(R);
        Observer.Observe('own processing DefaultLayoutName', Helper.NamedValue(RR, 'DefaultLayoutName'));
        Observer.Observe('own data report found', Format(R.Get(71393)));
        RR.GetTable(R);
        Observer.Observe('own data DefaultLayoutName', Helper.NamedValue(RR, 'DefaultLayoutName'));
        Observer.Observe('own data DefaultLayout', Helper.NamedValue(RR, 'DefaultLayout'));
        Observer.Observe('corpus rdlc report found', Format(R.Get(60872)));
        RR.GetTable(R);
        Observer.Observe('corpus rdlc DefaultLayoutName', Helper.NamedValue(RR, 'DefaultLayoutName'));
        Observer.Observe('corpus rdlc DefaultLayout', Helper.NamedValue(RR, 'DefaultLayout'));
        Observer.Observe('base 1306 found', Format(R.Get(1306)));
        RR.GetTable(R);
        Observer.Observe('base 1306 DefaultLayoutName', Helper.NamedValue(RR, 'DefaultLayoutName'));
        Observer.Observe('base 1306 DefaultLayout', Helper.NamedValue(RR, 'DefaultLayout'));
        Observer.Observe('base 1320 found', Format(R.Get(1320)));
        RR.GetTable(R);
        Observer.Observe('base 1320 DefaultLayoutName', Helper.NamedValue(RR, 'DefaultLayoutName'));
        Observer.Expect('own processing found', 'Yes');
        Observer.Expect('own processing DefaultLayoutName', '');
        Observer.Expect('own data report found', 'Yes');
        Observer.Expect('own data DefaultLayoutName', '');
        Observer.Expect('own data DefaultLayout', 'RDLC');
        Observer.Expect('corpus rdlc report found', 'Yes');
        Observer.Expect('corpus rdlc DefaultLayoutName', 'RdlcFixture');
        Observer.Expect('corpus rdlc DefaultLayout', 'RDLC');
        Observer.Expect('base 1306 found', 'Yes');
        Observer.Expect('base 1306 DefaultLayoutName', 'StandardSalesInvoice.docx');
        Observer.Expect('base 1306 DefaultLayout', 'Word');
        Observer.Expect('base 1320 found', 'Yes');
        Observer.Expect('base 1320 DefaultLayoutName', './System/Notifications/NotificationEmail.docx');
        Observer.Verify();
    end;

    [Test]
    procedure KeyTable_SumIndexFields_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
    begin
        Helper.KeyRows(Observer, 'own ', 71390, 5);
        Observer.Expect('own rows > 0', 'Yes');
        Observer.Expect('own key1 Key', 'A,B');
        Observer.Expect('own key1 SumIndexFields', '');
        Observer.Expect('own key1 MaintainSIFTIndex', 'No');
        Observer.Expect('own key2 Key', 'C');
        Observer.Expect('own key2 SumIndexFields', 'Amount,Qty');
        Observer.Expect('own key2 MaintainSIFTIndex', 'Yes');
        Observer.Expect('own key3 Key', 'Qty');
        Observer.Expect('own key3 SumIndexFields', '');
        Observer.Expect('own key3 MaintainSIFTIndex', 'No');
        Observer.Expect('own key4 Key', '$systemId');
        Observer.Expect('own key4 SumIndexFields', '');
        Observer.Expect('own key4 MaintainSIFTIndex', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure KeyTable_SumIndexFields_BaseApp()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
    begin
        Helper.KeyRows(Observer, 'cust ledger entry ', 21, 4);
        Observer.Expect('cust ledger entry rows > 0', 'Yes');
        Observer.Expect('cust ledger entry key1 Key', 'Entry No.');
        Observer.Expect('cust ledger entry key1 SumIndexFields', '');
        Observer.Expect('cust ledger entry key1 MaintainSIFTIndex', 'No');
#if BC28PLUS
        Observer.Expect('cust ledger entry key2 Key', 'Customer No.,Currency Code');
#else
        Observer.Expect('cust ledger entry key2 Key', 'Customer No.,Posting Date,Currency Code');
#endif
        Observer.Expect('cust ledger entry key2 SumIndexFields', 'Sales (LCY),Profit (LCY),Inv. Discount (LCY)');
        Observer.Expect('cust ledger entry key2 MaintainSIFTIndex', 'Yes');
        Observer.Expect('cust ledger entry key3 Key', 'Document No.');
        Observer.Expect('cust ledger entry key3 SumIndexFields', '');
        Observer.Expect('cust ledger entry key3 MaintainSIFTIndex', 'No');
        Observer.Expect('cust ledger entry key4 Key', 'External Document No.');
        Observer.Expect('cust ledger entry key4 SumIndexFields', '');
        Observer.Expect('cust ledger entry key4 MaintainSIFTIndex', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_IsPartOfPrimaryKey_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
    begin
        Helper.FieldRows(Observer, 'own ', 71390, 10);
        Observer.Expect('own field1 A', 'Yes');
        Observer.Expect('own field2 B', 'Yes');
        Observer.Expect('own field3 C', 'No');
        Observer.Expect('own field4 Amount', 'No');
        Observer.Expect('own field5 Qty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_IsPartOfPrimaryKey_BaseApp()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PM Values Helper";
    begin
        Helper.FieldRows(Observer, 'customer ', 18, 4);
        Helper.FieldRows(Observer, 'cust ledger entry ', 21, 3);
        Observer.Expect('customer field1 No.', 'Yes');
        Observer.Expect('customer field2 Name', 'No');
        Observer.Expect('customer field3 Search Name', 'No');
        Observer.Expect('customer field4 Name 2', 'No');
        Observer.Expect('cust ledger entry field1 Entry No.', 'Yes');
        Observer.Expect('cust ledger entry field3 Customer No.', 'No');
        Observer.Expect('cust ledger entry field4 Posting Date', 'No');
        Observer.Verify();
    end;

    // Corpus issue 668 item 46 (writer br): Field."App Package ID" and "App Runtime Package ID" after Get, after FindFirst and after
    // Next(1); Next(-1), for an own table and a Base Application table, compared with AllObj of the same table.
    local procedure BrPackageIds(var F: Record Field; TableId: Integer): Text
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Table, TableId);
        exit(
            'pkgnull=' + Format(IsNullGuid(F."App Package ID")) +
            ' rtnull=' + Format(IsNullGuid(F."App Runtime Package ID")) +
            ' pkg=allobj:' + Format(F."App Package ID" = AllObj."App Package ID") +
            ' rt=allobj:' + Format(F."App Runtime Package ID" = AllObj."App Runtime Package ID"));
    end;

    local procedure BrObservePackageIds(var Observer: Codeunit "Probe Observer"; Prefix: Text; TableId: Integer)
    var
        F: Record Field;
    begin
        F.Get(TableId, 1);
        Observer.Observe(Prefix + ' get', BrPackageIds(F, TableId));
        Clear(F);
        F.SetRange(TableNo, TableId);
        F.FindFirst();
        Observer.Observe(Prefix + ' findfirst', BrPackageIds(F, TableId));
        F.Get(TableId, 1);
        if F.Next(1) <> 0 then
            F.Next(-1);
        Observer.Observe(Prefix + ' next back', BrPackageIds(F, TableId) + ' no=' + Format(F."No."));
    end;

    [Test]
    procedure FieldTable_AppPackageIds_AfterGetFindAndNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BrObservePackageIds(Observer, 'own', 71390);
        BrObservePackageIds(Observer, 'item', Database::Item);
        Observer.Expect('own get', 'pkgnull=Yes rtnull=Yes pkg=allobj:No rt=allobj:No');
        Observer.Expect('own findfirst', 'pkgnull=No rtnull=No pkg=allobj:Yes rt=allobj:Yes');
        Observer.Expect('own next back', 'pkgnull=No rtnull=No pkg=allobj:Yes rt=allobj:Yes no=1');
        Observer.Expect('item get', 'pkgnull=No rtnull=No pkg=allobj:Yes rt=allobj:Yes');
        Observer.Expect('item findfirst', 'pkgnull=No rtnull=No pkg=allobj:Yes rt=allobj:Yes');
        Observer.Expect('item next back', 'pkgnull=No rtnull=No pkg=allobj:Yes rt=allobj:Yes no=1');
        Observer.Verify();
    end;
}
