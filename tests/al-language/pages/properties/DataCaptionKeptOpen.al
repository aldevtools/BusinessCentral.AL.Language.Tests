// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 77600-77609 (DKO Entry, DKO Log, DKO Mgt, six DKO pages, DKO Tests)
// Measured on BC 27.5, 28.5 and 29.0 (identical on all three). Probe: for al-runner's assumption data-caption-two-microsoft-opens-skipped. Two Worksheet opens outside the cells of
//   DataCaptionExprWorksheet.al and DataCaptionGetOpen.al. Both pages: SourceTableTemporary = true, InsertAllowed = false, a
//   DataCaptionExpression of their own; OnOpenPage inserts 0 or 1 rows into the temporary Rec.
//   Shape N: a Page variable's own procedure (SetDoc), then Run(), caught by a TestPage Trap; the expression is a page procedure
//     `if Rec."Doc Name" <> '' then exit(StrSubstNo(SelectedLbl, Rec."Doc Name")); exit('');` with SelectedLbl 'Picked - %1'.
//   Shape O: a Page variable's own procedure (SetSource), then SetTableView and RunModal(), answered by a ModalPageHandler; the
//     expression is `Mgt.GetCaption()`, a codeunit variable of the page whose procedure returns a Text variable of that codeunit.
//   Each shape on three pages: Pure (the expression as above), Logged (the same expression, which also logs DC=<value> in a
//   SingleInstance log, to count its runs and see Rec when it runs) and Plain (no DataCaptionExpression).
// Facts: what the test reads after the open on the Pure page equals what it reads on the Plain page (page-variable and Rec
//   controls, First and Next, Filter.GetFilter, an action that modifies Rec, Close); the caption of the Pure and Logged pages;
//   the log of the Logged page (runs before the Trap's first read or the handler, and after a Caption read).
// BC versions: 27.5, 28.5, 29.0

table 77600 "DKO Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc Name"; Text[50]) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 77601 "DKO Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        Rows: Integer;

    procedure Wipe(NewRows: Integer)
    begin
        Clear(Lines);
        Rows := NewRows;
    end;

    procedure RowsWanted(): Integer
    begin
        exit(Rows);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

codeunit 77602 "DKO Mgt"
{
    var
        CaptionText: Text;

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionText := NewCaption;
    end;

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

    procedure GetCaptionLogged(): Text
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('DC=' + CaptionText);
        exit(CaptionText);
    end;
}

page 77603 "DKO Nav Pure"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Nav';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { }
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77604 "DKO Nav Logged"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Nav Logged';
    DataCaptionExpression = GetCaptionText();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { }
            }
        }
    }

    var
        DocNo: Code[20];
        SelectedLbl: Label 'Picked - %1';

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;

    local procedure GetCaptionText(): Text
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('DC=' + Rec."Doc Name");
        if Rec."Doc Name" <> '' then
            exit(StrSubstNo(SelectedLbl, Rec."Doc Name"));
        exit('');
    end;
}

page 77605 "DKO Nav Plain"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Nav Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(DocCtl; DocNo) { }
            }
            repeater(Lines)
            {
                field(NameCtl; Rec."Doc Name") { }
            }
        }
    }

    var
        DocNo: Code[20];

    procedure SetDoc(NewDocNo: Code[20])
    begin
        DocNo := NewDocNo;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec."Doc Name" := 'Doc ' + DocNo;
            Rec.Insert();
        end;
    end;
}

page 77606 "DKO Lines Pure"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Lines';
    DataCaptionExpression = Mgt.GetCaption();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKO Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77607 "DKO Lines Logged"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Lines Logged';
    DataCaptionExpression = Mgt.GetCaptionLogged();
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKO Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

page 77608 "DKO Lines Plain"
{
    PageType = Worksheet;
    SourceTable = "DKO Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    Caption = 'DKO Lines Plain';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(QtyCtl; Rec.Qty) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calc)
            {
                trigger OnAction()
                begin
                    Rec.ModifyAll(Qty, 7);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "DKO Mgt";

    procedure SetSource(NewCaption: Text)
    begin
        Mgt.SetCaption(NewCaption);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "DKO Log";
    begin
        Log.Add('OnOpenPage');
        if Log.RowsWanted() = 1 then begin
            Rec."Entry No." := 1;
            Rec.Qty := 3;
            Rec.Insert();
        end;
    end;
}

codeunit 77609 "DKO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "DKO Log";
        Reads: Text;

    // Shape N: the reads a test makes after the trapped Run; the caption separately (a read of it may run the expression).
    local procedure NavReads(DocCtl: Text; Filter: Text; HasFirst: Boolean; Name: Text; HasNext: Boolean): Text
    begin
        exit(StrSubstNo('doc=%1 filter=%2 first=%3 name=%4 next=%5', DocCtl, Filter, HasFirst, Name, HasNext));
    end;

    [Test]
    procedure N_Pure_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Pure";
        P: TestPage "DKO Nav Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after', Log.Joined());
        Observer.Expect('reads', 'doc=D1 filter= first=No name= next=No');
        Observer.Expect('log', 'OnOpenPage | after run');
        Observer.Expect('caption', 'DKO Nav');
        Observer.Expect('log after', 'OnOpenPage | after run');
        Observer.Verify();
    end;

    [Test]
    procedure N_Pure_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Pure";
        P: TestPage "DKO Nav Pure";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Observe('log after', Log.Joined());
        Observer.Expect('reads', 'doc=D1 filter= first=Yes name=Doc D1 next=No');
        Observer.Expect('log', 'OnOpenPage | after run');
        Observer.Expect('caption', 'DKO Nav - Picked - Doc D1');
        Observer.Expect('log after', 'OnOpenPage | after run');
        Observer.Verify();
    end;

    [Test]
    procedure N_Plain_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Plain";
        P: TestPage "DKO Nav Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after', Log.Joined());
        Observer.Expect('reads', 'doc=D1 filter= first=No name= next=No');
        Observer.Expect('log', 'OnOpenPage | after run');
        Observer.Expect('log after', 'OnOpenPage | after run');
        Observer.Verify();
    end;

    [Test]
    procedure N_Plain_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Plain";
        P: TestPage "DKO Nav Plain";
        HasFirst: Boolean;
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        HasFirst := P.First();
        Observer.Observe('reads', NavReads(P.DocCtl.Value, P.Filter.GetFilter("Entry No."), HasFirst, P.NameCtl.Value, P.Next()));
        Observer.Observe('log', Log.Joined());
        P.Close();
        Observer.Observe('log after', Log.Joined());
        Observer.Expect('reads', 'doc=D1 filter= first=Yes name=Doc D1 next=No');
        Observer.Expect('log', 'OnOpenPage | after run');
        Observer.Expect('log after', 'OnOpenPage | after run');
        Observer.Verify();
    end;

    [Test]
    procedure N_Logged_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Logged";
        P: TestPage "DKO Nav Logged";
    begin
        Log.Wipe(0);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Expect('doc', 'D1');
        Observer.Expect('log', 'OnOpenPage | DC= | after run');
        Observer.Expect('caption', 'DKO Nav Logged');
        Observer.Expect('log after caption', 'OnOpenPage | DC= | after run');
        Observer.Verify();
    end;

    [Test]
    procedure N_Logged_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        NavPage: Page "DKO Nav Logged";
        P: TestPage "DKO Nav Logged";
    begin
        Log.Wipe(1);
        P.Trap();
        NavPage.SetDoc('D1');
        NavPage.Run();
        Log.Add('after run');
        Observer.Observe('doc', P.DocCtl.Value);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('caption', P.Caption());
        Observer.Observe('log after caption', Log.Joined());
        P.Close();
        Observer.Expect('doc', 'D1');
        Observer.Expect('log', 'OnOpenPage | DC=Doc D1 | after run');
        Observer.Expect('caption', 'DKO Nav Logged - Picked - Doc D1');
        Observer.Expect('log after caption', 'OnOpenPage | DC=Doc D1 | after run');
        Observer.Verify();
    end;

    // Shape O: the handler invokes the action, reads the row and (in the caption handlers) the caption.
    [Test]
    [HandlerFunctions('LinesPureHandler')]
    procedure O_Pure_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesPure(0, Observer);
        Observer.Expect('reads', 'first=No qty= filter=1 cap=DKO Lines');
        Observer.Expect('log', 'OnOpenPage | H0 | H1 | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinesPureHandler')]
    procedure O_Pure_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesPure(1, Observer);
        Observer.Expect('reads', 'first=Yes qty=7.00 filter=1 cap=DKO Lines - Src');
        Observer.Expect('log', 'OnOpenPage | H0 | H1 | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinesPlainHandler')]
    procedure O_Plain_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesPlain(0, Observer);
        Observer.Expect('reads', 'first=No qty= filter=1');
        Observer.Expect('log', 'OnOpenPage | H0 | H1 | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinesPlainHandler')]
    procedure O_Plain_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesPlain(1, Observer);
        Observer.Expect('reads', 'first=Yes qty=7.00 filter=1');
        Observer.Expect('log', 'OnOpenPage | H0 | H1 | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinesLoggedHandler')]
    procedure O_Logged_Modal_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesLogged(0, Observer);
        Observer.Expect('reads', 'cap=DKO Lines Logged');
        Observer.Expect('log', 'OnOpenPage | DC=Src | H0 | H1 | after run');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinesLoggedHandler')]
    procedure O_Logged_Modal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LinesLogged(1, Observer);
        Observer.Expect('reads', 'cap=DKO Lines Logged - Src');
        Observer.Expect('log', 'OnOpenPage | DC=Src | H0 | H1 | after run');
        Observer.Verify();
    end;

    local procedure LinesPure(Rows: Integer; var Observer: Codeunit "Probe Observer")
    var
        LinesPage: Page "DKO Lines Pure";
        View: Record "DKO Entry" temporary;
    begin
        Log.Wipe(Rows);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
    end;

    local procedure LinesPlain(Rows: Integer; var Observer: Codeunit "Probe Observer")
    var
        LinesPage: Page "DKO Lines Plain";
        View: Record "DKO Entry" temporary;
    begin
        Log.Wipe(Rows);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
    end;

    local procedure LinesLogged(Rows: Integer; var Observer: Codeunit "Probe Observer")
    var
        LinesPage: Page "DKO Lines Logged";
        View: Record "DKO Entry" temporary;
    begin
        Log.Wipe(Rows);
        Reads := '';
        View.SetRange("Entry No.", 1);
        LinesPage.SetSource('Src');
        LinesPage.SetTableView(View);
        LinesPage.RunModal();
        Log.Add('after run');
        Observer.Observe('reads', Reads);
        Observer.Observe('log', Log.Joined());
    end;

    [ModalPageHandler]
    procedure LinesPureHandler(var P: TestPage "DKO Lines Pure")
    var
        HasFirst: Boolean;
    begin
        Log.Add('H0');
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3 cap=%4', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."), P.Caption());
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure LinesPlainHandler(var P: TestPage "DKO Lines Plain")
    var
        HasFirst: Boolean;
    begin
        Log.Add('H0');
        P.Calc.Invoke();
        HasFirst := P.First();
        Reads := StrSubstNo('first=%1 qty=%2 filter=%3', HasFirst, P.QtyCtl.Value, P.Filter.GetFilter("Entry No."));
        Log.Add('H1');
    end;

    [ModalPageHandler]
    procedure LinesLoggedHandler(var P: TestPage "DKO Lines Logged")
    begin
        Log.Add('H0');
        Reads := 'cap=' + P.Caption();
        Log.Add('H1');
    end;
}
