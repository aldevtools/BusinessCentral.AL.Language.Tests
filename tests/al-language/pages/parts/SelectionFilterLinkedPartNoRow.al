// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95656-95657, pages 95658-95659, SingleInstance log 95660 (used only by test codeunit 95661)
// Probe (al-runner issue 6964): CurrPage.SetSelectionFilter called from OnAfterGetCurrRecord of a ListPart whose SubPageLink
//   (`"Table ID" = const(..), "No." = field("No.")`) selects no row of a table that has rows for other documents (the shape of Base
//   Application's "Doc. Attachment List Factbox"). Logged per call: the count and filters of a separate record that receives the selection,
//   and the key of the part's Rec. For comparison: the same part when the document has one row, and when the table is empty.
// local object: the part's SubPageLink and trigger are under test; the log must be owned by one test codeunit
// BC versions: 27-29

table 95656 "LT SFL Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95657 "LT SFL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer) { DataClassification = SystemMetadata; }
        field(2; "No."; Code[20]) { DataClassification = SystemMetadata; }
        field(3; "Line No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Table ID", "No.", "Line No.") { Clustered = true; }
    }
}

page 95658 "LT SFL Factbox"
{
    PageType = ListPart;
    SourceTable = "LT SFL Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Selected: Record "LT SFL Line";
        Log: Codeunit "LT SFL Log";
    begin
        CurrPage.SetSelectionFilter(Selected);
        Log.Add('rec=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No.") +
            ' count=' + Format(Selected.Count()) + ' filters=' + Selected.GetFilters());
    end;
}

page 95659 "LT SFL Card"
{
    PageType = Card;
    SourceTable = "LT SFL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Attachments; "LT SFL Factbox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(95656), "No." = field("No.");
            }
        }
    }
}

codeunit 95660 "LT SFL Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ' | ';
        Lines += Line;
    end;

    procedure Dump(): Text
    begin
        exit(Lines);
    end;
}

codeunit 95661 "LT SFL Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "LT SFL Log";

    local procedure Start()
    var
        Head: Record "LT SFL Head";
        Line: Record "LT SFL Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'A';
        Head.Insert();
        Log.Reset();
    end;

    local procedure AddLine(No: Code[20]; LineNo: Integer)
    var
        Line: Record "LT SFL Line";
    begin
        Line."Table ID" := 95656;
        Line."No." := No;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    [Test]
    procedure SetSelectionFilter_LinkedPartOnNoRow_TableHasOtherRows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SFL Card";
    begin
        Start();
        AddLine('B', 1);
        AddLine('B', 2);
        Card.OpenView();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part line', Card.Attachments.LineNoCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetSelectionFilter_LinkedPartOnNoRow_TableEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SFL Card";
    begin
        Start();
        Card.OpenView();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetSelectionFilter_LinkedPartOnOwnRow_TableHasOtherRows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SFL Card";
    begin
        Start();
        AddLine('A', 7);
        AddLine('B', 1);
        Card.OpenView();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part line', Card.Attachments.LineNoCtl.Value());
        Card.Close();
        Observer.Finish();
    end;
}
