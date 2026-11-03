// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own report 91230, table 91231 and test codeunit 91232
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the rows of the platform table Report Data Items for a report whose data items declare DataItemTableView = sorting(Number) order(ascending),
//   where(Code = const('')) and sorting(Code) order(descending) where(Code = filter(A*|B)): the name, the view text, the related table, the nesting and
//   FindSet through SetRange on the report id. And the platform table Tenant Report Layout, read by name through a RecordRef: its first 12 fields, and what Insert of a blank row
//   and of a row that names a report with an empty RDLC layout answers. The descending view with an ordinary sorting is pinned in handlers/TestReportMetadataColumns.al.
// BC versions: 27, 28, 29
table 91231 "LT SC Meta Row"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

report 91230 "LT SC Meta Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = MetaRdlc;

    dataset
    {
        dataitem(Ascending; Integer)
        {
            DataItemTableView = sorting(Number) order(ascending);
        }
        dataitem(EmptyCode; "LT SC Meta Row")
        {
            DataItemTableView = where(Code = const(''));
        }
        dataitem(Filtered; "LT SC Meta Row")
        {
            DataItemTableView = sorting(Code) order(descending) where(Code = filter('A*|B'));
        }
    }

    rendering
    {
        layout(MetaRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_19.rdlc';
            Caption = 'Metadata views layout';
        }
    }
}

codeunit 91232 "LT SC Report Metadata Views"
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

    [Test]
    procedure ReportDataItems_OrderAndWhereViews()
    var
        Observer: Codeunit "Probe Observer";
        Items: Record "Report Data Items";
        Found: Boolean;
    begin
        Items.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('count', Format(Items.Count()));
        Found := Items.FindSet();
        Observer.Observe('findset', Format(Found));
        if Found then
            repeat
                Observer.Observe('item ' + Items.Name, Format(Items."Data Item ID") + '|' + Format(Items."Related Table ID") + '|' + Format(Items."Indentation Level") + '|' + Items."Data Item Table View");
            until Items.Next() = 0;
        Observer.Expect('count', '3');
        Observer.Expect('findset', 'Yes');
        Observer.Expect('item EmptyCode', '57155483|91231|0|WHERE(Field1=0())');
        Observer.Expect('item Ascending', '1027492269|2000000026|0|SORTING(Field1) ORDER(0)');
        Observer.Expect('item Filtered', '1968063604|91231|0|SORTING(Field1) ORDER(1) WHERE(Field1=1(A*|B))');
        Observer.Verify();
    end;

    [Test]
    procedure TenantReportLayout_FreshTenant_FieldsAndInsert()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        TableId: Integer;
        Names: Text;
        i: Integer;
        Before: Integer;
    begin
        TableId := TableIdByName('Tenant Report Layout');
        RR.Open(TableId);
        Before := RR.Count();
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Number() <= 12 then
                Names += Format(FR.Number()) + ':' + FR.Name() + ':' + Format(FR.Type()) + ',';
        end;
        Observer.Observe('fields up to 12', Names);
        RR.Init();
        asserterror RR.Insert();
        // the text names the calling object, which differs between test runners: only the code is asserted
        Observer.Observe('insert blank code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('count unchanged after blank insert', Format(RR.Count() = Before));
        Clear(RR);
        RR.Open(TableId);
        RR.Init();
        RR.Field(1).Value := Report::"LT SC Meta Report";
        RR.Field(2).Value := 'LT SC Probe Layout';
        asserterror RR.Insert();
        Observer.ObserveError('insert with report id');
        Observer.Observe('count unchanged after insert with report id', Format(RR.Count() = Before));
        Observer.Expect('fields up to 12', '1:Report ID:Integer,2:Name:Text,5:App ID:GUID,3:Caption:Text,4:CaptionML:Text,6:Company Name:Text,7:Layout:Media,8:Layout Format:Option,9:Custom Type:GUID,10:MIME Type:Text,11:Description:Text,12:IsObsolete:Boolean,');
        Observer.Expect('insert blank code', 'AL:MetadataNotFound');
        Observer.Expect('count unchanged after blank insert', 'Yes');
        Observer.Expect('insert with report id|text', 'The current operation cannot be performed on an empty report layout of type RDLC for report 91230.');
        Observer.Expect('insert with report id|code', 'ReportLayoutValidation');
        Observer.Expect('count unchanged after insert with report id', 'Yes');
        Observer.Verify();
    end;
}
