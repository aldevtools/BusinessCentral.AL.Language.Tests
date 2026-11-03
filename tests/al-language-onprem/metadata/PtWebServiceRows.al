// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem app only: the Web Service table (2000000076) has Scope = OnPrem, so a RecordRef from a Target = Cloud app cannot open it.
// Fixtures used: Probe Observer (69160)
// Probe: the columns and the rows of the Web Service table in a fresh tenant (issue 580 item 7). Object id 61281.
// Writer QX (Microsoft's DemoTool): System Application Web Service Management.CreateWebService and CreateTenantWebService on page 42.
// Writer RD (DemoTool round 2): CreateTenantWebService calls of Create Web Services on rows the fresh tenant has (no row changes), Published = false,
//   an empty name (the object name without spaces, a new row), a new name (a new row); Tenant Web Service Columns / OData counts unchanged.
// Writer RJ (DemoTool, CreateJobWebServices and CreateTenantWebServiceOData on page 89 "Job List" as 'Job List'): the columns and OData row the
//   calls add to the fresh row, GenerateSelectText and GenerateODataV3/V4FilterText of a page service with no Tenant Web Service Filter rows.

codeunit 61281 "LT PT Web Service Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    [Test]
    procedure WebService_Content()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Index: Integer;
    begin
        RR.Open(2000000076);
        Observer.Observe('columns', Columns(RR));
        Observer.Observe('count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Index += 1;
                Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
        Observer.Expect('columns', '3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('count', '17');
        Observer.Expect('row1', '3=Codeunit;9=CompanySetupService;6=1801;12=Yes;13=No;14=No;');
        Observer.Expect('row2', '3=Codeunit;9=ExchangeServiceSetup;6=5324;12=Yes;13=No;14=No;');
        Observer.Expect('row3', '3=Codeunit;9=PageActionProvider;6=2915;12=Yes;13=No;14=No;');
        Observer.Expect('row4', '3=Codeunit;9=SummaryProvider;6=2718;12=Yes;13=No;14=No;');
        Observer.Expect('row5', '3=Page;9=AccountantPortalActivityCues;6=1314;12=Yes;13=No;14=No;');
        Observer.Expect('row6', '3=Page;9=AccountantPortalFinanceCues;6=1315;12=Yes;13=No;14=No;');
        Observer.Expect('row7', '3=Page;9=AccountantPortalUserTasks;6=1316;12=Yes;13=No;14=No;');
        Observer.Expect('row8', '3=Page;9=powerbifinance;6=197;12=Yes;13=No;14=No;');
        Observer.Expect('row9', '3=Page;9=SalesOrder;6=42;12=Yes;13=No;14=No;');
        Observer.Expect('row10', '3=Page;9=UserTaskSetComplete;6=1170;12=Yes;13=No;14=No;');
        Observer.Expect('row11', '3=Query;9=DimensionSets;6=257;12=Yes;13=No;14=No;');
        Observer.Expect('row12', '3=Query;9=ItemSalesAndProfit;6=103;12=Yes;13=No;14=No;');
        Observer.Expect('row13', '3=Query;9=ItemSalesByCustomer;6=102;12=Yes;13=No;14=No;');
        Observer.Expect('row14', '3=Query;9=SalesDashboard;6=101;12=Yes;13=No;14=No;');
        Observer.Expect('row15', '3=Query;9=SalesOpportunities;6=105;12=Yes;13=No;14=No;');
        Observer.Expect('row16', '3=Query;9=SalesOrdersBySalesPerson;6=104;12=Yes;13=No;14=No;');
        Observer.Expect('row17', '3=Query;9=TopCustomerOverview;6=100;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    // ---- Writer QX (Microsoft's DemoTool, Create Web Services: WebServiceManagement.CreateWebService(Page, Page::"Sales Order", '', true)):
    // the Web Service and Tenant Web Service rows for page 42 before and after, the name an empty ObjectName gives, a second call, a named call. ----

    local procedure QxRowsFor(ObjectId: Integer): Text
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        Result: Text;
    begin
        WebService.SetRange("Object Type", WebService."Object Type"::Page);
        WebService.SetRange("Object ID", ObjectId);
        if WebService.FindSet() then
            repeat
                Result += 'ws[' + WebService."Service Name" + '|' + Format(WebService.Published) + ']';
            until WebService.Next() = 0;
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectId);
        if TenantWebService.FindSet() then
            repeat
                Result += 'tws[' + TenantWebService."Service Name" + '|' + Format(TenantWebService.Published) + ']';
            until TenantWebService.Next() = 0;
        exit(Result);
    end;

    local procedure QxCounts(): Text
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
    begin
        exit(Format(WebService.Count()) + '|' + Format(TenantWebService.Count()));
    end;

    [Test]
    procedure QX_CreateWebService_SalesOrderPage()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('counts before', QxCounts());
        Observer.Observe('page 42 before', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', true);
        Observer.Observe('counts after', QxCounts());
        Observer.Observe('page 42 after', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', false);
        Observer.Observe('page 42 after unpublished call', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', true);
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", 'LTQXSalesOrder', true);
        Observer.Observe('page 42 after named call', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateTenantWebService(WebService."Object Type"::Page, Page::"Sales Order", 'LTQXTenantSalesOrder', true);
        Observer.Observe('page 42 after tenant call', QxRowsFor(Page::"Sales Order"));
        Observer.Observe('counts end', QxCounts());
        WebService.SetFilter("Service Name", 'LTQX*');
        WebService.DeleteAll();
        TenantWebService.SetFilter("Service Name", 'LTQX*');
        TenantWebService.DeleteAll();
        Observer.Observe('counts cleaned', QxCounts());
        Observer.Expect('counts before', '17|64');
        Observer.Expect('page 42 before', 'ws[SalesOrder|Yes]');
        Observer.Expect('counts after', '17|64');
        Observer.Expect('page 42 after', 'ws[SalesOrder|Yes]');
        Observer.Expect('page 42 after unpublished call', 'ws[SalesOrder|No]');
        Observer.Expect('page 42 after named call', 'ws[LTQXSalesOrder|Yes]ws[SalesOrder|Yes]');
        Observer.Expect('page 42 after tenant call', 'ws[LTQXSalesOrder|Yes]ws[SalesOrder|Yes]tws[LTQXTenantSalesOrder|Yes]');
        Observer.Expect('counts end', '18|65');
        Observer.Expect('counts cleaned', '17|64');
        Observer.Verify();
    end;

    // ---- Writer RD (Microsoft's DemoTool, Create Web Services: CreateJobWebServices, CreateWorkflowWebhookWebServices and
    // CreateExcelTemplateWebServices call WebServiceManagement.CreateTenantWebService(Type, Id, Name, true) for rows the fresh tenant already
    // has): every Tenant Web Service row (all columns) before and after each group of calls, the Tenant Web Service Columns and OData
    // counts, a Published = false call, a call with a new name for the same page, and the rows after the test restored them. ----

    local procedure RdAllRows(): Text
    var
        RR: RecordRef;
        Result: Text;
    begin
        RR.Open(Database::"Tenant Web Service");
        if RR.FindSet() then
            repeat
                Result += Row(RR) + '#';
            until RR.Next() = 0;
        exit(Result);
    end;

    local procedure RdTenantRows(ObjectType: Option; ObjectId: Integer): Text
    var
        TenantWebService: Record "Tenant Web Service";
        RR: RecordRef;
        Result: Text;
    begin
        TenantWebService.SetRange("Object Type", ObjectType);
        TenantWebService.SetRange("Object ID", ObjectId);
        if TenantWebService.FindSet() then
            repeat
                RR.GetTable(TenantWebService);
                Result += '[' + Row(RR) + ']';
            until TenantWebService.Next() = 0;
        exit(Result);
    end;

    local procedure RdCounts(): Text
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        Columns: Record "Tenant Web Service Columns";
        OData: Record "Tenant Web Service OData";
    begin
        exit(Format(WebService.Count()) + '|' + Format(TenantWebService.Count()) + '|' + Format(Columns.Count()) + '|' + Format(OData.Count()));
    end;

    local procedure RdWorkflowWebhookCalls()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Sales Document Entity", 'salesDocuments', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Sales Document Line Entity", 'salesDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Purchase Document Entity", 'purchaseDocuments', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Purchase Document Line Entity", 'purchaseDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Sales Document Entity", 'workflowSalesDocuments', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Sales Document Line Entity", 'workflowSalesDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Purchase Document Entity", 'workflowPurchaseDocuments', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Purchase Document Line Entity", 'workflowPurchaseDocumentLines', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Gen. Journal Batch Entity", 'workflowGenJournalBatches', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Gen. Journal Line Entity", 'workflowGenJournalLines', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Workflow - Customer Entity", 'workflowCustomers', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Workflow - Item Entity", 'workflowItems', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Workflow - Vendor Entity", 'workflowVendors', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Workflow Webhook Subscriptions", 'workflowWebhookSubscriptions', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Codeunit, Codeunit::"Workflow Webhook Subscription", 'WorkflowActionResponse', true);
    end;

    local procedure RdExcelTemplateCalls()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Income Statement Entity", 'ExcelTemplateIncomeStatement', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Balance Sheet Entity", 'ExcelTemplateBalanceSheet', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Trial Balance Entity", 'ExcelTemplateTrialBalance', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Retained Earnings Entity", 'ExcelTemplateRetainedEarnings', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Cash Flow Statement Entity", 'ExcelTemplateCashFlowStatement', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Aged AR Entity", 'ExcelTemplateAgedAccountsReceivable', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Aged AP Entity", 'ExcelTemplateAgedAccountsPayable', true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::ExcelTemplateCompanyInfo, 'ExcelTemplateViewCompanyInformation', true);
    end;

    [Test]
    procedure RD_CreateTenantWebService_DemoToolCalls()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        Observer: Codeunit "Probe Observer";
        Before: Text;
    begin
        Before := RdAllRows();
        Observer.Observe('counts before', RdCounts());
        Observer.Observe('job list before', RdTenantRows(TenantWebService."Object Type"::Page, Page::"Job List"));
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", 'Job List', true);
        Observer.Observe('job list call: all rows unchanged', Format(RdAllRows() = Before));
        Observer.Observe('job list after', RdTenantRows(TenantWebService."Object Type"::Page, Page::"Job List"));
        Observer.Observe('counts after job list', RdCounts());
        RdWorkflowWebhookCalls();
        Observer.Observe('workflow calls: all rows unchanged', Format(RdAllRows() = Before));
        Observer.Observe('counts after workflow', RdCounts());
        RdExcelTemplateCalls();
        Observer.Observe('excel calls: all rows unchanged', Format(RdAllRows() = Before));
        Observer.Observe('counts after excel', RdCounts());
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", 'Job List', false);
        Observer.Observe('job list unpublished call', RdTenantRows(TenantWebService."Object Type"::Page, Page::"Job List"));
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", '', true);
        Observer.Observe('job list empty name call', RdTenantRows(TenantWebService."Object Type"::Page, Page::"Job List"));
        Observer.Observe('counts after empty name', RdCounts());
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", 'LTRDJobList', true);
        Observer.Observe('job list new name call', RdTenantRows(TenantWebService."Object Type"::Page, Page::"Job List"));
        Observer.Observe('counts after new name', RdCounts());
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", Page::"Job List");
        TenantWebService.SetFilter("Service Name", '<>%1', 'Job List');
        TenantWebService.DeleteAll();
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", 'Job List', true);
        Observer.Observe('restored: all rows as before', Format(RdAllRows() = Before));
        Observer.Observe('counts restored', RdCounts());
        Observer.Expect('counts before', '17|64|402|29');
        Observer.Expect('job list before', '[3=Page;9=Job List;6=89;12=Yes;13=No;14=No;]');
        Observer.Expect('job list call: all rows unchanged', 'Yes');
        Observer.Expect('job list after', '[3=Page;9=Job List;6=89;12=Yes;13=No;14=No;]');
        Observer.Expect('counts after job list', '17|64|402|29');
        Observer.Expect('workflow calls: all rows unchanged', 'Yes');
        Observer.Expect('counts after workflow', '17|64|402|29');
        Observer.Expect('excel calls: all rows unchanged', 'Yes');
        Observer.Expect('counts after excel', '17|64|402|29');
        Observer.Expect('job list unpublished call', '[3=Page;9=Job List;6=89;12=No;13=No;14=No;]');
        Observer.Expect('job list empty name call', '[3=Page;9=Job List;6=89;12=No;13=No;14=No;][3=Page;9=JobList;6=89;12=Yes;13=No;14=No;]');
        Observer.Expect('counts after empty name', '17|65|402|29');
        Observer.Expect('job list new name call', '[3=Page;9=Job List;6=89;12=No;13=No;14=No;][3=Page;9=JobList;6=89;12=Yes;13=No;14=No;][3=Page;9=LTRDJobList;6=89;12=Yes;13=No;14=No;]');
        Observer.Expect('counts after new name', '17|66|402|29');
        Observer.Expect('restored: all rows as before', 'Yes');
        Observer.Expect('counts restored', '17|64|402|29');
        Observer.Verify();
    end;

    // ---- Writer RJ (Microsoft's DemoTool, Create Web Services.CreateJobWebServices, CreateWebServices.Codeunit.al:125-142, and its
    // CreateTenantWebServiceOData, :198-210): the seven CreateTenantWebServiceColumnForPage calls for 'Job List', the OData row, GenerateSelectText,
    // then GenerateODataV3FilterText and GenerateODataV4FilterText of that page service (no Tenant Web Service Filter rows; the query case is
    // RJ_CreateSegmentWebService_FilterTexts in lt-qx-dotnet/QxDotNetDemoShapes.al). The test then removes what it added. ----

    local procedure RjFindOData(var OData: Record "Tenant Web Service OData"; Id: RecordId): Boolean
    begin
        OData.Reset();
        OData.SetRange(TenantWebServiceID, Id);
        exit(OData.FindFirst());
    end;

    local procedure RjRowsOf(Id: RecordId; FromEntry: Integer): Text
    var
        Columns: Record "Tenant Web Service Columns";
        OData: Record "Tenant Web Service OData";
        Filters: Record "Tenant Web Service Filter";
        Result: Text;
    begin
        Columns.SetRange(TenantWebServiceID, Id);
        Result := 'columns ' + Format(Columns.Count());
        Columns.SetFilter("Entry ID", '>%1', FromEntry);
        Result += ' new ' + Format(Columns.Count()) + ':';
        if Columns.FindSet() then
            repeat
                Result += '[' + Format(Columns."Data Item") + '|' + Format(Columns."Field Number") + '|' + Columns."Field Name" + '|' + Format(Columns.Include) + ']';
            until Columns.Next() = 0;
        OData.SetRange(TenantWebServiceID, Id);
        Filters.SetRange(TenantWebServiceID, Id);
        exit(Result + ' odata ' + Format(OData.Count()) + ' filters ' + Format(Filters.Count()));
    end;

    local procedure RjClauses(var OData: Record "Tenant Web Service OData"): Text
    var
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        exit('[' + WebServiceManagement.GetODataSelectClause(OData) + '][' + WebServiceManagement.GetODataFilterClause(OData) + '][' +
          WebServiceManagement.GetODataV4FilterClause(OData) + ']');
    end;

    [Test]
    procedure RJ_CreateJobWebServices_PageFilterTexts()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        Columns: Record "Tenant Web Service Columns";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        Observer: Codeunit "Probe Observer";
        Before: Text;
        SelectText: Text;
        ODataV3FilterText: Text;
        ODataV4FilterText: Text;
        OldSelect: Text;
        OldV3: Text;
        OldV4: Text;
        MaxEntry: Integer;
        ODataExisted: Boolean;
        Ok: Boolean;
    begin
        Before := RdAllRows();
        Observer.Observe('counts before', RdCounts());
        TenantWebService.Get(TenantWebService."Object Type"::Page, 'Job List');
        Columns.SetCurrentKey("Entry ID");
        if Columns.FindLast() then
            MaxEntry := Columns."Entry ID";
        Observer.Observe('rows before', RjRowsOf(TenantWebService.RecordId, MaxEntry));
        ODataExisted := RjFindOData(TenantWebServiceOData, TenantWebService.RecordId);
        if ODataExisted then begin
            Observer.Observe('clauses before', RjClauses(TenantWebServiceOData));
            OldSelect := WebServiceManagement.GetODataSelectClause(TenantWebServiceOData);
            OldV3 := WebServiceManagement.GetODataFilterClause(TenantWebServiceOData);
            OldV4 := WebServiceManagement.GetODataV4FilterClause(TenantWebServiceOData);
        end;

        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Page, Page::"Job List", 'Job List', true);
        TenantWebService.Get(TenantWebService."Object Type"::Page, 'Job List');
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 1, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 3, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 5, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 19, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 20, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 2, Database::Job);
        WebServiceManagement.CreateTenantWebServiceColumnForPage(TenantWebService.RecordId, 1036, Database::Job);
        Observer.Observe('rows after columns', RjRowsOf(TenantWebService.RecordId, MaxEntry));

        TenantWebServiceOData.Init();
        TenantWebServiceOData.TenantWebServiceID := TenantWebService.RecordId;
        Observer.Observe('odata insert', Format(TenantWebServiceOData.Insert()));
        Ok := ODataUtility.GenerateSelectText(TenantWebService."Service Name", TenantWebService."Object Type", SelectText);
        Observer.Observe('select ok', Format(Ok));
        WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
        TenantWebServiceOData.Modify();
        Ok := ODataUtility.GenerateODataV3FilterText(TenantWebService."Service Name", TenantWebService."Object Type", ODataV3FilterText);
        Observer.Observe('v3 ok', Format(Ok));
        if not Ok then
            Observer.Observe('v3 error', GetLastErrorText());
        Ok := ODataUtility.GenerateODataV4FilterText(TenantWebService."Service Name", TenantWebService."Object Type", ODataV4FilterText);
        Observer.Observe('v4 ok', Format(Ok));
        if not Ok then
            Observer.Observe('v4 error', GetLastErrorText());
        Observer.Observe('select text', '[' + SelectText + ']');
        Observer.Observe('v3 text', '[' + ODataV3FilterText + ']');
        Observer.Observe('v4 text', '[' + ODataV4FilterText + ']');
        RjFindOData(TenantWebServiceOData, TenantWebService.RecordId);
        Observer.Observe('clauses after', RjClauses(TenantWebServiceOData));
        Observer.Observe('rows after', RjRowsOf(TenantWebService.RecordId, MaxEntry));
        Observer.Observe('counts after', RdCounts());

        Columns.Reset();
        Columns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Columns.SetFilter("Entry ID", '>%1', MaxEntry);
        Columns.DeleteAll();
        if ODataExisted then begin
            WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, OldSelect);
            WebServiceManagement.SetODataFilterClause(TenantWebServiceOData, OldV3);
            WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, OldV4);
            TenantWebServiceOData.Modify();
        end else
            TenantWebServiceOData.Delete();
        Observer.Observe('restored: all rows as before', Format(RdAllRows() = Before));
        Observer.Observe('counts restored', RdCounts());
        // The fresh tenant already has 'Job List' with 14 columns (the seven fields twice) and an OData row: the calls add seven columns, the
        // OData Insert fails, GenerateSelectText lists every column row, and both filter texts of a page service without filter rows are empty.
        Observer.Expect('counts before', '17|64|402|29');
        Observer.Expect('rows before', 'columns 14 new 0: odata 1 filters 0');
        Observer.Expect('clauses before', '[$select=No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager,No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager][][]');
        Observer.Expect('rows after columns', 'columns 21 new 7:[167|1|No|Yes][167|3|Description|Yes][167|5|Bill_to_Customer_No|Yes][167|19|Status|Yes][167|20|Person_Responsible|Yes][167|2|Search_Description|Yes][167|1036|Project_Manager|Yes] odata 1 filters 0');
        Observer.Expect('odata insert', 'No');
        Observer.Expect('select ok', 'Yes');
        Observer.Expect('v3 ok', 'Yes');
        Observer.Expect('v4 ok', 'Yes');
        Observer.Expect('select text', '[$select=No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager,No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager,No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager]');
        Observer.Expect('v3 text', '[]');
        Observer.Expect('v4 text', '[]');
        Observer.Expect('clauses after', '[$select=No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager,No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager,No,Description,Bill_to_Customer_No,Status,Person_Responsible,Search_Description,Project_Manager][][]');
        Observer.Expect('rows after', 'columns 21 new 7:[167|1|No|Yes][167|3|Description|Yes][167|5|Bill_to_Customer_No|Yes][167|19|Status|Yes][167|20|Person_Responsible|Yes][167|2|Search_Description|Yes][167|1036|Project_Manager|Yes] odata 1 filters 0');
        Observer.Expect('counts after', '17|64|409|29');
        Observer.Expect('restored: all rows as before', 'Yes');
        Observer.Expect('counts restored', '17|64|402|29');
        Observer.Verify();
    end;
}
