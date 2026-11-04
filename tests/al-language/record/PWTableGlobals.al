// Probe writer-c: table globals (ADR-021) open points. Observe-only: every test records values via "Probe Observer".
// Settles docs/probes-needed.md "Table globals (ADR-021)" rows: xRec in a plain procedure, Rename, records in arrays,
// SetTable target, Clear/Reset of record/collection globals, Page Insert/Modify without a validation.
// Fixtures: self-contained table 69700, 69701, page 69702, codeunit 69703.

table 69700 "PW TG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Counter: Integer;
        Tag: Text[30];
        Flag: Boolean;
        Dec: Decimal;
        Names: List of [Text];
        Dict: Dictionary of [Text, Integer];
        Inner: Record "PW TG Row";
        Opt: Option A,B,C;

    trigger OnInsert()
    begin
        LogLine('OnInsert ' + Describe());
    end;

    trigger OnModify()
    begin
        LogLine('OnModify ' + Describe() + ' xRec.Txt=' + xRec.Txt + ' xRec.' + xRec.Describe());
    end;

    trigger OnRename()
    begin
        LogLine('OnRename ' + Describe() + ' xRec.Id=' + xRec.Id + ' xRec.' + xRec.Describe());
    end;

    procedure LogLine(T: Text)
    var
        LogRec: Record "PW TG Log";
    begin
        LogRec.Init();
        LogRec.Line := CopyStr(T, 1, MaxStrLen(LogRec.Line));
        LogRec.Insert();
    end;

    procedure SetCounter(N: Integer)
    begin
        Counter := N;
    end;

    procedure SetAll()
    begin
        Counter := 7;
        Tag := 'tag';
        Flag := true;
        Dec := 1.5;
        Names.Add('n1');
        Names.Add('n2');
        Dict.Add('k', 1);
        Inner.Txt := 'inner';
        Opt := Opt::C;
    end;

    procedure Describe(): Text
    begin
        exit(StrSubstNo('globals[C=%1 T=%2 F=%3 D=%4 L=%5 Dict=%6 Inner=%7 Opt=%8]', Counter, Tag, Flag, Dec, Names.Count(), Dict.Count(), Inner.Txt, Opt));
    end;

    procedure XRecInfo(): Text
    begin
        exit('xRec.Id=' + xRec.Id + ' xRec.Txt=' + xRec.Txt + ' xRec.' + xRec.Describe());
    end;

    procedure SetXRecCounter(N: Integer)
    begin
        xRec.SetCounter(N);
    end;
}

table 69701 "PW TG Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Line; Text[250]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69702 "PW TG Card"
{
    PageType = Card;
    SourceTable = "PW TG Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ChangeInRec)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Txt := 'by action';
                    Rec.SetCounter(7);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Id := 'PGNEW';
        Rec.SetCounter(9);
    end;
}

codeunit 69703 "PW Table Globals Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Row: Record "PW TG Row";
        LogRec: Record "PW TG Log";
    begin
        Row.DeleteAll(false);
        LogRec.DeleteAll(false);
    end;

    local procedure ClearLog()
    var
        LogRec: Record "PW TG Log";
    begin
        LogRec.DeleteAll(false);
    end;

    local procedure LogText(): Text
    var
        LogRec: Record "PW TG Log";
        Result: Text;
    begin
        if LogRec.FindSet() then
            repeat
                Result += LogRec.Line + ' ; ';
            until LogRec.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure XRecPlainProc_NewVariable()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Observer.Observe('xrec_new_variable', Row.XRecInfo());
        Observer.Expect('xrec_new_variable', 'xRec.Id= xRec.Txt= xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure XRecPlainProc_ChangedInMemory_NotModified()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.Txt := 'db';
        Row.Insert();
        Row.SetCounter(4);
        Row.Txt := 'memory';
        Observer.Observe('xrec_after_insert_and_memory_change', Row.XRecInfo());
        Observer.Expect('xrec_after_insert_and_memory_change', 'xRec.Id= xRec.Txt= xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure XRecPlainProc_AfterGet()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.Txt := 'db';
        Row.Insert();
        Clear(Row);
        Row.Get('A');
        Row.Txt := 'edited';
        Observer.Observe('xrec_after_get_and_edit', Row.XRecInfo());
        Observer.Expect('xrec_after_get_and_edit', 'xRec.Id= xRec.Txt= xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure XRecPlainProc_AfterModify()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.Txt := 'db';
        Row.Insert();
        Row.SetCounter(3);
        Row.Txt := 'second';
        Row.Modify(true);
        Observer.Observe('xrec_after_modify', Row.XRecInfo());
        Observer.Observe('log', LogText());
        Observer.Expect('xrec_after_modify', 'xRec.Id= xRec.Txt= xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('log', 'OnModify globals[C=3 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] xRec.Txt=second xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; ');
        Observer.Verify();
    end;

    [Test]
    procedure XRecPlainProc_GlobalsSetThroughXRecStayVisible()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.SetXRecCounter(11);
        Observer.Observe('xrec_counter_after_set_in_plain_proc', Row.XRecInfo());
        Observer.Expect('xrec_counter_after_set_in_plain_proc', 'xRec.Id= xRec.Txt= xRec.globals[C=11 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_OnRenameSeesTheVariablesGlobals()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.Txt := 'db';
        Row.Insert();
        Row.SetCounter(5);
        Row.Rename('B');
        Observer.Observe('log_after_rename_with_counter_5', LogText());
        Observer.Observe('describe_after_rename', Row.Describe());
        Observer.Expect('log_after_rename_with_counter_5', 'OnRename globals[C=5 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] xRec.Id=A xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; ');
        Observer.Expect('describe_after_rename', 'globals[C=5 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_AfterGet_GlobalsAfterwards()
    var
        Row: Record "PW TG Row";
    begin
        Initialize();
        Row.Id := 'A';
        Row.Insert();
        Row.SetAll();
        Row.Rename('C');
        Observer.Observe('describe_after_setall_and_rename', Row.Describe());
        Observer.Observe('log', LogText());
        Observer.Expect('describe_after_setall_and_rename', 'globals[C=7 T=tag F=Yes D=1.5 L=2 Dict=1 Inner=inner Opt=C]');
        Observer.Expect('log', 'OnRename globals[C=7 T=tag F=Yes D=1.5 L=2 Dict=1 Inner=inner Opt=C] xRec.Id=A xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; ');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayOfRecords_EachElementHasItsOwnGlobals()
    var
        A: array[2] of Record "PW TG Row";
    begin
        A[1].SetCounter(3);
        Observer.Observe('a1', A[1].Describe());
        Observer.Observe('a2', A[2].Describe());
        A[2] := A[1];
        Observer.Observe('a2_after_assign', A[2].Describe());
        A[2].Copy(A[1]);
        Observer.Observe('a2_after_copy', A[2].Describe());
        A[1].Id := 'X';
        A[2].SetCounter(8);
        A[2].TransferFields(A[1]);
        Observer.Observe('a2_after_transferfields', A[2].Describe());
        Observer.Expect('a1', 'globals[C=3 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('a2', 'globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('a2_after_assign', 'globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('a2_after_copy', 'globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('a2_after_transferfields', 'globals[C=8 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TargetKeepsItsGlobals()
    var
        Src: Record "PW TG Row";
        Tgt: Record "PW TG Row";
        RecRef: RecordRef;
    begin
        Src.Id := 'S';
        Src.SetAll();
        Tgt.SetCounter(8);
        RecRef.GetTable(Src);
        RecRef.SetTable(Tgt);
        Observer.Observe('tgt_after_settable', Tgt.Id + ' ' + Tgt.Describe());
        Observer.Observe('src', Src.Describe());
        Observer.Expect('tgt_after_settable', 'S globals[C=8 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Expect('src', 'globals[C=7 T=tag F=Yes D=1.5 L=2 Dict=1 Inner=inner Opt=C]');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_AllGlobalKinds()
    var
        Row: Record "PW TG Row";
    begin
        Row.SetAll();
        Observer.Observe('before', Row.Describe());
        Clear(Row);
        Observer.Observe('after_clear', Row.Describe());
        Observer.Expect('before', 'globals[C=7 T=tag F=Yes D=1.5 L=2 Dict=1 Inner=inner Opt=C]');
        Observer.Expect('after_clear', 'globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure Reset_AllGlobalKinds()
    var
        Row: Record "PW TG Row";
    begin
        Row.SetAll();
        Row.Reset();
        Observer.Observe('after_reset', Row.Describe());
        Observer.Expect('after_reset', 'globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A]');
        Observer.Verify();
    end;

    [Test]
    procedure Init_AllGlobalKinds()
    var
        Row: Record "PW TG Row";
    begin
        Row.SetAll();
        Row.Init();
        Observer.Observe('after_init', Row.Describe());
        Observer.Expect('after_init', 'globals[C=7 T=tag F=Yes D=1.5 L=2 Dict=1 Inner=inner Opt=C]');
        Observer.Verify();
    end;

    [Test]
    procedure PageInsert_DraftRowFromNewAndClose_NoValidation()
    var
        Row: Record "PW TG Row";
        Card: TestPage "PW TG Card";
    begin
        Initialize();
        Card.OpenNew();
        Card.Close();
        Observer.Observe('rows_after_close', Format(Row.Count()));
        Observer.Observe('log', LogText());
        Observer.Expect('rows_after_close', '0');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PageInsert_NewThenSetTxtThenClose_ValidationBeforeInsert()
    var
        Row: Record "PW TG Row";
        Card: TestPage "PW TG Card";
    begin
        Initialize();
        Card.OpenNew();
        Card.Txt.SetValue('typed');
        Card.Close();
        Observer.Observe('rows_after_close', Format(Row.Count()));
        Observer.Observe('log', LogText());
        Observer.Expect('rows_after_close', '1');
        Observer.Expect('log', 'OnInsert globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; OnModify globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] xRec.Txt= xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; ');
        Observer.Verify();
    end;

    [Test]
    procedure PageModify_AfterActionChangedRec_NoValidation()
    var
        Row: Record "PW TG Row";
        Card: TestPage "PW TG Card";
    begin
        Initialize();
        Row.Id := 'E1';
        Row.Txt := 'orig';
        Row.Insert();
        ClearLog();
        Card.OpenEdit();
        Card.GoToKey('E1');
        Card.ChangeInRec.Invoke();
        Card.Close();
        Row.Get('E1');
        Observer.Observe('txt_after_close', Row.Txt);
        Observer.Observe('log', LogText());
        Observer.Expect('txt_after_close', 'by action');
        Observer.Expect('log', 'OnModify globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] xRec.Txt=orig xRec.globals[C=0 T= F=No D=0 L=0 Dict=0 Inner= Opt=A] ; ');
        Observer.Verify();
    end;
}
