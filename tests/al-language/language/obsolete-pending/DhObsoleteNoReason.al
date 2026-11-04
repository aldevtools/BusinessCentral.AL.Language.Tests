// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (corpus issue 663 item 7): ObsoleteState = Pending with ObsoleteReason or ObsoleteTag (or both) left out, on a table, page, query, report and
// permission set. It compiles; using such an object from code only gives the warning AL0432 "Table 'x' is marked for removal. " (empty reason; a
// warning, so it cannot be a must-not-compile case). The objects still work. Object ids 86080-86086.

table 86080 "LT DH Obs NoReason Table"
{
    DataClassification = SystemMetadata;
    ObsoleteState = Pending;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { ObsoleteState = Pending; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 86081 "LT DH Obs NoTag Card"
{
    PageType = Card;
    SourceTable = "LT DH Obs NoReason Table";
    ApplicationArea = All;
    UsageCategory = None;
    ObsoleteState = Pending;
    ObsoleteReason = 'Reason without a tag.';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

query 86082 "LT DH Obs NoReason Query"
{
    QueryType = Normal;
    ObsoleteState = Pending;
    ObsoleteTag = '1.0';

    elements
    {
        dataitem(Source; "LT DH Obs NoReason Table")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

report 86083 "LT DH Obs NoReason Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    ObsoleteState = Pending;

    dataset
    {
        dataitem(Source; "LT DH Obs NoReason Table")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT DH Obs NoReason Log";
            begin
                Log.Add(Format(Source.Id));
            end;
        }
    }
}

permissionset 86084 "LT DH Obs NoTag PS"
{
    Assignable = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Reason without a tag.';
    Permissions = tabledata "LT DH Obs NoReason Table" = RI;
}

codeunit 86085 "LT DH Obs NoReason Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 86086 "LT DH Obs NoReason Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT DH Obs NoReason Table";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    [Test]
    procedure PendingNoReason_TableAndField_ReadWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DH Obs NoReason Table";
    begin
        Seed();
        Row.Get(2);
        Row.Name := 'changed';
        Row.Modify();
        Row.Get(2);
        Observer.Observe('name_after_modify', Row.Name);
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('name_after_modify', 'changed');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PendingNoTag_Page_TestPageReadsAndWrites()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DH Obs NoReason Table";
        Pg: TestPage "LT DH Obs NoTag Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Observer.Observe('page_name', Pg.Name.Value);
        Pg.Name.SetValue('edited');
        Pg.Close();
        Row.Get(1);
        Observer.Observe('stored_name', Row.Name);
        Observer.Expect('page_name', 'one');
        Observer.Expect('stored_name', 'edited');
        Observer.Verify();
    end;

    [Test]
    procedure PendingNoReason_Query_OpensAndReads()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT DH Obs NoReason Query";
        Rows: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.Id) + '=' + Q.Name + ';';
        Q.Close();
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', '1=one;2=two;');
        Observer.Verify();
    end;

    [Test]
    procedure PendingNoReason_Report_Runs()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DH Obs NoReason Log";
    begin
        Seed();
        Log.Take();
        Report.Run(Report::"LT DH Obs NoReason Report");
        Observer.Observe('report_rows', Log.Take());
        Observer.Expect('report_rows', '1;2;');
        Observer.Verify();
    end;

    [Test]
    procedure PendingNoTag_PermissionSet_Metadata()
    var
        Observer: Codeunit "Probe Observer";
        Declared: Record "Metadata Permission";
        Grant: Text;
    begin
        Declared.SetRange("Role ID", 'LT DH OBS NOTAG PS');
        Declared.SetRange("Object Type", Declared."Object Type"::"Table Data");
        Declared.SetRange("Object ID", Database::"LT DH Obs NoReason Table");
        if Declared.FindFirst() then
            Grant := 'R=' + Format(Declared."Read Permission") + ' I=' + Format(Declared."Insert Permission") + ' M=' + Format(Declared."Modify Permission")
        else
            Grant := 'no row';
        Observer.Observe('grant', Grant);
        Observer.Observe('rows', Format(Declared.Count()));
        Observer.Expect('grant', 'R=Yes I=Yes M= ');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}
