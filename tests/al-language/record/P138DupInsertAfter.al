// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: self-contained table 74501, codeunits 74502, 74504, 74505, tableextension 74503
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: a duplicate-key Insert(true) whose result is NOT used (the statement form): which of the Before event, OnBeforeInsert (extension), After event and OnAfterInsert
// (extension) run, what the caller sees, what a later read of the table sees; the same with RunTrigger false and with the result used.

table 74501 "LT P138 Dup Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74502 "LT P138 Dup Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

tableextension 74503 "LT P138 Dup Row Ext" extends "LT P138 Dup Row"
{
    trigger OnBeforeInsert()
    var
        Log: Codeunit "LT P138 Dup Log";
    begin
        Log.Add('ExtBefore(' + Name + ')');
    end;

    trigger OnAfterInsert()
    var
        Log: Codeunit "LT P138 Dup Log";
    begin
        Log.Add('ExtAfter(' + Name + ')');
    end;
}

codeunit 74504 "LT P138 Dup Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT P138 Dup Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "LT P138 Dup Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT P138 Dup Log";
    begin
        Log.Add('EvBefore(' + Rec.Name + ',' + Format(RunTrigger) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P138 Dup Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "LT P138 Dup Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT P138 Dup Log";
    begin
        Log.Add('EvAfter(' + Rec.Name + ',' + Format(RunTrigger) + ')');
    end;
}

codeunit 74505 "LT P138 Dup Insert Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P138 Dup Log";

    local procedure Prepare()
    var
        Row: Record "LT P138 Dup Row";
    begin
        Row.DeleteAll();
        Log.Take();
    end;

    [Test]
    procedure P138_FirstInsert_RunsEverything()
    var
        Row: Record "LT P138 Dup Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert(true);
        Observer.Observe('log_first_true', Log.Take());
        Row.Id := 2;
        Row.Name := 'second';
        Row.Insert(false);
        Observer.Observe('log_first_false', Log.Take());
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('log_first_true', 'EvBefore(first,Yes);ExtBefore(first);ExtAfter(first);EvAfter(first,Yes);');
        Observer.Expect('log_first_false', 'EvBefore(second,No);EvAfter(second,No);');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P138_DuplicateInsert_ResultUsed()
    var
        Row: Record "LT P138 Dup Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Prepare();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert(true);
        Log.Take();
        Row.Id := 1;
        Row.Name := 'dup';
        Ok := Row.Insert(true);
        Observer.Observe('ok_true', Format(Ok));
        Observer.Observe('log_true', Log.Take());
        Row.Id := 1;
        Row.Name := 'dup2';
        Ok := Row.Insert(false);
        Observer.Observe('ok_false', Format(Ok));
        Observer.Observe('log_false', Log.Take());
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('ok_true', 'No');
        Observer.Expect('log_true', 'EvBefore(dup,Yes);ExtBefore(dup);');
        Observer.Expect('ok_false', 'No');
        Observer.Expect('log_false', 'EvBefore(dup2,No);');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P138_DuplicateInsert_AsserterrorStatementForm()
    var
        Row: Record "LT P138 Dup Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert(true);
        Log.Take();
        Row.Id := 1;
        Row.Name := 'dup';
        Row.Insert(true);
        Observer.Observe('statement_asserterror', 'no error');
        Observer.Observe('log_asserterror', Log.Take());
        asserterror Observer.Observe('count_after', Format(Row.Count()));
        Observer.ObserveError('af161');
        Observer.Expect('statement_asserterror', 'no error');
        Observer.Expect('log_asserterror', 'EvBefore(dup,Yes);ExtBefore(dup);ExtAfter(dup);EvAfter(dup,Yes);');
        Observer.Expect('af161|text', 'The record in table LT P138 Dup Row already exists. Identification fields and values: Id=''1''');
        Observer.Expect('af161|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure P138_DuplicateInsert_StatementFormWithTrigger()
    var
        Row: Record "LT P138 Dup Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Prepare();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert(true);
        Log.Take();
        Row.Id := 1;
        Row.Name := 'dup';
        Row.Insert(true);
        Observer.Observe('statement_true_no_error', 'no error');
        Observer.Observe('log_statement_true', Log.Take());
        Row.Id := 1;
        Row.Name := 'dup2';
        Ok := Row.Insert(true);
        Observer.Observe('then_used_form_ok', Format(Ok));
        Observer.Observe('then_used_form_log', Log.Take());
        Observer.Expect('statement_true_no_error', 'no error');
        Observer.Expect('log_statement_true', 'EvBefore(dup,Yes);ExtBefore(dup);ExtAfter(dup);EvAfter(dup,Yes);');
        Observer.Expect('then_used_form_ok', 'No');
        Observer.Expect('then_used_form_log', 'EvBefore(dup2,Yes);ExtBefore(dup2);');
        Observer.Verify();
    end;

    [Test]
    procedure P138_DuplicateInsert_StatementFormWithoutTrigger()
    var
        Row: Record "LT P138 Dup Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Prepare();
        Row.Id := 1;
        Row.Name := 'first';
        Row.Insert(false);
        Log.Take();
        Row.Id := 1;
        Row.Name := 'dup';
        Row.Insert(false);
        Observer.Observe('statement_false_no_error', 'no error');
        Observer.Observe('log_statement_false', Log.Take());
        Row.Id := 1;
        Row.Name := 'dup2';
        Ok := Row.Insert(false);
        Observer.Observe('then_used_form_ok', Format(Ok));
        Observer.Observe('then_used_form_log', Log.Take());
        Observer.Expect('statement_false_no_error', 'no error');
        Observer.Expect('log_statement_false', 'EvBefore(dup,No);EvAfter(dup,No);');
        Observer.Expect('then_used_form_ok', 'No');
        Observer.Expect('then_used_form_log', 'EvBefore(dup2,No);');
        Observer.Verify();
    end;
}
