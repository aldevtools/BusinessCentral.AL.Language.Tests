// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope; platform tables opened by RecordRef or by record variable in a Cloud app.
// Fixtures used: Probe Observer (69160), LT PT Ops and LT PT Arg (PtHelper.al); own codeunits 67514, 67517 and 67518. The Web Service table (2000000076) is Scope = OnPrem and is probed in tests/al-language-onprem/platform/PtWebServiceRows.al.
// Probe: the columns and rows of NAV App Setting (2000000201) and Tenant Web Service (2000000168) in a fresh tenant, and Insert, Modify, Delete and a get-or-insert pattern on NAV App Setting from an extension (issue 580 items 3 and 7).
// BC versions: 27+

codeunit 67514 "LT PT Services Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

    local procedure Columns(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + ':' + FR.Name + ':' + Format(FR.Type) + ':' + Format(FR.Length) + ':' + Format(FR.Class) + ';';
        end;
        exit(Result);
    end;

    local procedure Row(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + '=' + Format(FR.Value) + ';';
        end;
        exit(Result);
    end;

    local procedure Content(var Observer: Codeunit "Probe Observer"; TableNo: Integer)
    var
        RR: RecordRef;
    begin
        RR.Open(TableNo);
        Observer.Observe('columns', Columns(RR));
        Observer.Observe('count', Format(RR.Count()));
    end;

    local procedure Rows(var Observer: Codeunit "Probe Observer"; TableNo: Integer; FromRow: Integer; ToRow: Integer)
    var
        RR: RecordRef;
        Index: Integer;
    begin
        RR.Open(TableNo);
        if RR.FindSet() then
            repeat
                Index += 1;
                if (Index >= FromRow) and (Index <= ToRow) then
                    Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
    end;

    [Test]
    procedure NavAppSetting_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000201);
        Observer.Expect('columns', '1:App ID:GUID:16:Normal;2:Allow HttpClient Requests:Boolean:4:Normal;');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Content(Observer, 2000000168);
        Observer.Expect('columns', '3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('count', '64');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Rows_1_To_15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Rows(Observer, 2000000168, 1, 15);
        Observer.Expect('row1', '3=Codeunit;9=WorkflowActionResponse;6=1544;12=Yes;13=No;14=No;');
        Observer.Expect('row2', '3=Page;9=Chart of Accounts;6=16;12=Yes;13=No;14=No;');
        Observer.Expect('row3', '3=Page;9=ExcelTemplateAgedAccountsPayable;6=5500;12=Yes;13=No;14=No;');
        Observer.Expect('row4', '3=Page;9=ExcelTemplateAgedAccountsReceivable;6=5499;12=Yes;13=No;14=No;');
        Observer.Expect('row5', '3=Page;9=ExcelTemplateBalanceSheet;6=5501;12=Yes;13=No;14=No;');
        Observer.Expect('row6', '3=Page;9=ExcelTemplateCashFlowStatement;6=5493;12=Yes;13=No;14=No;');
        Observer.Expect('row7', '3=Page;9=ExcelTemplateIncomeStatement;6=5503;12=Yes;13=No;14=No;');
        Observer.Expect('row8', '3=Page;9=ExcelTemplateRetainedEarnings;6=5497;12=Yes;13=No;14=No;');
        Observer.Expect('row9', '3=Page;9=ExcelTemplateTrialBalance;6=5502;12=Yes;13=No;14=No;');
        Observer.Expect('row10', '3=Page;9=ExcelTemplateViewCompanyInformation;6=1320;12=Yes;13=No;14=No;');
        Observer.Expect('row11', '3=Page;9=Job List;6=89;12=Yes;13=No;14=No;');
        Observer.Expect('row12', '3=Page;9=Job Planning Lines;6=1007;12=Yes;13=No;14=No;');
        Observer.Expect('row13', '3=Page;9=Job Task Lines;6=1002;12=Yes;13=No;14=No;');
        Observer.Expect('row14', '3=Page;9=Power BI Aged Acc. Payable;6=6307;12=Yes;13=No;14=No;');
        Observer.Expect('row15', '3=Page;9=Power BI Aged Acc. Receivable;6=6308;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Rows_16_To_30()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Rows(Observer, 2000000168, 16, 30);
        Observer.Expect('row16', '3=Page;9=Power BI Aged Inventory Chart;6=6309;12=Yes;13=No;14=No;');
        Observer.Expect('row17', '3=Page;9=Power BI Job Act. v. Budg. Cost;6=6312;12=Yes;13=No;14=No;');
        Observer.Expect('row18', '3=Page;9=Power BI Job Act. v. Budg. Price;6=6310;12=Yes;13=No;14=No;');
        Observer.Expect('row19', '3=Page;9=Power BI Job Profitability;6=6311;12=Yes;13=No;14=No;');
        Observer.Expect('row20', '3=Page;9=Power BI Sales Pipeline;6=6314;12=Yes;13=No;14=No;');
        Observer.Expect('row21', '3=Page;9=Power BI Top 5 Opportunities;6=6315;12=Yes;13=No;14=No;');
        Observer.Expect('row22', '3=Page;9=Power BI WorkDate Calc.;6=6313;12=Yes;13=No;14=No;');
        Observer.Expect('row23', '3=Page;9=purchaseDocumentLines;6=6405;12=Yes;13=No;14=No;');
        Observer.Expect('row24', '3=Page;9=purchaseDocuments;6=6404;12=Yes;13=No;14=No;');
        Observer.Expect('row25', '3=Page;9=salesDocumentLines;6=6403;12=Yes;13=No;14=No;');
        Observer.Expect('row26', '3=Page;9=salesDocuments;6=6402;12=Yes;13=No;14=No;');
        Observer.Expect('row27', '3=Page;9=workflowCustomers;6=6408;12=Yes;13=No;14=No;');
        Observer.Expect('row28', '3=Page;9=workflowGenJournalBatches;6=6406;12=Yes;13=No;14=No;');
        Observer.Expect('row29', '3=Page;9=workflowGenJournalLines;6=6407;12=Yes;13=No;14=No;');
        Observer.Expect('row30', '3=Page;9=workflowItems;6=6409;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Rows_31_To_45()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Rows(Observer, 2000000168, 31, 45);
        Observer.Expect('row31', '3=Page;9=workflowPurchaseDocumentLines;6=6405;12=Yes;13=No;14=No;');
        Observer.Expect('row32', '3=Page;9=workflowPurchaseDocuments;6=6404;12=Yes;13=No;14=No;');
        Observer.Expect('row33', '3=Page;9=workflowSalesDocumentLines;6=6403;12=Yes;13=No;14=No;');
        Observer.Expect('row34', '3=Page;9=workflowSalesDocuments;6=6402;12=Yes;13=No;14=No;');
        Observer.Expect('row35', '3=Page;9=workflowVendors;6=6410;12=Yes;13=No;14=No;');
        Observer.Expect('row36', '3=Page;9=workflowWebhookSubscriptions;6=831;12=Yes;13=No;14=No;');
        Observer.Expect('row37', '3=Query;9=BankAccountLedgerEntries;6=264;12=Yes;13=No;14=No;');
        Observer.Expect('row38', '3=Query;9=Cust.LedgerEntries;6=262;12=Yes;13=No;14=No;');
        Observer.Expect('row39', '3=Query;9=DimensionSetEntries;6=260;12=Yes;13=No;14=No;');
        Observer.Expect('row40', '3=Query;9=FALedgerEntries;6=267;12=Yes;13=No;14=No;');
        Observer.Expect('row41', '3=Query;9=G/LBudgetEntries;6=270;12=Yes;13=No;14=No;');
        Observer.Expect('row42', '3=Query;9=G/LEntries;6=261;12=Yes;13=No;14=No;');
        Observer.Expect('row43', '3=Query;9=ItemLedgerEntries;6=265;12=Yes;13=No;14=No;');
        Observer.Expect('row44', '3=Query;9=JobLedgerEntries;6=268;12=Yes;13=No;14=No;');
        Observer.Expect('row45', '3=Query;9=Power BI Cust. Item Ledg. Ent.;6=61;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Rows_46_To_60()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Rows(Observer, 2000000168, 46, 60);
        Observer.Expect('row46', '3=Query;9=Power BI Cust. Ledger Entries;6=62;12=Yes;13=No;14=No;');
        Observer.Expect('row47', '3=Query;9=Power BI Customer List;6=50;12=Yes;13=No;14=No;');
        Observer.Expect('row48', '3=Query;9=Power BI GL Amount List;6=53;12=Yes;13=No;14=No;');
        Observer.Expect('row49', '3=Query;9=Power BI GL BudgetedAmount;6=58;12=Yes;13=No;14=No;');
        Observer.Expect('row50', '3=Query;9=Power BI Item Purchase List;6=52;12=Yes;13=No;14=No;');
        Observer.Expect('row51', '3=Query;9=Power BI Item Sales List;6=57;12=Yes;13=No;14=No;');
        Observer.Expect('row52', '3=Query;9=Power BI Jobs List;6=54;12=Yes;13=No;14=No;');
        Observer.Expect('row53', '3=Query;9=Power BI Purchase Hdr. Vendor;6=64;12=Yes;13=No;14=No;');
        Observer.Expect('row54', '3=Query;9=Power BI Purchase List;6=56;12=Yes;13=No;14=No;');
        Observer.Expect('row55', '3=Query;9=Power BI Sales Hdr. Cust.;6=60;12=Yes;13=No;14=No;');
        Observer.Expect('row56', '3=Query;9=Power BI Sales List;6=55;12=Yes;13=No;14=No;');
        Observer.Expect('row57', '3=Query;9=Power BI Top Cust. Overview;6=59;12=Yes;13=No;14=No;');
        Observer.Expect('row58', '3=Query;9=Power BI Vend. Item Ledg. Ent.;6=65;12=Yes;13=No;14=No;');
        Observer.Expect('row59', '3=Query;9=Power BI Vendor Ledger Entries;6=63;12=Yes;13=No;14=No;');
        Observer.Expect('row60', '3=Query;9=Power BI Vendor List;6=51;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Rows_61_To_64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Rows(Observer, 2000000168, 61, 64);
        Observer.Expect('row61', '3=Query;9=Res.LedgerEntries;6=269;12=Yes;13=No;14=No;');
        Observer.Expect('row62', '3=Query;9=SegmentLines;6=106;12=Yes;13=No;14=No;');
        Observer.Expect('row63', '3=Query;9=ValueEntries;6=266;12=Yes;13=No;14=No;');
        Observer.Expect('row64', '3=Query;9=VendorLedgerEntries;6=263;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;
}

codeunit 67518 "LT PT Nas Mutations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

    local procedure Clean()
    begin
        Ops.Perform(2000000201, 'deleteall', '', false);
    end;

    local procedure Standard(var Observer: Codeunit "Probe Observer"; TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    begin
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', FilterRequest, true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_no_triggers', Ops.Perform(TableNo, 'insert', InsertRequest, false));
        Observer.Observe('modify_no_triggers', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', FilterRequest, false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', FilterRequest, false));
    end;

    [Test]
    procedure NavAppSetting_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Standard(Observer, 2000000201, '1=11111111-2222-3333-4444-555555555555;2=true', '1=11111111-2222-3333-4444-555555555555', '2=false');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=<guid>;2=Yes;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=<guid>;2=No;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('modify_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure NavAppSetting_SeveralRowsAndBlankGuid()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        Clean();
        T := 2000000201;
        Observer.Observe('insert_one', Ops.Perform(T, 'insert', '1=11111111-2222-3333-4444-555555555551;2=true', true));
        Observer.Observe('insert_two', Ops.Perform(T, 'insert', '1=11111111-2222-3333-4444-555555555552;2=true', true));
        Observer.Observe('count_both', Ops.Perform(T, 'count', '2=true', false));
        Observer.Observe('insert_blank_guid', Ops.Perform(T, 'insert', '1=00000000-0000-0000-0000-000000000000;2=true', true));
        Observer.Observe('count_after_blank_guid', Ops.Perform(T, 'count', '', false));
        Observer.Expect('insert_one', 'ok:Yes');
        Observer.Expect('insert_two', 'ok:Yes');
        Observer.Expect('count_both', 'ok:2');
        Observer.Expect('insert_blank_guid', 'ok:Yes');
        Observer.Expect('count_after_blank_guid', 'ok:3');
        Observer.Verify();
    end;

    [Test]
    procedure NavAppSetting_GetOrInsert()
    var
        Observer: Codeunit "Probe Observer";
        Arg: Record "LT PT Arg" temporary;
    begin
        Clean();
        Arg.Init();
        Arg.Id := 1;
        Arg.Insert();
        Observer.Observe('first_call', RunText(Arg, 'getorinsert'));
        Observer.Observe('second_call', RunText(Arg, 'getorinsert'));
        Observer.Expect('first_call', 'ok:existed=No allow=Yes count=1');
        Observer.Expect('second_call', 'ok:existed=Yes allow=Yes count=1');
        Observer.Verify();
    end;

    [Test]
    procedure NavAppSetting_TypedBulkOperations()
    var
        Observer: Codeunit "Probe Observer";
        Arg: Record "LT PT Arg" temporary;
    begin
        Clean();
        Arg.Init();
        Arg.Id := 1;
        Arg.Insert();
        Observer.Observe('insert_one', Ops.Perform(2000000201, 'insert', '1=11111111-2222-3333-4444-555555555551;2=true', true));
        Observer.Observe('insert_two', Ops.Perform(2000000201, 'insert', '1=11111111-2222-3333-4444-555555555552;2=true', true));
        Observer.Observe('count', RunText(Arg, 'count'));
        Observer.Observe('modify_all', RunText(Arg, 'modifyall'));
        Observer.Observe('delete_all_false', RunText(Arg, 'deleteall_false'));
        Observer.Observe('insert_again', Ops.Perform(2000000201, 'insert', '1=11111111-2222-3333-4444-555555555551;2=true', true));
        Observer.Observe('delete_all_true', RunText(Arg, 'deleteall_true'));
        Observer.Observe('insert_third', Ops.Perform(2000000201, 'insert', '1=11111111-2222-3333-4444-555555555553;2=true', true));
        Observer.Observe('delete_all_default', RunText(Arg, 'deleteall'));
        Observer.Expect('insert_one', 'ok:Yes');
        Observer.Expect('insert_two', 'ok:Yes');
        Observer.Expect('count', 'ok:2');
        Observer.Expect('modify_all', 'ok:done false-count=2');
        Observer.Expect('delete_all_false', 'ok:done count=0');
        Observer.Expect('insert_again', 'ok:Yes');
        Observer.Expect('delete_all_true', 'ok:done count=0');
        Observer.Expect('insert_third', 'ok:Yes');
        Observer.Expect('delete_all_default', 'ok:done count=0');
        Observer.Verify();
    end;

    local procedure RunText(var Arg: Record "LT PT Arg" temporary; Op: Text): Text
    begin
        ClearLastError();
        Arg.Op := CopyStr(Op, 1, MaxStrLen(Arg.Op));
        if not Codeunit.Run(Codeunit::"LT PT Nas Runner", Arg) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok:' + Arg.Result);
    end;

}

// Typed-record operations on NAV App Setting, chosen by Rec.Op: getorinsert (Get by the app id, insert when missing, read back), deleteall, deleteall_false,
// deleteall_true, modifyall, count. Not a test codeunit.
codeunit 67517 "LT PT Nas Runner"
{
    TableNo = "LT PT Arg";

    trigger OnRun()
    var
        Setting: Record "NAV App Setting";
        AppId: Guid;
        Existed: Boolean;
    begin
        case Rec.Op of
            'getorinsert':
                begin
                    Evaluate(AppId, '11111111-2222-3333-4444-555555555556');
                    Existed := Setting.Get(AppId);
                    if not Existed then begin
                        Setting.Init();
                        Setting."App ID" := AppId;
                        Setting."Allow HttpClient Requests" := true;
                        Setting.Insert(true);
                    end;
                    Setting.Get(AppId);
                    Rec.Result := 'existed=' + Format(Existed) + ' allow=' + Format(Setting."Allow HttpClient Requests") + ' count=' + Format(Setting.Count());
                end;
            'deleteall':
                begin
                    Setting.DeleteAll();
                    Rec.Result := 'done count=' + Format(Setting.Count());
                end;
            'deleteall_false':
                begin
                    Setting.DeleteAll(false);
                    Rec.Result := 'done count=' + Format(Setting.Count());
                end;
            'deleteall_true':
                begin
                    Setting.DeleteAll(true);
                    Rec.Result := 'done count=' + Format(Setting.Count());
                end;
            'modifyall':
                begin
                    Setting.ModifyAll("Allow HttpClient Requests", false);
                    Setting.SetRange("Allow HttpClient Requests", false);
                    Rec.Result := 'done false-count=' + Format(Setting.Count());
                end;
            'count':
                Rec.Result := Format(Setting.Count());
        end;
    end;
}
