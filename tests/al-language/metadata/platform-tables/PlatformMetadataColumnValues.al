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

    // al-runner issue 8051: Field."App Package ID" and "App Runtime Package ID" of a field a table extension adds are the ids of the
    // extension's app (the AllObj row of the table extension), not the table's, after Get, after FindFirst on the key and in a scan of
    // the table's fields. Fields: the one cross-app fixture B's extension 61110 adds to cross-app fixture A's table 61101, the one this
    // app's extension 83950 adds to that table (table-objects/extensions/BwCrossAppObjects.al), and the one this app's extension 96160
    // adds to Base Application's Item (localization/app-xliff/lt-r7144-ext-caption/R7184BaseAppCaption.al). Measured with the same
    // shapes on a local BC 29.1.57326.57497 (OnPrem w1); BC 27 and 28 by CI.
    local procedure ExtFieldPackageIds(var F: Record Field; TableId: Integer; ExtensionId: Integer): Text
    var
        TableObj: Record AllObj;
        ExtensionObj: Record AllObj;
        Own: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Own);
        TableObj.Get(TableObj."Object Type"::Table, TableId);
        ExtensionObj.Get(ExtensionObj."Object Type"::TableExtension, ExtensionId);
        exit(
            'pkgnull=' + Format(IsNullGuid(F."App Package ID")) +
            ' rtnull=' + Format(IsNullGuid(F."App Runtime Package ID")) +
            ' pkg=table:' + Format(F."App Package ID" = TableObj."App Package ID") +
            ' pkg=ext:' + Format(F."App Package ID" = ExtensionObj."App Package ID") +
            ' rt=ext:' + Format(F."App Runtime Package ID" = ExtensionObj."App Runtime Package ID") +
            ' pkg=own:' + Format(F."App Package ID" = Own.PackageId));
    end;

    local procedure ObserveExtFieldPackageIds(var Observer: Codeunit "Probe Observer"; Prefix: Text; TableId: Integer; FieldNo: Integer; ExtensionId: Integer)
    var
        F: Record Field;
    begin
        F.Get(TableId, FieldNo);
        Observer.Observe(Prefix + ' get', ExtFieldPackageIds(F, TableId, ExtensionId));
        Clear(F);
        F.SetRange(TableNo, TableId);
        F.SetRange("No.", FieldNo);
        F.FindFirst();
        Observer.Observe(Prefix + ' findfirst', ExtFieldPackageIds(F, TableId, ExtensionId));
        Clear(F);
        F.SetRange(TableNo, TableId);
        F.FindSet();
        while F."No." <> FieldNo do
            if F.Next() = 0 then
                Error('Field %1 of table %2 is not in a scan of its table.', FieldNo, TableId);
        Observer.Observe(Prefix + ' scan', ExtFieldPackageIds(F, TableId, ExtensionId));
    end;

    [Test]
    procedure FieldTable_AppPackageIds_OfTableExtensionField_AreTheExtensionApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExtFieldPackageIds(Observer, 'xapp b', Database::"LT BW XA Base", 61110, 61110);
        ObserveExtFieldPackageIds(Observer, 'xapp own', Database::"LT BW XA Base", 83950, 83950);
        ObserveExtFieldPackageIds(Observer, 'item own', Database::Item, 96160, 96160);
        Observer.Expect('xapp b get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('xapp b findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('xapp b scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('xapp own get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('xapp own findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('xapp own scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('item own get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('item own findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('item own scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Verify();
    end;

    local procedure KeptByFilter(var F: Record Field; FieldNo: Integer): Text
    begin
        F.SetRange("No.", FieldNo);
        exit(Format(not F.IsEmpty()));
    end;

    // al-runner issue 8051: a Field read filtered on "App Package ID" <> the table's package id (cross-app fixture A's) keeps the fields
    // table extensions of other apps add to the table and drops the table's own fields. Measured as above.
    [Test]
    procedure FieldTable_FilterAppPackageIdNotTheTables_KeepsOnlyExtensionFields()
    var
        Observer: Codeunit "Probe Observer";
        F: Record Field;
        TableObj: Record AllObj;
    begin
        TableObj.Get(TableObj."Object Type"::Table, Database::"LT BW XA Base");
        F.SetRange(TableNo, Database::"LT BW XA Base");
        F.SetFilter("App Package ID", '<>%1', TableObj."App Package ID");
        Observer.Observe('field 1 kept', KeptByFilter(F, 1));
        Observer.Observe('field 2 kept', KeptByFilter(F, 2));
        Observer.Observe('xapp b field kept', KeptByFilter(F, 61110));
        Observer.Observe('own field kept', KeptByFilter(F, 83950));
        Observer.Expect('field 1 kept', 'No');
        Observer.Expect('field 2 kept', 'No');
        Observer.Expect('xapp b field kept', 'Yes');
        Observer.Expect('own field kept', 'Yes');
        Observer.Verify();
    end;

    // Follow-up of al-runner PR 8054: the package ids of a field a table extension of a Microsoft app adds. Base Application's
    // extensions 7049 and 3999 add field 7049 to System Application's table 2610 "Feature Data Update Status" and field 3999 to its
    // table 3902 "Retention Policy Setup Line"; Base Application's extension 910 adds field 32 to its own table 6502 "Item Tracking
    // Code"; this app's extension 71396 (below) adds field 71400 to table 2610. Measured with the same shapes on a local BC 29.1
    // (OnPrem w1); BC 27 and 28 by CI.
    [Test]
    procedure FieldTable_AppPackageIds_OfMicrosoftAppExtensionField_AreTheExtensionApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExtFieldPackageIds(Observer, 'base on sysapp 2610', 2610, 7049, 7049);
        ObserveExtFieldPackageIds(Observer, 'base on sysapp 3902', 3902, 3999, 3999);
        ObserveExtFieldPackageIds(Observer, 'base on own 6502', 6502, 32, 910);
        ObserveExtFieldPackageIds(Observer, 'own on sysapp 2610', 2610, 71400, 71396);
        Observer.Expect('base on sysapp 2610 get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on sysapp 2610 findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on sysapp 2610 scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on sysapp 3902 get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on sysapp 3902 findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on sysapp 3902 scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on own 6502 get', 'pkgnull=No rtnull=No pkg=table:Yes pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on own 6502 findfirst', 'pkgnull=No rtnull=No pkg=table:Yes pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('base on own 6502 scan', 'pkgnull=No rtnull=No pkg=table:Yes pkg=ext:Yes rt=ext:Yes pkg=own:No');
        Observer.Expect('own on sysapp 2610 get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('own on sysapp 2610 findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('own on sysapp 2610 scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Verify();
    end;

    // Follow-up of al-runner PR 8054: an obsolete (Pending and Removed), FlowField, FlowFilter and disabled field that this app's
    // extension 71395 (below) adds to cross-app fixture A's table 61101 carries the extension's ids too. Measured as above.
    [Test]
    procedure FieldTable_AppPackageIds_OfObsoleteFlowAndDisabledExtensionFields_AreTheExtensionApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExtFieldPackageIds(Observer, 'pending', Database::"LT BW XA Base", 71395, 71395);
        ObserveExtFieldPackageIds(Observer, 'removed', Database::"LT BW XA Base", 71396, 71395);
        ObserveExtFieldPackageIds(Observer, 'flowfield', Database::"LT BW XA Base", 71397, 71395);
        ObserveExtFieldPackageIds(Observer, 'flowfilter', Database::"LT BW XA Base", 71398, 71395);
        ObserveExtFieldPackageIds(Observer, 'disabled', Database::"LT BW XA Base", 71399, 71395);
        Observer.Expect('pending get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('pending findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('pending scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('removed get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('removed findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('removed scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfield get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfield findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfield scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfilter get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfilter findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('flowfilter scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('disabled get', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('disabled findfirst', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Expect('disabled scan', 'pkgnull=No rtnull=No pkg=table:No pkg=ext:Yes rt=ext:Yes pkg=own:Yes');
        Observer.Verify();
    end;

    // Follow-up of al-runner PR 8054: a Field read filtered on "App Package ID" <> the table's package id keeps the obsolete,
    // FlowField, FlowFilter and disabled extension fields of table 61101, and on System Application's table 2610 keeps the fields
    // of Base Application's extension and of this app's and drops the table's own field 1. Measured as above.
    [Test]
    procedure FieldTable_FilterAppPackageIdNotTheTables_KeepsObsoleteFlowDisabledAndMicrosoftExtensionFields()
    var
        Observer: Codeunit "Probe Observer";
        F: Record Field;
        TableObj: Record AllObj;
    begin
        TableObj.Get(TableObj."Object Type"::Table, Database::"LT BW XA Base");
        F.SetRange(TableNo, Database::"LT BW XA Base");
        F.SetFilter("App Package ID", '<>%1', TableObj."App Package ID");
        Observer.Observe('pending kept', KeptByFilter(F, 71395));
        Observer.Observe('removed kept', KeptByFilter(F, 71396));
        Observer.Observe('flowfield kept', KeptByFilter(F, 71397));
        Observer.Observe('flowfilter kept', KeptByFilter(F, 71398));
        Observer.Observe('disabled kept', KeptByFilter(F, 71399));
        Clear(F);
        TableObj.Get(TableObj."Object Type"::Table, 2610);
        F.SetRange(TableNo, 2610);
        F.SetFilter("App Package ID", '<>%1', TableObj."App Package ID");
        Observer.Observe('2610 field 1 kept', KeptByFilter(F, 1));
        Observer.Observe('2610 base field kept', KeptByFilter(F, 7049));
        Observer.Observe('2610 own field kept', KeptByFilter(F, 71400));
        Observer.Expect('pending kept', 'Yes');
        Observer.Expect('removed kept', 'Yes');
        Observer.Expect('flowfield kept', 'Yes');
        Observer.Expect('flowfilter kept', 'Yes');
        Observer.Expect('disabled kept', 'Yes');
        Observer.Expect('2610 field 1 kept', 'No');
        Observer.Expect('2610 base field kept', 'Yes');
        Observer.Expect('2610 own field kept', 'Yes');
        Observer.Verify();
    end;

    local procedure OwnFieldGetPackageIds(TableId: Integer): Text
    var
        F: Record Field;
        TableObj: Record AllObj;
    begin
        TableObj.Get(TableObj."Object Type"::Table, TableId);
        F.Get(TableId, 1);
        exit(
            'pkgnull=' + Format(IsNullGuid(F."App Package ID")) +
            ' rtnull=' + Format(IsNullGuid(F."App Runtime Package ID")) +
            ' pkg=allobj:' + Format(F."App Package ID" = TableObj."App Package ID"));
    end;

    // Follow-up of al-runner PR 8054: a Get of field 1 of a System Application table (2610, 3902) gives null package ids, as for a
    // table of this app (FieldTable_AppPackageIds_AfterGetFindAndNext above) and of cross-app fixture A; for a Base Application table
    // (6502) it gives the table's AllObj ids, as for Item above. Measured as above.
    [Test]
    procedure FieldTable_AppPackageIds_GetOfOwnField_NullForSystemApplicationAndFixtureTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('sysapp 2610', OwnFieldGetPackageIds(2610));
        Observer.Observe('sysapp 3902', OwnFieldGetPackageIds(3902));
        Observer.Observe('base 6502', OwnFieldGetPackageIds(6502));
        Observer.Observe('xapp a 61101', OwnFieldGetPackageIds(Database::"LT BW XA Base"));
        Observer.Expect('sysapp 2610', 'pkgnull=Yes rtnull=Yes pkg=allobj:No');
        Observer.Expect('sysapp 3902', 'pkgnull=Yes rtnull=Yes pkg=allobj:No');
        Observer.Expect('base 6502', 'pkgnull=No rtnull=No pkg=allobj:Yes');
        Observer.Expect('xapp a 61101', 'pkgnull=Yes rtnull=Yes pkg=allobj:No');
        Observer.Verify();
    end;
}

// local object: the tests read the Field rows of the fields these extensions declare (their obsolete state, class and Enabled are
// what the tests vary), and the package ids of an extension field of this app on a System Application table.
tableextension 71395 "LT PM Values XA Base Ext" extends "LT BW XA Base"
{
    fields
    {
        field(71395; "LT PM Pending"; Integer)
        {
            DataClassification = SystemMetadata;
            ObsoleteState = Pending;
            ObsoleteReason = 'Probe of the Field row of an obsolete extension field.';
            ObsoleteTag = '1.0';
        }
        field(71396; "LT PM Removed"; Integer)
        {
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Probe of the Field row of an obsolete extension field.';
            ObsoleteTag = '1.0';
        }
        field(71397; "LT PM FlowField"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BW XA Base");
        }
        field(71398; "LT PM FlowFilter"; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(71399; "LT PM Disabled"; Integer)
        {
            DataClassification = SystemMetadata;
            Enabled = false;
        }
    }
}

tableextension 71396 "LT PM Values Feature Ext" extends "Feature Data Update Status"
{
    fields
    {
        field(71400; "LT PM Feature Note"; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }
}
