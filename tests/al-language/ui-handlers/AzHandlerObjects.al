// Fixture objects of the AZ handler probes (corpus issue 652, writer AZ); the tests are in AzHandlerTests.al.

table 80620 "LT AZ Hnd Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Collects what code run under a handler or a report did; one owner: codeunit "LT AZ Handler Tests".
codeunit 80621 "LT AZ Hnd Log"
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

codeunit 80623 "LT AZ Hnd Confirm OnRun"
{
    trigger OnRun()
    begin
        Answer := Confirm('az confirm from onrun');
        Result := 'after confirm';
    end;

    var
        Answer: Boolean;
        Result: Text;

    procedure GetResult(): Text
    begin
        exit(Result + ' answer=' + Format(Answer));
    end;
}

report 80624 "LT AZ Hnd Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT AZ Hnd Row")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT AZ Hnd Log";
            begin
                Log.Add('row' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Tag; Tag) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    var
        Log: Codeunit "LT AZ Hnd Log";
    begin
        Log.Add('prereport tag=' + Tag);
    end;

    var
        Tag: Text[30];
}

page 80625 "LT AZ Hnd Card"
{
    PageType = Card;
    SourceTable = "LT AZ Hnd Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 80626 "LT AZ Hnd List"
{
    PageType = List;
    SourceTable = "LT AZ Hnd Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
