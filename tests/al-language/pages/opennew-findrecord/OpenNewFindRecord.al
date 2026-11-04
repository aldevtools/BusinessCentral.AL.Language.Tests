// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-opennew-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74458, enum 74459, pages 74460 and 74461, log 74462, test codeunit 74463
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage.OpenNew on a card and on a list whose OnFindRecord writes its Which to a trace, on an empty table and on a table with rows: the trace of OnFindRecord, OnNewRecord and OnOpenPage calls, xRec in OnNewRecord and the key shown on the first row.
// BC versions: 29 (27 and 28 by CI)

table 74458 "LT ON Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Kind; Enum "LT ON Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 74459 "LT ON Kind"
{
    Extensible = true;

    value(0; Alpha) { Caption = 'Alpha Caption'; }
    value(1; Beta) { Caption = 'Beta Caption'; }
}

codeunit 74462 "LT ON Log"
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

page 74460 "LT ON Card"
{
    PageType = Card;
    SourceTable = "LT ON Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('Card.OnOpenPage');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('Card.OnFindRecord(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('Card.OnNewRecord xrec=' + Format(xRec.Id) + ' below=' + Format(BelowxRec));
    end;
}

page 74461 "LT ON List"
{
    PageType = List;
    SourceTable = "LT ON Row";
    ApplicationArea = All;
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

    trigger OnOpenPage()
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('List.OnOpenPage');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('List.OnFindRecord(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        L: Codeunit "LT ON Log";
    begin
        L.Add('List.OnNewRecord xrec=' + Format(xRec.Id) + ' below=' + Format(BelowxRec));
    end;
}

codeunit 74463 "LT OpenNew FindRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithRows: Boolean)
    var
        Row: Record "LT ON Row";
    begin
        Row.DeleteAll();
        if not WithRows then
            exit;
        Row.Id := 10; Row.Name := 'ten'; Row.Insert();
        Row.Id := 20; Row.Name := 'twenty'; Row.Insert();
    end;

    [Test]
    procedure Card_OpenNew_EmptyTable()
    var
        Card: TestPage "LT ON Card";
        L: Codeunit "LT ON Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        L.Take();
        Card.OpenNew();
        Observer.Observe('trace', L.Take());
        Observer.Observe('id', Card.Id.Value);
        Card.Close();
        Observer.Observe('close_trace', L.Take());
        Observer.Expect('trace', 'Card.OnOpenPage;Card.OnNewRecord xrec=0 below=Yes;');
        Observer.Expect('id', '0');
        Observer.Expect('close_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_TableWithRows()
    var
        Card: TestPage "LT ON Card";
        L: Codeunit "LT ON Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        L.Take();
        Card.OpenNew();
        Observer.Observe('trace', L.Take());
        Observer.Observe('id', Card.Id.Value);
        Card.Close();
        Observer.Observe('close_trace', L.Take());
        Observer.Expect('trace', 'Card.OnOpenPage;Card.OnNewRecord xrec=20 below=Yes;');
        Observer.Expect('id', '0');
        Observer.Expect('close_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenNew_EmptyTable()
    var
        List: TestPage "LT ON List";
        L: Codeunit "LT ON Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        L.Take();
        List.OpenNew();
        Observer.Observe('trace', L.Take());
        Observer.Observe('id', List.Id.Value);
        List.Close();
        Observer.Observe('close_trace', L.Take());
        Observer.Expect('trace', 'List.OnOpenPage;List.OnNewRecord xrec=0 below=Yes;');
        Observer.Expect('id', '0');
        Observer.Expect('close_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenNew_TableWithRows()
    var
        List: TestPage "LT ON List";
        L: Codeunit "LT ON Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        L.Take();
        List.OpenNew();
        Observer.Observe('trace', L.Take());
        Observer.Observe('id', List.Id.Value);
        Observer.Observe('first_row_after_new', Format(List.First()));
        Observer.Observe('first_id', List.Id.Value);
        List.Close();
        Observer.Observe('close_trace', L.Take());
        Observer.Expect('trace', 'List.OnOpenPage;List.OnNewRecord xrec=20 below=Yes;');
        Observer.Expect('id', '0');
        Observer.Expect('first_row_after_new', 'No');
        Observer.Expect('first_id', '0');
        Observer.Expect('close_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenEdit_And_OpenView_TableWithRows()
    var
        Card: TestPage "LT ON Card";
        L: Codeunit "LT ON Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        L.Take();
        Card.OpenEdit();
        Observer.Observe('edit_trace', L.Take());
        Observer.Observe('edit_id', Card.Id.Value);
        Card.Close();
        L.Take();
        Card.OpenView();
        Observer.Observe('view_trace', L.Take());
        Card.Close();
        Observer.Expect('edit_trace', 'Card.OnOpenPage;Card.OnFindRecord(=><);');
        Observer.Expect('edit_id', '10');
        Observer.Expect('view_trace', 'Card.OnOpenPage;Card.OnFindRecord(=><);');
        Observer.Verify();
    end;
}
