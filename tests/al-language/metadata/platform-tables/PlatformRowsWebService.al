// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, in 8 tests of 9 rows each,, with every column, of the platform table Tenant Web Service on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78111.

codeunit 78111 "LT AD Plat Rows WebSvc"
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
    procedure Rows_TenantWebService_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 0, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 1', 'Object Type=Codeunit|Service Name=WorkflowActionResponse|Object ID=1544|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 2', 'Object Type=Page|Service Name=Chart of Accounts|Object ID=16|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 3', 'Object Type=Page|Service Name=ExcelTemplateAgedAccountsPayable|Object ID=5500|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 4', 'Object Type=Page|Service Name=ExcelTemplateAgedAccountsReceivable|Object ID=5499|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 5', 'Object Type=Page|Service Name=ExcelTemplateBalanceSheet|Object ID=5501|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 6', 'Object Type=Page|Service Name=ExcelTemplateCashFlowStatement|Object ID=5493|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 7', 'Object Type=Page|Service Name=ExcelTemplateIncomeStatement|Object ID=5503|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 8', 'Object Type=Page|Service Name=ExcelTemplateRetainedEarnings|Object ID=5497|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 9', 'Object Type=Page|Service Name=ExcelTemplateTrialBalance|Object ID=5502|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 9, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 10', 'Object Type=Page|Service Name=ExcelTemplateViewCompanyInformation|Object ID=1320|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 11', 'Object Type=Page|Service Name=Job List|Object ID=89|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 12', 'Object Type=Page|Service Name=Job Planning Lines|Object ID=1007|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 13', 'Object Type=Page|Service Name=Job Task Lines|Object ID=1002|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 14', 'Object Type=Page|Service Name=Power BI Aged Acc. Payable|Object ID=6307|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 15', 'Object Type=Page|Service Name=Power BI Aged Acc. Receivable|Object ID=6308|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 16', 'Object Type=Page|Service Name=Power BI Aged Inventory Chart|Object ID=6309|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 17', 'Object Type=Page|Service Name=Power BI Job Act. v. Budg. Cost|Object ID=6312|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 18', 'Object Type=Page|Service Name=Power BI Job Act. v. Budg. Price|Object ID=6310|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 18, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 19', 'Object Type=Page|Service Name=Power BI Job Profitability|Object ID=6311|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 20', 'Object Type=Page|Service Name=Power BI Sales Pipeline|Object ID=6314|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 21', 'Object Type=Page|Service Name=Power BI Top 5 Opportunities|Object ID=6315|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 22', 'Object Type=Page|Service Name=Power BI WorkDate Calc.|Object ID=6313|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 23', 'Object Type=Page|Service Name=purchaseDocumentLines|Object ID=6405|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 24', 'Object Type=Page|Service Name=purchaseDocuments|Object ID=6404|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 25', 'Object Type=Page|Service Name=salesDocumentLines|Object ID=6403|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 26', 'Object Type=Page|Service Name=salesDocuments|Object ID=6402|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 27', 'Object Type=Page|Service Name=workflowCustomers|Object ID=6408|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 27, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 28', 'Object Type=Page|Service Name=workflowGenJournalBatches|Object ID=6406|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 29', 'Object Type=Page|Service Name=workflowGenJournalLines|Object ID=6407|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 30', 'Object Type=Page|Service Name=workflowItems|Object ID=6409|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 31', 'Object Type=Page|Service Name=workflowPurchaseDocumentLines|Object ID=6405|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 32', 'Object Type=Page|Service Name=workflowPurchaseDocuments|Object ID=6404|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 33', 'Object Type=Page|Service Name=workflowSalesDocumentLines|Object ID=6403|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 34', 'Object Type=Page|Service Name=workflowSalesDocuments|Object ID=6402|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 35', 'Object Type=Page|Service Name=workflowVendors|Object ID=6410|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 36', 'Object Type=Page|Service Name=workflowWebhookSubscriptions|Object ID=831|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 36, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 37', 'Object Type=Query|Service Name=BankAccountLedgerEntries|Object ID=264|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 38', 'Object Type=Query|Service Name=Cust.LedgerEntries|Object ID=262|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 39', 'Object Type=Query|Service Name=DimensionSetEntries|Object ID=260|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 40', 'Object Type=Query|Service Name=FALedgerEntries|Object ID=267|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 41', 'Object Type=Query|Service Name=G/LBudgetEntries|Object ID=270|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 42', 'Object Type=Query|Service Name=G/LEntries|Object ID=261|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 43', 'Object Type=Query|Service Name=ItemLedgerEntries|Object ID=265|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 44', 'Object Type=Query|Service Name=JobLedgerEntries|Object ID=268|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 45', 'Object Type=Query|Service Name=Power BI Cust. Item Ledg. Ent.|Object ID=61|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_06()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 45, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 46', 'Object Type=Query|Service Name=Power BI Cust. Ledger Entries|Object ID=62|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 47', 'Object Type=Query|Service Name=Power BI Customer List|Object ID=50|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 48', 'Object Type=Query|Service Name=Power BI GL Amount List|Object ID=53|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 49', 'Object Type=Query|Service Name=Power BI GL BudgetedAmount|Object ID=58|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 50', 'Object Type=Query|Service Name=Power BI Item Purchase List|Object ID=52|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 51', 'Object Type=Query|Service Name=Power BI Item Sales List|Object ID=57|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 52', 'Object Type=Query|Service Name=Power BI Jobs List|Object ID=54|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 53', 'Object Type=Query|Service Name=Power BI Purchase Hdr. Vendor|Object ID=64|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 54', 'Object Type=Query|Service Name=Power BI Purchase List|Object ID=56|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_07()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 54, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 55', 'Object Type=Query|Service Name=Power BI Sales Hdr. Cust.|Object ID=60|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 56', 'Object Type=Query|Service Name=Power BI Sales List|Object ID=55|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 57', 'Object Type=Query|Service Name=Power BI Top Cust. Overview|Object ID=59|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 58', 'Object Type=Query|Service Name=Power BI Vend. Item Ledg. Ent.|Object ID=65|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 59', 'Object Type=Query|Service Name=Power BI Vendor Ledger Entries|Object ID=63|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 60', 'Object Type=Query|Service Name=Power BI Vendor List|Object ID=51|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 61', 'Object Type=Query|Service Name=Res.LedgerEntries|Object ID=269|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 62', 'Object Type=Query|Service Name=SegmentLines|Object ID=106|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Expect('Tenant Web Service row 63', 'Object Type=Query|Service Name=ValueEntries|Object ID=266|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_TenantWebService_08()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Tenant Web Service', 63, 9);
        Observer.Expect('Tenant Web Service id', '2000000168');
        Observer.Expect('Tenant Web Service row 64', 'Object Type=Query|Service Name=VendorLedgerEntries|Object ID=263|Published=Yes|ExcludeFieldsOutsideRepeater=No|ExcludeNonEditableFlowFields=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Count_TenantWebService()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: Integer;
    begin
        Id := TableIdByName('Tenant Web Service');
        Observer.Observe('id', Format(Id));
        RR.Open(Id);
        Observer.Observe('count', Format(RR.Count()));
        Observer.Expect('id', '2000000168');
        Observer.Expect('count', '64');
        Observer.Verify();
    end;
}
