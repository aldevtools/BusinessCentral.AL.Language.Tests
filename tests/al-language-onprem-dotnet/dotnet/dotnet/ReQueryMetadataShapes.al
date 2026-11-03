// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; System Application (Web Service Management, DotNet aliases
//   QueryMetadataReader and QueryFields), Base Application (codeunit ODataUtility); self-contained tables 99415, 99416, query 99417, test codeunit 99418
// Probe (writer RE, Microsoft's DemoTool, Create Web Services): ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData) of a query
//   that has a FlowField column, a nested data item and a Method = Count column: the entries of MetaData.Fields() (FieldNo, TableNo, FieldName,
//   in order), and the Tenant Web Service Columns rows WebServiceManagement.CreateTenantWebServiceColumnForQuery gives for each column.
//   One data item with normal fields is pinned in lt-qx-dotnet/QxDotNetDemoShapes.al (QX_QueryMetadataReader_TenantWebServiceColumns).
// Writer RJ (DemoTool on BC 29): MetaData.Fields() of Method = Sum, Count, Average, Min and Max columns (queries 60760 and 86175 of the main
//   app) and of Base Application's query 51 "Power BI Vendor List".
// BC versions: 27, 28, 29
table 99415 "LT RE QM Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Line Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT RE QM Line".Amount where("Header Id" = field(Id)));
        }
        field(4; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RE QM Line" where("Header Id" = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 99416 "LT RE QM Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header Id"; Integer) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Header Id", "Line No.") { Clustered = true; }
    }
}

query 99417 "LT RE QM Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Head; "LT RE QM Header")
        {
            column(HeadId; Id) { }
            column(HeadName; Name) { }
            column(LineTotal; "Line Total") { }
            column(LineCountFlow; "Line Count") { }
            dataitem(Line; "LT RE QM Line")
            {
                DataItemLink = "Header Id" = Head.Id;
                column(LineDescription; Description) { }
                column(LineAmount; Amount) { }
                column(Lines)
                {
                    Method = Count;
                }
            }
        }
    }
}

codeunit 99418 "LT RE Query Metadata Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FieldsText(MetaData: DotNet QueryMetadataReader): Text
    var
        QueryField: DotNet QueryFields;
        Result: Text;
        i: Integer;
    begin
        for i := 0 to MetaData.Fields().Count() - 1 do begin
            QueryField := MetaData.Fields().Item(i);
            Result += '[' + Format(QueryField.FieldNo()) + '|' + Format(QueryField.TableNo()) + '|' + QueryField.FieldName() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure RE_QueryMetadataReader_FlowFieldNestedCount()
    var
        TenantWebService: Record "Tenant Web Service";
        Columns: Record "Tenant Web Service Columns";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUtility: Codeunit ODataUtility;
        Observer: Codeunit "Probe Observer";
        MetaData: DotNet QueryMetadataReader;
        Result: Text;
    begin
        TenantWebService.SetFilter("Service Name", 'LTRE*');
        TenantWebService.DeleteAll(true);
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Query, Query::"LT RE QM Query", 'LTREQuery', true);
        Observer.Observe('get', Format(TenantWebService.Get(TenantWebService."Object Type"::Query, 'LTREQuery')));
        ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData);
        Observer.Observe('metadata is null', Format(IsNull(MetaData)));
        if not IsNull(MetaData) then begin
            Observer.Observe('fields count', Format(MetaData.Fields().Count()));
            Observer.Observe('fields', FieldsText(MetaData));
        end;
        // The calls Microsoft's DemoTool makes: one per column, field number and data item table; 0 = the Method = Count column, 9 = no column.
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 1, Database::"LT RE QM Header", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 2, Database::"LT RE QM Header", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 3, Database::"LT RE QM Header", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 4, Database::"LT RE QM Header", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 4, Database::"LT RE QM Line", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 3, Database::"LT RE QM Line", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 0, Database::"LT RE QM Line", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 1, Database::"LT RE QM Line", MetaData);
        WebServiceManagement.CreateTenantWebServiceColumnForQuery(TenantWebService.RecordId, 9, Database::"LT RE QM Header", MetaData);
        Columns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        if Columns.FindSet() then
            repeat
                Result += '[' + Format(Columns."Data Item") + '|' + Format(Columns."Field Number") + '|' + Columns."Field Name" + '|' + Format(Columns.Include) + ']';
            until Columns.Next() = 0;
        Observer.Observe('columns', Result);
        Columns.DeleteAll();
        TenantWebService.Delete(true);
        Observer.Expect('get', 'Yes');
        Observer.Expect('metadata is null', 'No');
        Observer.Expect('fields count', '7');
        // One entry per column in query order: the FlowField columns carry their field number, the nested data item's columns its table,
        // the Method = Count column field number 0; FieldName is the column name.
        Observer.Expect('fields', '[1|99415|HeadId][2|99415|HeadName][3|99415|LineTotal][4|99415|LineCountFlow][4|99416|LineDescription][3|99416|LineAmount][0|99416|Lines]');
        // A field with no column (1 of the line table, 9 of the header) still gets a row, with a blank Field Name.
        Observer.Expect('columns', '[99415|1|HeadId|Yes][99415|2|HeadName|Yes][99415|3|LineTotal|Yes][99415|4|LineCountFlow|Yes][99416|4|LineDescription|Yes][99416|3|LineAmount|Yes][99416|0|Lines|Yes][99416|1||Yes][99415|9||Yes]');
        Observer.Verify();
    end;

    // ---- Writer RJ (Microsoft's DemoTool, Create Web Services.CreatePowerBITenantWebServices and the other query web services): the entries
    // of MetaData.Fields() for query columns with Method = Sum, Count, Average, Min and Max next to a plain column (query 60760 "QJ Order Sum",
    // one data item), the same methods on a nested data item (query 86175), and Base Application's query 51 "Power BI Vendor List" (ReverseSign
    // columns, a FlowField, a nested data item), read the way ODataUtility.GetTenantWebServiceMetadata reads them (no Tenant Web Service row). ----

    local procedure RjFieldsOf(QueryId: Integer): Text
    var
        TenantWebService: Record "Tenant Web Service";
        ODataUtility: Codeunit ODataUtility;
        MetaData: DotNet QueryMetadataReader;
    begin
        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Query;
        TenantWebService."Object ID" := QueryId;
        ODataUtility.GetTenantWebServiceMetadata(TenantWebService, MetaData);
        if IsNull(MetaData) then
            exit('null');
        exit(Format(MetaData.Fields().Count()) + ':' + FieldsText(MetaData));
    end;

    [Test]
    procedure RJ_QueryMetadataReader_AggregateMethods()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('one data item', RjFieldsOf(60760));
        Observer.Observe('nested data item', RjFieldsOf(86175));
        Observer.Observe('query 51', RjFieldsOf(51));
        // Sum, Average, Min and Max columns carry the field number of their source field and the table of their data item, like a plain column;
        // the Method = Count column has field number 0. FieldName is the column name. ReverseSign and FlowField columns are plain entries.
        Observer.Expect('one data item', '6:[2|60862|CustNo][3|60862|TotalAmount][0|60862|CountAmount][3|60862|AverageAmount][3|60862|MinAmount][3|60862|MaxAmount]');
        Observer.Expect('nested data item', '5:[1|74054|DocNo][4|74055|SumKind][4|74055|AvgKind][4|74055|MinKind][4|74055|MaxKind]');
        Observer.Expect('query 51', '10:[1|23|Vendor_No][2|23|Vendor_Name][66|23|Balance_Due][4|380|Posting_Date][36|380|Applied_Vend_Ledger_Entry_No][7|380|Amount][8|380|Amount_LCY][13|380|Transaction_No][1|380|Entry_No][39|380|Remaining_Pmt_Disc_Possible]');
        Observer.Verify();
    end;
}
