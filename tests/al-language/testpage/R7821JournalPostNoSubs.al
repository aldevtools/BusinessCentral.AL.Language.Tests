// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 67223-67226 (TP R7821N *)
// local object: the page's Post action is what the test checks
// Probe: from al-runner issue 7821, follow-up of testpage/R7821JournalPostVariants.al. That file measured the base-page variants in a page
//   that two manual subscriber codeunits subscribe to (OnBeforeActionEvent and OnAfterActionEvent of Post). The reporter's app has no
//   such codeunit. This file has the same table, page body and Post action under own objects, and no codeunit subscribes to this page.
//   The Post action copies Rec, deletes every line in Rec's view and, when Find('=><') answers false, resets the copy, sets the batch
//   filter in FilterGroup(2), assigns "Line No." := 1 (a key no row has), copies it back into Rec and calls CurrPage.Update(false).
//   Cells, each with OpenEdit and with Page.Run(Id, Rec) on a trapped TestPage where both apply:
//   - one, two and three B1 lines (the record handed to Page.Run is filtered to B1 and stands on its first line);
//   - one B1 line plus one line in another batch (B2 after B1 in key order, A1 before it);
//   - Page.Run record shapes: no filter, no filter standing on the A1 line, a "Line No." filter (one and two B1 lines), a Quantity filter
//     next to the batch filter, the batch filter in FilterGroup(2) only, a temporary record, and the record standing on the last or the
//     middle line before the action.
//   Per cell: the page triggers that ran on the open and after Post, the "Line No." and Quantity the page shows after Post (Value and
//   AsDecimal), the triggers those reads ran, the triggers of Close and the lines left. Nothing is read from the page before Post.
// Result (measured on Windows BC 27.5, 28.5 and 29.0 containers, before the corpus CI run):
//   - Without subscriber codeunits the results equal those of R7821JournalPostVariants.al: one line, and one line plus a B2 or A1 line,
//     give `R:10000;N:0;C:0;N:0;C:0;N:0;C:0;` with both opens. Two lines give five N:0;C:0 pairs on BC 27.5 and 29.0, four on BC 28.5
//     (also when the record stands on the last line). Three lines give five pairs on every version, from the first, the middle or the
//     last line. The R: entry after Post is the line the record stood on.
//   - The blank line after Post shows "Line No." 0 and Quantity 0 (Value '0.00', AsDecimal 0), not the deleted line's 300. The reads run
//     no trigger, Close runs none, no B1 line is left (other-batch lines stay).
//   - Page.Run record shapes: no filter (also standing on the A1 line), a Quantity filter, and the batch filter in FilterGroup(2) only
//     give the one-line result. A temporary record: the page works on the temporary table; the one-line result, the temporary table is
//     empty after Post and the stored line stays. A "Line No." filter of 10000 with one line gives the one-line result; with two lines
//     Post deletes only line 10000 and the page then shows line 20000 with Quantity 300:
//     `R:10000;R:20000;N:0;C:0;R:20000;R:20000;R:20000;C:20000;`.
//   - On the open: OnAfterGetRecord runs for the rows from the record's line on, then again for that line, then OnAfterGetCurrRecord
//     (see 'after open' per test).
// BC versions: 27+ (tested by the corpus CI matrix)

table 67223 "TP R7821N Line"
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

page 67224 "TP R7821N Wks"
{
    PageType = Worksheet;
    SourceTable = "TP R7821N Line";
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
                    Posted: Record "TP R7821N Line";
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
        Log: Codeunit "TP R7821N Log";
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TP R7821N Log";
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TP R7821N Log";
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;
}

codeunit 67225 "TP R7821N Log"
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

codeunit 67226 "TP R7821N Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertLines(Rows: Integer; OtherBatch: Code[10])
    var
        Line: Record "TP R7821N Line";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to Rows do begin
            Line.Init();
            Line."Batch Name" := 'B1';
            Line."Line No." := i * 10000;
            Line.Quantity := 300;
            Line.Insert();
        end;
        if OtherBatch <> '' then begin
            Line.Init();
            Line."Batch Name" := OtherBatch;
            Line."Line No." := 10000;
            Line.Quantity := 100;
            Line.Insert();
        end;
    end;

    local procedure ObserveRows(var Observer: Codeunit "Probe Observer")
    var
        Line: Record "TP R7821N Line";
        Other: Record "TP R7821N Line";
        LineNos: Text;
    begin
        Line.SetRange("Batch Name", 'B1');
        if Line.FindSet() then
            repeat
                LineNos += Format(Line."Line No.") + ';';
            until Line.Next() = 0;
        Observer.Observe('B1 lines left', LineNos);
        Other.SetFilter("Batch Name", '<>%1', 'B1');
        Observer.Observe('other batch lines left', Format(Other.Count()));
    end;

    // Opens the page (Page.Run of Line on a trapped TestPage, or OpenEdit), invokes Post and observes the page after it.
    local procedure RunWks(var Observer: Codeunit "Probe Observer"; var Line: Record "TP R7821N Line"; WithPageRun: Boolean)
    var
        Log: Codeunit "TP R7821N Log";
        Worksheet: TestPage "TP R7821N Wks";
    begin
        Commit();
        Log.Take();
        if WithPageRun then begin
            Worksheet.Trap();
            Page.Run(Page::"TP R7821N Wks", Line);
        end else
            Worksheet.OpenEdit();
        Observer.Observe('after open', Log.Take());
        Worksheet.Post.Invoke();
        Observer.Observe('after post', Log.Take());
        Observer.Observe('shown line', Worksheet."Line No.".Value());
        Observer.Observe('shown quantity', Worksheet.Quantity.Value());
        Observer.Observe('quantity as decimal', Format(Worksheet.Quantity.AsDecimal()));
        Observer.Observe('after reads', Log.Take());
        Worksheet.Close();
        Observer.Observe('after close', Log.Take());
        ObserveRows(Observer);
    end;

    local procedure RunFiltered(var Observer: Codeunit "Probe Observer"; Rows: Integer; OtherBatch: Code[10]; WithPageRun: Boolean)
    var
        Line: Record "TP R7821N Line";
    begin
        InsertLines(Rows, OtherBatch);
        Line.SetRange("Batch Name", 'B1');
        Line.FindFirst();
        RunWks(Observer, Line, WithPageRun);
    end;

    [Test]
    procedure TPN7821_OneLine_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, '', false);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_OneLine_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, '', true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_TwoLines_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 2, '', false);
        Observer.Expect('after open', 'R:10000;R:20000;R:10000;R:10000;C:10000;');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#else
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#endif
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_TwoLines_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 2, '', true);
        Observer.Expect('after open', 'R:10000;R:20000;R:10000;R:10000;C:10000;');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#else
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#endif
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_ThreeLines_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 3, '', false);
        Observer.Expect('after open', 'R:10000;R:20000;R:30000;R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_ThreeLines_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 3, '', true);
        Observer.Expect('after open', 'R:10000;R:20000;R:30000;R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_OtherBatchAfter_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, 'B2', false);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_OtherBatchAfter_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, 'B2', true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_OtherBatchBefore_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, 'A1', false);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_OtherBatchBefore_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunFiltered(Observer, 1, 'A1', true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecNoFilter_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(1, '');
        Line.FindFirst();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecNoFilterOnA1_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(1, 'A1');
        Line.FindFirst();
        Observer.Observe('record before open', Line."Batch Name" + ' ' + Format(Line."Line No."));
        RunWks(Observer, Line, true);
        Observer.Expect('record before open', 'A1 10000');
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecLineNoFilter_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(1, '');
        Line.SetRange("Batch Name", 'B1');
        Line.SetRange("Line No.", 10000);
        Line.FindFirst();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecLineNoFilterTwoLines_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(2, '');
        Line.SetRange("Batch Name", 'B1');
        Line.SetRange("Line No.", 10000);
        Line.FindFirst();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;R:20000;N:0;C:0;R:20000;R:20000;R:20000;C:20000;');
        Observer.Expect('shown line', '20000');
        Observer.Expect('shown quantity', '300.00');
        Observer.Expect('quantity as decimal', '300');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '20000;');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecQuantityFilter_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(1, '');
        Line.SetRange("Batch Name", 'B1');
        Line.SetRange(Quantity, 300);
        Line.FindFirst();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecBatchFilterGroup2_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(1, '');
        Line.FilterGroup(2);
        Line.SetRange("Batch Name", 'B1');
        Line.FilterGroup(0);
        Line.FindFirst();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_RecTemporary_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
        TempLine: Record "TP R7821N Line" temporary;
    begin
        InsertLines(1, '');
        Line.FindFirst();
        TempLine := Line;
        TempLine.Insert();
        TempLine.SetRange("Batch Name", 'B1');
        TempLine.FindFirst();
        RunWks(Observer, TempLine, true);
        TempLine.Reset();
        Observer.Observe('temporary lines left', Format(TempLine.Count()));
        Observer.Expect('after open', 'R:10000;R:10000;C:10000;');
        Observer.Expect('after post', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '10000;');
        Observer.Expect('other batch lines left', '0');
        Observer.Expect('temporary lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_TwoLinesOnLast_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(2, '');
        Line.SetRange("Batch Name", 'B1');
        Line.FindLast();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:20000;R:10000;R:20000;R:20000;C:20000;');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('after post', 'R:20000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#else
        Observer.Expect('after post', 'R:20000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
#endif
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_ThreeLinesOnMiddle_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(3, '');
        Line.SetRange("Batch Name", 'B1');
        Line.Get('B1', 20000);
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:20000;R:30000;R:20000;R:10000;R:20000;R:20000;C:20000;');
        Observer.Expect('after post', 'R:20000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TPN7821_ThreeLinesOnLast_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "TP R7821N Line";
    begin
        InsertLines(3, '');
        Line.SetRange("Batch Name", 'B1');
        Line.FindLast();
        RunWks(Observer, Line, true);
        Observer.Expect('after open', 'R:30000;R:20000;R:10000;R:30000;R:30000;C:30000;');
        Observer.Expect('after post', 'R:30000;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown line', '0');
        Observer.Expect('shown quantity', '0.00');
        Observer.Expect('quantity as decimal', '0');
        Observer.Expect('after reads', '');
        Observer.Expect('after close', '');
        Observer.Expect('B1 lines left', '');
        Observer.Expect('other batch lines left', '0');
        Observer.Verify();
    end;
}
