// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 67138-67141 (TP R7821 *)
// local object: the page's Post action is what the test checks
// Probe: from al-runner issue 7821 (follow-up of 6027, 6292, 7197): a Worksheet with the new-row line (AutoSplitKey, DelayedInsert)
//   filtered to batch B1 in FilterGroup(2) in OnOpenPage, with OnAfterGetRecord, OnNewRecord and OnAfterGetCurrRecord. Its Post action
//   copies Rec, deletes every line of the batch and, when Find('=><') answers false, resets the copy, sets the batch filter in
//   FilterGroup(2), assigns "Line No." := 1 (a key no row has), copies it back into Rec and calls CurrPage.Update(false), as codeunit
//   241 "Item Jnl.-Post" leaves page 99000823 "Output Journal". The test opens the page (OpenEdit, or Page.Run on a filtered record),
//   invokes Post and reads the page triggers that ran after the action. The reporter saw on BC 29.0 with one line
//   `R:10000;N:0;C:0;N:0;C:0;N:0;C:0;` for both opens.
// Result: awaiting the corpus CI run (BC 27.5, 28.5 and 29.0).
// BC versions: 27+ (tested by the corpus CI matrix)

table 67138 "TP R7821 Line"
{
    fields
    {
        field(1; "Batch Name"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Quantity; Decimal) { }
    }
    keys
    {
        key(PK; "Batch Name", "Line No.") { Clustered = true; }
    }
}

codeunit 67139 "TP R7821 Log"
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

page 67140 "TP R7821 Wks"
{
    PageType = Worksheet;
    SourceTable = "TP R7821 Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
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
                var
                    Posted: Record "TP R7821 Line";
                begin
                    Posted.Copy(Rec);
                    Rec.DeleteAll();
                    if not Posted.Find('=><') then begin
                        Posted.Reset();
                        Posted.FilterGroup(2);
                        Posted.SetRange("Batch Name", 'B1');
                        Posted.FilterGroup(0);
                        Posted."Line No." := 1;
                    end;
                    Rec.Copy(Posted);
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
    var
        Log: Codeunit "TP R7821 Log";
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TP R7821 Log";
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TP R7821 Log";
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;
}

codeunit 67141 "TP R7821 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lines: Integer; WithPageRun: Boolean)
    var
        Line: Record "TP R7821 Line";
        Log: Codeunit "TP R7821 Log";
        Worksheet: TestPage "TP R7821 Wks";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to Lines do begin
            Line.Init();
            Line."Batch Name" := 'B1';
            Line."Line No." := i * 10000;
            Line.Quantity := 300;
            Line.Insert();
        end;
        Line.SetRange("Batch Name", 'B1');
        Line.FindFirst();
        Commit();

        if WithPageRun then begin
            Worksheet.Trap();
            Page.Run(Page::"TP R7821 Wks", Line);
        end else
            Worksheet.OpenEdit();
        Log.Take();
        Worksheet.Post.Invoke();
        Observer.Observe('after post', Log.Take());
        Observer.Observe('shown line', Worksheet."Line No.".Value());
        Worksheet.Close();
        Observer.Observe('after close', Log.Take());
        Observer.Observe('lines left', Format(Line.Count()));
    end;

    [Test]
    procedure TP7821_OneLine_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, false);
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('after close', '');
        Observer.Expect('lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TP7821_OneLine_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, true);
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('after close', '');
        Observer.Expect('lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TP7821_TwoLines_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, false);
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('after close', '');
        Observer.Expect('lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TP7821_ThreeLines_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, false);
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('after close', '');
        Observer.Expect('lines left', '0');
        Observer.Verify();
    end;
}
