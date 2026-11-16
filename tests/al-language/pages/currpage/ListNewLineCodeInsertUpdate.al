// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// local object: the table field's OnValidate that inserts the page's new line, and the page triggers that log, are what is under test
// Fixtures used: shared Assert (60021); own table 97030, log codeunit 97031, pages 97032 and 97033, opener codeunit 97034, test codeunit 97035
// Probe (al-runner issue 8186): a List page stands on its new line (New()). SetValue on Name runs the table field's OnValidate, which inserts
//   Rec itself (Insert(true), with an AutoIncrement key field), and then the control's OnValidate, which calls CurrPage.Update() or
//   CurrPage.Update(false). Readings: the page and table triggers each step runs, the row the page shows after the refresh, the rows the
//   table holds, where a later SetValue lands, and Previous()/Next() from there. Cells: a page with and without AutoSplitKey, opened with
//   OpenEdit and with Page.RunModal, on an empty view and on a view with one row before, Update() and Update(false).
//   Measured on a local BC 29.1 OnPrem w1 container; BC 27.5 and 28.5 are left to CI.
// BC versions: 27, 28, 29

table 97030 "LT NI Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[10]) { }
        field(2; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(3; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT NI Log";
            begin
                Log.Add('T.V(' + Name + ')');
                if "Entry No." = 0 then
                    Insert(true);
            end;
        }
        field(4; Value; Text[30]) { }
    }

    keys
    {
        key(PK; "Group Code", "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT NI Log";
    begin
        Log.Add('T.I(' + Name + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT NI Log";
    begin
        Log.Add('T.M(' + Name + '/' + Value + ')');
    end;
}

codeunit 97031 "LT NI Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        UpdateFalse: Boolean;

    procedure Reset(NewUpdateFalse: Boolean)
    begin
        Buffer := '';
        UpdateFalse := NewUpdateFalse;
    end;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure IsUpdateFalse(): Boolean
    begin
        exit(UpdateFalse);
    end;

    procedure Bool(Value: Boolean): Text
    begin
        if Value then
            exit('T');
        exit('F');
    end;
}

page 97032 "LT NI Lines"
{
    PageType = List;
    SourceTable = "LT NI Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('P.V(' + Log.Bool(Rec."Entry No." <> 0) + ')');
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                        Log.Add('P.V.end');
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INS(' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MOD(' + Rec.Name + '/' + Rec.Value + ')');
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Name + ')');
    end;

    var
        Log: Codeunit "LT NI Log";
}

page 97033 "LT NI Lines No Split"
{
    PageType = List;
    SourceTable = "LT NI Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('P.V(' + Log.Bool(Rec."Entry No." <> 0) + ')');
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                        Log.Add('P.V.end');
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INS(' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MOD(' + Rec.Name + '/' + Rec.Value + ')');
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Name + ')');
    end;

    var
        Log: Codeunit "LT NI Log";
}

codeunit 97034 "LT NI Opener"
{
    procedure Open()
    var
        Line: Record "LT NI Line";
    begin
        Page.RunModal(Page::"LT NI Lines", Line);
    end;
}

codeunit 97035 "LT NI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "LT NI Log";
        ModalRowBefore: Boolean;

    local procedure Initialize(RowBefore: Boolean; UpdateFalse: Boolean)
    var
        Line: Record "LT NI Line";
    begin
        Line.DeleteAll();
        if RowBefore then begin
            Line.Init();
            Line.Name := 'A';
            Line.Insert();
        end;
        Commit();
        Log.Reset(UpdateFalse);
    end;

    local procedure Rows(): Text
    var
        Line: Record "LT NI Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line.Name + '/' + Line.Value + ',';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure ExpectedOpen(RowBefore: Boolean): Text
    begin
        if RowBefore then
            exit('P.AGR(A);P.AGR(A);P.AGCR(A);');
        exit('P.NEW;P.AGCR();P.NEW;P.AGCR();');
    end;

    local procedure ExpectedSetName(RowBefore: Boolean; UpdateFalse: Boolean): Text
    var
        Result: Text;
    begin
        Result := 'T.V(X);T.I(X);P.V(T);';
        if not UpdateFalse then
            Result += 'P.MOD(X/);T.M(X/);';
        Result += 'P.V.end;';
        if RowBefore then
            exit(Result + 'P.AGR(X);P.AGR(A);P.AGR(X);P.AGR(X);P.AGCR(X);');
        exit(Result + 'P.AGR(X);P.AGR(X);P.AGCR(X);');
    end;

    local procedure ExpectedRowsBefore(RowBefore: Boolean): Text
    begin
        if RowBefore then
            exit('A/,');
        exit('');
    end;

    // The steps after OnNewRecord, the same for both pages: what each step logs, what the page shows and what the table holds.
    local procedure CheckAfterSetName(RowBefore: Boolean; UpdateFalse: Boolean; SetNameLog: Text; Shown: Text)
    begin
        Assert.AreEqual(ExpectedSetName(RowBefore, UpdateFalse), SetNameLog,
            'SetValue on Name: the table field inserts the line, CurrPage.Update modifies it (Update() only), and the refresh reads it');
        Assert.AreEqual('X/', Shown, 'the page shows the line the table field inserted');
        Assert.AreEqual(ExpectedRowsBefore(RowBefore) + 'X/,', Rows(), 'one row inserted, no second insert');
    end;

    local procedure CheckAfterSetValue(RowBefore: Boolean; SetValueLog: Text; Shown: Text)
    begin
        Assert.AreEqual('', SetValueLog, 'SetValue on Value runs no trigger');
        Assert.AreEqual('X/V', Shown, 'Value lands on the inserted line');
        Assert.AreEqual(ExpectedRowsBefore(RowBefore) + 'X/,', Rows(), 'Value is not saved yet');
    end;

    local procedure CheckMoves(RowBefore: Boolean; PrevMove: Text; PrevLog: Text; NextMove: Text; NextLog: Text)
    begin
        if RowBefore then begin
            Assert.AreEqual('T/A', PrevMove, 'Previous moves to the row before');
            Assert.AreEqual('P.MOD(X/V);T.M(X/V);P.AGR(A);P.AGR(A);P.AGCR(A);', PrevLog, 'Previous saves Value, then reads the row before');
            Assert.AreEqual('T/X', NextMove, 'Next moves back to the inserted line');
            Assert.AreEqual('P.AGR(X);P.AGR(X);P.AGCR(X);', NextLog, 'Next reads the inserted line');
        end else begin
            Assert.AreEqual('F/X', PrevMove, 'Previous finds no row before the inserted line');
            Assert.AreEqual('', PrevLog, 'Previous runs no trigger');
            Assert.AreEqual('T/', NextMove, 'Next moves to a new line');
            Assert.AreEqual('P.MOD(X/V);T.M(X/V);P.NEW;P.AGCR();', NextLog, 'Next saves Value, then starts a new line');
        end;
    end;

    local procedure DriveSplit(var Lines: TestPage "LT NI Lines"; RowBefore: Boolean; UpdateFalse: Boolean)
    var
        PrevMove: Text;
        PrevLog: Text;
        NextMove: Text;
    begin
        Assert.AreEqual(ExpectedOpen(RowBefore), Log.Take(), 'the open');
        Lines.New();
        Assert.AreEqual('P.NEW;P.AGCR();', Log.Take(), 'New()');
        Lines.Name.SetValue('X');
        CheckAfterSetName(RowBefore, UpdateFalse, Log.Take(), Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.Value.SetValue('V');
        CheckAfterSetValue(RowBefore, Log.Take(), Lines.Name.Value() + '/' + Lines.Value.Value());
        PrevMove := Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value();
        PrevLog := Log.Take();
        NextMove := Log.Bool(Lines.Next()) + '/' + Lines.Name.Value();
        CheckMoves(RowBefore, PrevMove, PrevLog, NextMove, Log.Take());
    end;

    local procedure DriveNoSplit(var Lines: TestPage "LT NI Lines No Split"; RowBefore: Boolean)
    var
        PrevMove: Text;
        PrevLog: Text;
        NextMove: Text;
    begin
        Assert.AreEqual(ExpectedOpen(RowBefore), Log.Take(), 'the open');
        Lines.New();
        Assert.AreEqual('P.NEW;P.AGCR();', Log.Take(), 'New()');
        Lines.Name.SetValue('X');
        CheckAfterSetName(RowBefore, false, Log.Take(), Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.Value.SetValue('V');
        CheckAfterSetValue(RowBefore, Log.Take(), Lines.Name.Value() + '/' + Lines.Value.Value());
        PrevMove := Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value();
        PrevLog := Log.Take();
        NextMove := Log.Bool(Lines.Next()) + '/' + Lines.Name.Value();
        CheckMoves(RowBefore, PrevMove, PrevLog, NextMove, Log.Take());
    end;

    local procedure CheckClosed(RowBefore: Boolean)
    begin
        Assert.AreEqual('', Log.Take(), 'closing the page saves nothing more');
        Assert.AreEqual(ExpectedRowsBefore(RowBefore) + 'X/V,', Rows(), 'the inserted line holds Value');
    end;

    [Test]
    procedure ListNewLine_FieldValidateInserts_Update_EmptyView_ModifiesAndShowsTheLine()
    var
        Lines: TestPage "LT NI Lines";
    begin
        Initialize(false, false);
        Lines.OpenEdit();
        DriveSplit(Lines, false, false);
        Lines.Close();
        CheckClosed(false);
    end;

    [Test]
    procedure ListNewLine_FieldValidateInserts_Update_RowBefore_ModifiesAndShowsTheLine()
    var
        Lines: TestPage "LT NI Lines";
    begin
        Initialize(true, false);
        Lines.OpenEdit();
        DriveSplit(Lines, true, false);
        Lines.Close();
        CheckClosed(true);
    end;

    [Test]
    procedure ListNewLine_NoAutoSplitKey_FieldValidateInserts_Update_EmptyView_ModifiesAndShowsTheLine()
    var
        Lines: TestPage "LT NI Lines No Split";
    begin
        Initialize(false, false);
        Lines.OpenEdit();
        DriveNoSplit(Lines, false);
        Lines.Close();
        CheckClosed(false);
    end;

    [Test]
    procedure ListNewLine_NoAutoSplitKey_FieldValidateInserts_Update_RowBefore_ModifiesAndShowsTheLine()
    var
        Lines: TestPage "LT NI Lines No Split";
    begin
        Initialize(true, false);
        Lines.OpenEdit();
        DriveNoSplit(Lines, true);
        Lines.Close();
        CheckClosed(true);
    end;

    [Test]
    procedure ListNewLine_FieldValidateInserts_UpdateFalse_EmptyView_ShowsTheLineWithoutModify()
    var
        Lines: TestPage "LT NI Lines";
    begin
        Initialize(false, true);
        Lines.OpenEdit();
        DriveSplit(Lines, false, true);
        Lines.Close();
        CheckClosed(false);
    end;

    [Test]
    procedure ListNewLine_FieldValidateInserts_UpdateFalse_RowBefore_ShowsTheLineWithoutModify()
    var
        Lines: TestPage "LT NI Lines";
    begin
        Initialize(true, true);
        Lines.OpenEdit();
        DriveSplit(Lines, true, true);
        Lines.Close();
        CheckClosed(true);
    end;

    [Test]
    [HandlerFunctions('LinesModalHandler')]
    procedure ListNewLine_RunModal_FieldValidateInserts_Update_EmptyView_ModifiesAndShowsTheLine()
    var
        Opener: Codeunit "LT NI Opener";
    begin
        Initialize(false, false);
        ModalRowBefore := false;
        Opener.Open();
        CheckClosed(false);
    end;

    [Test]
    [HandlerFunctions('LinesModalHandler')]
    procedure ListNewLine_RunModal_FieldValidateInserts_Update_RowBefore_ModifiesAndShowsTheLine()
    var
        Opener: Codeunit "LT NI Opener";
    begin
        Initialize(true, false);
        ModalRowBefore := true;
        Opener.Open();
        CheckClosed(true);
    end;

    [ModalPageHandler]
    procedure LinesModalHandler(var Lines: TestPage "LT NI Lines")
    begin
        DriveSplit(Lines, ModalRowBefore, false);
        Lines.OK().Invoke();
    end;
}
