// Fixtures of the "LT CU" probes (corpus #670, odd AL behavior leads part E, items 31-45).
// Scope: in-scope
// Not test codeunits. Each object is used only by the LT CU test codeunits in this folder.

table 85300 "LT CU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Name = 'commit-in-oninsert' then
            Commit();
    end;

    trigger OnModify()
    begin
        if Name = 'commit-in-onmodify' then
            Commit();
    end;
}

table 85301 "LT CU Other"
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

page 85302 "LT CU Row List"
{
    PageType = List;
    SourceTable = "LT CU Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }
}

// Inserts row 100 and ends normally.
codeunit 85303 "LT CU Inserter"
{
    trigger OnRun()
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := 100;
        Row.Name := 'by run';
        Row.Insert();
    end;
}

// Inserts row 101, then fails.
codeunit 85304 "LT CU Failing Inserter"
{
    trigger OnRun()
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := 101;
        Row.Name := 'by failing run';
        Row.Insert();
        Error('failing run');
    end;
}

codeunit 85305 "LT CU TableNo Run"
{
    TableNo = "LT CU Row";

    trigger OnRun()
    begin
        Rec.Name := 'set by OnRun';
    end;
}

// Processing-only report with a request page. OnPreReport inserts row 900 as the sign that the report ran.
report 85306 "LT CU Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT CU Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnPreReport()
    var
        Marker: Record "LT CU Row";
    begin
        Marker.Id := 900;
        Marker.Name := 'report ran';
        Marker.Insert();
    end;

    var
        Note: Text;
}

// Manual subscriber: commits inside OnAfterInsertEvent of LT CU Row when the row's name asks for it.
codeunit 85307 "LT CU Commit Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT CU Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure CommitOnAfterInsert(var Rec: Record "LT CU Row"; RunTrigger: Boolean)
    begin
        if Rec.Name = 'commit-in-sub' then
            Commit();
    end;
}
