// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73860 (log), table 73861, page 73862, codeunit 73863
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "List open" (Page reads after an action, and a list that ends inside its window, corpus bump 7)
// Facts: log of OnAfterGetRecord (R) and OnAfterGetCurrRecord (C) when a list page is opened through a TestPage over 0, 1, 2, 3, 4, 5, 10, 19, 20, 21 and 40 rows
// BC versions: 29 (27 and 28 by CI)

codeunit 73860 "LT PnF LO Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry;
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

table 73861 "LT PnF LO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73862 "LT PnF LO List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF LO Row";

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

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF LO Log";
    begin
        Log.Add('R');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF LO Log";
    begin
        Log.Add('C');
    end;
}

codeunit 73863 "LT PnF List Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT PnF LO Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Id := i;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure OpenCount(Rows: Integer; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF LO Log";
        P: TestPage "LT PnF LO List";
        Seq: Text;
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Seq := Log.Take();
        Observer.Observe(Name + '|seq', Seq);
        Observer.Observe(Name + '|reads', Format(StrLen(Seq) - StrLen(DelChr(Seq, '=', 'R'))));
        Observer.Observe(Name + '|curr', Format(StrLen(Seq) - StrLen(DelChr(Seq, '=', 'C'))));
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure ListOpen_SmallTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenCount(0, 'rows0', Observer);
        OpenCount(1, 'rows1', Observer);
        OpenCount(2, 'rows2', Observer);
        OpenCount(3, 'rows3', Observer);
        OpenCount(4, 'rows4', Observer);
        OpenCount(5, 'rows5', Observer);
        Observer.Expect('rows0|seq', '');
        Observer.Expect('rows0|reads', '0');
        Observer.Expect('rows0|curr', '0');
        Observer.Expect('rows1|seq', 'RRC');
        Observer.Expect('rows1|reads', '2');
        Observer.Expect('rows1|curr', '1');
        Observer.Expect('rows2|seq', 'RRRRC');
        Observer.Expect('rows2|reads', '4');
        Observer.Expect('rows2|curr', '1');
        Observer.Expect('rows3|seq', 'RRRRRC');
        Observer.Expect('rows3|reads', '5');
        Observer.Expect('rows3|curr', '1');
        Observer.Expect('rows4|seq', 'RRRRRRC');
        Observer.Expect('rows4|reads', '6');
        Observer.Expect('rows4|curr', '1');
        Observer.Expect('rows5|seq', 'RRRRRRRC');
        Observer.Expect('rows5|reads', '7');
        Observer.Expect('rows5|curr', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ListOpen_Window_Boundary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenCount(10, 'rows10', Observer);
        OpenCount(18, 'rows18', Observer);
        OpenCount(19, 'rows19', Observer);
        OpenCount(20, 'rows20', Observer);
        OpenCount(21, 'rows21', Observer);
        OpenCount(40, 'rows40', Observer);
        Observer.Expect('rows10|seq', 'RRRRRRRRRRRRC');
        Observer.Expect('rows10|reads', '12');
        Observer.Expect('rows10|curr', '1');
        Observer.Expect('rows18|seq', 'RRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('rows18|reads', '20');
        Observer.Expect('rows18|curr', '1');
        Observer.Expect('rows19|seq', 'RRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('rows19|reads', '21');
        Observer.Expect('rows19|curr', '1');
        Observer.Expect('rows20|seq', 'RRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('rows20|reads', '22');
        Observer.Expect('rows20|curr', '1');
        Observer.Expect('rows21|seq', 'RRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('rows21|reads', '22');
        Observer.Expect('rows21|curr', '1');
        Observer.Expect('rows40|seq', 'RRRRRRRRRRRRRRRRRRRRRRC');
        Observer.Expect('rows40|reads', '22');
        Observer.Expect('rows40|curr', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ListOpen_FilteredView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF LO Log";
        P: TestPage "LT PnF LO List";
        Seq: Text;
    begin
        Seed(30);
        Log.Take();
        P.OpenView();
        P.Filter.SetFilter(Id, '1..2');
        Seq := Log.Take();
        Observer.Observe('after_filter|seq', Seq);
        P.Close();
        Log.Take();
        Observer.Expect('after_filter|seq', 'RRRRRRRRRRRRRRRRRRRRRRCRRRRC');
        Observer.Verify();
    end;
}
