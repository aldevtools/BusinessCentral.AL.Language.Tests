// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90983 - 90984 (writer Y5)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6379. A ListPart whose repeater controls are bound to page variables that OnAfterGetRecord fills:
//   a plain Text variable, an element of a Text array (ElementText[2]), an element of an Integer array (ElementNo[3]),
//   and an array element that OnAfterGetRecord never assigns (ElementText[1]). The host Document page shows the part;
//   the test walks the part with First, Next, Previous, Last and GoToKey and reads each control on each row.
// Result: OBSERVED_RESULT
// Source: al-runner issue 6379 (the reporter's repro passed on a real BC 28.5 container).
// BC versions: 27, 28, 29

table 90983 "LT Y5 AE Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 90984 "LT Y5 AE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Row ID"; Integer) { }
        field(2; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "Row ID") { Clustered = true; }
    }
}

page 90983 "LT Y5 AE Part"
{
    PageType = ListPart;
    SourceTable = "LT Y5 AE Row";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Plain; PlainText) { ApplicationArea = All; Caption = 'Plain'; }
                field(Element; ElementText[2]) { ApplicationArea = All; Caption = 'Element'; }
                field(Unset; ElementText[1]) { ApplicationArea = All; Caption = 'Unset'; }
                field(Number; ElementNo[3]) { ApplicationArea = All; Caption = 'Number'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PlainText := 'cell of ' + Rec."No.";
        ElementText[2] := 'cell of ' + Rec."No.";
        ElementNo[3] := Rec."Row ID" * 10;
    end;

    var
        PlainText: Text;
        ElementText: array[3] of Text;
        ElementNo: array[3] of Integer;
}

page 90984 "LT Y5 AE Host"
{
    PageType = Document;
    SourceTable = "LT Y5 AE Host";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
            part(Cells; "LT Y5 AE Part") { ApplicationArea = All; }
        }
    }
}

codeunit 90983 "LT Y5 AE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_ArrayElementControl_FirstThenNext()
    var
        Host: TestPage "LT Y5 AE Host";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        Host.OpenView();
        Observer.Observe('first', Format(Host.Cells.First()));
        Observer.Observe('A element', Host.Cells.Element.Value());
        Observer.Observe('A plain', Host.Cells.Plain.Value());
        Observer.Observe('A number', Host.Cells.Number.Value());
        Observer.Observe('A unset', Host.Cells.Unset.Value());
        Observer.Observe('next', Format(Host.Cells.Next()));
        Observer.Observe('B element', Host.Cells.Element.Value());
        Observer.Observe('B plain', Host.Cells.Plain.Value());
        Observer.Observe('B number', Host.Cells.Number.Value());
        Observer.Observe('B unset', Host.Cells.Unset.Value());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ArrayElementControl_ElementOnlyAfterNext()
    var
        Host: TestPage "LT Y5 AE Host";
        Observer: Codeunit "Probe Observer";
        Shown: Text;
    begin
        // The reporter's exact shape: only the array-element control is read.
        InsertRows();
        Host.OpenView();
        Host.Cells.First();
        Shown := Host.Cells.Element.Value() + ',';
        Host.Cells.Next();
        Shown += Host.Cells.Element.Value() + ',';
        Observer.Observe('shown', Shown);
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ArrayElementControl_LastPreviousGoToKey()
    var
        Host: TestPage "LT Y5 AE Host";
        Observer: Codeunit "Probe Observer";
    begin
        InsertRows();
        Host.OpenView();
        Observer.Observe('last', Format(Host.Cells.Last()));
        Observer.Observe('C element', Host.Cells.Element.Value());
        Observer.Observe('C number', Host.Cells.Number.Value());
        Observer.Observe('previous', Format(Host.Cells.Previous()));
        Observer.Observe('B element', Host.Cells.Element.Value());
        Observer.Observe('B number', Host.Cells.Number.Value());
        Observer.Observe('gotokey 1', Format(Host.Cells.GoToKey(1)));
        Observer.Observe('A element', Host.Cells.Element.Value());
        Observer.Observe('A number', Host.Cells.Number.Value());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ArrayElementControl_ReadBeforeFirst()
    var
        Host: TestPage "LT Y5 AE Host";
        Observer: Codeunit "Probe Observer";
    begin
        // No navigation in the part: read the controls right after OpenView.
        InsertRows();
        Host.OpenView();
        Observer.Observe('element', Host.Cells.Element.Value());
        Observer.Observe('plain', Host.Cells.Plain.Value());
        Observer.Observe('number', Host.Cells.Number.Value());
        Host.Close();
        Observer.Finish();
    end;

    local procedure InsertRows()
    var
        CellHost: Record "LT Y5 AE Host";
        CellRow: Record "LT Y5 AE Row";
    begin
        CellHost.DeleteAll();
        CellRow.DeleteAll();
        CellHost."Code" := 'H1';
        CellHost.Insert();
        CellRow."Row ID" := 1;
        CellRow."No." := 'A';
        CellRow.Insert();
        CellRow."Row ID" := 2;
        CellRow."No." := 'B';
        CellRow.Insert();
        CellRow."Row ID" := 3;
        CellRow."No." := 'C';
        CellRow.Insert();
    end;
}
