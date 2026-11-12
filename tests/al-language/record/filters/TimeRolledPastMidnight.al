// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer 69160, own tables 75011 and 75012, LT RH Time Key Row 88000 (record/filters/P130DateFilters.al)
// Probe: measured on a local BC 28.5 service tier; other BC versions are checked by the corpus CI matrix.
// Facts: a Time of 23:59:59.999 in a database table rounds past the day in SQL. A row that holds it reads back 00:00:00, yet filters,
//   counts, deletes and sorts as a time after every time of the day; a Modify that leaves the field as read keeps it; a FlowField and
//   a FieldRef read it as 00:00:00; a temporary table keeps 23:59:59.999. In a primary key, Get by 23:59:59.999 and by 00:00:00
//   find the row while a filter on 00:00:00 does not.
// BC versions: 28 (27 and 29 by CI)

// local object: a Time field outside the primary key, with a key on it, and no other field the probe would have to fill.
table 75011 "LT TRM Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Tm; Time) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(TmKey; Tm) { }
    }
}

// local object: FlowFields over the Time field of table 75011.
table 75012 "LT TRM Sum"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; MaxTm; Time) { FieldClass = FlowField; CalcFormula = max("LT TRM Row".Tm); }
        field(3; MinTm; Time) { FieldClass = FlowField; CalcFormula = min("LT TRM Row".Tm); }
        field(4; LookupTm; Time) { FieldClass = FlowField; CalcFormula = lookup("LT TRM Row".Tm where(Id = field(Id))); }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75013 "LT TRM Time Rolled Over"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        R: Record "LT TRM Row";
        S: Record "LT TRM Sum";
        K: Record "LT RH Time Key Row";
    begin
        R.DeleteAll();
        S.DeleteAll();
        K.DeleteAll();
    end;

    local procedure Seed()
    begin
        Add(1, 000000T);
        Add(2, 120000T);
        Add(3, 235959.997T);
        Add(4, 235959.999T);
        Add(5, 000000.001T);
    end;

    local procedure Add(Id: Integer; T: Time)
    var
        R: Record "LT TRM Row";
    begin
        R.Init();
        R.Id := Id;
        R.Tm := T;
        R.Insert();
    end;

    local procedure Ids(var R: Record "LT TRM Row") s: Text
    begin
        if R.FindSet() then
            repeat
                s += Format(R.Id);
            until R.Next() = 0;
    end;

    local procedure Found(Ok: Boolean): Text
    begin
        if Ok then
            exit('found');
        exit('not found');
    end;

    local procedure Cell(var R: Record "LT TRM Row"): Text
    begin
        exit(Ids(R) + '/' + Format(R.Count()));
    end;

    [Test]
    procedure Time_StoredRolledOver_ReadsMidnight_FiltersAfterTheDay()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT TRM Row";
        s: Text;
    begin
        Initialize();
        Seed();
        if R.FindSet() then
            repeat
                s += Format(R.Id) + ':' + Format(R.Tm, 0, 9) + ';';
            until R.Next() = 0;
        Observer.Observe('read', s);
        R.SetFilter(Tm, '<%1', 235959.999T);
        Observer.Observe('lt999', Cell(R));
        R.SetFilter(Tm, '<=%1', 235959.999T);
        Observer.Observe('le999', Cell(R));
        R.SetFilter(Tm, '>%1', 235959.999T);
        Observer.Observe('gt999', Cell(R));
        R.SetFilter(Tm, '>=%1', 235959.999T);
        Observer.Observe('ge999', Cell(R));
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('eq999', Cell(R));
        R.SetRange(Tm, 000000T, 235959.999T);
        Observer.Observe('range0', Cell(R));
        R.SetRange(Tm, 120000T, 235959.999T);
        Observer.Observe('range12', Cell(R));
        R.SetRange(Tm, 000000T);
        Observer.Observe('eq0', Cell(R));
        R.SetFilter(Tm, '<>%1', 235959.999T);
        Observer.Observe('ne999', Cell(R));
        R.SetFilter(Tm, '<>%1', 000000T);
        Observer.Observe('ne0', Cell(R));
        R.SetFilter(Tm, '<%1', 235959.998T);
        Observer.Observe('lt998', Cell(R));
        R.SetFilter(Tm, '<%1', 235959.997T);
        Observer.Observe('lt997', Cell(R));
        R.SetFilter(Tm, '>%1', 000000T);
        Observer.Observe('gt0', Cell(R));
        R.SetFilter(Tm, '>%1', 235959.997T);
        Observer.Observe('gt997', Cell(R));
        R.SetFilter(Tm, '%1|%2', 120000T, 235959.999T);
        Observer.Observe('or12_999', Cell(R));
        Observer.Expect('read', '1:00:00:00;2:12:00:00;3:23:59:59.997;4:00:00:00;5:00:00:00;');
        Observer.Expect('lt999', '1235/4');
        Observer.Expect('le999', '12345/5');
        Observer.Expect('gt999', '/0');
        Observer.Expect('ge999', '4/1');
        Observer.Expect('eq999', '4/1');
        Observer.Expect('range0', '12345/5');
        Observer.Expect('range12', '234/3');
        Observer.Expect('eq0', '15/2');
        Observer.Expect('ne999', '1235/4');
        Observer.Expect('ne0', '234/3');
        Observer.Expect('lt998', '125/3');
        Observer.Expect('lt997', '125/3');
        Observer.Expect('gt0', '234/3');
        Observer.Expect('gt997', '4/1');
        Observer.Expect('or12_999', '24/2');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StoredRolledOver_SortsAfterTheDay()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT TRM Row";
    begin
        Initialize();
        Seed();
        R.SetCurrentKey(Tm);
        Observer.Observe('asc', Ids(R));
        R.Ascending(false);
        Observer.Observe('desc', Ids(R));
        R.Ascending(true);
        R.FindFirst();
        Observer.Observe('first', Format(R.Id));
        R.FindLast();
        Observer.Observe('last', Format(R.Id) + ':' + Format(R.Tm, 0, 9));
        Observer.Expect('asc', '15234');
        Observer.Expect('desc', '43251');
        Observer.Expect('first', '1');
        Observer.Expect('last', '4:00:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StoredRolledOver_DeleteAllBelowKeepsIt()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT TRM Row";
    begin
        Initialize();
        Seed();
        R.SetFilter(Tm, '<%1', 235959.999T);
        R.DeleteAll();
        R.Reset();
        Observer.Observe('left', Ids(R));
        Observer.Expect('left', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StoredRolledOver_ModifyKeepsUnchangedField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT TRM Row";
    begin
        Initialize();
        Seed();
        R.Get(4);
        R.Note := 'x';
        R.Modify();
        R.Reset();
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('note_eq999', Cell(R));
        R.SetRange(Tm, 000000T);
        Observer.Observe('note_eq0', Cell(R));
        R.Reset();
        R.Get(4);
        R.Tm := 000000T;
        R.Modify();
        R.Reset();
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('midnight_eq999', Cell(R));
        R.SetRange(Tm, 000000T);
        Observer.Observe('midnight_eq0', Cell(R));
        R.Reset();
        R.Get(2);
        R.Tm := 235959.999T;
        R.Modify();
        R.Reset();
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('set_eq999', Cell(R));
        R.Get(2);
        Observer.Observe('set_read', Format(R.Tm, 0, 9));
        R.Reset();
        R.SetRange(Id, 1);
        R.ModifyAll(Tm, 235959.999T);
        R.Reset();
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('modifyall_eq999', Cell(R));
        R.Reset();
        R.ModifyAll(Note, 'y');
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('modifyallnote_eq999', Cell(R));
        Observer.Expect('note_eq999', '4/1');
        Observer.Expect('note_eq0', '15/2');
        Observer.Expect('midnight_eq999', '4/1');
        Observer.Expect('midnight_eq0', '15/2');
        Observer.Expect('set_eq999', '24/2');
        Observer.Expect('set_read', '00:00:00');
        Observer.Expect('modifyall_eq999', '124/3');
        Observer.Expect('modifyallnote_eq999', '124/3');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Temporary_KeepsTheMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT TRM Row" temporary;
    begin
        Initialize();
        R.Id := 1;
        R.Tm := 000000T;
        R.Insert();
        R.Id := 2;
        R.Tm := 120000T;
        R.Insert();
        R.Id := 3;
        R.Tm := 235959.997T;
        R.Insert();
        R.Id := 4;
        R.Tm := 235959.999T;
        R.Insert();
        R.Id := 5;
        R.Tm := 000000.001T;
        R.Insert();
        R.Get(4);
        Observer.Observe('read4', Format(R.Tm, 0, 9));
        R.SetFilter(Tm, '<%1', 235959.999T);
        Observer.Observe('lt999', Cell(R));
        R.SetRange(Tm, 235959.999T);
        Observer.Observe('eq999', Cell(R));
        R.SetRange(Tm, 000000T);
        Observer.Observe('eq0', Cell(R));
        R.Reset();
        R.SetCurrentKey(Tm);
        Observer.Observe('asc', Ids(R));
        Observer.Expect('read4', '23:59:59.999');
        Observer.Expect('lt999', '1235/4');
        Observer.Expect('eq999', '4/1');
        Observer.Expect('eq0', '1/1');
        Observer.Expect('asc', '15234');
        Observer.Verify();
    end;

    [Test]
    procedure Time_PrimaryKeyRolledOver_GetFindsItFilterOnMidnightDoesNot()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT RH Time Key Row";
        G: Record "LT RH Time Key Row";
        s: Text;
    begin
        Initialize();
        K."Entry Code" := 'A';
        K."Entry Time" := 235959.999T;
        K.Insert();
        K."Entry Code" := 'A';
        K."Entry Time" := 120000T;
        K.Insert();
        Observer.Observe('get999', Found(G.Get('A', 235959.999T)) + ':' + Format(G."Entry Time", 0, 9));
        Clear(G);
        Observer.Observe('get0', Found(G.Get('A', 000000T)) + ':' + Format(G."Entry Time", 0, 9));
        K.Reset();
        K.SetRange("Entry Time", 235959.999T);
        Observer.Observe('eq999', Format(K.Count()));
        K.SetRange("Entry Time", 000000T);
        Observer.Observe('eq0', Format(K.Count()));
        K.SetFilter("Entry Time", '<%1', 235959.999T);
        Observer.Observe('lt999', Format(K.Count()));
        K.SetFilter("Entry Time", '>%1', 120000T);
        Observer.Observe('gt12', Format(K.Count()));
        K.Reset();
        if K.FindSet() then
            repeat
                s += Format(K."Entry Time", 0, 9) + ';';
            until K.Next() = 0;
        Observer.Observe('rows', s);
        Observer.Expect('get999', 'found:00:00:00');
        Observer.Expect('get0', 'found:00:00:00');
        Observer.Expect('eq999', '1');
        Observer.Expect('eq0', '0');
        Observer.Expect('lt999', '1');
        Observer.Expect('gt12', '1');
        Observer.Expect('rows', '12:00:00;00:00:00;');
        Observer.Verify();
    end;

    [Test]
    procedure Time_StoredRolledOver_FlowFieldAndFieldRefReadMidnight()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT TRM Sum";
        RR: RecordRef;
    begin
        Initialize();
        Seed();
        S.Id := 4;
        S.Insert();
        S.CalcFields(MaxTm, MinTm, LookupTm);
        Observer.Observe('max', Format(S.MaxTm, 0, 9));
        Observer.Observe('min', Format(S.MinTm, 0, 9));
        Observer.Observe('lookup', Format(S.LookupTm, 0, 9));
        RR.Open(Database::"LT TRM Row");
        RR.Field(1).SetRange(4);
        RR.FindFirst();
        Observer.Observe('fieldref', Format(RR.Field(2).Value, 0, 9));
        RR.Field(1).SetRange();
        RR.Field(2).SetRange(235959.999T);
        Observer.Observe('fieldref_eq999', Format(RR.Count()));
        Observer.Expect('max', '00:00:00');
        Observer.Expect('min', '00:00:00');
        Observer.Expect('lookup', '00:00:00');
        Observer.Expect('fieldref', '00:00:00');
        Observer.Expect('fieldref_eq999', '1');
        Observer.Verify();
    end;
}
