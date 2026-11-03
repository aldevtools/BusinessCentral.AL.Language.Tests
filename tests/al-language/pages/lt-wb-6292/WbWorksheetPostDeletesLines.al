// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6292 (follow-up to 6027, reporter's repro, passed on real BC): a Worksheet without the new-row line whose action deletes its lines and leaves Rec on a primary key no row has (as page 5510 Post does) stands on the blank Rec; no error.

table 90607 "LT WB Line"
{
    fields
    {
        field(1; "Batch Name"; Code[10]) { }
        field(2; "Line No."; Integer) { }
    }
    keys
    {
        key(PK; "Batch Name", "Line No.") { Clustered = true; }
    }
}

page 90608 "LT WB Line Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT WB Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';

                trigger OnAction()
                begin
                    Rec.DeleteAll();
                    Rec."Line No." := 1;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Batch Name", 'B1');
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Shown += 1;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Current := Rec."Line No.";
    end;

    var
        Shown: Integer;
        Current: Integer;
}

codeunit 90609 "LT WB Line Worksheet Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PostOfTwoLinesThatDeletesThemAndLeavesRecOnAnotherKey()
    begin
        PostLinesAndVerify(2);
    end;

    [Test]
    procedure PostOfOneLineThatDeletesItAndLeavesRecOnAnotherKey()
    begin
        PostLinesAndVerify(1);
    end;

    local procedure PostLinesAndVerify(LineCount: Integer)
    var
        Line: Record "LT WB Line";
        Worksheet: TestPage "LT WB Line Worksheet";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to LineCount do begin
            Line."Batch Name" := 'B1';
            Line."Line No." := i * 10000;
            Line.Insert();
        end;

        Worksheet.OpenEdit();
        Worksheet.Post.Invoke();
        Worksheet.Close();

        if not Line.IsEmpty() then
            Error('A line is still there.');
    end;
}
