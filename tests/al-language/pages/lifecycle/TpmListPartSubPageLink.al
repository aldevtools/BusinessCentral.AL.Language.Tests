// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the document page with a ListPart linked by SubPageLink, the logging triggers and the tables are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97440-97446, test codeunit 97446
// Area (TestPage lifecycle matrix, shape "ListPart inside a document page with SubPageLink"): OpenEdit, OpenView, OpenNew and New of the
//   document, First, Last, Next, Previous, GoToKey and GoToRecord on the document and on the part, SetValue on a line field, New on the part,
//   an action on the part that inserts or deletes a line, moving the document (the part is filtered to the new document), Close and the close
//   at the end of a test; documents with 3 lines and with 25 lines (more than one window). Each cell Observes the shown rows, whether a line
//   was inserted or modified (and the Doc No. it got), the order of page and table triggers and the error text.
// BC versions: 27, 28, 29

table 97440 "TPM Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Title; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97441 "TPM Doc Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('T-I:' + "Doc No." + '/' + Format("Line No."));
    end;

    trigger OnModify()
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('T-M:' + "Doc No." + '/' + Format("Line No."));
    end;
}

page 97442 "TPM Doc Lines"
{
    PageType = ListPart;
    SourceTable = "TPM Doc Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddLine)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    New: Record "TPM Doc Line";
                begin
                    New."Doc No." := Rec."Doc No.";
                    New."Line No." := Rec."Line No." + 5;
                    New.Name := 'added';
                    New.Insert(true);
                end;
            }
            action(DeleteLine)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(false);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('L-NEW:' + Rec."Doc No." + '/' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('L-INS:' + Rec."Doc No." + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('L-AGC:' + Rec."Doc No." + '/' + Format(Rec."Line No."));
    end;
}

page 97443 "TPM Doc Card"
{
    PageType = Document;
    SourceTable = "TPM Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Title; Rec.Title) { ApplicationArea = All; }
            part(Lines; "TPM Doc Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('D-NEW:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('D-AGC:' + Rec."No.");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM Part Log";
    begin
        Log.Add('D-QC:' + Format(CloseAction));
        exit(true);
    end;
}

codeunit 97445 "TPM Part Log"
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
        Result := Entries.TrimEnd();
        Entries := '';
    end;
}

codeunit 97446 "TPM Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM Part Log";

    // two documents D1 and D2; D1 has LinesOfD1 lines 10000, 20000 ..., D2 has two lines
    local procedure Seed(LinesOfD1: Integer)
    var
        Doc: Record "TPM Doc";
        Line: Record "TPM Doc Line";
        i: Integer;
    begin
        Line.DeleteAll(false);
        Doc.DeleteAll(false);
        Doc."No." := 'D1';
        Doc.Title := 'first';
        Doc.Insert(false);
        Doc."No." := 'D2';
        Doc.Title := 'second';
        Doc.Insert(false);
        for i := 1 to LinesOfD1 do begin
            Line.Init();
            Line."Doc No." := 'D1';
            Line."Line No." := i * 10000;
            Line.Name := 'a' + Format(i);
            Line.Insert(false);
        end;
        for i := 1 to 2 do begin
            Line.Init();
            Line."Doc No." := 'D2';
            Line."Line No." := i * 10000;
            Line.Name := 'b' + Format(i);
            Line.Insert(false);
        end;
        Log.Take();
    end;

    local procedure Lines(): Text
    var
        Line: Record "TPM Doc Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Doc No." + '/' + Format(Line."Line No.") + '=' + Line.Name + ' ';
            until Line.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure Docs(): Text
    var
        Doc: Record "TPM Doc";
        Result: Text;
    begin
        if Doc.FindSet() then
            repeat
                Result += Doc."No." + '=' + Doc.Title + ' ';
            until Doc.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure Shown(var P: TestPage "TPM Doc Card"): Text
    begin
        exit(P."No.".Value() + ' line ' + P.Lines."Line No.".Value() + '|' + P.Lines.Name.Value());
    end;

    [TryFunction]
    local procedure TrySetLineName(var P: TestPage "TPM Doc Card"; Value: Text)
    begin
        P.Lines.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetTitle(var P: TestPage "TPM Doc Card"; Value: Text)
    begin
        P.Title.SetValue(Value);
    end;

    [Test]
    procedure TPM_Part_OpenEdit_ShowsFirstDocumentAndItsFirstLine()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_OpenView_PartNotEditable_SetValueRefused()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenView();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('part Name editable', Format(P.Lines.Name.Editable()));
        Log.Take();
        if not TrySetLineName(P, 'viewed') then
            Observer.ObserveError('SetValue on the part in view mode');
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Observe('lines', Lines());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_OpenNew_PartHasNoLinesUntilKeyEntered()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenNew();
        Observer.Observe('log after OpenNew', Log.Take());
        Observer.Observe('part Line No. shown', P.Lines."Line No.".Value());
        Observer.Observe('part First', Format(P.Lines.First()));
        Observer.Observe('part Next', Format(P.Lines.Next()));
        P.Close();
        Observer.Observe('docs', Docs());
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_OpenNew_KeyThenNewLineOnPart_LineGetsDocNo()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenNew();
        P."No.".SetValue('D9');
        Log.Take();
        P.Lines.New();
        Observer.Observe('log after part New', Log.Take());
        Observer.Observe('part Line No. after New', P.Lines."Line No.".Value());
        Observer.Observe('Name ok', Format(TrySetLineName(P, 'new line')));
        Observer.Observe('log after Name', Log.Take());
        P.Close();
        Observer.Observe('docs', Docs());
        Observer.Observe('lines of D9', Lines().Substring(Lines().IndexOf('D9/')));
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_Navigation_FirstLastNextPrevious_OnPart()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('part Last', Format(P.Lines.Last()) + ' ' + Shown(P));
        Observer.Observe('part Next past end', Format(P.Lines.Next()) + ' ' + Shown(P));
        Observer.Observe('part Previous', Format(P.Lines.Previous()) + ' ' + Shown(P));
        Observer.Observe('part First', Format(P.Lines.First()) + ' ' + Shown(P));
        Observer.Observe('part Previous before start', Format(P.Lines.Previous()) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_Navigation_DocumentNextFiltersThePartToTheNewDocument()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.Last();
        Log.Take();
        Observer.Observe('document Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('log after document Next', Log.Take());
        Observer.Observe('part Last', Format(P.Lines.Last()) + ' ' + Shown(P));
        Observer.Observe('document Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('part shows after coming back', Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_GoToKeyAndGoToRecord_OnPartAndOnDocument()
    var
        P: TestPage "TPM Doc Card";
        Line: Record "TPM Doc Line";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('part GoToKey D1 20000', Format(P.Lines.GoToKey('D1', 20000)) + ' ' + Shown(P));
        Observer.Observe('part GoToKey 30000 (Line No. only)', Format(P.Lines.GoToKey('D1', 30000)) + ' ' + Shown(P));
        Observer.Observe('part GoToKey line of D2', Format(P.Lines.GoToKey('D2', 10000)) + ' ' + Shown(P));
        Observer.Observe('part GoToKey missing', Format(P.Lines.GoToKey('D1', 999)) + ' ' + Shown(P));
        Line.Get('D1', 10000);
        Observer.Observe('part GoToRecord D1 10000', Format(P.Lines.GoToRecord(Line)) + ' ' + Shown(P));
        Line.Get('D2', 20000);
        Observer.Observe('part GoToRecord line of D2', Format(P.Lines.GoToRecord(Line)) + ' ' + Shown(P));
        Observer.Observe('document GoToKey D2', Format(P.GoToKey('D2')) + ' ' + Shown(P));
        Observer.Observe('part GoToKey D2 20000 after moving', Format(P.Lines.GoToKey('D2', 20000)) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_SetValue_OnLineName_ModifiesTheLine()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.GoToKey('D1', 20000);
        Log.Take();
        Observer.Observe('Name ok', Format(TrySetLineName(P, 'changed')));
        Observer.Observe('log after SetValue', Log.Take());
        Observer.Observe('lines after SetValue', Lines());
        P.Lines.Next();
        Observer.Observe('log after part Next', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_SetValue_OnDocumentTitleWithPartOpen_ModifiesTheDocument()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('Title ok', Format(TrySetTitle(P, 'renamed')));
        Observer.Observe('log after SetValue', Log.Take());
        Observer.Observe('docs', Docs());
        Observer.Observe('shown', Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_New_BetweenLines_AutoSplitKeyAndDocNoFromLink()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.First();
        Log.Take();
        P.Lines.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('Line No. after New', P.Lines."Line No.".Value());
        Observer.Observe('Name ok', Format(TrySetLineName(P, 'middle')));
        Observer.Observe('log after Name', Log.Take());
        P.Lines.Next();
        Observer.Observe('log after Next', Log.Take());
        Observer.Observe('lines', Lines());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_Action_InsertsLineAfterCurrent_GoToKeyOfIt()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.GoToKey('D1', 20000);
        Log.Take();
        P.Lines.AddLine.Invoke();
        Observer.Observe('log after AddLine', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('GoToKey 20005', Format(P.Lines.GoToKey('D1', 20005)) + ' ' + Shown(P));
        Observer.Observe('Next', Format(P.Lines.Next()) + ' ' + Shown(P));
        Observer.Observe('lines', Lines());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_Action_DeletesCurrentLine_ShownLineAfter()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.GoToKey('D1', 20000);
        Log.Take();
        P.Lines.DeleteLine.Invoke();
        Observer.Observe('log after DeleteLine', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('Next', Format(P.Lines.Next()) + ' ' + Shown(P));
        Observer.Observe('lines', Lines());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_LongPart_25Lines_WalkAndGoToKey()
    var
        P: TestPage "TPM Doc Card";
        Count: Integer;
    begin
        Seed(25);
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('part Last', Format(P.Lines.Last()) + ' ' + Shown(P));
        Observer.Observe('GoToKey line 24', Format(P.Lines.GoToKey('D1', 240000)) + ' ' + Shown(P));
        Observer.Observe('GoToKey line 12', Format(P.Lines.GoToKey('D1', 120000)) + ' ' + Shown(P));
        P.Lines.First();
        Count := 1;
        while P.Lines.Next() do
            Count += 1;
        Observer.Observe('lines walked with Next', Format(Count));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Part_LongPart_25Lines_ActionInsertsLineAndGoToKey()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(25);
        P.OpenEdit();
        P.Lines.GoToKey('D1', 220000);
        P.Lines.AddLine.Invoke();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('GoToKey 220005', Format(P.Lines.GoToKey('D1', 220005)) + ' ' + Shown(P));
        Observer.Observe('GoToKey 10000', Format(P.Lines.GoToKey('D1', 10000)) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    // The card stays open when this test ends with a value set on the part; the next test reads the lines.
    [Test]
    procedure TPM_Part_EndOfTest_LeftOpenAfterPartSetValue_Write()
    var
        P: TestPage "TPM Doc Card";
    begin
        Seed(3);
        P.OpenEdit();
        P.Lines.GoToKey('D1', 20000);
        P.Lines.Name.SetValue('left open');
        Log.Take();
    end;

    [Test]
    procedure TPM_Part_EndOfTest_LeftOpenAfterPartSetValue_Read()
    begin
        Observer.Observe('lines', Lines());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
