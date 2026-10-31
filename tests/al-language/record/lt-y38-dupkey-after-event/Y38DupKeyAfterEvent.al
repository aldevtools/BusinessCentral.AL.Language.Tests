// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained tables 92580-92582, table extension 92583, SingleInstance log codeunit 92584 (used
// only by test codeunit 92586), static subscriber codeunit 92585.
// Writer Y38 (gap cycle 3, C3-17): a statement-form Insert of a key that already exists, into a table without a Blob or AutoIncrement field
// (BC defers that error to the next access: record/TestRecordRuntimeTextsAndViews.al:180), when the table has an OnAfterInsertEvent
// subscriber (table T) or a table-extension OnAfterInsert trigger (table V). Table U has neither. Neighbour of
// events/lt-db-events/DbtEvents.al Insert_DuplicateKey (the After event runs with the duplicate's values).

table 92580 "LT Y38 DK T"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT Y38 DK Log";
    begin
        Log.Add('TI' + Format(Id) + '(' + Name + ')');
    end;
}

table 92581 "LT Y38 DK U"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 92582 "LT Y38 DK V"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 92583 "LT Y38 DK V Ext" extends "LT Y38 DK V"
{
    trigger OnAfterInsert()
    var
        Log: Codeunit "LT Y38 DK Log";
    begin
        Log.Add('XAI' + Format(Rec.Id) + '(' + Rec.Name + ')');
    end;
}

codeunit 92584 "LT Y38 DK Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ReadT: Boolean;
        ReadU: Boolean;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
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

    procedure SetReads(NewReadT: Boolean; NewReadU: Boolean)
    begin
        ReadT := NewReadT;
        ReadU := NewReadU;
    end;

    procedure ReadsT(): Boolean
    begin
        exit(ReadT);
    end;

    procedure ReadsU(): Boolean
    begin
        exit(ReadU);
    end;
}

codeunit 92585 "LT Y38 DK Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"LT Y38 DK T", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertT(var Rec: Record "LT Y38 DK T"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT Y38 DK Log";
    begin
        Log.Add('BI' + Format(Rec.Id) + '(' + Rec.Name + ')/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y38 DK T", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertT(var Rec: Record "LT Y38 DK T"; RunTrigger: Boolean)
    var
        Other: Record "LT Y38 DK T";
        Control: Record "LT Y38 DK U";
        Log: Codeunit "LT Y38 DK Log";
    begin
        Log.Add('AI' + Format(Rec.Id) + '(' + Rec.Name + ')/' + Format(RunTrigger) + '/temp=' + Format(Rec.IsTemporary()) +
            '/sid-null=' + Format(IsNullGuid(Rec.SystemId)));
        if Log.ReadsT() then
            Log.Add('cnt=' + Format(Other.Count()));
        if Log.ReadsU() then
            Log.Add('ucnt=' + Format(Control.Count()));
    end;
}

codeunit 92586 "LT Y38 DK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Empties T, U and V, stores row 1 'orig' in each and (WithCommit) commits, so a rollback goes back to it.
    local procedure Prep(WithCommit: Boolean)
    var
        T: Record "LT Y38 DK T";
        U: Record "LT Y38 DK U";
        V: Record "LT Y38 DK V";
        Log: Codeunit "LT Y38 DK Log";
    begin
        Log.SetReads(false, false);
        T.DeleteAll();
        U.DeleteAll();
        V.DeleteAll();
        T.Id := 1;
        T.Name := 'orig';
        T.Insert(false);
        U.Id := 1;
        U.Name := 'orig';
        U.Insert(false);
        V.Id := 1;
        V.Name := 'orig';
        V.Insert(false);
        if WithCommit then
            Commit();
        Log.Take();
    end;

    local procedure StoredT(): Text
    var
        T: Record "LT Y38 DK T";
    begin
        if not T.Get(1) then
            exit('no row');
        exit(T.Name);
    end;

    local procedure InsertDupT(Name: Text[30]; RunTrigger: Boolean)
    var
        T: Record "LT Y38 DK T";
    begin
        T.Id := 1;
        T.Name := Name;
        T.Insert(RunTrigger);
    end;

    // D1, the blocked shape: Insert(true) of the existing key 1, statement form; then the next read of T is a Count.
    [Test]
    procedure DK_AfterEvent_Statement_ThenCount()
    var
        T2: Record "LT Y38 DK T";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        Prep(true);
        InsertDupT('dup', true);
        Observer.Observe('insert', 'no error');
        Observer.Observe('log', Log.Take());
        asserterror N := T2.Count();
        Observer.ObserveError('count');
        Observer.Observe('log after count', Log.Take());
        Observer.Observe('stored', StoredT());
        Observer.Observe('count after', Format(T2.Count()));
        Observer.Finish();
    end;

    // D2: the next access is Commit.
    [Test]
    procedure DK_AfterEvent_Statement_ThenCommit()
    var
        T2: Record "LT Y38 DK T";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(true);
        InsertDupT('dup', true);
        Observer.Observe('log', Log.Take());
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Observe('stored', StoredT());
        Observer.Observe('count after', Format(T2.Count()));
        Observer.Finish();
    end;

    // D3: the DbtEvents order (a guarded Insert of the same key next), then Commit.
    [Test]
    procedure DK_AfterEvent_Statement_ThenGuardedInsert()
    var
        T: Record "LT Y38 DK T";
        T2: Record "LT Y38 DK T";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep(true);
        InsertDupT('dup', true);
        Observer.Observe('log', Log.Take());
        T.Id := 1;
        T.Name := 'dup2';
        Ok := T.Insert(true);
        Observer.Observe('guarded', Format(Ok) + '|' + GetLastErrorText());
        Observer.Observe('log guarded', Log.Take());
        Commit();
        Observer.Observe('commit', 'no error');
        Observer.Observe('stored', StoredT());
        Observer.Observe('count after', Format(T2.Count()));
        Observer.Finish();
    end;

    // D3b: as D3 without the Commit: the next access after the guarded Insert is a Count.
    [Test]
    procedure DK_AfterEvent_Statement_GuardedInsert_ThenCount()
    var
        T: Record "LT Y38 DK T";
        T2: Record "LT Y38 DK T";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep(true);
        InsertDupT('dup', true);
        T.Id := 1;
        T.Name := 'dup2';
        Ok := T.Insert(true);
        Observer.Observe('guarded', Format(Ok));
        Observer.Observe('count', Format(T2.Count()));
        Observer.Observe('stored', StoredT());
        Observer.Finish();
    end;

    // D4: nothing reads T after the duplicate; the test ends. The outcome of the test is the observation.
    [Test]
    procedure DK_AfterEvent_Statement_TestEnd()
    begin
        Prep(true);
        InsertDupT('dup', true);
    end;

    // D4b: as D4 without the Commit after the seed (the DbtEvents shape: seed and duplicate in one transaction).
    [Test]
    procedure DK_AfterEvent_Statement_TestEnd_NoCommit()
    begin
        Prep(false);
        InsertDupT('dup', true);
    end;

    // D4c: the control: table U (no After subscriber), nothing reads U afterwards, the test ends.
    [Test]
    procedure DK_NoEvent_Statement_TestEnd()
    var
        U: Record "LT Y38 DK U";
    begin
        Prep(true);
        U.Id := 1;
        U.Name := 'dup';
        U.Insert(true);
    end;

    // D5: the After subscriber reads T itself (Count of another T variable).
    [Test]
    procedure DK_AfterEvent_ReadInsideSubscriber()
    var
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(true);
        Log.SetReads(true, false);
        asserterror InsertDupT('dup', true);
        Observer.ObserveError('insert');
        Log.SetReads(false, false);
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', StoredT());
        Observer.Finish();
    end;

    // D5b: the After subscriber reads another table (U) instead.
    [Test]
    procedure DK_AfterEvent_ReadOtherTableInsideSubscriber()
    var
        T2: Record "LT Y38 DK T";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        Prep(true);
        Log.SetReads(false, true);
        InsertDupT('dup', true);
        Log.SetReads(false, false);
        Observer.Observe('log', Log.Take());
        asserterror N := T2.Count();
        Observer.ObserveError('count');
        Observer.Finish();
    end;

    // D6: Insert(false): the After event runs with RunTrigger No.
    [Test]
    procedure DK_AfterEvent_InsertFalse()
    var
        T2: Record "LT Y38 DK T";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        Prep(true);
        InsertDupT('dup', false);
        Observer.Observe('log', Log.Take());
        asserterror N := T2.Count();
        Observer.ObserveError('count');
        Observer.Observe('stored', StoredT());
        Observer.Finish();
    end;

    // D7: table V has a table-extension OnAfterInsert trigger and no subscribers.
    [Test]
    procedure DK_ExtAfterTrigger_Statement()
    var
        V: Record "LT Y38 DK V";
        V2: Record "LT Y38 DK V";
        Log: Codeunit "LT Y38 DK Log";
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        Prep(true);
        V.Id := 1;
        V.Name := 'dup';
        V.Insert(true);
        Observer.Observe('insert', 'no error');
        Observer.Observe('log', Log.Take());
        asserterror N := V2.Count();
        Observer.ObserveError('count');
        Observer.Finish();
    end;
}
