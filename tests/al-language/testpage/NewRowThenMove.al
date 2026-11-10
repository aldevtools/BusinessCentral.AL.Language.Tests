// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope (Cloud). TestPage; a PageHandler for the built-in Edit and View actions.
// local object: the page shapes (a List and a ListPlus whose page-variable control calls CurrPage.Update(true), a list that is not editable with a
//   CardPageId) and their triggers are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63410, log codeunit 63411, pages 63412 to 63416, test codeunit 63419
// Probe (al-runner issues 7452 and 7477): the new-row line a test reaches with New() and leaves without typing on it.
//   7452: First(), Last(), Previous(), Next() and GoToKey right after New() on a List and on a ListPlus (repeater, a part beside it, a page
//   variable shown outside the repeater). OnNewRecord clears the page variables, OnAfterGetCurrRecord fills them from the row. The reading is the
//   result of the move, the row and the page variables the page shows afterwards, the trigger log and the stored rows.
//   7477: the built-in Edit and View actions of a list that is not editable (CardPageId) on its new-row line, over an empty table and over two
//   rows, with and without New() before: whether the card opens, which row and mode the handler sees, and what the handler's own New() stores.
//   Already pinned: R6977ListViewNext.al (Next() onto the new-row line), TestPageNewRowLine_Tests.al and TestPageLastNewRowLine_Tests.al (the
//   new-row line reached with Next() and Last()), PnC07TestPage.al New_AfterMovingAwayFromNewRow (Previous() after a key was typed),
//   TestPageListViewEditAction_Tests.al (Edit and View on a stored row).
//   Log: N = OnNewRecord, R:<code> = OnAfterGetRecord, C:<code> = OnAfterGetCurrRecord, I:<code> = OnInsertRecord, M:<code> = OnModifyRecord.
// BC versions: 27, 28, 29

table 63410 "PNL NR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; Formula; Text[100]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 63411 "PNL NR Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 63412 "PNL NR List"
{
    PageType = List;
    SourceTable = "PNL NR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(FormulaText; FormulaText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(FormulaText, 1, MaxStrLen(Rec.Formula));
                        CurrPage.Update(true);
                    end;
                }
                field(FullFormula; FullText)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FormulaText := '';
        FullText := '';
        Log.Add('N');
    end;

    trigger OnAfterGetRecord()
    begin
        FormulaText := Rec.Formula;
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FormulaText := Rec.Formula;
        FullText := 'F:' + Rec.Formula;
        Log.Add('C:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Code");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Code");
    end;

    var
        Log: Codeunit "PNL NR Log";
        FormulaText: Text;
        FullText: Text;
}

page 63414 "PNL NR Symbols"
{
    PageType = ListPart;
    SourceTable = "PNL NR Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    procedure SetSource(Row: Record "PNL NR Row")
    begin
        SourceCode := Row."Code";
    end;

    var
        SourceCode: Code[20];
}

page 63413 "PNL NR Plus"
{
    PageType = ListPlus;
    SourceTable = "PNL NR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(FormulaText; FormulaText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(FormulaText, 1, MaxStrLen(Rec.Formula));
                        CurrPage.Update(true);
                    end;
                }
            }
            part(Symbols; "PNL NR Symbols")
            {
                ApplicationArea = All;
                UpdatePropagation = SubPart;
            }
            field(FullFormula; FullText)
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FormulaText := '';
        FullText := '';
        Log.Add('N');
    end;

    trigger OnAfterGetRecord()
    begin
        FormulaText := Rec.Formula;
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FormulaText := Rec.Formula;
        FullText := 'F:' + Rec.Formula;
        CurrPage.Symbols.Page.SetSource(Rec);
        Log.Add('C:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Symbols.Page.SetSource(Rec);
        Log.Add('I:' + Rec."Code");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Code");
    end;

    var
        Log: Codeunit "PNL NR Log";
        FormulaText: Text;
        FullText: Text;
}

page 63416 "PNL NR Card"
{
    PageType = Card;
    SourceTable = "PNL NR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 63415 "PNL NR Read Only List"
{
    PageType = List;
    SourceTable = "PNL NR Row";
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "PNL NR Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 63419 "PNL New Row Then Move"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PNL NR Log";
        CardRuns: Integer;

    local procedure Initialize()
    var
        Row: Record "PNL NR Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Log.Take();
        CardRuns := 0;
    end;

    local procedure Seed(Count: Integer)
    var
        Row: Record "PNL NR Row";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'S' + Format(i);
            Row.Description := 'stored ' + Format(i);
            Row.Formula := Format(i) + '+' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure Stored(): Text
    var
        Row: Record "PNL NR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Formula + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryMoveList(var P: TestPage "PNL NR List"; Step: Text; var Moved: Boolean)
    begin
        case Step of
            'FIRST':
                Moved := P.First();
            'LAST':
                Moved := P.Last();
            'PREVIOUS':
                Moved := P.Previous();
            'NEXT':
                Moved := P.Next();
            else
                Moved := P.GoToKey(Step);
        end;
    end;

    [TryFunction]
    local procedure TryMovePlus(var P: TestPage "PNL NR Plus"; Step: Text; var Moved: Boolean)
    begin
        case Step of
            'FIRST':
                Moved := P.First();
            'LAST':
                Moved := P.Last();
            'PREVIOUS':
                Moved := P.Previous();
            'NEXT':
                Moved := P.Next();
            else
                Moved := P.GoToKey(Step);
        end;
    end;

    [TryFunction]
    local procedure TryShownList(var P: TestPage "PNL NR List"; var Shown: Text)
    begin
        Shown := P."Code".Value() + '|' + P.FormulaText.Value() + '|' + P.FullFormula.Value();
    end;

    [TryFunction]
    local procedure TryShownPlus(var P: TestPage "PNL NR Plus"; var Shown: Text)
    begin
        Shown := P."Code".Value() + '|' + P.FormulaText.Value() + '|' + P.FullFormula.Value();
    end;

    local procedure ReadList(var P: TestPage "PNL NR List"; Name: Text)
    var
        Shown: Text;
    begin
        if TryShownList(P, Shown) then
            Observer.Observe(Name, Shown)
        else
            Observer.ObserveError(Name + ' error');
    end;

    local procedure ReadPlus(var P: TestPage "PNL NR Plus"; Name: Text)
    var
        Shown: Text;
    begin
        if TryShownPlus(P, Shown) then
            Observer.Observe(Name, Shown)
        else
            Observer.ObserveError(Name + ' error');
    end;

    local procedure MoveList(var P: TestPage "PNL NR List"; Step: Text)
    var
        Moved: Boolean;
    begin
        if TryMoveList(P, Step, Moved) then
            Observer.Observe('move ' + Step, Format(Moved))
        else
            Observer.ObserveError('move ' + Step + ' error');
        ReadList(P, 'shown after ' + Step);
        Observer.Observe('log after ' + Step, Log.Take());
        Observer.Observe('stored after ' + Step, Stored());
    end;

    local procedure MovePlus(var P: TestPage "PNL NR Plus"; Step: Text)
    var
        Moved: Boolean;
    begin
        if TryMovePlus(P, Step, Moved) then
            Observer.Observe('move ' + Step, Format(Moved))
        else
            Observer.ObserveError('move ' + Step + ' error');
        ReadPlus(P, 'shown after ' + Step);
        Observer.Observe('log after ' + Step, Log.Take());
        Observer.Observe('stored after ' + Step, Stored());
    end;

    // OpenNew, one typed row (Code, Description, FormulaText), then New() and nothing typed on the new row.
    local procedure TypeOneRowThenNewList(var P: TestPage "PNL NR List")
    begin
        P.OpenNew();
        P."Code".SetValue('FORMULA1');
        P.Description.SetValue('First Formula');
        P.FormulaText.SetValue('2+4');
        Log.Take();
        P.New();
        ReadList(P, 'shown after New');
        Observer.Observe('log after New', Log.Take());
    end;

    local procedure TypeOneRowThenNewPlus(var P: TestPage "PNL NR Plus")
    begin
        P.OpenNew();
        P."Code".SetValue('FORMULA1');
        P.Description.SetValue('First Formula');
        P.FormulaText.SetValue('2+4');
        Log.Take();
        P.New();
        ReadPlus(P, 'shown after New');
        Observer.Observe('log after New', Log.Take());
    end;

    [Test]
    procedure List_TypedRow_New_First()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        TypeOneRowThenNewList(P);
        MoveList(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'Yes');
        Observer.Expect('shown after FIRST', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after FIRST', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after FIRST', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure List_TypedRow_New_Last()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        TypeOneRowThenNewList(P);
        MoveList(P, 'LAST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move LAST', 'Yes');
        Observer.Expect('shown after LAST', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after LAST', 'N C: N C: R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after LAST', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure List_TypedRow_New_Previous()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        TypeOneRowThenNewList(P);
        MoveList(P, 'PREVIOUS');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move PREVIOUS', 'Yes');
        Observer.Expect('shown after PREVIOUS', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after PREVIOUS', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after PREVIOUS', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure List_TypedRow_New_Next()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        TypeOneRowThenNewList(P);
        MoveList(P, 'NEXT');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move NEXT', 'No');
        Observer.Expect('shown after NEXT', '||F:');
        Observer.Expect('log after NEXT', '');
        Observer.Expect('stored after NEXT', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure List_TypedRow_New_GoToKey()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        TypeOneRowThenNewList(P);
        MoveList(P, 'FORMULA1');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FORMULA1', 'Yes');
        Observer.Expect('shown after FORMULA1', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after FORMULA1', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after FORMULA1', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure List_TwoStoredRows_OpenEdit_New_First()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        Seed(2);
        P.OpenEdit();
        P.Last();
        Log.Take();
        P.New();
        ReadList(P, 'shown after New');
        Observer.Observe('log after New', Log.Take());
        MoveList(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'Yes');
        Observer.Expect('shown after FIRST', 'S1|1+1|F:1+1');
        Observer.Expect('log after FIRST', 'R:S1 R:S1 C:S1 ');
        Observer.Expect('stored after FIRST', 'S1=1+1;S2=2+2;');
        Observer.Verify();
    end;

    [Test]
    procedure List_EmptyTable_OpenEdit_New_First()
    var
        P: TestPage "PNL NR List";
    begin
        Initialize();
        P.OpenEdit();
        Log.Take();
        P.New();
        ReadList(P, 'shown after New');
        Observer.Observe('log after New', Log.Take());
        MoveList(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'No');
        Observer.Expect('shown after FIRST', '||F:');
        Observer.Expect('log after FIRST', 'N C: ');
        Observer.Expect('stored after FIRST', '');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_TypedRow_New_First()
    var
        P: TestPage "PNL NR Plus";
    begin
        // The reporter's steps of issue 7452.
        Initialize();
        TypeOneRowThenNewPlus(P);
        MovePlus(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'Yes');
        Observer.Expect('shown after FIRST', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after FIRST', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after FIRST', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_TypedRow_New_Last()
    var
        P: TestPage "PNL NR Plus";
    begin
        Initialize();
        TypeOneRowThenNewPlus(P);
        MovePlus(P, 'LAST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move LAST', 'Yes');
        Observer.Expect('shown after LAST', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after LAST', 'N C: N C: R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after LAST', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_TypedRow_New_Previous()
    var
        P: TestPage "PNL NR Plus";
    begin
        Initialize();
        TypeOneRowThenNewPlus(P);
        MovePlus(P, 'PREVIOUS');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move PREVIOUS', 'Yes');
        Observer.Expect('shown after PREVIOUS', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after PREVIOUS', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after PREVIOUS', 'FORMULA1=2+4;');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_TypedRow_New_SecondRowTyped_First()
    var
        P: TestPage "PNL NR Plus";
    begin
        // The control the reporter names: a second row typed after New() and before First().
        Initialize();
        TypeOneRowThenNewPlus(P);
        P."Code".SetValue('FORMULA2');
        P.FormulaText.SetValue('3+5');
        Log.Take();
        MovePlus(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'Yes');
        Observer.Expect('shown after FIRST', 'FORMULA1|2+4|F:2+4');
        Observer.Expect('log after FIRST', 'R:FORMULA1 R:FORMULA1 C:FORMULA1 ');
        Observer.Expect('stored after FIRST', 'FORMULA1=2+4;FORMULA2=3+5;');
        Observer.Verify();
    end;

    [Test]
    procedure ListPlus_TwoStoredRows_OpenEdit_New_First()
    var
        P: TestPage "PNL NR Plus";
    begin
        Initialize();
        Seed(2);
        P.OpenEdit();
        P.Last();
        Log.Take();
        P.New();
        ReadPlus(P, 'shown after New');
        Observer.Observe('log after New', Log.Take());
        MovePlus(P, 'FIRST');
        P.Close();
        Observer.Expect('shown after New', '||F:');
        Observer.Expect('log after New', 'N C: ');
        Observer.Expect('move FIRST', 'Yes');
        Observer.Expect('shown after FIRST', 'S1|1+1|F:1+1');
        Observer.Expect('log after FIRST', 'R:S1 R:S1 C:S1 ');
        Observer.Expect('stored after FIRST', 'S1=1+1;S2=2+2;');
        Observer.Verify();
    end;

    // ---- issue 7477: the built-in Edit and View actions on the new-row line of a list that is not editable ----

    [TryFunction]
    local procedure TryNew(var P: TestPage "PNL NR Read Only List")
    begin
        P.New();
    end;

    [TryFunction]
    local procedure TryEdit(var P: TestPage "PNL NR Read Only List")
    begin
        P.Edit().Invoke();
    end;

    [TryFunction]
    local procedure TryView(var P: TestPage "PNL NR Read Only List")
    begin
        P.View().Invoke();
    end;

    local procedure EditOrView(SeedCount: Integer; CallNew: Boolean; UseView: Boolean)
    var
        P: TestPage "PNL NR Read Only List";
        Ok: Boolean;
    begin
        Seed(SeedCount);
        P.OpenEdit();
        Observer.Observe('list editable', Format(P.Editable()));
        if CallNew then
            if TryNew(P) then
                Observer.Observe('New', 'ok')
            else
                Observer.ObserveError('New error');
        Observer.Observe('list row before', P."Code".Value());
        if UseView then
            Ok := TryView(P)
        else
            Ok := TryEdit(P);
        if Ok then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke error');
        Observer.Observe('card handler runs', Format(CardRuns));
        Observer.Observe('list row after', P."Code".Value());
        P.Close();
        Observer.Observe('stored', Stored());
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure ReadOnlyList_EmptyTable_New_Edit()
    begin
        // The reporter's steps of issue 7477.
        Initialize();
        EditOrView(0, true, false);
        Observer.Expect('list editable', 'No');
        Observer.Expect('New', 'ok');
        Observer.Expect('list row before', '');
        Observer.Expect('card row', '');
        Observer.Expect('card editable', 'Yes');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('card handler runs', '1');
        Observer.Expect('list row after', 'X');
        Observer.Expect('stored', 'X=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure ReadOnlyList_EmptyTable_NoNew_Edit()
    begin
        Initialize();
        EditOrView(0, false, false);
        Observer.Expect('list editable', 'No');
        Observer.Expect('list row before', '');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('card handler runs', '0');
        Observer.Expect('list row after', '');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure ReadOnlyList_EmptyTable_New_View()
    begin
        Initialize();
        EditOrView(0, true, true);
        Observer.Expect('list editable', 'No');
        Observer.Expect('New', 'ok');
        Observer.Expect('list row before', '');
        Observer.Expect('card row', '');
        Observer.Expect('card editable', 'No');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('card handler runs', '1');
        Observer.Expect('list row after', 'X');
        Observer.Expect('stored', 'X=;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure ReadOnlyList_TwoRows_New_Edit()
    begin
        Initialize();
        EditOrView(2, true, false);
        Observer.Expect('list editable', 'No');
        Observer.Expect('New', 'ok');
        Observer.Expect('list row before', '');
        Observer.Expect('card row', 'S1');
        Observer.Expect('card editable', 'Yes');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('card handler runs', '1');
        Observer.Expect('list row after', 'X');
        Observer.Expect('stored', 'S1=1+1;S2=2+2;X=;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "PNL NR Card")
    begin
        CardRuns += 1;
        Observer.Observe('card row', Card."Code".Value());
        Observer.Observe('card editable', Format(Card.Editable()));
        if not TryCardNew(Card) then
            Observer.ObserveError('card New error');
        Card.Close();
    end;

    [TryFunction]
    local procedure TryCardNew(var Card: TestPage "PNL NR Card")
    begin
        Card.New();
        Card."Code".SetValue('X');
        Card.Description.SetValue('typed on the card');
    end;
}
