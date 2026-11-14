// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: own tables 70031 to 70036, own log and subscriber codeunits 70037 and 70038, Probe Observer 69160
// Probe: written against Business Central 28 and 29 service tiers (the corpus CI legs); every literal asserted below is what those tiers produced.
// Facts: a Date or DateTime in the year 1753 written to a field of a database table. The SQL datetime column cannot hold it; the corpus already pins
//   the error text and code of an Insert of 1753-01-01 (record/filters/P130DateFilters.al, BT_DateAndDateTime_SqlRangeOnInsert). These tests measure
//   the other dates of 1753, 1754-01-01 (the first year after), closing dates, DateTimes on a one-digit and a two-digit 12-hour clock hour and at
//   the rounding edge, for Insert, Modify (plain, Modify(true) with a table trigger, with an event subscriber, `if not Modify()`), Validate then
//   Modify, ModifyAll, Rename of a Date and a DateTime key, a table with a Blob field, a temporary record, a Date FlowFilter field and filters on
//   a Date and a DateTime field. Each cell is `<op>|<value>|stage` (the last statement the code reached before the error: the write itself, or
//   the next access of the table), `|text`, `|code` (GetLastErrorText and GetLastErrorCode inside asserterror) and `|row` (row 1 after the asserterror).
// BC versions: 28 and 29 (27 by CI)

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
}

codeunit 70039 "LT SD Floor 1753"
{
    Subtype = Test;
    TestPermissions = Disabled;

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
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Date_1753_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'insert', ClosingDate(17531231D));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_Date_ClosingAndOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modify', ClosingDate(17530615D));
        CellD(Observer, 'row', 'modify', ClosingDate(17531231D));
        CellD(Observer, 'row', 'modify', 17521231D);
        CellD(Observer, 'row', 'modify', 0D);
        CellD(Observer, 'row', 'modify', ClosingDate(17540101D));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Insert_DateTime_MorningHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 100000T);
        CellT(Observer, 'row', 'insert', 17530615D, 113000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Insert_DateTime_AfternoonHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17530615D, 235959T);
        CellT(Observer, 'row', 'insert', 17530102D, 000000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Insert_DateTime_RoundingEdge_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'insert', 17540101D, 000000T);
        CellT(Observer, 'row', 'insert', 17540101D, 000000.001T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_DateTime_MorningHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 100000T);
        CellT(Observer, 'row', 'modify', 17530615D, 113000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_DateTime_AfternoonHours_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17530615D, 235959T);
        CellT(Observer, 'row', 'modify', 17530101D, 000001T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_DateTime_RoundingEdge_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify', 17540101D, 000000T);
        CellT(Observer, 'row', 'modify', 17521231D, 120000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Date_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'insert-true', 17530615D);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_Date_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'modify', 17540101D, 'none');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_Date_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellN(Observer, 'row', 'modify-result', 17530615D, 'none');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Modify_DateTime_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'modify-result', 17540101D, 030000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ValidateThenModify_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'row', 'validate-modify', 17540101D, 030000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ModifyAll_Forms_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'row', 'modifyall-empty', 17530615D);
        CellD(Observer, 'row', 'modifyall', 17530101D);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Trigger_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'trig', 'modify-true', 17540101D);
        CellD(Observer, 'trig', 'modify', 17540101D);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Trigger_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'trig', 'modify-true', 17540101D, 030000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Trigger_ModifyAll_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'sub', 'modifyall-true', 17540101D);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'sub', 'modify-true', 17540101D);
        CellD(Observer, 'sub', 'insert-true', 17540101D);
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'sub', 'insert-true', 17530615D, 030000T);
        CellT(Observer, 'sub', 'modify-true', 17530615D, 030000T);
        CellT(Observer, 'sub', 'modify-true', 17530615D, 130000T);
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'sub', 'modify-false', 17530615D, 130000T);
        CellT(Observer, 'sub', 'modify-true', 17540101D, 030000T);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Blob_Date_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellD(Observer, 'blob', 'modify', 17540101D);
        CellN(Observer, 'blob', 'modify', 17530615D, 'none');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Blob_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellT(Observer, 'blob', 'modify', 17540101D, 030000T);
        CellN(Observer, 'blob', 'insert', 17530615D, 'none');
        Observer.Finish();
    end;

    [Test]
    procedure RowAfterError_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellR(Observer, 'row', 'modify', 17530615D);
        CellR(Observer, 'trig', 'modify-true', 17530615D);
        CellR(Observer, 'sub', 'modify-true', 17530615D);
        Observer.Finish();
    end;

    [Test]
    procedure RowAfterError_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CellR(Observer, 'blob', 'modify', 17530615D);
        CellR(Observer, 'row', 'modifyall', 17530615D);
        CellR(Observer, 'row', 'modify', 17540101D);
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Rename_DateKey_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'rename', 17521231D, 'get');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Rename_DateKey_NextAccess_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyCell(Observer, 'insert', 17540101D, 'get');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Rename_DateTimeKey_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DtKeyCell(Observer, 'insert', 17530615D, 030000T, 'get');
        DtKeyCell(Observer, 'insert', 17540101D, 000000T, 'get');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure TempRecord_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempCell(Observer, 'to-db', 0D, CreateDateTime(17540101D, 000000T), true);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
