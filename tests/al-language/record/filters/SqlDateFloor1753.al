// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: own tables 70031 to 70036, own log and subscriber codeunits 70037 and 70038, Probe Observer 69160
// Probe: measured on Business Central 27.5, 28.5 and 29.0 (the corpus CI legs); the three agree on every cell, so no version guard. Every literal asserted below is what those tiers produced.
// Facts: a Date or DateTime in the year 1753 written to a field of a database table. The SQL datetime column cannot hold it; the corpus already pins
//   the error text and code of an Insert of 1753-01-01 (record/filters/P130DateFilters.al, BT_DateAndDateTime_SqlRangeOnInsert). These tests measure
//   the other dates of 1753, 1752-12-31, 1754-01-01 (the first year after: accepted), closing dates, DateTimes on a one-digit and a two-digit 12-hour
//   clock hour (the error text pads the hour to two digits: 01:00 AM, 12:00 AM for 00:00:01) and at the edge of the year
//   (1753-12-31 23:59:59.999 is refused like every other 1753 value, it is not rounded into 1754; 1754-01-01 00:00:00.001 is accepted), for Insert,
//   Modify (plain, Modify(true) with a table trigger, with an event subscriber, `if not Modify()`), Validate then Modify, ModifyAll, Rename of a Date
//   and a DateTime key, a table with a Blob field, a temporary record, a Date FlowFilter field and filters on a Date and a DateTime field.
//   Each cell is `<op>|<value>|stage` (the last statement the code reached before the error: `next` for an Insert, where the error shows at the
//   next access of the table, `modify`, `modifyall`, `rename` and `insert` for a table with a Blob field, where the write itself raises it; `after`
//   when the write succeeded), `|text`, `|code` (GetLastErrorText and GetLastErrorCode inside asserterror) and `|row` (row 1 after the asserterror).
//   A temporary record, a FlowFilter and a filter on a 1753 value raise no error. The error of an Insert reaches the table triggers and subscribers
//   (the log shows `beforeInsert;afterInsert;`), the error of a Modify stops before the after-event (`beforeModify;`).
//   Dates before 1753 (1700-01-01, 1752-12-31) and DateTimes (1700-01-01 12:00, 1752-12-31 23:59) fail like 1753: Insert at the next access, Modify at the Modify call,
//   same text and code. After the error of a Modify(true) on a table with an OnModify trigger the record variable keeps the assigned Date and the trigger's
//   Hits (10) while the stored row has the old Date and Hits 0 (Kept_RecordAfterModifyError).
// BC versions: 27, 28 and 29

table 70031 "LT SD Floor Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
        field(5; Fil; Date) { FieldClass = FlowFilter; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70032 "LT SD Floor Trig"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Hits += 1;
    end;

    trigger OnModify()
    begin
        Hits += 10;
    end;
}

table 70033 "LT SD Floor Sub"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70034 "LT SD Floor Blob"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
        field(5; Payload; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70035 "LT SD Floor Date Key"
{
    fields
    {
        field(1; Dk; Date) { }
        field(2; Amount; Integer) { }
    }
    keys
    {
        key(PK; Dk) { Clustered = true; }
    }
}

table 70036 "LT SD Floor DateTime Key"
{
    fields
    {
        field(1; Dtk; DateTime) { }
        field(2; Amount; Integer) { }
    }
    keys
    {
        key(PK; Dtk) { Clustered = true; }
    }
}

table 74985 "LT SD Floor Trig Log"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('trigModify:' + Format(Dt, 0, 9));
    end;
}

table 74986 "LT SD Floor Trig Raise"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnModify()
    begin
        Error('trigger raised');
    end;
}

table 74987 "LT SD Floor Trig SetDt"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnModify()
    begin
        if Dt = 20240103D then
            Dt := 17530615D
        else
            Dt := 20240104D;
    end;
}

table 74988 "LT SD Floor Sub Read"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Dtm; DateTime) { }
        field(4; Hits; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70037 "LT SD Floor Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(What: Text)
    begin
        Entries += What + ';';
    end;

    procedure Dump(): Text
    begin
        exit(Entries);
    end;

    procedure Clear()
    begin
        Entries := '';
    end;
}

codeunit 70038 "LT SD Floor Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT SD Floor Sub", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertSub(var Rec: Record "LT SD Floor Sub"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('beforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SD Floor Sub", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSub(var Rec: Record "LT SD Floor Sub"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('afterInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SD Floor Sub", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifySub(var Rec: Record "LT SD Floor Sub"; var xRec: Record "LT SD Floor Sub"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('beforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SD Floor Sub", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySub(var Rec: Record "LT SD Floor Sub"; var xRec: Record "LT SD Floor Sub"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('afterModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SD Floor Sub Read", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSubRead(var Rec: Record "LT SD Floor Sub Read"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
    begin
        Log.Add('afterInsertRead:' + Format(Rec.Dt, 0, 9));
    end;
}

codeunit 70039 "LT SD Floor 1753"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        KeptRec: Record "LT SD Floor Trig";

    local procedure Seed()
    var
        Row: Record "LT SD Floor Row";
        Trig: Record "LT SD Floor Trig";
        Sub: Record "LT SD Floor Sub";
        Blob: Record "LT SD Floor Blob";
        DateKey: Record "LT SD Floor Date Key";
        DtKey: Record "LT SD Floor DateTime Key";
        Log: Codeunit "LT SD Floor Log";
        Old: DateTime;
    begin
        Row.DeleteAll();
        Trig.DeleteAll();
        Sub.DeleteAll();
        Blob.DeleteAll();
        DateKey.DeleteAll();
        DtKey.DeleteAll();
        Old := CreateDateTime(20240102D, 120000T);
        Row.Id := 1;
        Row.Dt := 20240102D;
        Row.Dtm := Old;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Trig.Id := 1;
        Trig.Dt := 20240102D;
        Trig.Dtm := Old;
        Trig.Insert();
        Sub.Id := 1;
        Sub.Dt := 20240102D;
        Sub.Dtm := Old;
        Sub.Insert();
        Blob.Id := 1;
        Blob.Dt := 20240102D;
        Blob.Dtm := Old;
        Blob.Insert();
        DateKey.Dk := 20240102D;
        DateKey.Insert();
        DtKey.Dtk := Old;
        DtKey.Insert();
        Log.Clear();
        Commit();
    end;

    local procedure RowAfter(Kind: Text): Text
    var
        Row: Record "LT SD Floor Row";
        Trig: Record "LT SD Floor Trig";
        Sub: Record "LT SD Floor Sub";
        Blob: Record "LT SD Floor Blob";
    begin
        case Kind of
            'row':
                begin
                    Row.Get(1);
                    exit(Format(Row.Dt, 0, 9) + '|' + Format(Row.Dtm, 0, 9));
                end;
            'trig':
                begin
                    Trig.Get(1);
                    exit(Format(Trig.Dt, 0, 9) + '|' + Format(Trig.Dtm, 0, 9) + '|' + Format(Trig.Hits));
                end;
            'sub':
                begin
                    Sub.Get(1);
                    exit(Format(Sub.Dt, 0, 9) + '|' + Format(Sub.Dtm, 0, 9));
                end;
            'blob':
                begin
                    Blob.Get(1);
                    exit(Format(Blob.Dt, 0, 9) + '|' + Format(Blob.Dtm, 0, 9));
                end;
        end;
    end;

    local procedure AttemptRow(Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor Row";
        Back: Record "LT SD Floor Row";
        Other: Record "LT SD Floor Date Key";
        RowId: Integer;
        Counted: Integer;
    begin
        Stage := 'start';
        RowId := 1;
        case Op of
            'insert', 'insert-true':
                begin
                    RowId := 900;
                    R.Init();
                    R.Id := RowId;
                    if UseDt then
                        R.Dtm := Stamp
                    else
                        R.Dt := D;
                    Stage := 'insert';
                    if Op = 'insert' then
                        R.Insert()
                    else
                        R.Insert(true);
                end;
            'modify', 'modify-true', 'modify-false', 'modify-result', 'modify-result-true', 'validate-modify':
                begin
                    R.Get(1);
                    Stage := 'assign';
                    if Op = 'validate-modify' then begin
                        if UseDt then
                            R.Validate(Dtm, Stamp)
                        else
                            R.Validate(Dt, D);
                    end else
                        if UseDt then
                            R.Dtm := Stamp
                        else
                            R.Dt := D;
                    Stage := 'modify';
                    case Op of
                        'modify', 'validate-modify':
                            R.Modify();
                        'modify-true':
                            R.Modify(true);
                        'modify-false':
                            R.Modify(false);
                        'modify-result':
                            if not R.Modify() then
                                Error('modify returned false');
                        'modify-result-true':
                            if not R.Modify(true) then
                                Error('modify returned false');
                    end;
                end;
            'modifyall', 'modifyall-true', 'modifyall-empty':
                begin
                    if Op = 'modifyall-empty' then
                        R.SetRange(Id, 99);
                    Stage := 'modifyall';
                    if UseDt then
                        R.ModifyAll(Dtm, Stamp, Op = 'modifyall-true')
                    else
                        R.ModifyAll(Dt, D, Op = 'modifyall-true');
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(RowId);
            'count':
                Counted := Back.Count();
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        if Next = 'get' then
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Hits));
        Error('no read: ' + Next);
    end;

    local procedure AttemptTrig(Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor Trig";
        Back: Record "LT SD Floor Trig";
        Other: Record "LT SD Floor Date Key";
        RowId: Integer;
        Counted: Integer;
    begin
        Stage := 'start';
        RowId := 1;
        case Op of
            'insert', 'insert-true':
                begin
                    RowId := 900;
                    R.Init();
                    R.Id := RowId;
                    if UseDt then
                        R.Dtm := Stamp
                    else
                        R.Dt := D;
                    Stage := 'insert';
                    if Op = 'insert' then
                        R.Insert()
                    else
                        R.Insert(true);
                end;
            'modify', 'modify-true', 'modify-false', 'modify-result', 'modify-result-true', 'validate-modify':
                begin
                    R.Get(1);
                    Stage := 'assign';
                    if Op = 'validate-modify' then begin
                        if UseDt then
                            R.Validate(Dtm, Stamp)
                        else
                            R.Validate(Dt, D);
                    end else
                        if UseDt then
                            R.Dtm := Stamp
                        else
                            R.Dt := D;
                    Stage := 'modify';
                    case Op of
                        'modify', 'validate-modify':
                            R.Modify();
                        'modify-true':
                            R.Modify(true);
                        'modify-false':
                            R.Modify(false);
                        'modify-result':
                            if not R.Modify() then
                                Error('modify returned false');
                        'modify-result-true':
                            if not R.Modify(true) then
                                Error('modify returned false');
                    end;
                end;
            'modifyall', 'modifyall-true', 'modifyall-empty':
                begin
                    if Op = 'modifyall-empty' then
                        R.SetRange(Id, 99);
                    Stage := 'modifyall';
                    if UseDt then
                        R.ModifyAll(Dtm, Stamp, Op = 'modifyall-true')
                    else
                        R.ModifyAll(Dt, D, Op = 'modifyall-true');
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(RowId);
            'count':
                Counted := Back.Count();
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        if Next = 'get' then
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Hits));
        Error('no read: ' + Next);
    end;

    local procedure AttemptSub(Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor Sub";
        Back: Record "LT SD Floor Sub";
        Other: Record "LT SD Floor Date Key";
        RowId: Integer;
        Counted: Integer;
    begin
        Stage := 'start';
        RowId := 1;
        case Op of
            'insert', 'insert-true':
                begin
                    RowId := 900;
                    R.Init();
                    R.Id := RowId;
                    if UseDt then
                        R.Dtm := Stamp
                    else
                        R.Dt := D;
                    Stage := 'insert';
                    if Op = 'insert' then
                        R.Insert()
                    else
                        R.Insert(true);
                end;
            'modify', 'modify-true', 'modify-false', 'modify-result', 'modify-result-true', 'validate-modify':
                begin
                    R.Get(1);
                    Stage := 'assign';
                    if Op = 'validate-modify' then begin
                        if UseDt then
                            R.Validate(Dtm, Stamp)
                        else
                            R.Validate(Dt, D);
                    end else
                        if UseDt then
                            R.Dtm := Stamp
                        else
                            R.Dt := D;
                    Stage := 'modify';
                    case Op of
                        'modify', 'validate-modify':
                            R.Modify();
                        'modify-true':
                            R.Modify(true);
                        'modify-false':
                            R.Modify(false);
                        'modify-result':
                            if not R.Modify() then
                                Error('modify returned false');
                        'modify-result-true':
                            if not R.Modify(true) then
                                Error('modify returned false');
                    end;
                end;
            'modifyall', 'modifyall-true', 'modifyall-empty':
                begin
                    if Op = 'modifyall-empty' then
                        R.SetRange(Id, 99);
                    Stage := 'modifyall';
                    if UseDt then
                        R.ModifyAll(Dtm, Stamp, Op = 'modifyall-true')
                    else
                        R.ModifyAll(Dt, D, Op = 'modifyall-true');
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(RowId);
            'count':
                Counted := Back.Count();
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        if Next = 'get' then
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Hits));
        Error('no read: ' + Next);
    end;

    local procedure AttemptBlob(Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor Blob";
        Back: Record "LT SD Floor Blob";
        Other: Record "LT SD Floor Date Key";
        RowId: Integer;
        Counted: Integer;
    begin
        Stage := 'start';
        RowId := 1;
        case Op of
            'insert', 'insert-true':
                begin
                    RowId := 900;
                    R.Init();
                    R.Id := RowId;
                    if UseDt then
                        R.Dtm := Stamp
                    else
                        R.Dt := D;
                    Stage := 'insert';
                    if Op = 'insert' then
                        R.Insert()
                    else
                        R.Insert(true);
                end;
            'modify', 'modify-true', 'modify-false', 'modify-result', 'modify-result-true', 'validate-modify':
                begin
                    R.Get(1);
                    Stage := 'assign';
                    if Op = 'validate-modify' then begin
                        if UseDt then
                            R.Validate(Dtm, Stamp)
                        else
                            R.Validate(Dt, D);
                    end else
                        if UseDt then
                            R.Dtm := Stamp
                        else
                            R.Dt := D;
                    Stage := 'modify';
                    case Op of
                        'modify', 'validate-modify':
                            R.Modify();
                        'modify-true':
                            R.Modify(true);
                        'modify-false':
                            R.Modify(false);
                        'modify-result':
                            if not R.Modify() then
                                Error('modify returned false');
                        'modify-result-true':
                            if not R.Modify(true) then
                                Error('modify returned false');
                    end;
                end;
            'modifyall', 'modifyall-true', 'modifyall-empty':
                begin
                    if Op = 'modifyall-empty' then
                        R.SetRange(Id, 99);
                    Stage := 'modifyall';
                    if UseDt then
                        R.ModifyAll(Dtm, Stamp, Op = 'modifyall-true')
                    else
                        R.ModifyAll(Dt, D, Op = 'modifyall-true');
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(RowId);
            'count':
                Counted := Back.Count();
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        if Next = 'get' then
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Hits));
        Error('no read: ' + Next);
    end;
    local procedure Dispatch(Kind: Text; Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; var Stage: Text)
    begin
        case Kind of
            'row':
                AttemptRow(Op, D, Stamp, UseDt, Next, Stage);
            'trig':
                AttemptTrig(Op, D, Stamp, UseDt, Next, Stage);
            'sub':
                AttemptSub(Op, D, Stamp, UseDt, Next, Stage);
            'blob':
                AttemptBlob(Op, D, Stamp, UseDt, Next, Stage);
        end;
    end;


    local procedure DName(D: Date): Text
    begin
        if D = 0D then
            exit('0D');
        if D <> NormalDate(D) then
            exit('C' + Format(NormalDate(D), 0, 9));
        exit(Format(D, 0, 9));
    end;

    // One cell: seed and commit, run Attempt inside asserterror, record the stage, the error (and with ShowRow row 1 afterwards; with the Sub table the event log).
    local procedure Cell(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; Next: Text; ShowRow: Boolean)
    var
        Log: Codeunit "LT SD Floor Log";
        Stage: Text;
        Name: Text;
    begin
        if UseDt then
            Name := Op + ' ' + Format(Stamp, 0, 9)
        else
            Name := Op + ' ' + DName(D);
        if Kind <> 'row' then
            Name := Kind + ' ' + Name;
        if Next <> 'get' then
            Name += ' n=' + Next;
        Seed();
        asserterror Dispatch(Kind, Op, D, Stamp, UseDt, Next, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
        if ShowRow then
            Observer.Observe(Name + '|row', RowAfter(Kind));
        if Kind = 'sub' then
            Observer.Observe(Name + '|log', Log.Dump());
    end;

    local procedure CellD(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; D: Date)
    begin
        Cell(Observer, Kind, Op, D, 0DT, false, 'get', false);
    end;

    [TryFunction]
    local procedure TryClosing(Base: Date; var D: Date)
    begin
        D := ClosingDate(Base);
    end;

    local procedure CellC(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; Base: Date)
    var
        D: Date;
    begin
        if not TryClosing(Base, D) then begin
            Observer.Observe('closing ' + Format(Base, 0, 9) + '|error', GetLastErrorText());
            exit;
        end;
        CellD(Observer, Kind, Op, D);
    end;

    local procedure SeedX()
    var
        TL: Record "LT SD Floor Trig Log";
        TR: Record "LT SD Floor Trig Raise";
        TS: Record "LT SD Floor Trig SetDt";
        S2: Record "LT SD Floor Sub Read";
        Blob: Record "LT SD Floor Blob";
        DateKey: Record "LT SD Floor Date Key";
        DtKey: Record "LT SD Floor DateTime Key";
        Log: Codeunit "LT SD Floor Log";
        Old: DateTime;
    begin
        TL.DeleteAll();
        TR.DeleteAll();
        TS.DeleteAll();
        S2.DeleteAll();
        Blob.DeleteAll();
        DateKey.DeleteAll();
        DtKey.DeleteAll();
        Old := CreateDateTime(20240102D, 120000T);
        TL.Id := 1;
        TL.Dt := 20240102D;
        TL.Dtm := Old;
        TL.Insert();
        TR.Id := 1;
        TR.Dt := 20240102D;
        TR.Dtm := Old;
        TR.Insert();
        TS.Id := 1;
        TS.Dt := 20240102D;
        TS.Dtm := Old;
        TS.Insert();
        S2.Id := 1;
        S2.Dt := 20240102D;
        S2.Dtm := Old;
        S2.Insert();
        Blob.Id := 1;
        Blob.Dt := 20240102D;
        Blob.Dtm := Old;
        Blob.Insert();
        DateKey.Dk := 20240102D;
        DateKey.Insert();
        DtKey.Dtk := Old;
        DtKey.Insert();
        Log.Clear();
        Commit();
    end;

    local procedure XAttempt(Which: Text; var Stage: Text)
    var
        TL: Record "LT SD Floor Trig Log";
        TR: Record "LT SD Floor Trig Raise";
        TS: Record "LT SD Floor Trig SetDt";
        S2: Record "LT SD Floor Sub Read";
        Blob: Record "LT SD Floor Blob";
        DateKey: Record "LT SD Floor Date Key";
        DtKey: Record "LT SD Floor DateTime Key";
        Out: OutStream;
    begin
        Stage := 'start';
        case Which of
            'tl-1753', 'tl-1754', 'tl-1753-notrig':
                begin
                    TL.Get(1);
                    if Which = 'tl-1754' then
                        TL.Dt := 17540101D
                    else
                        TL.Dt := 17530615D;
                    Stage := 'modify';
                    TL.Modify(Which <> 'tl-1753-notrig');
                end;
            'tr-1753', 'tr-1754':
                begin
                    TR.Get(1);
                    if Which = 'tr-1754' then
                        TR.Dt := 17540101D
                    else
                        TR.Dt := 17530615D;
                    Stage := 'modify';
                    TR.Modify(true);
                end;
            'ts-sets-1753', 'ts-1753-set-ok':
                begin
                    TS.Get(1);
                    if Which = 'ts-sets-1753' then
                        TS.Dt := 20240103D
                    else
                        TS.Dt := 17530615D;
                    Stage := 'modify';
                    TS.Modify(true);
                end;
            's2-insert-1753', 's2-insert-1754':
                begin
                    S2.Id := 900;
                    if Which = 's2-insert-1754' then
                        S2.Dt := 17540101D
                    else
                        S2.Dt := 17530615D;
                    Stage := 'insert';
                    S2.Insert(true);
                end;
            'blob-content-1753', 'blob-content-1754':
                begin
                    Blob.Id := 900;
                    if Which = 'blob-content-1754' then
                        Blob.Dt := 17540101D
                    else
                        Blob.Dt := 17530615D;
                    Blob.Payload.CreateOutStream(Out);
                    Out.WriteText('payload');
                    Stage := 'insert';
                    Blob.Insert();
                end;
            'dk-absent-1753', 'dk-absent-1754':
                begin
                    DateKey.Dk := 20250505D;
                    Stage := 'rename';
                    if Which = 'dk-absent-1754' then
                        DateKey.Rename(17540101D)
                    else
                        DateKey.Rename(17530615D);
                end;
            'dtk-absent-1753', 'dtk-absent-1754':
                begin
                    DtKey.Dtk := CreateDateTime(20250505D, 120000T);
                    Stage := 'rename';
                    if Which = 'dtk-absent-1754' then
                        DtKey.Rename(CreateDateTime(17540101D, 030000T))
                    else
                        DtKey.Rename(CreateDateTime(17530615D, 030000T));
                end;
        end;
        Stage := 'next';
        XState(Which);
        Stage := 'after';
        Error('no error');
    end;

    local procedure XState(Which: Text): Text
    var
        TL: Record "LT SD Floor Trig Log";
        TR: Record "LT SD Floor Trig Raise";
        TS: Record "LT SD Floor Trig SetDt";
        S2: Record "LT SD Floor Sub Read";
        Blob: Record "LT SD Floor Blob";
        DateKey: Record "LT SD Floor Date Key";
        DtKey: Record "LT SD Floor DateTime Key";
    begin
        case CopyStr(Which, 1, 2) of
            'tl':
                begin
                    TL.Get(1);
                    exit(Format(TL.Dt, 0, 9));
                end;
            'tr':
                begin
                    TR.Get(1);
                    exit(Format(TR.Dt, 0, 9));
                end;
            'ts':
                begin
                    TS.Get(1);
                    exit(Format(TS.Dt, 0, 9));
                end;
            's2':
                begin
                    exit(Format(S2.Count()) + '|' + Format(S2.Get(900)));
                end;
            'bl':
                begin
                    exit(Format(Blob.Count()) + '|' + Format(Blob.Get(900)));
                end;
            'dk':
                begin
                    exit(Format(DateKey.Count()) + '|' + Format(DateKey.FindFirst()) + '|' + Format(DateKey.Dk, 0, 9));
                end;
            'dt':
                begin
                    exit(Format(DtKey.Count()) + '|' + Format(DtKey.FindFirst()) + '|' + Format(DtKey.Dtk, 0, 9));
                end;
        end;
    end;

    local procedure XCell(var Observer: Codeunit "Probe Observer"; Which: Text)
    var
        Log: Codeunit "LT SD Floor Log";
        Stage: Text;
    begin
        SeedX();
        asserterror XAttempt(Which, Stage);
        Observer.Observe(Which + '|stage', Stage);
        Observer.ObserveError(Which);
        Observer.Observe(Which + '|log', Log.Dump());
        Observer.Observe(Which + '|state', XState(Which));
    end;

    local procedure KeptAttempt(D: Date; var Stage: Text)
    begin
        Stage := 'get';
        KeptRec.Get(1);
        Stage := 'assign';
        KeptRec.Dt := D;
        Stage := 'modify';
        KeptRec.Modify(true);
        Stage := 'after';
        Error('no error');
    end;

    // The record variable after the error of a Modify(true) on the trigger table: does it keep what the trigger set (Hits) and the assigned Date.
    local procedure KeptCell(var Observer: Codeunit "Probe Observer"; D: Date)
    var
        Stage: Text;
        Name: Text;
    begin
        Name := 'kept ' + Format(D, 0, 9);
        Seed();
        Clear(KeptRec);
        asserterror KeptAttempt(D, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
        Observer.Observe(Name + '|var', Format(KeptRec.Dt, 0, 9) + '|' + Format(KeptRec.Hits) + '|' + Format(KeptRec.Dtm, 0, 9));
        Observer.Observe(Name + '|row', RowAfter('trig'));
    end;

    local procedure OutCell(var Observer: Codeunit "Probe Observer"; Op: Text; D: Date; T: Time; UseDt: Boolean)
    begin
        if UseDt then
            Cell(Observer, 'row', Op, 0D, CreateDateTime(D, T), true, 'get', true)
        else
            Cell(Observer, 'row', Op, D, 0DT, false, 'get', true);
    end;

    local procedure CellT(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; D: Date; T: Time)
    begin
        Cell(Observer, Kind, Op, 0D, CreateDateTime(D, T), true, 'get', false);
    end;

    local procedure CellN(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; D: Date; Next: Text)
    begin
        Cell(Observer, Kind, Op, D, 0DT, false, Next, false);
    end;

    local procedure CellR(var Observer: Codeunit "Probe Observer"; Kind: Text; Op: Text; D: Date)
    begin
        Cell(Observer, Kind, Op, D, 0DT, false, 'get', true);
    end;

    local procedure KeyCell(var Observer: Codeunit "Probe Observer"; Op: Text; D: Date; Next: Text)
    var
        DateKey: Record "LT SD Floor Date Key";
        Stage: Text;
        Name: Text;
    begin
        Name := 'dk ' + Op + ' ' + Format(D, 0, 9);
        if Next <> 'get' then
            Name += ' n=' + Next;
        Seed();
        asserterror AttemptDateKey(Op, D, Next, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
        DateKey.FindFirst();
        Observer.Observe(Name + '|key', Format(DateKey.Dk, 0, 9) + '|' + Format(DateKey.Count()));
    end;

    local procedure DtKeyCell(var Observer: Codeunit "Probe Observer"; Op: Text; D: Date; T: Time; Next: Text)
    var
        DtKey: Record "LT SD Floor DateTime Key";
        Stage: Text;
        Name: Text;
        Stamp: DateTime;
    begin
        Stamp := CreateDateTime(D, T);
        Name := 'dtk ' + Op + ' ' + Format(Stamp, 0, 9);
        if Next <> 'get' then
            Name += ' n=' + Next;
        Seed();
        asserterror AttemptDtKey(Op, Stamp, Next, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
        DtKey.FindFirst();
        Observer.Observe(Name + '|key', Format(DtKey.Dtk, 0, 9) + '|' + Format(DtKey.Count()));
    end;

    local procedure TempCell(var Observer: Codeunit "Probe Observer"; Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean)
    var
        Stage: Text;
        Name: Text;
    begin
        if UseDt then
            Name := 'temp ' + Op + ' ' + Format(Stamp, 0, 9)
        else
            Name := 'temp ' + Op + ' ' + DName(D);
        Seed();
        asserterror AttemptTemp(Op, D, Stamp, UseDt, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
    end;

    local procedure FilterCell(var Observer: Codeunit "Probe Observer"; Op: Text; D: Date; Stamp: DateTime)
    var
        Stage: Text;
        Name: Text;
    begin
        if Stamp <> 0DT then
            Name := Op + ' ' + Format(Stamp, 0, 9)
        else
            Name := Op + ' ' + Format(D, 0, 9);
        Seed();
        asserterror AttemptFilter(Op, D, Stamp, Stage);
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
    end;

    local procedure AttemptDateKey(Op: Text; D: Date; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor Date Key";
        Back: Record "LT SD Floor Date Key";
        Other: Record "LT SD Floor Row";
        Counted: Integer;
    begin
        Stage := 'start';
        case Op of
            'insert':
                begin
                    R.Dk := D;
                    Stage := 'insert';
                    R.Insert();
                end;
            'rename':
                begin
                    R.Get(20240102D);
                    Stage := 'rename';
                    R.Rename(D);
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(D);
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        Error('stored:' + Format(Back.Dk, 0, 9) + '|' + Format(R.Dk, 0, 9));
    end;

    local procedure AttemptDtKey(Op: Text; Stamp: DateTime; Next: Text; var Stage: Text)
    var
        R: Record "LT SD Floor DateTime Key";
        Back: Record "LT SD Floor DateTime Key";
        Other: Record "LT SD Floor Row";
        Counted: Integer;
    begin
        Stage := 'start';
        case Op of
            'insert':
                begin
                    R.Dtk := Stamp;
                    Stage := 'insert';
                    R.Insert();
                end;
            'rename':
                begin
                    R.Get(CreateDateTime(20240102D, 120000T));
                    Stage := 'rename';
                    R.Rename(Stamp);
                end;
        end;
        Stage := 'next';
        case Next of
            'get':
                Back.Get(Stamp);
            'other':
                Counted := Other.Count();
            'commit':
                Commit();
        end;
        Stage := 'after';
        Error('stored:' + Format(Back.Dtk, 0, 9) + '|' + Format(R.Dtk, 0, 9));
    end;

    local procedure AttemptTemp(Op: Text; D: Date; Stamp: DateTime; UseDt: Boolean; var Stage: Text)
    var
        Temp: Record "LT SD Floor Row" temporary;
        R: Record "LT SD Floor Row";
        Back: Record "LT SD Floor Row";
    begin
        Stage := 'start';
        Temp.Init();
        Temp.Id := 900;
        if Op = 'modify' then begin
            Temp.Dt := 20240102D;
            Temp.Insert();
            Stage := 'modify';
            if UseDt then
                Temp.Dtm := Stamp
            else
                Temp.Dt := D;
            Temp.Modify();
        end else begin
            if UseDt then
                Temp.Dtm := Stamp
            else
                Temp.Dt := D;
            Stage := 'insert';
            Temp.Insert();
        end;
        Stage := 'next';
        Temp.Get(900);
        if (Op = 'to-db') or (Op = 'assign-db') then begin
            Stage := 'db-assign';
            if Op = 'to-db' then
                R.TransferFields(Temp)
            else
                R := Temp;
            Stage := 'db-insert';
            R.Insert();
            Stage := 'db-next';
            Back.Get(900);
            Stage := 'db-after';
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9));
        end;
        Stage := 'after';
        Error('stored:' + Format(Temp.Dt, 0, 9) + '|' + Format(Temp.Dtm, 0, 9));
    end;

    local procedure AttemptFilter(Op: Text; D: Date; Stamp: DateTime; var Stage: Text)
    var
        R: Record "LT SD Floor Row";
        Back: Record "LT SD Floor Row";
    begin
        Stage := 'start';
        case Op of
            'ff-setrange':
                begin
                    Stage := 'filter';
                    R.SetRange(Fil, D);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Fil));
                end;
            'ff-setfilter-text':
                begin
                    Stage := 'filter';
                    R.SetFilter(Fil, Format(D));
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Fil));
                end;
            'ff-setfilter-arg':
                begin
                    Stage := 'filter';
                    R.SetFilter(Fil, '..%1', D);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Fil));
                end;
            'ff-assign-insert':
                begin
                    R.Init();
                    R.Id := 900;
                    R.Fil := D;
                    Stage := 'insert';
                    R.Insert();
                    Stage := 'next';
                    Back.Get(900);
                    Stage := 'after';
                    Error('stored:' + Format(Back.Fil, 0, 9) + '|' + Format(R.Fil, 0, 9));
                end;
            'ff-assign-modify':
                begin
                    R.Get(1);
                    R.Fil := D;
                    Stage := 'modify';
                    R.Modify();
                    Stage := 'next';
                    Back.Get(1);
                    Stage := 'after';
                    Error('stored:' + Format(Back.Fil, 0, 9) + '|' + Format(R.Fil, 0, 9));
                end;
            'dt-setrange':
                begin
                    Stage := 'filter';
                    R.SetRange(Dt, D);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt));
                end;
            'dt-setrange-span':
                begin
                    Stage := 'filter';
                    R.SetRange(Dt, 17530101D, D);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt));
                end;
            'dt-setfilter-arg':
                begin
                    Stage := 'filter';
                    R.SetFilter(Dt, '..%1', D);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt));
                end;
            'dtm-setrange':
                begin
                    Stage := 'filter';
                    R.SetRange(Dtm, Stamp);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dtm));
                end;
            'dtm-setfilter-arg':
                begin
                    Stage := 'filter';
                    R.SetFilter(Dtm, '..%1', Stamp);
                    Stage := 'count';
                    Error('count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dtm));
                end;
        end;
    end;


    [Test]
    procedure Insert_Date_1753_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'insert', 17530102D);
        CellD(Observer, 'row', 'insert', 17530615D);
        CellD(Observer, 'row', 'insert', 17531231D);
        CellD(Observer, 'row', 'insert', 17540101D);
        CellD(Observer, 'row', 'insert', ClosingDate(17530615D));
        Observer.Expect('insert 1753-01-02|stage', 'next');
        Observer.Expect('insert 1753-01-02|text', 'Cannot write the value 01/02/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-01-02|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15|stage', 'next');
        Observer.Expect('insert 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-12-31|stage', 'next');
        Observer.Expect('insert 1753-12-31|text', 'Cannot write the value 12/31/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1754-01-01|stage', 'after');
        Observer.Expect('insert 1754-01-01|text', 'stored:1754-01-01||0');
        Observer.Expect('insert 1754-01-01|code', 'Dialog');
        Observer.Expect('insert C1753-06-15|stage', 'next');
        Observer.Expect('insert C1753-06-15|text', 'Cannot write the value C06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert C1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Date_1753_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'insert', ClosingDate(17531231D));
        Observer.Expect('insert C1753-12-31|stage', 'next');
        Observer.Expect('insert C1753-12-31|text', 'Cannot write the value C12/31/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert C1753-12-31|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_1753()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modify', 17530101D);
        CellD(Observer, 'row', 'modify', 17530102D);
        CellD(Observer, 'row', 'modify', 17530615D);
        CellD(Observer, 'row', 'modify', 17531231D);
        CellD(Observer, 'row', 'modify', 17540101D);
        Observer.Expect('modify 1753-01-01|stage', 'modify');
        Observer.Expect('modify 1753-01-01|text', 'Cannot write the value 01/01/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-01-02|stage', 'modify');
        Observer.Expect('modify 1753-01-02|text', 'Cannot write the value 01/02/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-01-02|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15|stage', 'modify');
        Observer.Expect('modify 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-12-31|stage', 'modify');
        Observer.Expect('modify 1753-12-31|text', 'Cannot write the value 12/31/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1754-01-01|stage', 'after');
        Observer.Expect('modify 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('modify 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellC(Observer, 'row', 'modify', 17530615D);
        Observer.Expect('modify C1753-06-15|stage', 'modify');
        Observer.Expect('modify C1753-06-15|text', 'Cannot write the value C06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify C1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellC(Observer, 'row', 'modify', 17531231D);
        Observer.Expect('modify C1753-12-31|stage', 'modify');
        Observer.Expect('modify C1753-12-31|text', 'Cannot write the value C12/31/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify C1753-12-31|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modify', 17521231D);
        Observer.Expect('modify 1752-12-31|stage', 'modify');
        Observer.Expect('modify 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modify', 0D);
        Observer.Expect('modify 0D|stage', 'after');
        Observer.Expect('modify 0D|text', 'stored:|2024-01-02T12:00:00Z|0');
        Observer.Expect('modify 0D|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellC(Observer, 'row', 'modify', 17540101D);
        Observer.Expect('modify C1754-01-01|stage', 'after');
        Observer.Expect('modify C1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('modify C1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_TriggerLog()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'tl-1753');
        XCell(Observer, 'tl-1754');
        XCell(Observer, 'tl-1753-notrig');
        Observer.Expect('tl-1753|stage', 'modify');
        Observer.Expect('tl-1753|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig Log because the value is either too long or the content is invalid.');
        Observer.Expect('tl-1753|code', 'NDBCS:BadCSideData');
        Observer.Expect('tl-1753|log', 'trigModify:1753-06-15;');
        Observer.Expect('tl-1753|state', '2024-01-02');
        Observer.Expect('tl-1754|stage', 'after');
        Observer.Expect('tl-1754|text', 'no error');
        Observer.Expect('tl-1754|code', 'Dialog');
        Observer.Expect('tl-1754|log', 'trigModify:1754-01-01;');
        Observer.Expect('tl-1754|state', '2024-01-02');
        Observer.Expect('tl-1753-notrig|stage', 'modify');
        Observer.Expect('tl-1753-notrig|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig Log because the value is either too long or the content is invalid.');
        Observer.Expect('tl-1753-notrig|code', 'NDBCS:BadCSideData');
        Observer.Expect('tl-1753-notrig|log', '');
        Observer.Expect('tl-1753-notrig|state', '2024-01-02');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_TriggerRaise()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'tr-1753');
        XCell(Observer, 'tr-1754');
        Observer.Expect('tr-1753|stage', 'modify');
        Observer.Expect('tr-1753|text', 'trigger raised');
        Observer.Expect('tr-1753|code', 'Dialog');
        Observer.Expect('tr-1753|log', '');
        Observer.Expect('tr-1753|state', '2024-01-02');
        Observer.Expect('tr-1754|stage', 'modify');
        Observer.Expect('tr-1754|text', 'trigger raised');
        Observer.Expect('tr-1754|code', 'Dialog');
        Observer.Expect('tr-1754|log', '');
        Observer.Expect('tr-1754|state', '2024-01-02');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_TriggerSetsDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'ts-sets-1753');
        XCell(Observer, 'ts-1753-set-ok');
        Observer.Expect('ts-sets-1753|stage', 'modify');
        Observer.Expect('ts-sets-1753|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig SetDt because the value is either too long or the content is invalid.');
        Observer.Expect('ts-sets-1753|code', 'NDBCS:BadCSideData');
        Observer.Expect('ts-sets-1753|log', '');
        Observer.Expect('ts-sets-1753|state', '2024-01-02');
        Observer.Expect('ts-1753-set-ok|stage', 'after');
        Observer.Expect('ts-1753-set-ok|text', 'no error');
        Observer.Expect('ts-1753-set-ok|code', 'Dialog');
        Observer.Expect('ts-1753-set-ok|log', '');
        Observer.Expect('ts-1753-set-ok|state', '2024-01-02');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_SubscriberReadsDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 's2-insert-1753');
        XCell(Observer, 's2-insert-1754');
        Observer.Expect('s2-insert-1753|stage', 'next');
        Observer.Expect('s2-insert-1753|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub Read because the value is either too long or the content is invalid.');
        Observer.Expect('s2-insert-1753|code', 'NDBCS:BadCSideData');
        Observer.Expect('s2-insert-1753|log', 'afterInsertRead:1753-06-15;');
        Observer.Expect('s2-insert-1753|state', '1|No');
        Observer.Expect('s2-insert-1754|stage', 'after');
        Observer.Expect('s2-insert-1754|text', 'no error');
        Observer.Expect('s2-insert-1754|code', 'Dialog');
        Observer.Expect('s2-insert-1754|log', 'afterInsertRead:1754-01-01;');
        Observer.Expect('s2-insert-1754|state', '1|No');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_BlobContent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'blob-content-1753');
        XCell(Observer, 'blob-content-1754');
        Observer.Expect('blob-content-1753|stage', 'insert');
        Observer.Expect('blob-content-1753|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob-content-1753|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob-content-1753|log', '');
        Observer.Expect('blob-content-1753|state', '1|No');
        Observer.Expect('blob-content-1754|stage', 'after');
        Observer.Expect('blob-content-1754|text', 'no error');
        Observer.Expect('blob-content-1754|code', 'Dialog');
        Observer.Expect('blob-content-1754|log', '');
        Observer.Expect('blob-content-1754|state', '1|No');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_BlobInsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'blob', 'insert-true', 17530615D);
        CellT(Observer, 'blob', 'insert-true', 17530615D, 030000T);
        Observer.Expect('blob insert-true 1753-06-15|stage', 'insert');
        Observer.Expect('blob insert-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob insert-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob insert-true 1753-06-15T03:00:00Z|stage', 'insert');
        Observer.Expect('blob insert-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob insert-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_RenameAbsentKey_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'dk-absent-1753');
        XCell(Observer, 'dk-absent-1754');
        Observer.Expect('dk-absent-1753|stage', 'rename');
        Observer.Expect('dk-absent-1753|text', 'The LT SD Floor Date Key does not exist. Identification fields and values: Dk=''05/05/25''');
        Observer.Expect('dk-absent-1753|code', 'DB:RecordNotFound');
        Observer.Expect('dk-absent-1753|log', '');
        Observer.Expect('dk-absent-1753|state', '1|Yes|2024-01-02');
        Observer.Expect('dk-absent-1754|stage', 'rename');
        Observer.Expect('dk-absent-1754|text', 'The LT SD Floor Date Key does not exist. Identification fields and values: Dk=''05/05/25''');
        Observer.Expect('dk-absent-1754|code', 'DB:RecordNotFound');
        Observer.Expect('dk-absent-1754|log', '');
        Observer.Expect('dk-absent-1754|state', '1|Yes|2024-01-02');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_RenameAbsentKey_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        XCell(Observer, 'dtk-absent-1753');
        XCell(Observer, 'dtk-absent-1754');
        Observer.Expect('dtk-absent-1753|stage', 'rename');
        Observer.Expect('dtk-absent-1753|text', 'The LT SD Floor DateTime Key does not exist. Identification fields and values: Dtk=''05/05/25 12:00 PM''');
        Observer.Expect('dtk-absent-1753|code', 'DB:RecordNotFound');
        Observer.Expect('dtk-absent-1753|log', '');
        Observer.Expect('dtk-absent-1753|state', '1|Yes|2024-01-02T12:00:00Z');
        Observer.Expect('dtk-absent-1754|stage', 'rename');
        Observer.Expect('dtk-absent-1754|text', 'The LT SD Floor DateTime Key does not exist. Identification fields and values: Dtk=''05/05/25 12:00 PM''');
        Observer.Expect('dtk-absent-1754|code', 'DB:RecordNotFound');
        Observer.Expect('dtk-absent-1754|log', '');
        Observer.Expect('dtk-absent-1754|state', '1|Yes|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Extra_ModifyAllNoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'trig', 'modifyall-empty', 17530615D);
        CellT(Observer, 'row', 'modifyall-empty', 17530615D, 030000T);
        CellD(Observer, 'trig', 'modifyall-empty', 17540101D);
        Observer.Expect('trig modifyall-empty 1753-06-15|stage', 'modifyall');
        Observer.Expect('trig modifyall-empty 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modifyall-empty 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall-empty 1753-06-15T03:00:00Z|stage', 'modifyall');
        Observer.Expect('modifyall-empty 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall-empty 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modifyall-empty 1754-01-01|stage', 'after');
        Observer.Expect('trig modifyall-empty 1754-01-01|text', 'stored:2024-01-02|2024-01-02T12:00:00Z|0');
        Observer.Expect('trig modifyall-empty 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Outside_Date_Insert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutCell(Observer, 'insert', 17000101D, 0T, false);
        OutCell(Observer, 'insert', 17521231D, 0T, false);
        Observer.Expect('insert 1700-01-01|stage', 'next');
        Observer.Expect('insert 1700-01-01|text', 'Cannot write the value 01/01/1700 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1700-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1700-01-01|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('insert 1752-12-31|stage', 'next');
        Observer.Expect('insert 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1752-12-31|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Outside_Date_Modify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutCell(Observer, 'modify', 17000101D, 0T, false);
        OutCell(Observer, 'modify', 17521231D, 0T, false);
        Observer.Expect('modify 1700-01-01|stage', 'modify');
        Observer.Expect('modify 1700-01-01|text', 'Cannot write the value 01/01/1700 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1700-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1700-01-01|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('modify 1752-12-31|stage', 'modify');
        Observer.Expect('modify 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1752-12-31|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Outside_DateTime_Insert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutCell(Observer, 'insert', 17000101D, 120000T, true);
        OutCell(Observer, 'insert', 17521231D, 235900T, true);
        Observer.Expect('insert 1700-01-01T12:00:00Z|stage', 'next');
        Observer.Expect('insert 1700-01-01T12:00:00Z|text', 'Cannot write the value 01/01/1700 12:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1700-01-01T12:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1700-01-01T12:00:00Z|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('insert 1752-12-31T23:59:00Z|stage', 'next');
        Observer.Expect('insert 1752-12-31T23:59:00Z|text', 'Cannot write the value 12/31/1752 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1752-12-31T23:59:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1752-12-31T23:59:00Z|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Outside_DateTime_Modify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutCell(Observer, 'modify', 17000101D, 120000T, true);
        OutCell(Observer, 'modify', 17521231D, 235900T, true);
        Observer.Expect('modify 1700-01-01T12:00:00Z|stage', 'modify');
        Observer.Expect('modify 1700-01-01T12:00:00Z|text', 'Cannot write the value 01/01/1700 12:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1700-01-01T12:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1700-01-01T12:00:00Z|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('modify 1752-12-31T23:59:00Z|stage', 'modify');
        Observer.Expect('modify 1752-12-31T23:59:00Z|text', 'Cannot write the value 12/31/1752 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1752-12-31T23:59:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1752-12-31T23:59:00Z|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Kept_RecordAfterModifyError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeptCell(Observer, 17530615D);
        KeptCell(Observer, 17540101D);
        Observer.Expect('kept 1753-06-15|stage', 'modify');
        Observer.Expect('kept 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('kept 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('kept 1753-06-15|var', '1753-06-15|10|2024-01-02T12:00:00Z');
        Observer.Expect('kept 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z|0');
        Observer.Expect('kept 1754-01-01|stage', 'after');
        Observer.Expect('kept 1754-01-01|text', 'no error');
        Observer.Expect('kept 1754-01-01|code', 'Dialog');
        Observer.Expect('kept 1754-01-01|var', '1754-01-01|10|2024-01-02T12:00:00Z');
        Observer.Expect('kept 1754-01-01|row', '2024-01-02|2024-01-02T12:00:00Z|0');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_MorningHours_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 000001T);
        CellT(Observer, 'row', 'insert', 17530615D, 010000T);
        CellT(Observer, 'row', 'insert', 17530615D, 030000T);
        CellT(Observer, 'row', 'insert', 17530615D, 090000T);
        Observer.Expect('insert 1753-06-15T00:00:01Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T00:00:01Z|text', 'Cannot write the value 06/15/1753 12:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T00:00:01Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T01:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T01:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T01:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T03:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T09:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T09:00:00Z|text', 'Cannot write the value 06/15/1753 09:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T09:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_MorningHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 100000T);
        CellT(Observer, 'row', 'insert', 17530615D, 113000T);
        Observer.Expect('insert 1753-06-15T10:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T10:00:00Z|text', 'Cannot write the value 06/15/1753 10:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T10:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T11:30:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T11:30:00Z|text', 'Cannot write the value 06/15/1753 11:30 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T11:30:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_AfternoonHours_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 120000T);
        CellT(Observer, 'row', 'insert', 17530615D, 130000T);
        CellT(Observer, 'row', 'insert', 17530615D, 150000T);
        CellT(Observer, 'row', 'insert', 17530615D, 215959T);
        Observer.Expect('insert 1753-06-15T12:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T12:00:00Z|text', 'Cannot write the value 06/15/1753 12:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T12:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T13:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T15:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T15:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T15:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15T21:59:59Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T21:59:59Z|text', 'Cannot write the value 06/15/1753 09:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T21:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_AfternoonHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 235959T);
        CellT(Observer, 'row', 'insert', 17530102D, 000000T);
        Observer.Expect('insert 1753-06-15T23:59:59Z|stage', 'next');
        Observer.Expect('insert 1753-06-15T23:59:59Z|text', 'Cannot write the value 06/15/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15T23:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-01-02T00:00:00Z|stage', 'next');
        Observer.Expect('insert 1753-01-02T00:00:00Z|text', 'Cannot write the value 01/02/1753 12:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-01-02T00:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_RoundingEdge_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17531231D, 235959T);
        CellT(Observer, 'row', 'insert', 17531231D, 235959.997T);
        CellT(Observer, 'row', 'insert', 17531231D, 235959.998T);
        CellT(Observer, 'row', 'insert', 17531231D, 235959.999T);
        Observer.Expect('insert 1753-12-31T23:59:59Z|stage', 'next');
        Observer.Expect('insert 1753-12-31T23:59:59Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-12-31T23:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-12-31T23:59:59.997Z|stage', 'next');
        Observer.Expect('insert 1753-12-31T23:59:59.997Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-12-31T23:59:59.997Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-12-31T23:59:59.998Z|stage', 'next');
        Observer.Expect('insert 1753-12-31T23:59:59.998Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-12-31T23:59:59.998Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-12-31T23:59:59.999Z|stage', 'next');
        Observer.Expect('insert 1753-12-31T23:59:59.999Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-12-31T23:59:59.999Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DateTime_RoundingEdge_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17540101D, 000000T);
        CellT(Observer, 'row', 'insert', 17540101D, 000000.001T);
        Observer.Expect('insert 1754-01-01T00:00:00Z|stage', 'after');
        Observer.Expect('insert 1754-01-01T00:00:00Z|text', 'stored:|1754-01-01T00:00:00Z|0');
        Observer.Expect('insert 1754-01-01T00:00:00Z|code', 'Dialog');
        Observer.Expect('insert 1754-01-01T00:00:00.001Z|stage', 'after');
        Observer.Expect('insert 1754-01-01T00:00:00.001Z|text', 'stored:|1754-01-01T00:00:00Z|0');
        Observer.Expect('insert 1754-01-01T00:00:00.001Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_MorningHours_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 000001T);
        CellT(Observer, 'row', 'modify', 17530615D, 010000T);
        CellT(Observer, 'row', 'modify', 17530615D, 030000T);
        CellT(Observer, 'row', 'modify', 17530615D, 090000T);
        Observer.Expect('modify 1753-06-15T00:00:01Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T00:00:01Z|text', 'Cannot write the value 06/15/1753 12:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T00:00:01Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T01:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T01:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T01:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T09:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T09:00:00Z|text', 'Cannot write the value 06/15/1753 09:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T09:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_MorningHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 100000T);
        CellT(Observer, 'row', 'modify', 17530615D, 113000T);
        Observer.Expect('modify 1753-06-15T10:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T10:00:00Z|text', 'Cannot write the value 06/15/1753 10:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T10:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T11:30:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T11:30:00Z|text', 'Cannot write the value 06/15/1753 11:30 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T11:30:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_AfternoonHours_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 120000T);
        CellT(Observer, 'row', 'modify', 17530615D, 130000T);
        CellT(Observer, 'row', 'modify', 17530615D, 150000T);
        CellT(Observer, 'row', 'modify', 17530615D, 215959T);
        Observer.Expect('modify 1753-06-15T12:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T12:00:00Z|text', 'Cannot write the value 06/15/1753 12:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T12:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T15:00:00Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T15:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T15:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15T21:59:59Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T21:59:59Z|text', 'Cannot write the value 06/15/1753 09:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T21:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_AfternoonHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 235959T);
        CellT(Observer, 'row', 'modify', 17530101D, 000001T);
        Observer.Expect('modify 1753-06-15T23:59:59Z|stage', 'modify');
        Observer.Expect('modify 1753-06-15T23:59:59Z|text', 'Cannot write the value 06/15/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15T23:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-01-01T00:00:01Z|stage', 'modify');
        Observer.Expect('modify 1753-01-01T00:00:01Z|text', 'Cannot write the value 01/01/1753 12:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-01-01T00:00:01Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_RoundingEdge_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17531231D, 235959T);
        CellT(Observer, 'row', 'modify', 17531231D, 235959.997T);
        CellT(Observer, 'row', 'modify', 17531231D, 235959.998T);
        CellT(Observer, 'row', 'modify', 17531231D, 235959.999T);
        Observer.Expect('modify 1753-12-31T23:59:59Z|stage', 'modify');
        Observer.Expect('modify 1753-12-31T23:59:59Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-12-31T23:59:59Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-12-31T23:59:59.997Z|stage', 'modify');
        Observer.Expect('modify 1753-12-31T23:59:59.997Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-12-31T23:59:59.997Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-12-31T23:59:59.998Z|stage', 'modify');
        Observer.Expect('modify 1753-12-31T23:59:59.998Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-12-31T23:59:59.998Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-12-31T23:59:59.999Z|stage', 'modify');
        Observer.Expect('modify 1753-12-31T23:59:59.999Z|text', 'Cannot write the value 12/31/1753 11:59 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-12-31T23:59:59.999Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_RoundingEdge_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17540101D, 000000T);
        CellT(Observer, 'row', 'modify', 17521231D, 120000T);
        Observer.Expect('modify 1754-01-01T00:00:00Z|stage', 'after');
        Observer.Expect('modify 1754-01-01T00:00:00Z|text', 'stored:2024-01-02|1754-01-01T00:00:00Z|0');
        Observer.Expect('modify 1754-01-01T00:00:00Z|code', 'Dialog');
        Observer.Expect('modify 1752-12-31T12:00:00Z|stage', 'modify');
        Observer.Expect('modify 1752-12-31T12:00:00Z|text', 'Cannot write the value 12/31/1752 12:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1752-12-31T12:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Date_NextAccess_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'insert', 17530615D, 'other');
        CellN(Observer, 'row', 'insert', 17530615D, 'count');
        CellN(Observer, 'row', 'insert', 17530615D, 'commit');
        CellN(Observer, 'row', 'insert', 17530615D, 'none');
        Observer.Expect('insert 1753-06-15 n=other|stage', 'after');
        Observer.Expect('insert 1753-06-15 n=other|text', 'no read: other');
        Observer.Expect('insert 1753-06-15 n=other|code', 'Dialog');
        Observer.Expect('insert 1753-06-15 n=count|stage', 'next');
        Observer.Expect('insert 1753-06-15 n=count|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15 n=count|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15 n=commit|stage', 'next');
        Observer.Expect('insert 1753-06-15 n=commit|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert 1753-06-15 n=commit|code', 'NDBCS:BadCSideData');
        Observer.Expect('insert 1753-06-15 n=none|stage', 'after');
        Observer.Expect('insert 1753-06-15 n=none|text', 'no read: none');
        Observer.Expect('insert 1753-06-15 n=none|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Date_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'insert-true', 17530615D);
        Observer.Expect('insert-true 1753-06-15|stage', 'next');
        Observer.Expect('insert-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('insert-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_NextAccess_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'modify', 17530615D, 'other');
        CellN(Observer, 'row', 'modify', 17530615D, 'count');
        CellN(Observer, 'row', 'modify', 17530615D, 'commit');
        CellN(Observer, 'row', 'modify', 17530615D, 'none');
        Observer.Expect('modify 1753-06-15 n=other|stage', 'modify');
        Observer.Expect('modify 1753-06-15 n=other|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15 n=other|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15 n=count|stage', 'modify');
        Observer.Expect('modify 1753-06-15 n=count|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15 n=count|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15 n=commit|stage', 'modify');
        Observer.Expect('modify 1753-06-15 n=commit|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15 n=commit|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15 n=none|stage', 'modify');
        Observer.Expect('modify 1753-06-15 n=none|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15 n=none|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'modify', 17540101D, 'none');
        Observer.Expect('modify 1754-01-01 n=none|stage', 'after');
        Observer.Expect('modify 1754-01-01 n=none|text', 'no read: none');
        Observer.Expect('modify 1754-01-01 n=none|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_Forms_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modify-result', 17530615D);
        CellD(Observer, 'row', 'modify-result-true', 17530615D);
        CellD(Observer, 'row', 'modify-true', 17530615D);
        CellD(Observer, 'row', 'modify-false', 17530615D);
        CellD(Observer, 'row', 'modify-result', 17540101D);
        Observer.Expect('modify-result 1753-06-15|stage', 'modify');
        Observer.Expect('modify-result 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-result 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-result-true 1753-06-15|stage', 'modify');
        Observer.Expect('modify-result-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-result-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-true 1753-06-15|stage', 'modify');
        Observer.Expect('modify-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-false 1753-06-15|stage', 'modify');
        Observer.Expect('modify-false 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-false 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-result 1754-01-01|stage', 'after');
        Observer.Expect('modify-result 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('modify-result 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Date_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'modify-result', 17530615D, 'none');
        Observer.Expect('modify-result 1753-06-15 n=none|stage', 'modify');
        Observer.Expect('modify-result 1753-06-15 n=none|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-result 1753-06-15 n=none|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_Forms_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify-result', 17530615D, 030000T);
        CellT(Observer, 'row', 'modify-result-true', 17530615D, 030000T);
        CellT(Observer, 'row', 'modify-true', 17530615D, 030000T);
        CellT(Observer, 'row', 'modify-false', 17530615D, 130000T);
        Observer.Expect('modify-result 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('modify-result 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-result 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-result-true 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('modify-result-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-result-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-true 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('modify-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify-false 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('modify-false 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify-false 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_DateTime_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify-result', 17540101D, 030000T);
        Observer.Expect('modify-result 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('modify-result 1754-01-01T03:00:00Z|text', 'stored:2024-01-02|1754-01-01T03:00:00Z|0');
        Observer.Expect('modify-result 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateThenModify_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'validate-modify', 17530615D);
        CellD(Observer, 'row', 'validate-modify', 17540101D);
        CellT(Observer, 'row', 'validate-modify', 17530615D, 030000T);
        CellT(Observer, 'row', 'validate-modify', 17530615D, 130000T);
        Observer.Expect('validate-modify 1753-06-15|stage', 'modify');
        Observer.Expect('validate-modify 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('validate-modify 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('validate-modify 1754-01-01|stage', 'after');
        Observer.Expect('validate-modify 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('validate-modify 1754-01-01|code', 'Dialog');
        Observer.Expect('validate-modify 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('validate-modify 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('validate-modify 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('validate-modify 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('validate-modify 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('validate-modify 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateThenModify_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'validate-modify', 17540101D, 030000T);
        Observer.Expect('validate-modify 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('validate-modify 1754-01-01T03:00:00Z|text', 'stored:2024-01-02|1754-01-01T03:00:00Z|0');
        Observer.Expect('validate-modify 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Forms_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modifyall', 17530615D);
        CellD(Observer, 'row', 'modifyall-true', 17530615D);
        CellT(Observer, 'row', 'modifyall', 17530615D, 030000T);
        CellD(Observer, 'row', 'modifyall', 17540101D);
        Observer.Expect('modifyall 1753-06-15|stage', 'modifyall');
        Observer.Expect('modifyall 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall-true 1753-06-15|stage', 'modifyall');
        Observer.Expect('modifyall-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall 1753-06-15T03:00:00Z|stage', 'modifyall');
        Observer.Expect('modifyall 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall 1754-01-01|stage', 'after');
        Observer.Expect('modifyall 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('modifyall 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modifyall-empty', 17530615D);
        CellD(Observer, 'row', 'modifyall', 17530101D);
        Observer.Expect('modifyall-empty 1753-06-15|stage', 'modifyall');
        Observer.Expect('modifyall-empty 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall-empty 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall 1753-01-01|stage', 'modifyall');
        Observer.Expect('modifyall 1753-01-01|text', 'Cannot write the value 01/01/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall 1753-01-01|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_Date_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'trig', 'insert-true', 17530615D);
        CellD(Observer, 'trig', 'insert', 17530615D);
        CellD(Observer, 'trig', 'modify-true', 17530615D);
        CellD(Observer, 'trig', 'modify-false', 17530615D);
        Observer.Expect('trig insert-true 1753-06-15|stage', 'next');
        Observer.Expect('trig insert-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig insert-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig insert 1753-06-15|stage', 'next');
        Observer.Expect('trig insert 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig insert 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-true 1753-06-15|stage', 'modify');
        Observer.Expect('trig modify-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-false 1753-06-15|stage', 'modify');
        Observer.Expect('trig modify-false 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-false 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'trig', 'modify-true', 17540101D);
        CellD(Observer, 'trig', 'modify', 17540101D);
        Observer.Expect('trig modify-true 1754-01-01|stage', 'after');
        Observer.Expect('trig modify-true 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|10');
        Observer.Expect('trig modify-true 1754-01-01|code', 'Dialog');
        Observer.Expect('trig modify 1754-01-01|stage', 'after');
        Observer.Expect('trig modify 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('trig modify 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'trig', 'insert-true', 17530615D, 030000T);
        CellT(Observer, 'trig', 'modify-true', 17530615D, 030000T);
        CellT(Observer, 'trig', 'modify-true', 17530615D, 130000T);
        CellT(Observer, 'trig', 'modify-result-true', 17530615D, 130000T);
        Observer.Expect('trig insert-true 1753-06-15T03:00:00Z|stage', 'next');
        Observer.Expect('trig insert-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig insert-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-true 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('trig modify-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-true 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('trig modify-true 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-true 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-result-true 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('trig modify-result-true 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-result-true 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'trig', 'modify-true', 17540101D, 030000T);
        Observer.Expect('trig modify-true 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('trig modify-true 1754-01-01T03:00:00Z|text', 'stored:2024-01-02|1754-01-01T03:00:00Z|10');
        Observer.Expect('trig modify-true 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_ModifyAll_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'trig', 'modifyall-true', 17530615D);
        CellD(Observer, 'trig', 'modifyall', 17530615D);
        CellD(Observer, 'trig', 'modifyall-true', 17540101D);
        CellD(Observer, 'sub', 'modifyall-true', 17530615D);
        Observer.Expect('trig modifyall-true 1753-06-15|stage', 'modifyall');
        Observer.Expect('trig modifyall-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modifyall-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modifyall 1753-06-15|stage', 'modifyall');
        Observer.Expect('trig modifyall 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modifyall 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modifyall-true 1754-01-01|stage', 'after');
        Observer.Expect('trig modifyall-true 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|10');
        Observer.Expect('trig modifyall-true 1754-01-01|code', 'Dialog');
        Observer.Expect('sub modifyall-true 1753-06-15|stage', 'modifyall');
        Observer.Expect('sub modifyall-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modifyall-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modifyall-true 1753-06-15|log', 'beforeModify;');
        Observer.Verify();
    end;

    [Test]
    procedure Trigger_ModifyAll_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'sub', 'modifyall-true', 17540101D);
        Observer.Expect('sub modifyall-true 1754-01-01|stage', 'after');
        Observer.Expect('sub modifyall-true 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('sub modifyall-true 1754-01-01|code', 'Dialog');
        Observer.Expect('sub modifyall-true 1754-01-01|log', 'beforeModify;afterModify;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_Date_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'sub', 'insert-true', 17530615D);
        CellD(Observer, 'sub', 'modify-true', 17530615D);
        CellD(Observer, 'sub', 'modify-false', 17530615D);
        CellD(Observer, 'sub', 'modify-result-true', 17530615D);
        Observer.Expect('sub insert-true 1753-06-15|stage', 'next');
        Observer.Expect('sub insert-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub insert-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub insert-true 1753-06-15|log', 'beforeInsert;afterInsert;');
        Observer.Expect('sub modify-true 1753-06-15|stage', 'modify');
        Observer.Expect('sub modify-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-true 1753-06-15|log', 'beforeModify;');
        Observer.Expect('sub modify-false 1753-06-15|stage', 'modify');
        Observer.Expect('sub modify-false 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-false 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-false 1753-06-15|log', 'beforeModify;');
        Observer.Expect('sub modify-result-true 1753-06-15|stage', 'modify');
        Observer.Expect('sub modify-result-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-result-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-result-true 1753-06-15|log', 'beforeModify;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'sub', 'modify-true', 17540101D);
        CellD(Observer, 'sub', 'insert-true', 17540101D);
        Observer.Expect('sub modify-true 1754-01-01|stage', 'after');
        Observer.Expect('sub modify-true 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('sub modify-true 1754-01-01|code', 'Dialog');
        Observer.Expect('sub modify-true 1754-01-01|log', 'beforeModify;afterModify;');
        Observer.Expect('sub insert-true 1754-01-01|stage', 'after');
        Observer.Expect('sub insert-true 1754-01-01|text', 'stored:1754-01-01||0');
        Observer.Expect('sub insert-true 1754-01-01|code', 'Dialog');
        Observer.Expect('sub insert-true 1754-01-01|log', 'beforeInsert;afterInsert;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'sub', 'insert-true', 17530615D, 030000T);
        CellT(Observer, 'sub', 'modify-true', 17530615D, 030000T);
        CellT(Observer, 'sub', 'modify-true', 17530615D, 130000T);
        Observer.Expect('sub insert-true 1753-06-15T03:00:00Z|stage', 'next');
        Observer.Expect('sub insert-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub insert-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub insert-true 1753-06-15T03:00:00Z|log', 'beforeInsert;afterInsert;');
        Observer.Expect('sub modify-true 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('sub modify-true 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-true 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-true 1753-06-15T03:00:00Z|log', 'beforeModify;');
        Observer.Expect('sub modify-true 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('sub modify-true 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-true 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-true 1753-06-15T13:00:00Z|log', 'beforeModify;');
        Observer.Verify();
    end;

    [Test]
    procedure Subscriber_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'sub', 'modify-false', 17530615D, 130000T);
        CellT(Observer, 'sub', 'modify-true', 17540101D, 030000T);
        Observer.Expect('sub modify-false 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('sub modify-false 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-false 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-false 1753-06-15T13:00:00Z|log', 'beforeModify;');
        Observer.Expect('sub modify-true 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('sub modify-true 1754-01-01T03:00:00Z|text', 'stored:2024-01-02|1754-01-01T03:00:00Z|0');
        Observer.Expect('sub modify-true 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Expect('sub modify-true 1754-01-01T03:00:00Z|log', 'beforeModify;afterModify;');
        Observer.Verify();
    end;

    [Test]
    procedure Blob_Date_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'blob', 'insert', 17530615D);
        CellD(Observer, 'blob', 'modify', 17530615D);
        CellD(Observer, 'blob', 'modify-result', 17530615D);
        CellD(Observer, 'blob', 'insert', 17540101D);
        Observer.Expect('blob insert 1753-06-15|stage', 'insert');
        Observer.Expect('blob insert 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob insert 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob modify 1753-06-15|stage', 'modify');
        Observer.Expect('blob modify 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob modify-result 1753-06-15|stage', 'modify');
        Observer.Expect('blob modify-result 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify-result 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob insert 1754-01-01|stage', 'after');
        Observer.Expect('blob insert 1754-01-01|text', 'stored:1754-01-01||0');
        Observer.Expect('blob insert 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Blob_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'blob', 'modify', 17540101D);
        CellN(Observer, 'blob', 'modify', 17530615D, 'none');
        Observer.Expect('blob modify 1754-01-01|stage', 'after');
        Observer.Expect('blob modify 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('blob modify 1754-01-01|code', 'Dialog');
        Observer.Expect('blob modify 1753-06-15 n=none|stage', 'modify');
        Observer.Expect('blob modify 1753-06-15 n=none|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify 1753-06-15 n=none|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure Blob_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'blob', 'insert', 17530615D, 030000T);
        CellT(Observer, 'blob', 'modify', 17530615D, 030000T);
        CellT(Observer, 'blob', 'modify', 17530615D, 130000T);
        CellT(Observer, 'blob', 'insert', 17540101D, 030000T);
        Observer.Expect('blob insert 1753-06-15T03:00:00Z|stage', 'insert');
        Observer.Expect('blob insert 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob insert 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob modify 1753-06-15T03:00:00Z|stage', 'modify');
        Observer.Expect('blob modify 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtm in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob modify 1753-06-15T13:00:00Z|stage', 'modify');
        Observer.Expect('blob modify 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob insert 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('blob insert 1754-01-01T03:00:00Z|text', 'stored:|1754-01-01T03:00:00Z|0');
        Observer.Expect('blob insert 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Blob_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'blob', 'modify', 17540101D, 030000T);
        CellN(Observer, 'blob', 'insert', 17530615D, 'none');
        Observer.Expect('blob modify 1754-01-01T03:00:00Z|stage', 'after');
        Observer.Expect('blob modify 1754-01-01T03:00:00Z|text', 'stored:2024-01-02|1754-01-01T03:00:00Z|0');
        Observer.Expect('blob modify 1754-01-01T03:00:00Z|code', 'Dialog');
        Observer.Expect('blob insert 1753-06-15 n=none|stage', 'insert');
        Observer.Expect('blob insert 1753-06-15 n=none|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob insert 1753-06-15 n=none|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure RowAfterError_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellR(Observer, 'row', 'modify', 17530615D);
        CellR(Observer, 'trig', 'modify-true', 17530615D);
        CellR(Observer, 'sub', 'modify-true', 17530615D);
        Observer.Expect('modify 1753-06-15|stage', 'modify');
        Observer.Expect('modify 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modify 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modify 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('trig modify-true 1753-06-15|stage', 'modify');
        Observer.Expect('trig modify-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Trig because the value is either too long or the content is invalid.');
        Observer.Expect('trig modify-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('trig modify-true 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z|0');
        Observer.Expect('sub modify-true 1753-06-15|stage', 'modify');
        Observer.Expect('sub modify-true 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Sub because the value is either too long or the content is invalid.');
        Observer.Expect('sub modify-true 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('sub modify-true 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('sub modify-true 1753-06-15|log', 'beforeModify;');
        Observer.Verify();
    end;

    [Test]
    procedure RowAfterError_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellR(Observer, 'blob', 'modify', 17530615D);
        CellR(Observer, 'row', 'modifyall', 17530615D);
        CellR(Observer, 'row', 'modify', 17540101D);
        Observer.Expect('blob modify 1753-06-15|stage', 'modify');
        Observer.Expect('blob modify 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Blob because the value is either too long or the content is invalid.');
        Observer.Expect('blob modify 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('blob modify 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('modifyall 1753-06-15|stage', 'modifyall');
        Observer.Expect('modifyall 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('modifyall 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('modifyall 1753-06-15|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Expect('modify 1754-01-01|stage', 'after');
        Observer.Expect('modify 1754-01-01|text', 'stored:1754-01-01|2024-01-02T12:00:00Z|0');
        Observer.Expect('modify 1754-01-01|code', 'Dialog');
        Observer.Expect('modify 1754-01-01|row', '2024-01-02|2024-01-02T12:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateKey_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'rename', 17530102D, 'get');
        KeyCell(Observer, 'rename', 17530615D, 'get');
        KeyCell(Observer, 'rename', 17531231D, 'get');
        KeyCell(Observer, 'rename', 17540101D, 'get');
        KeyCell(Observer, 'rename', 17530101D, 'get');
        Observer.Expect('dk rename 1753-01-02|stage', 'rename');
        Observer.Expect('dk rename 1753-01-02|text', 'Cannot write the value 01/02/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-01-02|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-01-02|key', '2024-01-02|1');
        Observer.Expect('dk rename 1753-06-15|stage', 'rename');
        Observer.Expect('dk rename 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-06-15|key', '2024-01-02|1');
        Observer.Expect('dk rename 1753-12-31|stage', 'rename');
        Observer.Expect('dk rename 1753-12-31|text', 'Cannot write the value 12/31/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-12-31|key', '2024-01-02|1');
        Observer.Expect('dk rename 1754-01-01|stage', 'after');
        Observer.Expect('dk rename 1754-01-01|text', 'stored:1754-01-01|1754-01-01');
        Observer.Expect('dk rename 1754-01-01|code', 'Dialog');
        Observer.Expect('dk rename 1754-01-01|key', '2024-01-02|1');
        Observer.Expect('dk rename 1753-01-01|stage', 'rename');
        Observer.Expect('dk rename 1753-01-01|text', 'Cannot write the value 01/01/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-01-01|key', '2024-01-02|1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateKey_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'rename', 17521231D, 'get');
        Observer.Expect('dk rename 1752-12-31|stage', 'rename');
        Observer.Expect('dk rename 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1752-12-31|key', '2024-01-02|1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateKey_NextAccess_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'rename', 17530615D, 'other');
        KeyCell(Observer, 'rename', 17530615D, 'commit');
        KeyCell(Observer, 'rename', 17530615D, 'none');
        KeyCell(Observer, 'insert', 17530615D, 'get');
        KeyCell(Observer, 'insert', 17530615D, 'none');
        Observer.Expect('dk rename 1753-06-15 n=other|stage', 'rename');
        Observer.Expect('dk rename 1753-06-15 n=other|text', 'Cannot write the value 06/15/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-06-15 n=other|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-06-15 n=other|key', '2024-01-02|1');
        Observer.Expect('dk rename 1753-06-15 n=commit|stage', 'rename');
        Observer.Expect('dk rename 1753-06-15 n=commit|text', 'Cannot write the value 06/15/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-06-15 n=commit|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-06-15 n=commit|key', '2024-01-02|1');
        Observer.Expect('dk rename 1753-06-15 n=none|stage', 'rename');
        Observer.Expect('dk rename 1753-06-15 n=none|text', 'Cannot write the value 06/15/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk rename 1753-06-15 n=none|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk rename 1753-06-15 n=none|key', '2024-01-02|1');
        Observer.Expect('dk insert 1753-06-15|stage', 'next');
        Observer.Expect('dk insert 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dk in the table LT SD Floor Date Key because the value is either too long or the content is invalid.');
        Observer.Expect('dk insert 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('dk insert 1753-06-15|key', '2024-01-02|1');
        Observer.Expect('dk insert 1753-06-15 n=none|stage', 'after');
        Observer.Expect('dk insert 1753-06-15 n=none|text', 'stored:|1753-06-15');
        Observer.Expect('dk insert 1753-06-15 n=none|code', 'Dialog');
        Observer.Expect('dk insert 1753-06-15 n=none|key', '2024-01-02|1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateKey_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'insert', 17540101D, 'get');
        Observer.Expect('dk insert 1754-01-01|stage', 'after');
        Observer.Expect('dk insert 1754-01-01|text', 'stored:1754-01-01|1754-01-01');
        Observer.Expect('dk insert 1754-01-01|code', 'Dialog');
        Observer.Expect('dk insert 1754-01-01|key', '2024-01-02|1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateTimeKey_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DtKeyCell(Observer, 'rename', 17530615D, 030000T, 'get');
        DtKeyCell(Observer, 'rename', 17530615D, 130000T, 'get');
        DtKeyCell(Observer, 'rename', 17540101D, 000000T, 'get');
        DtKeyCell(Observer, 'rename', 17530615D, 130000T, 'none');
        Observer.Expect('dtk rename 1753-06-15T03:00:00Z|stage', 'rename');
        Observer.Expect('dtk rename 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtk in the table LT SD Floor DateTime Key because the value is either too long or the content is invalid.');
        Observer.Expect('dtk rename 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('dtk rename 1753-06-15T03:00:00Z|key', '2024-01-02T12:00:00Z|1');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z|stage', 'rename');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtk in the table LT SD Floor DateTime Key because the value is either too long or the content is invalid.');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z|key', '2024-01-02T12:00:00Z|1');
        Observer.Expect('dtk rename 1754-01-01T00:00:00Z|stage', 'after');
        Observer.Expect('dtk rename 1754-01-01T00:00:00Z|text', 'stored:1754-01-01T00:00:00Z|1754-01-01T00:00:00Z');
        Observer.Expect('dtk rename 1754-01-01T00:00:00Z|code', 'Dialog');
        Observer.Expect('dtk rename 1754-01-01T00:00:00Z|key', '2024-01-02T12:00:00Z|1');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z n=none|stage', 'rename');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z n=none|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtk in the table LT SD Floor DateTime Key because the value is either too long or the content is invalid.');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z n=none|code', 'NDBCS:BadCSideData');
        Observer.Expect('dtk rename 1753-06-15T13:00:00Z n=none|key', '2024-01-02T12:00:00Z|1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_DateTimeKey_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DtKeyCell(Observer, 'insert', 17530615D, 030000T, 'get');
        DtKeyCell(Observer, 'insert', 17540101D, 000000T, 'get');
        Observer.Expect('dtk insert 1753-06-15T03:00:00Z|stage', 'next');
        Observer.Expect('dtk insert 1753-06-15T03:00:00Z|text', 'Cannot write the value 06/15/1753 03:00 AM to the field Dtk in the table LT SD Floor DateTime Key because the value is either too long or the content is invalid.');
        Observer.Expect('dtk insert 1753-06-15T03:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('dtk insert 1753-06-15T03:00:00Z|key', '2024-01-02T12:00:00Z|1');
        Observer.Expect('dtk insert 1754-01-01T00:00:00Z|stage', 'after');
        Observer.Expect('dtk insert 1754-01-01T00:00:00Z|text', 'stored:1754-01-01T00:00:00Z|1754-01-01T00:00:00Z');
        Observer.Expect('dtk insert 1754-01-01T00:00:00Z|code', 'Dialog');
        Observer.Expect('dtk insert 1754-01-01T00:00:00Z|key', '2024-01-02T12:00:00Z|1');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_Date()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempCell(Observer, 'insert', 17530615D, 0DT, false);
        TempCell(Observer, 'modify', 17530615D, 0DT, false);
        TempCell(Observer, 'insert', 17530101D, 0DT, false);
        TempCell(Observer, 'to-db', 17530615D, 0DT, false);
        TempCell(Observer, 'assign-db', 17530615D, 0DT, false);
        TempCell(Observer, 'to-db', 17540101D, 0DT, false);
        Observer.Expect('temp insert 1753-06-15|stage', 'after');
        Observer.Expect('temp insert 1753-06-15|text', 'stored:1753-06-15|');
        Observer.Expect('temp insert 1753-06-15|code', 'Dialog');
        Observer.Expect('temp modify 1753-06-15|stage', 'after');
        Observer.Expect('temp modify 1753-06-15|text', 'stored:1753-06-15|');
        Observer.Expect('temp modify 1753-06-15|code', 'Dialog');
        Observer.Expect('temp insert 1753-01-01|stage', 'after');
        Observer.Expect('temp insert 1753-01-01|text', 'stored:1753-01-01|');
        Observer.Expect('temp insert 1753-01-01|code', 'Dialog');
        Observer.Expect('temp to-db 1753-06-15|stage', 'db-next');
        Observer.Expect('temp to-db 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('temp to-db 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('temp assign-db 1753-06-15|stage', 'db-next');
        Observer.Expect('temp assign-db 1753-06-15|text', 'Cannot write the value 06/15/1753 to the field Dt in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('temp assign-db 1753-06-15|code', 'NDBCS:BadCSideData');
        Observer.Expect('temp to-db 1754-01-01|stage', 'db-after');
        Observer.Expect('temp to-db 1754-01-01|text', 'stored:1754-01-01|');
        Observer.Expect('temp to-db 1754-01-01|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempCell(Observer, 'insert', 0D, CreateDateTime(17530615D, 030000T), true);
        TempCell(Observer, 'modify', 0D, CreateDateTime(17530615D, 030000T), true);
        TempCell(Observer, 'insert', 0D, CreateDateTime(17530101D, 000000T), true);
        TempCell(Observer, 'to-db', 0D, CreateDateTime(17530615D, 130000T), true);
        TempCell(Observer, 'assign-db', 0D, CreateDateTime(17530615D, 130000T), true);
        Observer.Expect('temp insert 1753-06-15T03:00:00Z|stage', 'after');
        Observer.Expect('temp insert 1753-06-15T03:00:00Z|text', 'stored:|1753-06-15T03:00:00Z');
        Observer.Expect('temp insert 1753-06-15T03:00:00Z|code', 'Dialog');
        Observer.Expect('temp modify 1753-06-15T03:00:00Z|stage', 'after');
        Observer.Expect('temp modify 1753-06-15T03:00:00Z|text', 'stored:2024-01-02|1753-06-15T03:00:00Z');
        Observer.Expect('temp modify 1753-06-15T03:00:00Z|code', 'Dialog');
        Observer.Expect('temp insert 1753-01-01T00:00:00Z|stage', 'after');
        Observer.Expect('temp insert 1753-01-01T00:00:00Z|text', 'stored:|1753-01-01T00:00:00Z');
        Observer.Expect('temp insert 1753-01-01T00:00:00Z|code', 'Dialog');
        Observer.Expect('temp to-db 1753-06-15T13:00:00Z|stage', 'db-next');
        Observer.Expect('temp to-db 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('temp to-db 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Expect('temp assign-db 1753-06-15T13:00:00Z|stage', 'db-next');
        Observer.Expect('temp assign-db 1753-06-15T13:00:00Z|text', 'Cannot write the value 06/15/1753 01:00 PM to the field Dtm in the table LT SD Floor Row because the value is either too long or the content is invalid.');
        Observer.Expect('temp assign-db 1753-06-15T13:00:00Z|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempCell(Observer, 'to-db', 0D, CreateDateTime(17540101D, 000000T), true);
        Observer.Expect('temp to-db 1754-01-01T00:00:00Z|stage', 'db-after');
        Observer.Expect('temp to-db 1754-01-01T00:00:00Z|text', 'stored:|1754-01-01T00:00:00Z');
        Observer.Expect('temp to-db 1754-01-01T00:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilter_Date()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterCell(Observer, 'ff-setrange', 17530615D, 0DT);
        FilterCell(Observer, 'ff-setfilter-text', 17530615D, 0DT);
        FilterCell(Observer, 'ff-setfilter-arg', 17530615D, 0DT);
        FilterCell(Observer, 'ff-setrange', 17530101D, 0DT);
        FilterCell(Observer, 'ff-assign-insert', 17530615D, 0DT);
        FilterCell(Observer, 'ff-assign-modify', 17530615D, 0DT);
        Observer.Expect('ff-setrange 1753-06-15|stage', 'count');
        Observer.Expect('ff-setrange 1753-06-15|text', 'count=2 filter=06/15/1753');
        Observer.Expect('ff-setrange 1753-06-15|code', 'Dialog');
        Observer.Expect('ff-setfilter-text 1753-06-15|stage', 'count');
        Observer.Expect('ff-setfilter-text 1753-06-15|text', 'count=2 filter=06/15/1753');
        Observer.Expect('ff-setfilter-text 1753-06-15|code', 'Dialog');
        Observer.Expect('ff-setfilter-arg 1753-06-15|stage', 'count');
        Observer.Expect('ff-setfilter-arg 1753-06-15|text', 'count=2 filter=..06/15/1753');
        Observer.Expect('ff-setfilter-arg 1753-06-15|code', 'Dialog');
        Observer.Expect('ff-setrange 1753-01-01|stage', 'count');
        Observer.Expect('ff-setrange 1753-01-01|text', 'count=2 filter=01/01/1753');
        Observer.Expect('ff-setrange 1753-01-01|code', 'Dialog');
        Observer.Expect('ff-assign-insert 1753-06-15|stage', 'after');
        Observer.Expect('ff-assign-insert 1753-06-15|text', 'stored:|1753-06-15');
        Observer.Expect('ff-assign-insert 1753-06-15|code', 'Dialog');
        Observer.Expect('ff-assign-modify 1753-06-15|stage', 'after');
        Observer.Expect('ff-assign-modify 1753-06-15|text', 'stored:|1753-06-15');
        Observer.Expect('ff-assign-modify 1753-06-15|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_DateAndDateTimeFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterCell(Observer, 'dt-setrange', 17530615D, 0DT);
        FilterCell(Observer, 'dt-setrange-span', 17530615D, 0DT);
        FilterCell(Observer, 'dt-setfilter-arg', 17531231D, 0DT);
        FilterCell(Observer, 'dt-setfilter-arg', 17540101D, 0DT);
        FilterCell(Observer, 'dtm-setrange', 0D, CreateDateTime(17530615D, 030000T));
        FilterCell(Observer, 'dtm-setfilter-arg', 0D, CreateDateTime(17530615D, 130000T));
        Observer.Expect('dt-setrange 1753-06-15|stage', 'count');
        Observer.Expect('dt-setrange 1753-06-15|text', 'count=0 filter=06/15/1753');
        Observer.Expect('dt-setrange 1753-06-15|code', 'Dialog');
        Observer.Expect('dt-setrange-span 1753-06-15|stage', 'count');
        Observer.Expect('dt-setrange-span 1753-06-15|text', 'count=0 filter=01/01/1753..06/15/1753');
        Observer.Expect('dt-setrange-span 1753-06-15|code', 'Dialog');
        Observer.Expect('dt-setfilter-arg 1753-12-31|stage', 'count');
        Observer.Expect('dt-setfilter-arg 1753-12-31|text', 'count=0 filter=..12/31/1753');
        Observer.Expect('dt-setfilter-arg 1753-12-31|code', 'Dialog');
        Observer.Expect('dt-setfilter-arg 1754-01-01|stage', 'count');
        Observer.Expect('dt-setfilter-arg 1754-01-01|text', 'count=0 filter=..01/01/1754');
        Observer.Expect('dt-setfilter-arg 1754-01-01|code', 'Dialog');
        Observer.Expect('dtm-setrange 1753-06-15T03:00:00Z|stage', 'count');
        Observer.Expect('dtm-setrange 1753-06-15T03:00:00Z|text', 'count=0 filter=06/15/1753 03:00 AM');
        Observer.Expect('dtm-setrange 1753-06-15T03:00:00Z|code', 'Dialog');
        Observer.Expect('dtm-setfilter-arg 1753-06-15T13:00:00Z|stage', 'count');
        Observer.Expect('dtm-setfilter-arg 1753-06-15T13:00:00Z|text', 'count=0 filter=..06/15/1753 01:00 PM');
        Observer.Expect('dtm-setfilter-arg 1753-06-15T13:00:00Z|code', 'Dialog');
        Observer.Verify();
    end;
}
