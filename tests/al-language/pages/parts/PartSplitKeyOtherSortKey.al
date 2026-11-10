// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62610 62611, log codeunit 62612, part pages 62613..62615, host pages
//   62616..62621, test codeunit 62622
// Probe: observe-only. Area: the line number AutoSplitKey gives a new row of a ListPart that is not read in primary key order.
//   TpmDelayedInsertAutoSplitKey.al pins the number at the end, between two lines and before the first line of a list in primary key
//   order. Not pinned (al-runner issue 7402): a part whose SubPageView sorts by a secondary key (ascending and descending), by the
//   primary key descending, a part page with its own SourceTableView in the secondary key, and the same with DelayedInsert.
//   PkAsc is the control (no view).
// Lines of H1 (Line No. / Seq No.): 10000/20, 20000/40, 30000/10, 40000/30. In Seq No. order: 30000, 10000, 40000, 20000, so the
//   neighbours of a row differ between the primary key and the view. H2 has no lines.
// Steps per host: New after Last, after First, after First and Next, with no move, on the empty part, two new rows in a row, and
//   the reported shape (RunModal, the handler adds a row and invokes OK).
// Observed: the part triggers with Rec and xRec line numbers (log), the Line No. the new row shows, and the stored lines.
// local object: the part properties AutoSplitKey, DelayedInsert, SourceTableView and the SubPageView of each host are what the test checks
// BC versions: 27, 28, 29

table 62610 "PG SK Head"
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

table 62611 "PG SK Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Seq No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Descr; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
        key(Seq; "Head Code", "Seq No.") { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('T-I ' + Format("Line No."));
    end;
}

codeunit 62612 "PG SK Log"
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

page 62613 "PG SK Lines"
{
    PageType = ListPart;
    SourceTable = "PG SK Line";
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
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62614 "PG SK Lines Own View"
{
    PageType = ListPart;
    SourceTable = "PG SK Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    SourceTableView = sorting("Head Code", "Seq No.");

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62615 "PG SK Lines Delayed"
{
    PageType = ListPart;
    SourceTable = "PG SK Line";
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
                field("Seq No."; Rec."Seq No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG SK Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' x=' + Format(xRec."Line No.") + ' below=' + Format(BelowxRec));
        exit(true);
    end;
}

page 62616 "PG SK Host PkAsc"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
            }
        }
    }
}

page 62617 "PG SK Host SeqAsc"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 62618 "PG SK Host SeqDesc"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.") order(descending);
            }
        }
    }
}

page 62619 "PG SK Host PkDesc"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Line No.") order(descending);
            }
        }
    }
}

page 62620 "PG SK Host OwnSeq"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines Own View")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
            }
        }
    }
}

page 62621 "PG SK Host SeqDelayed"
{
    PageType = Card;
    SourceTable = "PG SK Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(Lines; "PG SK Lines Delayed")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = sorting("Head Code", "Seq No.");
            }
        }
    }
}

codeunit 62622 "PG SK Split Key Other Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG SK Log";

    local procedure Seed()
    var
        Head: Record "PG SK Head";
        Line: Record "PG SK Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Insert();
        Head.Code := 'H2';
        Head.Insert();
        AddLine(10000, 20);
        AddLine(20000, 40);
        AddLine(30000, 10);
        AddLine(40000, 30);
        Log.Take();
    end;

    local procedure AddLine(LineNo: Integer; SeqNo: Integer)
    var
        Line: Record "PG SK Line";
    begin
        Line.Init();
        Line."Head Code" := 'H1';
        Line."Line No." := LineNo;
        Line."Seq No." := SeqNo;
        Line.Descr := 'old';
        Line.Insert();
    end;

    local procedure Lines(HeadCode: Code[10]) Result: Text
    var
        Line: Record "PG SK Line";
    begin
        Line.SetRange("Head Code", HeadCode);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + '/' + Format(Line."Seq No.") + '=' + Line.Descr + ' ';
            until Line.Next() = 0;
        Result := '[' + Result + ']';
    end;

    [Test]
    procedure PkAsc_NewAfterLast()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkAsc_NewAfterFirst()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkAsc_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkAsc_NewWithNoMove()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkAsc_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure PkAsc_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host PkAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PkAscModalHandler')]
    procedure PkAsc_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host PkAsc", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure PkAscModalHandler(var Card: TestPage "PG SK Host PkAsc")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

    [Test]
    procedure SeqAsc_NewAfterLast()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqAsc_NewAfterFirst()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqAsc_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqAsc_NewWithNoMove()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqAsc_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqAsc_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host SeqAsc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SeqAscModalHandler')]
    procedure SeqAsc_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host SeqAsc", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure SeqAscModalHandler(var Card: TestPage "PG SK Host SeqAsc")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

    [Test]
    procedure SeqDesc_NewAfterLast()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDesc_NewAfterFirst()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDesc_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDesc_NewWithNoMove()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDesc_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDesc_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host SeqDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SeqDescModalHandler')]
    procedure SeqDesc_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host SeqDesc", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure SeqDescModalHandler(var Card: TestPage "PG SK Host SeqDesc")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

    [Test]
    procedure PkDesc_NewAfterLast()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDesc_NewAfterFirst()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDesc_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDesc_NewWithNoMove()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDesc_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure PkDesc_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host PkDesc";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PkDescModalHandler')]
    procedure PkDesc_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host PkDesc", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure PkDescModalHandler(var Card: TestPage "PG SK Host PkDesc")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

    [Test]
    procedure OwnSeq_NewAfterLast()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure OwnSeq_NewAfterFirst()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure OwnSeq_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure OwnSeq_NewWithNoMove()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure OwnSeq_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure OwnSeq_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host OwnSeq";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OwnSeqModalHandler')]
    procedure OwnSeq_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host OwnSeq", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure OwnSeqModalHandler(var Card: TestPage "PG SK Host OwnSeq")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

    [Test]
    procedure SeqDelayed_NewAfterLast()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.Last();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDelayed_NewAfterFirst()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDelayed_NewAfterFirstAndNext()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Card.Lines.First();
        Card.Lines.Next();
        Observer.Observe('row before New', Card.Lines."Line No.".Value);
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDelayed_NewWithNoMove()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H1'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDelayed_NewOnEmptyPart()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Log.Take();
        Card.Lines.New();
        Observer.Observe('log New', Log.Take());
        Observer.Observe('shown after New', Card.Lines."Line No.".Value);
        Card.Lines.Descr.SetValue('new');
        Observer.Observe('log typed', Log.Take());
        Observer.Observe('shown after typed', Card.Lines."Line No.".Value);
        Observer.Observe('lines after typed', Lines('H2'));
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure SeqDelayed_TwoNewRowsInARow()
    var
        Card: TestPage "PG SK Host SeqDelayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H1');
        Log.Take();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new1');
        Observer.Observe('log first', Log.Take());
        Card.Lines.New();
        Observer.Observe('log second New', Log.Take());
        Card.Lines.Descr.SetValue('new2');
        Card.Lines."Seq No.".SetValue(15);
        Observer.Observe('log second typed', Log.Take());
        Observer.Observe('shown', Card.Lines."Line No.".Value);
        Card.Close();
        Observer.Observe('log close', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SeqDelayedModalHandler')]
    procedure SeqDelayed_RunModalHandlerAddsRowThenOK()
    var
        Head: Record "PG SK Head";
        Result: Action;
    begin
        Seed();
        Head.Get('H1');
        Result := Page.RunModal(Page::"PG SK Host SeqDelayed", Head);
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines('H1'));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure SeqDelayedModalHandler(var Card: TestPage "PG SK Host SeqDelayed")
    begin
        Card.Lines.New();
        Card.Lines.Descr.SetValue('modal');
        Card.Lines."Seq No.".SetValue(25);
        Card.OK().Invoke();
    end;

}
