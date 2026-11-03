// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 81159, pages 81164-81167, codeunit 81163, test codeunit 81164
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a card run with Page.Run(Id, Rec): which Which strings OnFindRecord is asked, and whether the card shows (in a control, in
//   OnAfterGetRecord and in an action) the field that OnOpenPage set on Rec without Modify, or the row read again from the table.
//   Cards over a temporary source (SourceTableTemporary) and over the database table, each with an OnFindRecord that logs Which and
//   exits true without touching Rec, and without OnFindRecord. The caller hands a temporary record (one row, Descr = 'passed'), and for
//   the database cards also the stored row (Descr = 'stored').
//   Shape of Microsoft's page 554 "Analysis by Dimensions" (sets Rec."Account Filter" in OnOpenPage without Modify).
// Measured (BC 29.0): with OnFindRecord the card is asked OnFindRecord('=') once (not '=>'), after OnOpenPage, with Rec as OnOpenPage left it;
//   the field OnOpenPage set shows in the control, in OnAfterGetRecord and in the action, for a temporary and a database card and for a
//   temporary or a stored record passed in. Without OnFindRecord the row is read again: the field OnOpenPage set is blank, and the card
//   shows what the passed record held (Descr 'passed' or 'stored'). After the action: OnAfterGetRecord, then (with the trigger) OnFindRecord('=')
//   and OnAfterGetRecord again.
// Asked by al-runtime-rs (assumption page-run-record-onfindrecord-card).
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660.
// BC versions: all (CI)

table 81159 "LT BE Cf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Descr; Text[30]) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 81163 "LT BE Cf Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 81164 "LT BE Cf Card TF"
{
    PageType = Card;
    SourceTable = "LT BE Cf Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Descr + '/' + Rec.Note);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Cf Log";

    trigger OnOpenPage()
    begin
        Log.Add('O:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        Rec.Note := 'in memory';
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('F:' + Which + ':' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
    end;
}

page 81165 "LT BE Cf Card T"
{
    PageType = Card;
    SourceTable = "LT BE Cf Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Descr + '/' + Rec.Note);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Cf Log";

    trigger OnOpenPage()
    begin
        Log.Add('O:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        Rec.Note := 'in memory';
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
    end;
}

page 81166 "LT BE Cf Card DF"
{
    PageType = Card;
    SourceTable = "LT BE Cf Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Descr + '/' + Rec.Note);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Cf Log";

    trigger OnOpenPage()
    begin
        Log.Add('O:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        Rec.Note := 'in memory';
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('F:' + Which + ':' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
    end;
}

page 81167 "LT BE Cf Card D"
{
    PageType = Card;
    SourceTable = "LT BE Cf Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Show)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Descr + '/' + Rec.Note);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Cf Log";

    trigger OnOpenPage()
    begin
        Log.Add('O:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
        Rec.Note := 'in memory';
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id) + '/' + Rec.Descr + '/' + Rec.Note);
    end;
}

codeunit 81164 "LT BE Card OnFindRecord Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BE Cf Log";

    local procedure Store()
    var
        Row: Record "LT BE Cf Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Descr := 'stored';
        Row.Insert();
    end;

    local procedure MakeTemp(var TempRow: Record "LT BE Cf Row" temporary)
    begin
        TempRow.Id := 1;
        TempRow.Descr := 'passed';
        TempRow.Insert();
    end;

    [PageHandler]
    procedure TempFindHandler(var C: TestPage "LT BE Cf Card TF")
    begin
        Observer.Observe('open', Log.Take());
        Observer.Observe('descrCtl', C.DescrCtl.Value());
        Observer.Observe('noteCtl', C.NoteCtl.Value());
        C.Show.Invoke();
        Observer.Observe('action', Log.Take());
        C.Close();
        Observer.Observe('close', Log.Take());
    end;

    [Test]
    [HandlerFunctions('TempFindHandler')]
    procedure CardTempFind_PageRun_TempRec()
    var
        Row: Record "LT BE Cf Row" temporary;
    begin
        Store();
        MakeTemp(Row);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card TF", Row);
        Observer.Expect('open', 'O:1/passed/;F:=:1/passed/in memory;R:1/passed/in memory');
        Observer.Expect('descrCtl', 'passed');
        Observer.Expect('noteCtl', 'in memory');
        Observer.Expect('action', 'R:1/passed/in memory;A:passed/in memory;R:1/passed/in memory;F:=:1/passed/in memory;R:1/passed/in memory');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempFindHandler')]
    procedure CardTempFind_PageRun_StoredRec()
    var
        Row: Record "LT BE Cf Row";
    begin
        Store();
        Row.Get(1);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card TF", Row);
        Observer.Expect('open', 'O:1/stored/;F:=:1/stored/in memory;R:1/stored/in memory');
        Observer.Expect('descrCtl', 'stored');
        Observer.Expect('noteCtl', 'in memory');
        Observer.Expect('action', 'R:1/stored/in memory;A:stored/in memory;R:1/stored/in memory;F:=:1/stored/in memory;R:1/stored/in memory');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [PageHandler]
    procedure TempHandler(var C: TestPage "LT BE Cf Card T")
    begin
        Observer.Observe('open', Log.Take());
        Observer.Observe('descrCtl', C.DescrCtl.Value());
        Observer.Observe('noteCtl', C.NoteCtl.Value());
        C.Show.Invoke();
        Observer.Observe('action', Log.Take());
        C.Close();
        Observer.Observe('close', Log.Take());
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure CardTemp_PageRun_TempRec()
    var
        Row: Record "LT BE Cf Row" temporary;
    begin
        Store();
        MakeTemp(Row);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card T", Row);
        Observer.Expect('open', 'O:1/passed/;R:1/passed/');
        Observer.Expect('descrCtl', 'passed');
        Observer.Expect('noteCtl', '');
        Observer.Expect('action', 'R:1/passed/;A:passed/;R:1/passed/;R:1/passed/');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure CardTemp_PageRun_StoredRec()
    var
        Row: Record "LT BE Cf Row";
    begin
        Store();
        Row.Get(1);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card T", Row);
        Observer.Expect('open', 'O:1/stored/;R:1/stored/');
        Observer.Expect('descrCtl', 'stored');
        Observer.Expect('noteCtl', '');
        Observer.Expect('action', 'R:1/stored/;A:stored/;R:1/stored/;R:1/stored/');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [PageHandler]
    procedure DbFindHandler(var C: TestPage "LT BE Cf Card DF")
    begin
        Observer.Observe('open', Log.Take());
        Observer.Observe('descrCtl', C.DescrCtl.Value());
        Observer.Observe('noteCtl', C.NoteCtl.Value());
        C.Show.Invoke();
        Observer.Observe('action', Log.Take());
        C.Close();
        Observer.Observe('close', Log.Take());
    end;

    [Test]
    [HandlerFunctions('DbFindHandler')]
    procedure CardDbFind_PageRun_TempRec()
    var
        Row: Record "LT BE Cf Row" temporary;
    begin
        Store();
        MakeTemp(Row);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card DF", Row);
        Observer.Expect('open', 'O:1/passed/;F:=:1/passed/in memory;R:1/passed/in memory');
        Observer.Expect('descrCtl', 'passed');
        Observer.Expect('noteCtl', 'in memory');
        Observer.Expect('action', 'R:1/passed/in memory;A:passed/in memory;R:1/passed/in memory;F:=:1/passed/in memory;R:1/passed/in memory');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DbFindHandler')]
    procedure CardDbFind_PageRun_StoredRec()
    var
        Row: Record "LT BE Cf Row";
    begin
        Store();
        Row.Get(1);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card DF", Row);
        Observer.Expect('open', 'O:1/stored/;F:=:1/stored/in memory;R:1/stored/in memory');
        Observer.Expect('descrCtl', 'stored');
        Observer.Expect('noteCtl', 'in memory');
        Observer.Expect('action', 'R:1/stored/in memory;A:stored/in memory;R:1/stored/in memory;F:=:1/stored/in memory;R:1/stored/in memory');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [PageHandler]
    procedure DbHandler(var C: TestPage "LT BE Cf Card D")
    begin
        Observer.Observe('open', Log.Take());
        Observer.Observe('descrCtl', C.DescrCtl.Value());
        Observer.Observe('noteCtl', C.NoteCtl.Value());
        C.Show.Invoke();
        Observer.Observe('action', Log.Take());
        C.Close();
        Observer.Observe('close', Log.Take());
    end;

    [Test]
    [HandlerFunctions('DbHandler')]
    procedure CardDb_PageRun_TempRec()
    var
        Row: Record "LT BE Cf Row" temporary;
    begin
        Store();
        MakeTemp(Row);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card D", Row);
        Observer.Expect('open', 'O:1/passed/;R:1/passed/');
        Observer.Expect('descrCtl', 'passed');
        Observer.Expect('noteCtl', '');
        Observer.Expect('action', 'R:1/passed/;A:passed/;R:1/passed/;R:1/passed/');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DbHandler')]
    procedure CardDb_PageRun_StoredRec()
    var
        Row: Record "LT BE Cf Row";
    begin
        Store();
        Row.Get(1);
        Log.Take();
        Page.Run(Page::"LT BE Cf Card D", Row);
        Observer.Expect('open', 'O:1/stored/;R:1/stored/');
        Observer.Expect('descrCtl', 'stored');
        Observer.Expect('noteCtl', '');
        Observer.Expect('action', 'R:1/stored/;A:stored/;R:1/stored/;R:1/stored/');
        Observer.Expect('close', '');
        Observer.Verify();
    end;
}
