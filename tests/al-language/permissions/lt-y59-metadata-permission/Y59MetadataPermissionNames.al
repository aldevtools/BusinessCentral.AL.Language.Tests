// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 6, G6-01a): the VALUE of the FlowField "Object Name" (column 6) of Metadata Permission (2000000251) for the rows of an own
//   permission set that names a table (as Table Data and as Table), a table without a Caption, a page, a codeunit, a report, a query and an
//   XmlPort: after CalcFields, without CalcFields, with SetAutoCalcFields, through a FieldRef, and as a filter. Also the values of column 3
//   "Role Name", 13 "Assignable" and 15 "AL Object Name" (FlowFields too) and 12 "Type". The System Application reads column 6 in
//   Permission Impl. GetObjectCaptionAndName. Neighbours: permissions/W6PermissionColumns.al (column metadata of 3, 13, 14, 15; own rows'
//   types and rights), permissions/TestMetadataExpandedPermission.al.
// BC versions: 27.5, 28.5, 29.0.

table 93200 "LT Y59 Cap Table"
{
    Caption = 'LT Y59 Table Caption';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93201 "LT Y59 NoCap Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 93200 "LT Y59 Cap Page"
{
    Caption = 'LT Y59 Page Caption';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 Cap Table";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

codeunit 93200 "LT Y59 Perm Codeunit"
{
    procedure Nothing()
    begin
    end;
}

report 93200 "LT Y59 Perm Report"
{
    Caption = 'LT Y59 Report Caption';
    ProcessingOnly = true;
    UsageCategory = None;
}

query 93200 "LT Y59 Perm Query"
{
    Caption = 'LT Y59 Query Caption';
    QueryType = Normal;

    elements
    {
        dataitem(CapTable; "LT Y59 Cap Table")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 93200 "LT Y59 Perm XmlPort"
{
    schema
    {
        textelement(Root) { }
    }
}

permissionset 93200 "LT Y59 PS Names"
{
    Assignable = true;
    Caption = 'LT Y59 PS Names Caption';
    Permissions =
        tabledata "LT Y59 Cap Table" = RIMD,
        table "LT Y59 Cap Table" = X,
        tabledata "LT Y59 NoCap Table" = R,
        page "LT Y59 Cap Page" = X,
        codeunit "LT Y59 Perm Codeunit" = X,
        report "LT Y59 Perm Report" = X,
        query "LT Y59 Perm Query" = X,
        xmlport "LT Y59 Perm XmlPort" = X;
}

codeunit 93201 "LT Y59 Metadata Perm Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OwnAppId(): Guid
    var
        Module: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Module);
        exit(Module.Id());
    end;

    local procedure FilterOwnSet(var MetadataPermission: Record "Metadata Permission")
    begin
        MetadataPermission.SetRange("App ID", OwnAppId());
        MetadataPermission.SetRange("Role ID", 'LT Y59 PS NAMES');
    end;

    local procedure RowKey(var MetadataPermission: Record "Metadata Permission"): Text
    begin
        exit(Format(MetadataPermission."Object Type") + ' ' + Format(MetadataPermission."Object ID"));
    end;

    [Test]
    procedure Y59_ObjectName_AfterCalcFields()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        FilterOwnSet(MetadataPermission);
        Observer.Observe('count', Format(MetadataPermission.Count()));
        if MetadataPermission.FindSet() then
            repeat
                MetadataPermission.CalcFields("Object Name");
                Observer.Observe(RowKey(MetadataPermission), MetadataPermission."Object Name");
            until MetadataPermission.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_ObjectName_WithoutCalcFields()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        FilterOwnSet(MetadataPermission);
        if MetadataPermission.FindSet() then
            repeat
                Observer.Observe(RowKey(MetadataPermission), '[' + MetadataPermission."Object Name" + ']');
            until MetadataPermission.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_ObjectName_SetAutoCalcFields()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        FilterOwnSet(MetadataPermission);
        MetadataPermission.SetAutoCalcFields("Object Name");
        if MetadataPermission.FindSet() then
            repeat
                Observer.Observe(RowKey(MetadataPermission), '[' + MetadataPermission."Object Name" + ']');
            until MetadataPermission.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_ObjectName_ObjectIdZero()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        // The SUPER permission set grants every object of a type with Object ID 0; only the first such row is read (no Microsoft counts).
        MetadataPermission.SetRange("Role ID", 'SUPER');
        MetadataPermission.SetRange("Object ID", 0);
        Observer.Observe('found', Format(MetadataPermission.FindFirst()));
        if MetadataPermission."Object ID" = 0 then begin
            Observer.Observe('object_type', Format(MetadataPermission."Object Type"));
            MetadataPermission.CalcFields("Object Name", "AL Object Name");
            Observer.Observe('object_name', '[' + MetadataPermission."Object Name" + ']');
            Observer.Observe('object_name_length', Format(StrLen(MetadataPermission."Object Name")));
            Observer.Observe('al_object_name', '[' + MetadataPermission."AL Object Name" + ']');
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_ObjectName_ThroughRecordRef_FieldRef()
    var
        MetadataPermission: Record "Metadata Permission";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"Metadata Permission");
        RecRef.Field(1).SetRange(OwnAppId());
        RecRef.Field(2).SetRange('LT Y59 PS NAMES');
        RecRef.Field(4).SetRange(MetadataPermission."Object Type"::Page);
        Observer.Observe('found', Format(RecRef.FindFirst()));
        FldRef := RecRef.Field(6);
        Observer.Observe('name', FldRef.Name);
        Observer.Observe('caption', FldRef.Caption);
        Observer.Observe('class', Format(FldRef.Class));
        Observer.Observe('type', Format(FldRef.Type));
        Observer.Observe('length', Format(FldRef.Length));
        Observer.Observe('value_before_calcfield', '[' + Format(FldRef.Value) + ']');
        FldRef.CalcField();
        Observer.Observe('value_after_calcfield', '[' + Format(FldRef.Value) + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Y59_OtherColumns_Values()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        FilterOwnSet(MetadataPermission);
        if MetadataPermission.FindSet() then
            repeat
                MetadataPermission.CalcFields("Role Name", Assignable, "AL Object Name");
                Observer.Observe(RowKey(MetadataPermission), 'Role Name=' + MetadataPermission."Role Name" + ';Assignable=' + Format(MetadataPermission.Assignable) +
                    ';AL Object Name=' + MetadataPermission."AL Object Name" + ';Type=' + Format(MetadataPermission.Type));
            until MetadataPermission.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_ObjectName_FilterOnFlowField()
    var
        MetadataPermission: Record "Metadata Permission";
        Observer: Codeunit "Probe Observer";
    begin
        FilterOwnSet(MetadataPermission);
        MetadataPermission.SetFilter("Object Name", '@lt y59 table*');
        Observer.Observe('count_table_caption', Format(MetadataPermission.Count()));
        MetadataPermission.SetFilter("Object Name", '*Caption');
        Observer.Observe('count_ends_caption', Format(MetadataPermission.Count()));
        MetadataPermission.SetRange("Object Name", 'LT Y59 NoCap Table');
        Observer.Observe('count_nocap_name', Format(MetadataPermission.Count()));
        Observer.Finish();
    end;
}
