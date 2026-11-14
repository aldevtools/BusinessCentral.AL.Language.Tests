// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62690 62691 62697, log codeunit 62692, part pages 62693 62698, host pages
//   62694 62695 62699, test codeunit 62696
// Probe: observe-only. Area: the line number AutoSplitKey gives a new row of a ListPart whose SubPageView sorts by a secondary key, in the
//   shapes PartSplitKeyOtherSortKey.al does not measure (al-runner issue 7402):
//   1. the Card host run by Page.RunModal as a statement (not in lookup mode); PartSplitKeyOtherSortKey.al:584 uses the return value;
//   2. a RunModal handler on an empty part (the file measures the handler only on a part with rows, where New() raises);
//   3. a Document host (the file measures Card hosts only);
//   4. three values typed into the new row (the file types one or two);
//   5. a typed field whose table OnValidate trigger sets another field of the row.
// Lines of H1 (Line No. / Seq No.): 10000/20, 20000/40, 30000/10, 40000/30. In Seq No. order: 30000, 10000, 40000, 20000. H2 has no lines.
// Observed: the part and table triggers with the Rec and xRec line numbers (log), the Line No. the new row shows, the RunModal result or
//   error, and the stored lines.
// local object: the part properties AutoSplitKey and the SubPageView, the host page type and how the host is run are what the test checks
// BC versions: 27, 28, 29

table 62690 "PG SR Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 62691 "PG SR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Seq No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Descr; Text[30]) { DataClassification = SystemMetadata; }
        field(5; Qty; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
        key(Seq; "Head Code", "Seq No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('T-I ' + Format("Line No."));
    end;
}

table 62697 "PG SR Line V"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Seq No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Descr; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PG SR Log";
            begin
                Log.Add('T-V ' + Format("Line No."));
                Qty := 7;
            end;
        }
        field(5; Qty; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
        key(Seq; "Head Code", "Seq No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('T-I ' + Format("Line No."));
    end;
}

codeunit 62692 "PG SR Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

page 62693 "PG SR Lines"
{
    PageType = ListPart;
    SourceTable = "PG SR Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62698 "PG SR Lines V"
{
    PageType = ListPart;
    SourceTable = "PG SR Line V";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG SR Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62694 "PG SR Card"
{
    PageType = Card;
    SourceTable = "PG SR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SR Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62695 "PG SR Document"
{
    PageType = Document;
    SourceTable = "PG SR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SR Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62699 "PG SR Card V"
{
    PageType = Card;
    SourceTable = "PG SR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SR Lines V")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

codeunit 62696 "PG SR Split Key RunModal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG SR Log";
        TypeThree: Boolean;

    local procedure Seed()
    var
        Head: Record "PG SR Head";
        Line: Record "PG SR Line";
        LineV: Record "PG SR Line V";
    begin
        Line.DeleteAll();
        LineV.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Insert();
        Head.Code := 'H2';
        Head.Insert();
        AddLine(10000, 20);
        AddLine(20000, 40);
        AddLine(30000, 10);
        AddLine(40000, 30);
        TypeThree := false;
        Log.Take();
    end;

    local procedure AddLine(LineNo: Integer; SeqNo: Integer)
    var
        Line: Record "PG SR Line";
        LineV: Record "PG SR Line V";
    begin
        Line.Init();
        Line."Head Code" := 'H1';
        Line."Line No." := LineNo;
        Line."Seq No." := SeqNo;
        Line.Descr := 'old';
        Line.Insert();
        LineV.TransferFields(Line);
        LineV.Insert();
    end;

    local procedure Lines(HeadCode: Code[10]) Result: Text
    var
        Line: Record "PG SR Line";
    begin
        Line.SetRange("Head Code", HeadCode);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Format(Line."Seq No.") + '=' + Line.Descr + ':' + Format(Line.Qty) + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    local procedure LinesV(HeadCode: Code[10]) Result: Text
    var
        Line: Record "PG SR Line V";
    begin
        Line.SetRange("Head Code", HeadCode);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Format(Line."Seq No.") + '=' + Line.Descr + ':' + Format(Line.Qty) + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    // Cell 1: RunModal as a statement on a part with rows (the handler starts the line with no move, as :766 does).
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Statement_RowsPart()
    var
        Head: Record "PG SR Head";
    begin
        Observer.Discard();
        Seed();
        Head.Get('H1');
        asserterror
        begin
            Page.RunModal(Page::"PG SR Card", Head);
            Error('');
        end;
        Observer.ObserveError('RunModal');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    // Cell 1 and 2: RunModal as a statement on the empty part.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Statement_EmptyPart()
    var
        Head: Record "PG SR Head";
    begin
        Observer.Discard();
        Seed();
        Head.Get('H2');
        Page.RunModal(Page::"PG SR Card", Head);
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    // Cell 2: the return value used (lookup mode) on the empty part.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Lookup_EmptyPart()
    var
        Head: Record "PG SR Head";
        Result: Action;
    begin
        Observer.Discard();
        Seed();
        Head.Get('H2');
        Result := Page.RunModal(Page::"PG SR Card", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    // Cells 2 and 4: the reporter's handler, three values, lookup mode and as a statement, on the empty part.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Lookup_EmptyPart_ThreeValues()
    var
        Head: Record "PG SR Head";
        Result: Action;
    begin
        Observer.Discard();
        Seed();
        TypeThree := true;
        Head.Get('H2');
        Result := Page.RunModal(Page::"PG SR Card", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Statement_EmptyPart_ThreeValues()
    var
        Head: Record "PG SR Head";
    begin
        Observer.Discard();
        Seed();
        TypeThree := true;
        Head.Get('H2');
        Page.RunModal(Page::"PG SR Card", Head);
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure CardHandler(var Card: TestPage "PG SR Card")
    begin
        Card.Lines.New();
        Observer.Observe('handler New', Log.Take());
        Card.Lines.Descr.SetValue('modal');
        Observer.Observe('handler Descr', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('handler Seq', Log.Take());
        if TypeThree then begin
            Card.Lines.Qty.SetValue(3);
            Observer.Observe('handler Qty', Log.Take());
        end;
        Observer.Observe('handler shown', Card.Lines."Line No.".Value);
        Card.OK().Invoke();
    end;

    // Cell 4: three values on a Card the test opened, after Last (the two-value form is PartSplitKeyOtherSortKey.al:599).
    [Test]
    procedure Card_AfterLast_ThreeValues()
    var
        Card: TestPage "PG SR Card";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log Descr', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('log Seq', Log.Take());
        Card.Lines.Qty.SetValue(3);
        Observer.Observe('log Qty', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    // Cell 3: a Document host, after Last and on the empty part.
    [Test]
    procedure Document_AfterLast()
    var
        Doc: TestPage "PG SR Document";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('log New', Log.Take());
        Doc.Lines.Descr.SetValue('new');
        Observer.Observe('log Descr', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value);
        Doc.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure Document_EmptyPart()
    var
        Doc: TestPage "PG SR Document";
    begin
        Observer.Discard();
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H2');
        Log.Take();
        Doc.Lines.New();
        Observer.Observe('log New', Log.Take());
        Doc.Lines.Descr.SetValue('new');
        Observer.Observe('log Descr', Log.Take());
        Observer.Observe('shown', Doc.Lines."Line No.".Value);
        Doc.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    // Cell 5: a typed field with a table OnValidate trigger that sets another field, after Last.
    [Test]
    procedure TableValidate_AfterLast()
    var
        Card: TestPage "PG SR Card V";
    begin
        Observer.Discard();
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log Descr', Log.Take());
        Card.Lines."Seq No.".SetValue(25);
        Observer.Observe('log Seq', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Qty.Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', LinesV('H1'));
        Observer.Finish();
    end;
}
