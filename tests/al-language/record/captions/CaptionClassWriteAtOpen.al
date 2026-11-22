// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 75820 to 75822, log codeunit 75820 (SingleInstance, used only by test codeunit 75829),
//   pages 75820 to 75825, test codeunit 75829
// local object: the CaptionClass expression of the table fields is the thing under test, so the tables and pages are own objects (standing rule 2)
// Probe: al-runner issue 7391 (follow-up). A CaptionClass expression that really executes a database write while a page opens, as the
//   expression of Acc. Schedule Line "Dimension 1 Filter" can reach Record.Modify. Questions: does the open raise, how many times does the
//   expression run with the empty record and with the row, and which of its writes are still there after the open and after the Close.
// Area: writes executed in a CaptionClass expression.
//   Expressions (each counts its runs per field in the SingleInstance log, empty record or row, before it writes):
//     f10 inserts a CWO Hit row on every run; f11 only when the record is a row (Id <> 0); f12 only for the empty record (Id = 0);
//     f13 Get and Modify of a counter row (Runs + 1); f14 Rec.Modify() when the record is a row; f15 ModifyAll on a counter row (Touched);
//     f16 deletes one of 50 marker rows on every run.
//   Readers: Card pages that show f10 to f12, f13, f14, f15 or f16, opened with OpenNew, OpenEdit and OpenView (one stored row Id 1), a List
//   with f10 to f12, and FieldCaption on the empty record and on the row.
//   Per case: how far it came (stage open, close or done), the error ('no error' when nothing raised), then after the open and after the
//   Close: runs per field (f<no>:<empty runs>/<row runs>), CWO Hit rows per field, counter f13 runs, f15 Touched, marker rows left, the row's
//   Name. The case runs inside asserterror, so its writes are rolled back before the next case.
// Neighbours (not repeated here): CaptionClassStateFreeCalls.al (expressions that write nothing, and Message, Confirm, Error branches),
//   SxCaptionClassCount.al and testpage/Y61CaptionClassCount.al (run counts of expressions without writes).
// Not covered: Rename, DeleteAll and RecordRef writes; the Acc. Schedule Overview page itself (Base Application data).
// What BC did (27.5, 28.5 and 29.0 alike): no open, Close or FieldCaption raised, and every write the expressions made was still there
//   after the Close. An open runs the expression of every field of the source table, also of fields not on the page, 9 to 11 times with the
//   empty record; a field shown on the page runs once more, with the row after OpenEdit and OpenView and with the empty record after
//   OpenNew. Close runs none. FieldCaption runs the expression once, on the record it is called on.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 75820 "CWO Log"
{
    SingleInstance = true;

    var
        EmptyRuns: array[7] of Integer;
        RowRuns: array[7] of Integer;

    // FieldNumber is 10 to 16.
    procedure Hit(FieldNumber: Integer; RowId: Integer)
    begin
        if RowId = 0 then
            EmptyRuns[FieldNumber - 9] += 1
        else
            RowRuns[FieldNumber - 9] += 1;
    end;

    // 'f10:<empty runs>/<row runs> ...' for the fields that ran, 'none' when nothing ran. Clears the counts.
    procedure Take(): Text
    var
        Result: Text;
        Index: Integer;
    begin
        for Index := 1 to 7 do begin
            if (EmptyRuns[Index] <> 0) or (RowRuns[Index] <> 0) then
                Result += 'f' + Format(Index + 9) + ':' + Format(EmptyRuns[Index]) + '/' + Format(RowRuns[Index]) + ' ';
            EmptyRuns[Index] := 0;
            RowRuns[Index] := 0;
        end;
        if Result = '' then
            exit('none');
        exit(Result.TrimEnd());
    end;
}

table 75821 "CWO Hit"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Field No."; Integer) { }
        field(3; "Row Id"; Integer) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 75822 "CWO Counter"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Integer) { }
        field(2; Runs; Integer) { }
        field(3; Touched; Boolean) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 75820 "CWO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(10; "Ins Always"; Integer) { CaptionClass = InsAlwaysCc(); }
        field(11; "Ins Row"; Integer) { CaptionClass = InsRowCc(); }
        field(12; "Ins Empty"; Integer) { CaptionClass = InsEmptyCc(); }
        field(13; "Mod Counter"; Integer) { CaptionClass = ModCounterCc(); }
        field(14; "Self Modify"; Integer) { CaptionClass = SelfModifyCc(); }
        field(15; "Modify All"; Integer) { CaptionClass = ModifyAllCc(); }
        field(16; "Delete One"; Integer) { CaptionClass = DeleteOneCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "CWO Log";

    local procedure AddHit(FieldNumber: Integer)
    var
        HitRow: Record "CWO Hit";
    begin
        HitRow.Init();
        HitRow."Field No." := FieldNumber;
        HitRow."Row Id" := Id;
        HitRow.Insert();
    end;

    local procedure InsAlwaysCc(): Text
    begin
        Log.Hit(10, Id);
        AddHit(10);
        exit('3,Ins Always Cap');
    end;

    local procedure InsRowCc(): Text
    begin
        Log.Hit(11, Id);
        if Id <> 0 then
            AddHit(11);
        exit('3,Ins Row Cap');
    end;

    local procedure InsEmptyCc(): Text
    begin
        Log.Hit(12, Id);
        if Id = 0 then
            AddHit(12);
        exit('3,Ins Empty Cap');
    end;

    local procedure ModCounterCc(): Text
    var
        Counter: Record "CWO Counter";
    begin
        Log.Hit(13, Id);
        if Counter.Get(13) then begin
            Counter.Runs += 1;
            Counter.Modify();
        end;
        exit('3,Mod Counter Cap');
    end;

    local procedure SelfModifyCc(): Text
    begin
        Log.Hit(14, Id);
        if Id <> 0 then
            Rec.Modify();
        exit('3,Self Modify Cap');
    end;

    local procedure ModifyAllCc(): Text
    var
        Counter: Record "CWO Counter";
    begin
        Log.Hit(15, Id);
        Counter.SetRange("Code", 15);
        Counter.ModifyAll(Touched, true);
        exit('3,Modify All Cap');
    end;

    local procedure DeleteOneCc(): Text
    var
        Counter: Record "CWO Counter";
    begin
        Log.Hit(16, Id);
        Counter.SetFilter("Code", '>=1000');
        if Counter.FindFirst() then
            Counter.Delete();
        exit('3,Delete One Cap');
    end;
}

page 75820 "CWO Ins Card"
{
    PageType = Card;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(C10; Rec."Ins Always") { ApplicationArea = All; }
            field(C11; Rec."Ins Row") { ApplicationArea = All; }
            field(C12; Rec."Ins Empty") { ApplicationArea = All; }
        }
    }
}

page 75821 "CWO Mod Card"
{
    PageType = Card;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(C13; Rec."Mod Counter") { ApplicationArea = All; }
        }
    }
}

page 75822 "CWO Self Card"
{
    PageType = Card;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(C14; Rec."Self Modify") { ApplicationArea = All; }
        }
    }
}

page 75823 "CWO ModAll Card"
{
    PageType = Card;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(C15; Rec."Modify All") { ApplicationArea = All; }
        }
    }
}

page 75824 "CWO Del Card"
{
    PageType = Card;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(C16; Rec."Delete One") { ApplicationArea = All; }
        }
    }
}

page 75825 "CWO Ins List"
{
    PageType = List;
    SourceTable = "CWO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(C10; Rec."Ins Always") { ApplicationArea = All; }
                field(C11; Rec."Ins Row") { ApplicationArea = All; }
                field(C12; Rec."Ins Empty") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 75829 "CWO Write Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "CWO Log";

    // One row (Id 1, Name one), counter rows 13 and 15, and 50 marker rows (Code 1000 to 1049); the log is cleared.
    local procedure Seed()
    var
        Row: Record "CWO Row";
        HitRow: Record "CWO Hit";
        Counter: Record "CWO Counter";
        Index: Integer;
    begin
        Row.DeleteAll();
        HitRow.DeleteAll();
        Counter.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Counter."Code" := 13;
        Counter.Insert();
        Counter."Code" := 15;
        Counter.Insert();
        for Index := 1000 to 1049 do begin
            Counter."Code" := Index;
            Counter.Insert();
        end;
        Log.Take();
    end;

    local procedure State(): Text
    var
        Row: Record "CWO Row";
        HitRow: Record "CWO Hit";
        Counter: Record "CWO Counter";
        Result: Text;
        FieldNumber: Integer;
    begin
        Result := 'runs=' + Log.Take() + ' hits=';
        for FieldNumber := 10 to 12 do begin
            HitRow.SetRange("Field No.", FieldNumber);
            Result += Format(HitRow.Count()) + '/';
        end;
        if Counter.Get(13) then
            Result += ' c13=' + Format(Counter.Runs);
        if Counter.Get(15) then
            Result += ' t15=' + Format(Counter.Touched);
        Counter.SetFilter("Code", '>=1000');
        Result += ' markers=' + Format(Counter.Count());
        Result += ' rows=' + Format(Row.Count());
        if Row.Get(1) then
            Result += ' name=' + Row.Name;
        exit(Result);
    end;

    local procedure InsCardCase(Opening: Text): Text
    var
        Card: TestPage "CWO Ins Card";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure ModCardCase(Opening: Text): Text
    var
        Card: TestPage "CWO Mod Card";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure SelfCardCase(Opening: Text): Text
    var
        Card: TestPage "CWO Self Card";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure ModAllCardCase(Opening: Text): Text
    var
        Card: TestPage "CWO ModAll Card";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure DelCardCase(Opening: Text): Text
    var
        Card: TestPage "CWO Del Card";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure InsListCase(Opening: Text): Text
    var
        Card: TestPage "CWO Ins List";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        ClearLastError();
        Stage := 'open';
        asserterror begin
            case Opening of
                'OpenNew':
                    Card.OpenNew();
                'OpenEdit':
                    Card.OpenEdit();
                'OpenView':
                    Card.OpenView();
            end;
            Got := ' open: ' + State();
            Stage := 'close';
            Card.Close();
            Got += ' close: ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    local procedure FieldCaptionCase(FieldNumber: Integer; RowId: Integer): Text
    var
        Row: Record "CWO Row";
        Got: Text;
        Stage: Text;
    begin
        Seed();
        if RowId <> 0 then
            Row.Get(RowId);
        ClearLastError();
        Stage := 'read';
        asserterror begin
            case FieldNumber of
                10:
                    Got := Row.FieldCaption("Ins Always");
                11:
                    Got := Row.FieldCaption("Ins Row");
                12:
                    Got := Row.FieldCaption("Ins Empty");
                13:
                    Got := Row.FieldCaption("Mod Counter");
                14:
                    Got := Row.FieldCaption("Self Modify");
                15:
                    Got := Row.FieldCaption("Modify All");
                16:
                    Got := Row.FieldCaption("Delete One");
            end;
            Got := ' caption=' + Got + ' ' + State();
            Stage := 'done';
            Error('no error');
        end;
        Got := 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}' + Got;
        ClearLastError();
        exit(Got);
    end;

    [Test]
    procedure WriteCaption_InsertCard_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', InsCardCase('OpenNew'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:12/0 f11:12/0 f12:12/0 f13:11/0 f14:11/0 f15:11/0 f16:11/0 hits=12/0/12/ c13=11 t15=Yes markers=39 rows=1 name=one close: runs=none hits=12/0/12/ c13=11 t15=Yes markers=39 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_InsertCard_OpenEditOpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenEdit', InsCardCase('OpenEdit'));
        Observer.Observe('OpenView', InsCardCase('OpenView'));
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:11/1 f11:11/1 f12:11/1 f13:11/0 f14:11/0 f15:11/0 f16:11/0 hits=12/1/11/ c13=11 t15=Yes markers=39 rows=1 name=one close: runs=none hits=12/1/11/ c13=11 t15=Yes markers=39 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:11/1 f11:11/1 f12:11/1 f13:11/0 f14:11/0 f15:11/0 f16:11/0 hits=12/1/11/ c13=11 t15=Yes markers=39 rows=1 name=one close: runs=none hits=12/1/11/ c13=11 t15=Yes markers=39 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_ModifyCard_Openings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', ModCardCase('OpenNew'));
        Observer.Observe('OpenEdit', ModCardCase('OpenEdit'));
        Observer.Observe('OpenView', ModCardCase('OpenView'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:10/0 f14:9/0 f15:9/0 f16:9/0 hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/1 f14:9/0 f15:9/0 f16:9/0 hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/1 f14:9/0 f15:9/0 f16:9/0 hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=10 t15=Yes markers=41 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_SelfModifyCard_Openings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', SelfCardCase('OpenNew'));
        Observer.Observe('OpenEdit', SelfCardCase('OpenEdit'));
        Observer.Observe('OpenView', SelfCardCase('OpenView'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:10/0 f15:9/0 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/1 f15:9/0 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/1 f15:9/0 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_ModifyAllCard_Openings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', ModAllCardCase('OpenNew'));
        Observer.Observe('OpenEdit', ModAllCardCase('OpenEdit'));
        Observer.Observe('OpenView', ModAllCardCase('OpenView'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:10/0 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:9/1 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:9/1 f16:9/0 hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=41 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_DeleteCard_Openings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', DelCardCase('OpenNew'));
        Observer.Observe('OpenEdit', DelCardCase('OpenEdit'));
        Observer.Observe('OpenView', DelCardCase('OpenView'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:9/0 f16:10/0 hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one');
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:9/0 f16:9/1 hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:9/0 f11:9/0 f12:9/0 f13:9/0 f14:9/0 f15:9/0 f16:9/1 hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one close: runs=none hits=9/0/9/ c13=9 t15=Yes markers=40 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_InsertList_Openings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('OpenNew', InsListCase('OpenNew'));
        Observer.Observe('OpenEdit', InsListCase('OpenEdit'));
        Observer.Observe('OpenView', InsListCase('OpenView'));
        Observer.Expect('OpenNew', 'stage=done error=no error {Dialog} open: runs=f10:11/0 f11:11/0 f12:11/0 f13:10/0 f14:10/0 f15:10/0 f16:10/0 hits=11/0/11/ c13=10 t15=Yes markers=40 rows=1 name=one close: runs=none hits=11/0/11/ c13=10 t15=Yes markers=40 rows=1 name=one');
        Observer.Expect('OpenEdit', 'stage=done error=no error {Dialog} open: runs=f10:10/1 f11:10/1 f12:10/1 f13:10/0 f14:10/0 f15:10/0 f16:10/0 hits=11/1/10/ c13=10 t15=Yes markers=40 rows=1 name=one close: runs=none hits=11/1/10/ c13=10 t15=Yes markers=40 rows=1 name=one');
        Observer.Expect('OpenView', 'stage=done error=no error {Dialog} open: runs=f10:10/1 f11:10/1 f12:10/1 f13:10/0 f14:10/0 f15:10/0 f16:10/0 hits=11/1/10/ c13=10 t15=Yes markers=40 rows=1 name=one close: runs=none hits=11/1/10/ c13=10 t15=Yes markers=40 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_FieldCaption_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        FieldNumber: Integer;
    begin
        for FieldNumber := 10 to 16 do
            Observer.Observe('f' + Format(FieldNumber), FieldCaptionCase(FieldNumber, 0));
        Observer.Expect('f10', 'stage=done error=no error {Dialog} caption=Ins Always Cap runs=f10:1/0 hits=1/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f11', 'stage=done error=no error {Dialog} caption=Ins Row Cap runs=f11:1/0 hits=0/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f12', 'stage=done error=no error {Dialog} caption=Ins Empty Cap runs=f12:1/0 hits=0/0/1/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f13', 'stage=done error=no error {Dialog} caption=Mod Counter Cap runs=f13:1/0 hits=0/0/0/ c13=1 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f14', 'stage=done error=no error {Dialog} caption=Self Modify Cap runs=f14:1/0 hits=0/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f15', 'stage=done error=no error {Dialog} caption=Modify All Cap runs=f15:1/0 hits=0/0/0/ c13=0 t15=Yes markers=50 rows=1 name=one');
        Observer.Expect('f16', 'stage=done error=no error {Dialog} caption=Delete One Cap runs=f16:1/0 hits=0/0/0/ c13=0 t15=No markers=49 rows=1 name=one');
        Observer.Verify();
    end;

    [Test]
    procedure WriteCaption_FieldCaption_Row()
    var
        Observer: Codeunit "Probe Observer";
        FieldNumber: Integer;
    begin
        for FieldNumber := 10 to 16 do
            Observer.Observe('f' + Format(FieldNumber), FieldCaptionCase(FieldNumber, 1));
        Observer.Expect('f10', 'stage=done error=no error {Dialog} caption=Ins Always Cap runs=f10:0/1 hits=1/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f11', 'stage=done error=no error {Dialog} caption=Ins Row Cap runs=f11:0/1 hits=0/1/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f12', 'stage=done error=no error {Dialog} caption=Ins Empty Cap runs=f12:0/1 hits=0/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f13', 'stage=done error=no error {Dialog} caption=Mod Counter Cap runs=f13:0/1 hits=0/0/0/ c13=1 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f14', 'stage=done error=no error {Dialog} caption=Self Modify Cap runs=f14:0/1 hits=0/0/0/ c13=0 t15=No markers=50 rows=1 name=one');
        Observer.Expect('f15', 'stage=done error=no error {Dialog} caption=Modify All Cap runs=f15:0/1 hits=0/0/0/ c13=0 t15=Yes markers=50 rows=1 name=one');
        Observer.Expect('f16', 'stage=done error=no error {Dialog} caption=Delete One Cap runs=f16:0/1 hits=0/0/0/ c13=0 t15=No markers=49 rows=1 name=one');
        Observer.Verify();
    end;
}
