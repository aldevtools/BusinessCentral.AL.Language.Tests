// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 73680, pages 73682 - 73683, codeunits 73681, 73684
// Probe: al-runner issue 8523. The batch switch from the new-row line of an empty batch (Y50UpdateFromNewLine.al pins it with a final
//   CurrPage.Update(false) or Update(true)), with the other second steps (CurrPage.SaveRecord(), none) and with or without the first
//   CurrPage.SaveRecord(), each after an earlier step on the same open page: a control whose OnValidate errors, alone or after
//   CurrPage.Update(true), Update(false) or SaveRecord(). Does the page modify the row Find('-') moved Rec onto (OnModifyRecord, the
//   table's OnModify), and what is stored. Rows: B1 10000 A; B2 10000 B, 20000 D; B3 none (the page opens on B3).
//   Log: V:start/V:done <Line No.> around the batch OnValidate, B:start/B:error around the failing one, R: OnAfterGetRecord,
//   C: OnAfterGetCurrRecord, N: OnNewRecord, M: OnModifyRecord (Rec and xRec), I: OnInsertRecord, L.*: table triggers.
// Facts (measured on BC 28.5; 27.5 and 29.0 see the pull request):
//   - A CurrPage.SaveRecord() or CurrPage.Update(true) after Find('-') moved Rec from the new-row line onto stored row B2/10000 modifies
//     that row inside the OnValidate: OnModifyRecord (xRec still the new line B3/0) and the table's OnModify run, with or without the
//     first SaveRecord, with or without an earlier step, on Worksheet and List. A Description that code set is stored. Update(false)
//     and no second step modify nothing.
//   - Which earlier step failed does not matter: an OnValidate that only errors gives the same result as one that called
//     Update(true), Update(false) or SaveRecord() before its error (none of those ran: no reads, no save).
//   - After any failed earlier step the TestPage shows blank controls, and a batch OnValidate that ends without CurrPage.Update
//     (SaveRecord or nothing as the second step) reads no rows: the page stays blank and Next returns false. With Update(true) or
//     Update(false) it reads the view as without the earlier step.
//   - Without the first SaveRecord and without an earlier step, Update(false) or no second step lands on the new-row line of B2.
// BC versions: 27, 28, 29

table 73680 "LT FU Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Batch Name"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; "No."; Code[20]) { }
        field(4; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "Batch Name", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('L.OnInsert:' + "Batch Name" + '/' + Format("Line No."));
    end;

    trigger OnModify()
    begin
        Log.Add('L.OnModify:' + "Batch Name" + '/' + Format("Line No.") + '/' + Description);
    end;

    var
        Log: Codeunit "LT FU Log";
}

page 73682 "LT FU Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT FU Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentBatch; CurrentBatch)
                {
                    ApplicationArea = All;
                    Caption = 'Batch';

                    // The batch switch of Y50UpdateFromNewLine.al with the steps the test picks: an optional first CurrPage.SaveRecord(),
                    // the batch filter in filter group 2 and Find('-'), an optional change of Rec.Description in code, then the second step.
                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        if Log.FirstSave() then
                            CurrPage.SaveRecord();
                        SetBatch();
                        if Log.Touch() then
                            Rec.Description := 'code';
                        case Log.Second() of
                            1:
                                CurrPage.SaveRecord();
                            2:
                                CurrPage.Update(true);
                            3:
                                CurrPage.Update(false);
                        end;
                        Log.Add('V:done ' + Format(Rec."Line No."));
                    end;
                }
                field(Boom; Boom)
                {
                    ApplicationArea = All;
                    Caption = 'Boom';

                    // The earlier step: always ends with an error, after the step the test picks.
                    trigger OnValidate()
                    begin
                        Log.Add('B:start ' + Format(Rec."Line No."));
                        case Log.BoomMode() of
                            1:
                                CurrPage.Update(true);
                            2:
                                CurrPage.Update(false);
                            3:
                                CurrPage.SaveRecord();
                        end;
                        Log.Add('B:error');
                        Error('LT FU boom');
                    end;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := 'B3';
        SetBatch();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + '/' + Rec.Description + ' x=' + xRec."Batch Name" + '/' + Format(xRec."Line No."));
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    local procedure SetBatch()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Batch Name", CurrentBatch);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT FU Log";
        CurrentBatch: Code[10];
        Boom: Integer;
}

page 73683 "LT FU List"
{
    PageType = List;
    SourceTable = "LT FU Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentBatch; CurrentBatch)
                {
                    ApplicationArea = All;
                    Caption = 'Batch';

                    // The batch switch of Y50UpdateFromNewLine.al with the steps the test picks: an optional first CurrPage.SaveRecord(),
                    // the batch filter in filter group 2 and Find('-'), an optional change of Rec.Description in code, then the second step.
                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        if Log.FirstSave() then
                            CurrPage.SaveRecord();
                        SetBatch();
                        if Log.Touch() then
                            Rec.Description := 'code';
                        case Log.Second() of
                            1:
                                CurrPage.SaveRecord();
                            2:
                                CurrPage.Update(true);
                            3:
                                CurrPage.Update(false);
                        end;
                        Log.Add('V:done ' + Format(Rec."Line No."));
                    end;
                }
                field(Boom; Boom)
                {
                    ApplicationArea = All;
                    Caption = 'Boom';

                    // The earlier step: always ends with an error, after the step the test picks.
                    trigger OnValidate()
                    begin
                        Log.Add('B:start ' + Format(Rec."Line No."));
                        case Log.BoomMode() of
                            1:
                                CurrPage.Update(true);
                            2:
                                CurrPage.Update(false);
                            3:
                                CurrPage.SaveRecord();
                        end;
                        Log.Add('B:error');
                        Error('LT FU boom');
                    end;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := 'B3';
        SetBatch();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + '/' + Rec.Description + ' x=' + xRec."Batch Name" + '/' + Format(xRec."Line No."));
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    local procedure SetBatch()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Batch Name", CurrentBatch);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT FU Log";
        CurrentBatch: Code[10];
        Boom: Integer;
}

// The log and the steps of the LT FU pages. Used by test codeunit 73684 only.
codeunit 73681 "LT FU Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        DoFirstSave: Boolean;
        SecondStep: Integer;
        DoTouch: Boolean;
        Boom: Integer;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    // NewSecond 0: none, 1: CurrPage.SaveRecord(), 2: CurrPage.Update(true), 3: CurrPage.Update(false).
    // NewBoom 0: error only, 1: CurrPage.Update(true) then error, 2: CurrPage.Update(false) then error, 3: CurrPage.SaveRecord() then error.
    procedure SetSteps(NewFirstSave: Boolean; NewSecond: Integer; NewTouch: Boolean; NewBoom: Integer)
    begin
        DoFirstSave := NewFirstSave;
        SecondStep := NewSecond;
        DoTouch := NewTouch;
        Boom := NewBoom;
    end;

    procedure FirstSave(): Boolean
    begin
        exit(DoFirstSave);
    end;

    procedure Second(): Integer
    begin
        exit(SecondStep);
    end;

    procedure Touch(): Boolean
    begin
        exit(DoTouch);
    end;

    procedure BoomMode(): Integer
    begin
        exit(Boom);
    end;
}

codeunit 73684 "LT FU NewLine Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FU Log";

    local procedure Seed(FirstSave: Boolean; Second: Integer; Touch: Boolean; BoomMode: Integer)
    var
        Line: Record "LT FU Line";
    begin
        Line.DeleteAll();
        AddLine('B1', 10000, 'A');
        AddLine('B2', 10000, 'B');
        AddLine('B2', 20000, 'D');
        Log.SetSteps(FirstSave, Second, Touch, BoomMode);
        Log.Take();
    end;

    local procedure AddLine(Batch: Code[10]; LineNo: Integer; No: Code[20])
    var
        Line: Record "LT FU Line";
    begin
        Line."Batch Name" := Batch;
        Line."Line No." := LineNo;
        Line."No." := No;
        Line.Description := 'd' + No;
        Line.Insert();
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT FU Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Batch Name" + '/' + Format(Line."Line No.") + '/' + Line."No." + '/' + Line.Description + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryBoomWs(var P: TestPage "LT FU Worksheet")
    begin
        P.Boom.SetValue(1);
    end;

    [TryFunction]
    local procedure TrySetBatchWs(var P: TestPage "LT FU Worksheet"; Batch: Text)
    begin
        P.CurrentBatch.SetValue(Batch);
    end;

    // Opens the page on the new-row line of the empty batch B3, runs the earlier step if asked, then switches to batch B2.
    local procedure RunWs(FirstSave: Boolean; Second: Integer; Touch: Boolean; WithBoom: Boolean; BoomMode: Integer)
    var
        P: TestPage "LT FU Worksheet";
        Ok: Boolean;
    begin
        Seed(FirstSave, Second, Touch, BoomMode);
        P.OpenEdit();
        Observer.Observe('open', P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
        if WithBoom then begin
            Ok := TryBoomWs(P);
            Observer.Observe('boom', Format(Ok));
            if not Ok then
                Observer.ObserveError('boom error');
            Observer.Observe('boom log', Log.Take());
            Observer.Observe('after boom', P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
            Observer.Observe('stored after boom', StoredLines());
        end;
        Ok := TrySetBatchWs(P, 'B2');
        Observer.Observe('validate', Format(Ok));
        if not Ok then
            Observer.ObserveError('validate error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', P."Line No.".Value() + '/' + P."No.".Value() + '/' + P.Description.Value() + ':' + Log.Take());
        Observer.Observe('stored after validate', StoredLines());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredLines());
    end;

    [TryFunction]
    local procedure TryBoomList(var P: TestPage "LT FU List")
    begin
        P.Boom.SetValue(1);
    end;

    [TryFunction]
    local procedure TrySetBatchList(var P: TestPage "LT FU List"; Batch: Text)
    begin
        P.CurrentBatch.SetValue(Batch);
    end;

    // Opens the page on the new-row line of the empty batch B3, runs the earlier step if asked, then switches to batch B2.
    local procedure RunList(FirstSave: Boolean; Second: Integer; Touch: Boolean; WithBoom: Boolean; BoomMode: Integer)
    var
        P: TestPage "LT FU List";
        Ok: Boolean;
    begin
        Seed(FirstSave, Second, Touch, BoomMode);
        P.OpenEdit();
        Observer.Observe('open', P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
        if WithBoom then begin
            Ok := TryBoomList(P);
            Observer.Observe('boom', Format(Ok));
            if not Ok then
                Observer.ObserveError('boom error');
            Observer.Observe('boom log', Log.Take());
            Observer.Observe('after boom', P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
            Observer.Observe('stored after boom', StoredLines());
        end;
        Ok := TrySetBatchList(P, 'B2');
        Observer.Observe('validate', Format(Ok));
        if not Ok then
            Observer.ObserveError('validate error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', P."Line No.".Value() + '/' + P."No.".Value() + '/' + P.Description.Value() + ':' + Log.Take());
        Observer.Observe('stored after validate', StoredLines());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Line No.".Value() + '/' + P."No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredLines());
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: none.
    [Test]
    procedure Ws_Save_SaveRecord_NoEarlierStep()
    begin
        RunWs(true, 1, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_Save_SaveRecord_AfterErrorOnly()
    begin
        RunWs(true, 1, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_SaveRecord_AfterFailedUpdateTrue()
    begin
        RunWs(true, 1, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_Save_SaveRecord_AfterFailedUpdateFalse()
    begin
        RunWs(true, 1, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.SaveRecord() then an error.
    [Test]
    procedure Ws_Save_SaveRecord_AfterFailedSaveRecord()
    begin
        RunWs(true, 1, false, true, 3);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: none.
    [Test]
    procedure Ws_Save_UpdateTrue_NoEarlierStep()
    begin
        RunWs(true, 2, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_Save_UpdateTrue_AfterErrorOnly()
    begin
        RunWs(true, 2, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_UpdateTrue_AfterFailedUpdateTrue()
    begin
        RunWs(true, 2, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_Save_UpdateTrue_AfterFailedUpdateFalse()
    begin
        RunWs(true, 2, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: CurrPage.SaveRecord() then an error.
    [Test]
    procedure Ws_Save_UpdateTrue_AfterFailedSaveRecord()
    begin
        RunWs(true, 2, false, true, 3);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(false); earlier step: none.
    [Test]
    procedure Ws_Save_UpdateFalse_NoEarlierStep()
    begin
        RunWs(true, 3, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(false); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_Save_UpdateFalse_AfterErrorOnly()
    begin
        RunWs(true, 3, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(false); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_UpdateFalse_AfterFailedUpdateTrue()
    begin
        RunWs(true, 3, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(false); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_Save_UpdateFalse_AfterFailedUpdateFalse()
    begin
        RunWs(true, 3, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(false); earlier step: CurrPage.SaveRecord() then an error.
    [Test]
    procedure Ws_Save_UpdateFalse_AfterFailedSaveRecord()
    begin
        RunWs(true, 3, false, true, 3);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then no second step; earlier step: none.
    [Test]
    procedure Ws_Save_NoSecond_NoEarlierStep()
    begin
        RunWs(true, 0, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then no second step; earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_Save_NoSecond_AfterErrorOnly()
    begin
        RunWs(true, 0, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then no second step; earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_NoSecond_AfterFailedUpdateTrue()
    begin
        RunWs(true, 0, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then no second step; earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_Save_NoSecond_AfterFailedUpdateFalse()
    begin
        RunWs(true, 0, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, then no second step; earlier step: CurrPage.SaveRecord() then an error.
    [Test]
    procedure Ws_Save_NoSecond_AfterFailedSaveRecord()
    begin
        RunWs(true, 0, false, true, 3);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.SaveRecord(); earlier step: none.
    [Test]
    procedure Ws_NoSave_SaveRecord_NoEarlierStep()
    begin
        RunWs(false, 1, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.SaveRecord(); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_NoSave_SaveRecord_AfterErrorOnly()
    begin
        RunWs(false, 1, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_NoSave_SaveRecord_AfterFailedUpdateTrue()
    begin
        RunWs(false, 1, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_NoSave_SaveRecord_AfterFailedUpdateFalse()
    begin
        RunWs(false, 1, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(true); earlier step: none.
    [Test]
    procedure Ws_NoSave_UpdateTrue_NoEarlierStep()
    begin
        RunWs(false, 2, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(true); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_NoSave_UpdateTrue_AfterErrorOnly()
    begin
        RunWs(false, 2, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(true); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_NoSave_UpdateTrue_AfterFailedUpdateTrue()
    begin
        RunWs(false, 2, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(true); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_NoSave_UpdateTrue_AfterFailedUpdateFalse()
    begin
        RunWs(false, 2, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(false); earlier step: none.
    [Test]
    procedure Ws_NoSave_UpdateFalse_NoEarlierStep()
    begin
        RunWs(false, 3, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000;N:B2/0 below=Yes;C:B2/0');
        Observer.Expect('current', '0//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No/0/:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(false); earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_NoSave_UpdateFalse_AfterErrorOnly()
    begin
        RunWs(false, 3, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(false); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_NoSave_UpdateFalse_AfterFailedUpdateTrue()
    begin
        RunWs(false, 3, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then CurrPage.Update(false); earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_NoSave_UpdateFalse_AfterFailedUpdateFalse()
    begin
        RunWs(false, 3, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then no second step; earlier step: none.
    [Test]
    procedure Ws_NoSave_NoSecond_NoEarlierStep()
    begin
        RunWs(false, 0, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000;N:B2/0 below=Yes;C:B2/0');
        Observer.Expect('current', '0//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No/0/:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then no second step; earlier step: an OnValidate that only errors.
    [Test]
    procedure Ws_NoSave_NoSecond_AfterErrorOnly()
    begin
        RunWs(false, 0, false, true, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then no second step; earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_NoSave_NoSecond_AfterFailedUpdateTrue()
    begin
        RunWs(false, 0, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: SetBatch, then no second step; earlier step: CurrPage.Update(false) then an error.
    [Test]
    procedure Ws_NoSave_NoSecond_AfterFailedUpdateFalse()
    begin
        RunWs(false, 0, false, true, 2);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // List page: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: none.
    [Test]
    procedure List_Save_SaveRecord_NoEarlierStep()
    begin
        RunList(true, 1, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // List page: first CurrPage.SaveRecord(), SetBatch, then CurrPage.SaveRecord(); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure List_Save_SaveRecord_AfterFailedUpdateTrue()
    begin
        RunList(true, 1, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // List page: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: none.
    [Test]
    procedure List_Save_UpdateTrue_NoEarlierStep()
    begin
        RunList(true, 2, false, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // List page: first CurrPage.SaveRecord(), SetBatch, then CurrPage.Update(true); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure List_Save_UpdateTrue_AfterFailedUpdateTrue()
    begin
        RunList(true, 2, false, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/dB x=B3/0;L.OnModify:B2/10000/dB;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then CurrPage.SaveRecord(); earlier step: none.
    [Test]
    procedure Ws_Save_SaveRecord_CodeChange_NoEarlierStep()
    begin
        RunWs(true, 1, true, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/code x=B3/0;L.OnModify:B2/10000/code;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/code:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then CurrPage.SaveRecord(); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_SaveRecord_CodeChange_AfterFailedUpdateTrue()
    begin
        RunWs(true, 1, true, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/code x=B3/0;L.OnModify:B2/10000/code;V:done 10000;R:B2/10000;C:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/code:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Expect('next', 'No/10000/B:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then CurrPage.Update(true); earlier step: none.
    [Test]
    procedure Ws_Save_UpdateTrue_CodeChange_NoEarlierStep()
    begin
        RunWs(true, 2, true, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/code x=B3/0;L.OnModify:B2/10000/code;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/code:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then CurrPage.Update(true); earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_UpdateTrue_CodeChange_AfterFailedUpdateTrue()
    begin
        RunWs(true, 2, true, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;M:B2/10000/code x=B3/0;L.OnModify:B2/10000/code;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/code:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/code;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then no second step; earlier step: none.
    [Test]
    procedure Ws_Save_NoSecond_CodeChange_NoEarlierStep()
    begin
        RunWs(true, 0, true, false, 0);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // Worksheet: first CurrPage.SaveRecord(), SetBatch, Rec.Description := 'code', then no second step; earlier step: CurrPage.Update(true) then an error.
    [Test]
    procedure Ws_Save_NoSecond_CodeChange_AfterFailedUpdateTrue()
    begin
        RunWs(true, 0, true, true, 1);
        Observer.Expect('open', '0/:N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('boom', 'No');
        Observer.Expect('boom error|text', 'Validation error for Field: Boom,  Message = ''LT FU boom''');
        Observer.Expect('boom error|code', 'TestValidation');
        Observer.Expect('boom log', 'B:start 0;B:error');
        Observer.Expect('after boom', '/:');
        Observer.Expect('stored after boom', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('validate', 'Yes');
        Observer.Expect('validate log', 'V:start 0;V:done 10000');
        Observer.Expect('current', '//:');
        Observer.Expect('stored after validate', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Expect('next', 'No//:');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;
}
