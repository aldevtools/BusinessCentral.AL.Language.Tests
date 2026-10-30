// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90940 - 90943 (writer Y1)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6292 (follow-up to 6027). The reporter's page exactly: a Worksheet without the new-row line (InsertAllowed = false,
//   no DelayedInsert) filtered in FilterGroup 2 on the first key field. The action Post deletes every line with Rec.DeleteAll(), sets
//   Rec."Line No." := 1 (a key no row has, as page 5510 "Production Journal" Post does) and calls CurrPage.Update(false). With 1, 2 and 3
//   lines: which triggers run after the action, what the page shows and whether a line is left.
//   Log: N:<Batch Name> = OnNewRecord, C:<Line No.>:<Batch Name> = OnAfterGetCurrRecord, R:<Line No.> = OnAfterGetRecord.
// Result: OBSERVED_RESULT
// Source: al-runner issue 6292.
// BC versions: 27, 28, 29

table 90940 "LT Y1 Post Line"
{
    DataClassification = SystemMetadata;

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

page 90941 "LT Y1 Post Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y1 Post Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(BatchCtl; Rec."Batch Name") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PostLog.Add('N:' + Rec."Batch Name");
    end;

    trigger OnAfterGetRecord()
    begin
        PostLog.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PostLog.Add('C:' + Format(Rec."Line No.") + ':' + Rec."Batch Name");
    end;

    var
        PostLog: Codeunit "LT Y1 Post Log";
}

codeunit 90942 "LT Y1 Post Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 90943 "LT Y1 Post Worksheet Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        PostLog: Codeunit "LT Y1 Post Log";

    local procedure RunPost(LineCount: Integer)
    var
        Line: Record "LT Y1 Post Line";
        Worksheet: TestPage "LT Y1 Post Worksheet";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to LineCount do begin
            Line."Batch Name" := 'B1';
            Line."Line No." := i * 10000;
            Line.Insert();
        end;
        PostLog.Take();
        Worksheet.OpenEdit();
        Observer.Observe('open log', PostLog.Take());
        Worksheet.Post.Invoke();
        Observer.Observe('post log', PostLog.Take());
        Observer.Observe('shown after post', Worksheet.BatchCtl.Value() + '|' + Worksheet.LineNoCtl.Value());
        Observer.Observe('lines left', Format(Line.Count()));
        Worksheet.Close();
        Observer.Observe('close log', PostLog.Take());
    end;

    [Test]
    procedure Y1_Post_OneLine()
    begin
        RunPost(1);
        Observer.Finish();
    end;

    [Test]
    procedure Y1_Post_TwoLines()
    begin
        RunPost(2);
        Observer.Finish();
    end;

    [Test]
    procedure Y1_Post_ThreeLines()
    begin
        RunPost(3);
        Observer.Finish();
    end;
}
