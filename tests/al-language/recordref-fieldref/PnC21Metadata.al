// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Rpt (71083), LT PnC Rpt Req (71088), LT PnC Qry (71093), LT PnC Qry Agg (71094)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: Report Data Items "Data Item ID is the item's position times ten; Sorting Fields; Data Item Table View"; Report Metadata "UseRequestPage defaults to true, ProcessingOnly to false"; Query Metadata "a query that is not an API query has blank API columns"; Page Action "Action Index and Action ID both count from 1"; Key, Field "rows of a table"; XmlPort Metadata Encoding "A left-out Encoding reads UTF16; a declared one reads the member of the column it names"
// BC versions: 29 (27 and 28 by CI)

codeunit 71137 "LT PnC Meta Helper"
{
    // Observes the named columns of the current row of RR (a name that is not a column reads nofield) as Prefix.<name>.
    procedure DumpNamed(var RR: RecordRef; Names: Text; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Parts: List of [Text];
        Part: Text;
        FR: FieldRef;
        i: Integer;
        Found: Boolean;
    begin
        Parts := Names.Split(',');
        foreach Part in Parts do begin
            Found := false;
            for i := 1 to RR.FieldCount() do begin
                FR := RR.FieldIndex(i);
                if FR.Name = Part then begin
                    Observer.Observe(Prefix + '.' + Part, Format(FR.Value));
                    Found := true;
                end;
            end;
            if not Found then
                Observer.Observe(Prefix + '.' + Part, 'nofield');
        end;
    end;

    procedure FieldNames(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Result += Format(FR.Number) + '=' + FR.Name + ',';
        end;
        exit(Result);
    end;
}

report 71140 "LT PnC Rpt Items"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(A; "LT PnC Rec")
        {
            DataItemTableView = sorting("No.") order(descending);
        }
        dataitem(B; "LT PnC Rec")
        {
            DataItemTableView = sorting(Name, "Code Value");
        }
        dataitem(C; "LT PnC Rec")
        {
            DataItemTableView = where(Name = const('x'));
        }
        dataitem(D; "LT PnC Rec")
        {
            DataItemTableView = sorting("No.") order(descending) where(Name = const('y'));
        }
        dataitem(E; "LT PnC Rec")
        {
            DataItemTableView = where(Other = filter(1 .. 5));
        }
    }
}

page 71141 "LT PnC Actions"
{
    PageType = Card;
    SourceTable = "LT PnC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(First)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
            group(Grouped)
            {
                action(Second)
                {
                    ApplicationArea = All;
                    RunObject = page "LT PnC Card";
                }
                action(Third)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
            }
            action(Fourth)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
        area(Navigation)
        {
            action(Nav)
            {
                ApplicationArea = All;
                RunObject = page "LT PnC List";
            }
        }
        area(Promoted)
        {
            actionref(First_Promoted; First) { }
        }
    }
}

xmlport 71142 "LT PnC XP Enc None"
{
    UseRequestPage = false;

    schema
    {
        textelement(Root) { }
    }
}

xmlport 71143 "LT PnC XP Enc UTF8"
{
    UseRequestPage = false;
    Encoding = UTF8;

    schema
    {
        textelement(Root) { }
    }
}

xmlport 71144 "LT PnC XP Enc UTF16"
{
    UseRequestPage = false;
    Encoding = UTF16;

    schema
    {
        textelement(Root) { }
    }
}

codeunit 71138 "LT PnC Meta Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReportDataItems_Columns()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        Items: Record "Report Data Items";
        RR: RecordRef;
        n: Integer;
    begin
        Items.SetRange("Report ID", 71140);
        RR.GetTable(Items);
        Observer.Observe('columns', Helper.FieldNames(RR));
        Observer.Observe('count', Format(Items.Count()));
        if Items.FindSet() then
            repeat
                n += 1;
                RR.GetTable(Items);
                Helper.DumpNamed(RR, 'Name,Data Item ID,Sorting Fields,Data Item Table View', 'item' + Format(n), Observer);
            until (Items.Next() = 0) or (n = 5);
        Observer.Expect('columns', '1=Report ID,2=Data Item ID,3=Name,4=Request Filter Fields,5=Related Table ID,6=Indentation Level,7=Sorting Fields,8=Data Item Table View,');
        Observer.Expect('count', '5');
        Observer.Expect('item1.Name', 'D');
        Observer.Expect('item1.Data Item ID', '120712215');
        Observer.Expect('item1.Sorting Fields', '1');
        Observer.Expect('item1.Data Item Table View', 'SORTING(Field1) ORDER(1) WHERE(Field2=0(y))');
        Observer.Expect('item2.Name', 'B');
        Observer.Expect('item2.Data Item ID', '589499809');
        Observer.Expect('item2.Sorting Fields', '2,3');
        Observer.Expect('item2.Data Item Table View', 'SORTING(Field2,Field3)');
        Observer.Expect('item3.Name', 'E');
        Observer.Expect('item3.Data Item ID', '758408832');
        Observer.Expect('item3.Sorting Fields', '');
        Observer.Expect('item3.Data Item Table View', 'WHERE(Field5=1(1..5))');
        Observer.Expect('item4.Name', 'C');
        Observer.Expect('item4.Data Item ID', '1227196426');
        Observer.Expect('item4.Sorting Fields', '');
        Observer.Expect('item4.Data Item Table View', 'WHERE(Field2=0(x))');
        Observer.Expect('item5.Name', 'A');
        Observer.Expect('item5.Data Item ID', '1792377636');
        Observer.Expect('item5.Sorting Fields', '1');
        Observer.Expect('item5.Data Item Table View', 'SORTING(Field1) ORDER(1)');
        Observer.Verify();
    end;

    [Test]
    procedure ReportDataItems_Link_And_Nesting()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        Items: Record "Report Data Items";
        RR: RecordRef;
        n: Integer;
    begin
        Items.SetRange("Report ID", 71083);
        Observer.Observe('count', Format(Items.Count()));
        if Items.FindSet() then
            repeat
                n += 1;
                RR.GetTable(Items);
                Helper.DumpNamed(RR, 'Name,Data Item ID,Indentation Level,Related Table ID', 'item' + Format(n), Observer);
            until Items.Next() = 0;
        Observer.Expect('count', '2');
        Observer.Expect('item1.Name', 'Kid');
        Observer.Expect('item1.Data Item ID', '1167510851');
        Observer.Expect('item1.Indentation Level', '1');
        Observer.Expect('item1.Related Table ID', '71081');
        Observer.Expect('item2.Name', 'Src');
        Observer.Expect('item2.Data Item ID', '1369927887');
        Observer.Expect('item2.Indentation Level', '0');
        Observer.Expect('item2.Related Table ID', '71080');
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure ReportMetadata_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        Meta: Record "Report Metadata";
        RR: RecordRef;
    begin
        RR.GetTable(Meta);
        Observer.Observe('columns', Helper.FieldNames(RR));
        Meta.SetRange(ID, 71083);
        Observer.Observe('noRequestPage.found', Format(Meta.FindFirst()));
        RR.GetTable(Meta);
        Helper.DumpNamed(RR, 'Name,UseRequestPage,ProcessingOnly,Caption', 'noRequestPage', Observer);
        Meta.SetRange(ID, 71088);
        Observer.Observe('requestPage.found', Format(Meta.FindFirst()));
        RR.GetTable(Meta);
        Helper.DumpNamed(RR, 'Name,UseRequestPage,ProcessingOnly,Caption', 'requestPage', Observer);
        Meta.SetRange(ID, 71140);
        Observer.Observe('items.found', Format(Meta.FindFirst()));
        RR.GetTable(Meta);
        Helper.DumpNamed(RR, 'Name,UseRequestPage,ProcessingOnly', 'items', Observer);
        Observer.Expect('columns', '1=ID,2=Name,3=Caption,4=UseRequestPage,5=UseSystemPrinter,6=EnableExternalImages,7=EnableHyperLinks,8=EnableExternalAssemblies,9=ProcessingOnly,10=ShowPrintStatus,11=TransactionType,12=PaperSourceFirstPage,13=PaperSourceDefaultPage,14=PaperSourceLastPage,15=PreviewMode,16=DefaultLayout,17=WordMergeDataItem,18=FirstDataItemTableID,19=MaxRows,20=MaxDocuments,21=Timeout,22=AllowScheduling,23=DefaultLayoutName,24=FormatRegion,25=ExcelLayoutMultipleDataSheets,26=App ID,27=InherentPermissions,28=InherentEntitlements,29=AL Namespace,30=DefaultHeaderFooterPartName,31=DefaultThemePartName,');
        Observer.Expect('noRequestPage.found', 'Yes');
        Observer.Expect('noRequestPage.Name', 'LT PnC Rpt');
        Observer.Expect('noRequestPage.UseRequestPage', 'No');
        Observer.Expect('noRequestPage.ProcessingOnly', 'Yes');
        Observer.Expect('noRequestPage.Caption', 'LT PnC Rpt');
        Observer.Expect('requestPage.found', 'Yes');
        Observer.Expect('requestPage.Name', 'LT PnC Rpt Req');
        Observer.Expect('requestPage.UseRequestPage', 'Yes');
        Observer.Expect('requestPage.ProcessingOnly', 'Yes');
        Observer.Expect('requestPage.Caption', 'LT PnC Rpt Req');
        Observer.Expect('items.found', 'Yes');
        Observer.Expect('items.Name', 'LT PnC Rpt Items');
        Observer.Expect('items.UseRequestPage', 'No');
        Observer.Expect('items.ProcessingOnly', 'Yes');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure QueryMetadata_NonApi()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        Meta: Record "Query Metadata";
        RR: RecordRef;
    begin
        RR.GetTable(Meta);
        Observer.Observe('columns', Helper.FieldNames(RR));
        Meta.SetRange(ID, 71093);
        Observer.Observe('found', Format(Meta.FindFirst()));
        RR.GetTable(Meta);
        Helper.DumpNamed(RR, 'Name,APIPublisher,APIGroup,APIVersion,EntityName,EntitySetName,QueryType', 'qry', Observer);
        Meta.SetRange(ID, 71094);
        Observer.Observe('agg.found', Format(Meta.FindFirst()));
        RR.GetTable(Meta);
        Helper.DumpNamed(RR, 'Name,APIPublisher,APIVersion,EntityName,EntitySetName', 'agg', Observer);
        Observer.Expect('columns', '1=ID,2=Name,3=Caption,4=APIPublisher,5=APIGroup,6=APIVersion,7=EntitySetName,8=EntityName,9=Category,10=App ID,11=InherentPermissions,12=InherentEntitlements,13=AL Namespace,');
        Observer.Expect('found', 'Yes');
        Observer.Expect('qry.Name', 'LT PnC Qry');
        Observer.Expect('qry.APIPublisher', '');
        Observer.Expect('qry.APIGroup', '');
        Observer.Expect('qry.APIVersion', '');
        Observer.Expect('qry.EntityName', '');
        Observer.Expect('qry.EntitySetName', '');
        Observer.Expect('qry.QueryType', 'nofield');
        Observer.Expect('agg.found', 'Yes');
        Observer.Expect('agg.Name', 'LT PnC Qry Agg');
        Observer.Expect('agg.APIPublisher', '');
        Observer.Expect('agg.APIVersion', '');
        Observer.Expect('agg.EntityName', '');
        Observer.Expect('agg.EntitySetName', '');
        Observer.Verify();
    end;
#endif
}

codeunit 71139 "LT PnC Meta Page Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageAction_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        PgAct: Record "Page Action";
        RR: RecordRef;
        n: Integer;
    begin
        RR.GetTable(PgAct);
        Observer.Observe('columns', Helper.FieldNames(RR));
        PgAct.SetRange("Page ID", 71141);
        Observer.Observe('count', Format(PgAct.Count()));
        if PgAct.FindSet() then
            repeat
                n += 1;
                RR.GetTable(PgAct);
                Helper.DumpNamed(RR, 'Name,Action Index,Action ID,Parent Action ID', 'row' + Format(n), Observer);
            until (PgAct.Next() = 0) or (n = 5);
        Observer.Expect('columns', '1=Page ID,2=Action Index,3=Action ID,4=Indentation,5=Parent Action ID,6=Action Type,7=Action Subtype,8=Name,9=Caption,10=ToolTip1,11=ToolTip2,12=ToolTip3,13=ToolTip4,14=Promoted,15=RunObjectType,16=RunObjectID,17=RunPageMode,18=RunSourceTable,19=ApplicationArea,');
        Observer.Expect('count', '32');
        Observer.Expect('row1.Name', '');
        Observer.Expect('row1.Action Index', '0');
        Observer.Expect('row1.Action ID', '496156356');
        Observer.Expect('row1.Parent Action ID', '0');
        Observer.Expect('row2.Name', 'First');
        Observer.Expect('row2.Action Index', '1');
        Observer.Expect('row2.Action ID', '611647077');
        Observer.Expect('row2.Parent Action ID', '496156356');
        Observer.Expect('row3.Name', 'Grouped');
        Observer.Expect('row3.Action Index', '2');
        Observer.Expect('row3.Action ID', '1240675217');
        Observer.Expect('row3.Parent Action ID', '496156356');
        Observer.Expect('row4.Name', 'Second');
        Observer.Expect('row4.Action Index', '3');
        Observer.Expect('row4.Action ID', '1754896199');
        Observer.Expect('row4.Parent Action ID', '1240675217');
        Observer.Expect('row5.Name', 'Third');
        Observer.Expect('row5.Action Index', '4');
        Observer.Expect('row5.Action ID', '1192222076');
        Observer.Expect('row5.Parent Action ID', '1240675217');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Key_Rows_Of_Own_Table()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        K: Record "Key";
        RR: RecordRef;
        n: Integer;
    begin
        RR.GetTable(K);
        Observer.Observe('columns', Helper.FieldNames(RR));
        K.SetRange(TableNo, 71080);
        Observer.Observe('count', Format(K.Count()));
        if K.FindSet() then
            repeat
                n += 1;
                RR.GetTable(K);
                Helper.DumpNamed(RR, 'No.,Key,Enabled,Clustered', 'key' + Format(n), Observer);
            until (K.Next() = 0) or (n = 4);
        Observer.Expect('columns', '1=TableNo,2=No.,3=TableName,4=Key,5=SumIndexFields,6=SQLIndex,7=Enabled,8=MaintainSQLIndex,9=MaintainSIFTIndex,10=Clustered,11=ObsoleteState,12=ObsoleteReason,13=Unique,14=Key name,15=Source App ID,');
        Observer.Expect('count', '4');
        Observer.Expect('key1.No.', '1');
        Observer.Expect('key1.Key', 'No.');
        Observer.Expect('key1.Enabled', 'Yes');
        Observer.Expect('key1.Clustered', 'Yes');
        Observer.Expect('key2.No.', '2');
        Observer.Expect('key2.Key', 'Name');
        Observer.Expect('key2.Enabled', 'Yes');
        Observer.Expect('key2.Clustered', 'No');
        Observer.Expect('key3.No.', '3');
        Observer.Expect('key3.Key', 'Code Value,Amount');
        Observer.Expect('key3.Enabled', 'Yes');
        Observer.Expect('key3.Clustered', 'No');
        Observer.Expect('key4.No.', '4');
        Observer.Expect('key4.Key', '$systemId');
        Observer.Expect('key4.Enabled', 'Yes');
        Observer.Expect('key4.Clustered', 'No');
        Observer.Verify();
    end;
#endif

#if BC29PLUS
    [Test]
    procedure Field_Rows_Of_Own_Table()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        F: Record "Field";
        RR: RecordRef;
        n: Integer;
    begin
        RR.GetTable(F);
        Observer.Observe('columns', Helper.FieldNames(RR));
        F.SetRange(TableNo, 71081);
        Observer.Observe('count', Format(F.Count()));
        if F.FindSet() then
            repeat
                n += 1;
                RR.GetTable(F);
                Helper.DumpNamed(RR, 'No.,FieldName,Type,Len,Class', 'field' + Format(n), Observer);
            until (F.Next() = 0) or (n = 3);
        Observer.Expect('columns', '1=TableNo,2=No.,3=TableName,4=FieldName,5=Type,6=Len,7=Class,8=Enabled,9=Type Name,10=ExternalName,20=Field Caption,21=RelationTableNo,22=RelationFieldNo,23=SQLDataType,24=OptionString,25=ObsoleteState,26=ObsoleteReason,27=DataClassification,28=IsPartOfPrimaryKey,60=App Package ID,61=App Runtime Package ID,62=OptimizeForTextSearch,63=Access,64=IsAllowedInCustomizations,');
        Observer.Expect('count', '11');
        Observer.Expect('field1.No.', '1');
        Observer.Expect('field1.FieldName', 'Entry No.');
        Observer.Expect('field1.Type', 'Integer');
        Observer.Expect('field1.Len', '4');
        Observer.Expect('field1.Class', 'Normal');
        Observer.Expect('field2.No.', '2');
        Observer.Expect('field2.FieldName', 'Parent No.');
        Observer.Expect('field2.Type', 'Integer');
        Observer.Expect('field2.Len', '4');
        Observer.Expect('field2.Class', 'Normal');
        Observer.Expect('field3.No.', '2000000000');
        Observer.Expect('field3.FieldName', '$systemId');
        Observer.Expect('field3.Type', 'GUID');
        Observer.Expect('field3.Len', '16');
        Observer.Expect('field3.Class', 'Normal');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure XmlPortMetadata_Encoding()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PnC Meta Helper";
        Meta: Record "XmlPort Metadata";
        RR: RecordRef;
        Ids: List of [Integer];
        Id: Integer;
    begin
        RR.GetTable(Meta);
        Observer.Observe('columns', Helper.FieldNames(RR));
        Ids.Add(71142);
        Ids.Add(71143);
        Ids.Add(71144);
        Ids.Add(71098);
        foreach Id in Ids do begin
            Meta.SetRange(ID, Id);
            if Meta.FindFirst() then begin
                RR.GetTable(Meta);
                Helper.DumpNamed(RR, 'Name,Encoding', 'xp' + Format(Id), Observer);
            end else
                Observer.Observe('xp' + Format(Id), 'notfound');
        end;
        Observer.Expect('columns', '1=ID,2=Name,3=Caption,4=UseRequestPage,5=TransactionType,6=Direction,7=Encoding,8=TextEncoding,9=Format,10=App ID,11=InherentPermissions,12=InherentEntitlements,13=AL Namespace,');
        Observer.Expect('xp71142.Name', 'LT PnC XP Enc None');
        Observer.Expect('xp71142.Encoding', 'UTF16');
        Observer.Expect('xp71143.Name', 'LT PnC XP Enc UTF8');
        Observer.Expect('xp71143.Encoding', 'UTF8');
        Observer.Expect('xp71144.Name', 'LT PnC XP Enc UTF16');
        Observer.Expect('xp71144.Encoding', 'UTF16');
        Observer.Expect('xp71098.Name', 'LT PnC XP Container');
        Observer.Expect('xp71098.Encoding', 'UTF16');
        Observer.Verify();
    end;
#endif
}
