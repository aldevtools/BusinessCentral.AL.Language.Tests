// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (gap cycle 6, G6-02): column 25 "SourceTableTemporary" of Page Metadata (2000000138) for pages that declare the property true, false
//   (explicit), not at all, a page on a table with TableType = Temporary, a Card page with the property, and a page without a SourceTable;
//   the column through a FieldRef, as a filter (SetRange true/false), as the filter of a list page whose SourceTable is Page Metadata (the
//   shape of Data Search Setup (Lists)), and as the second argument of RecordRef.Open (the shape of Agent Impl. OpenSetupPageId). Also
//   column 29 "App ID" compared with the own app id. Neighbours: TestPageMetadataVirtualTable.al, TestPageMetadataProperties.al.
// BC versions: 27.5, 28.5, 29.0.

table 93202 "LT Y59 PM Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 93203 "LT Y59 PM TmpSrc"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 93201 "LT Y59 PM True"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 PM Src";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
            }
        }
    }
}

page 93202 "LT Y59 PM False"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 PM Src";
    SourceTableTemporary = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
            }
        }
    }
}

page 93203 "LT Y59 PM None"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 PM Src";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
            }
        }
    }
}

page 93204 "LT Y59 PM TmpTable"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 PM TmpSrc";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { }
            }
        }
    }
}

page 93205 "LT Y59 PM Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y59 PM Src";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { }
        }
    }
}

page 93206 "LT Y59 PM NoSrc"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Info; InfoText) { }
        }
    }

    var
        InfoText: Text;
}

page 93207 "LT Y59 PM List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Page Metadata";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ID; Rec.ID) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(ID, 93201, 93206);
        Rec.SetRange(SourceTableTemporary, false);
    end;
}

codeunit 93204 "LT Y59 PM Source Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fact(PageId: Integer): Text
    var
        PageMetadata: Record "Page Metadata";
        Module: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Module);
        if not PageMetadata.Get(PageId) then
            exit('not found');
        exit('temp=' + Format(PageMetadata.SourceTableTemporary) + ';source=' + Format(PageMetadata.SourceTable) + ';type=' + Format(PageMetadata.PageType) +
            ';own_app=' + Format(PageMetadata."App ID" = Module.Id()));
    end;

    [Test]
    procedure Y59_SourceTableTemporary_ByDeclaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('declared_true', Fact(Page::"LT Y59 PM True"));
        Observer.Observe('declared_false', Fact(Page::"LT Y59 PM False"));
        Observer.Observe('not_declared', Fact(Page::"LT Y59 PM None"));
        Observer.Observe('temporary_table', Fact(Page::"LT Y59 PM TmpTable"));
        Observer.Observe('card_true', Fact(Page::"LT Y59 PM Card"));
        Observer.Observe('no_source_table', Fact(Page::"LT Y59 PM NoSrc"));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_SourceTableTemporary_FieldRef()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"Page Metadata");
        RecRef.Field(1).SetRange(Page::"LT Y59 PM True");
        Observer.Observe('found', Format(RecRef.FindFirst()));
        FldRef := RecRef.Field(25);
        Observer.Observe('field_25', FldRef.Name + '|' + Format(FldRef.Type) + '|' + Format(FldRef.Class) + '|' + Format(FldRef.Value));
        FldRef := RecRef.Field(29);
        Observer.Observe('field_29', FldRef.Name + '|' + Format(FldRef.Type) + '|' + Format(FldRef.Class));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_SourceTableTemporary_Filter()
    var
        PageMetadata: Record "Page Metadata";
        Ids: Text;
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.SetRange(ID, 93201, 93206);
        PageMetadata.SetRange(SourceTableTemporary, true);
        Observer.Observe('count_true', Format(PageMetadata.Count()));
        if PageMetadata.FindSet() then
            repeat
                Ids += Format(PageMetadata.ID) + ';';
            until PageMetadata.Next() = 0;
        Observer.Observe('ids_true', Ids);
        Ids := '';
        PageMetadata.SetRange(SourceTableTemporary, false);
        Observer.Observe('count_false', Format(PageMetadata.Count()));
        if PageMetadata.FindSet() then
            repeat
                Ids += Format(PageMetadata.ID) + ';';
            until PageMetadata.Next() = 0;
        Observer.Observe('ids_false', Ids);
        Observer.Finish();
    end;

    [Test]
    procedure Y59_SourceTableTemporary_ListPageOnPageMetadata()
    var
        List: TestPage "LT Y59 PM List";
        Ids: Text;
        Rows: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        List.OpenView();
        if List.First() then
            repeat
                Rows += 1;
                Ids += List.ID.Value() + ';';
            until not List.Next();
        List.Close();
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('ids', Ids);
        Observer.Finish();
    end;

    [Test]
    procedure Y59_SourceTableTemporary_RecordRefOpen()
    var
        PageMetadata: Record "Page Metadata";
        Src: Record "LT Y59 PM Src";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Src.DeleteAll();
        PageMetadata.Get(Page::"LT Y59 PM True");
        RecRef.Open(PageMetadata.SourceTable, PageMetadata.SourceTableTemporary);
        Observer.Observe('true_is_temporary', Format(RecRef.IsTemporary()));
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Insert();
        RecRef.Close();
        Observer.Observe('true_rows_in_database', Format(Src.Count()));
        PageMetadata.Get(Page::"LT Y59 PM False");
        RecRef.Open(PageMetadata.SourceTable, PageMetadata.SourceTableTemporary);
        Observer.Observe('false_is_temporary', Format(RecRef.IsTemporary()));
        RecRef.Init();
        RecRef.Field(1).Value := 'B';
        RecRef.Insert();
        RecRef.Close();
        Observer.Observe('false_rows_in_database', Format(Src.Count()));
        Src.DeleteAll();
        Observer.Finish();
    end;
}
