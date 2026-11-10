// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// local object: the triggers and subscribers of the table are what is under test, so the probe needs its own table and subscriber
// Fixtures used: Probe Observer (codeunit 69160); own table 99674, codeunits 99672 to 99674
// Probe (al-runner issue 7464): a Modify through a record variable whose own last Modify an asserterror rolled back, on a table with an OnModify
//   trigger and OnBeforeModifyEvent and OnAfterModifyEvent subscribers. record/StaleBuffer.al pins the table without triggers: the buffer
//   keeps what the rolled-back Modify wrote, a later Modify of an unchanged buffer answers true and writes nothing, a changed one writes the
//   whole row. This probe reads what the trigger and the events see (Rec and xRec fields, how often they run) in that Modify, and the stored row.
//   Cells: Modify and Modify(false); the buffer unchanged, a field changed or set to the value it holds; the rollback by an error in OnValidate
//   (the report) and by Error; a Commit before the first Modify or none (then the Insert is rolled back too); two Modify before the error.
// BC versions: 27, 28, 29

codeunit 99672 "LT MRB Log"
{
    SingleInstance = true;

    var
        Text1: Text;

    procedure Add(Value: Text)
    begin
        Text1 += Value + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text1;
        Text1 := '';
        exit(Result);
    end;
}

table 99674 "LT MRB Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Status; Option) { OptionMembers = Open,Registered,Closed; }
        field(3; Other; Text[30])
        {
            trigger OnValidate()
            begin
                if Other = 'X' then
                    Error('other is not allowed');
            end;
        }
        field(4; Counter; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnModify()
    var
        Log: Codeunit "LT MRB Log";
    begin
        Log.Add('T rec=' + Format(Status) + '/' + Other + '/' + Format(Counter) + ' x=' + Format(xRec.Status) + '/' + xRec.Other + '/' + Format(xRec.Counter));
    end;
}

codeunit 99673 "LT MRB Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"LT MRB Line", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT MRB Line"; var xRec: Record "LT MRB Line"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT MRB Log";
    begin
        Log.Add('B rec=' + Format(Rec.Status) + '/' + Rec.Other + '/' + Format(Rec.Counter) + ' x=' + Format(xRec.Status) + '/' + xRec.Other + '/' + Format(xRec.Counter) + ' run=' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT MRB Line", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModify(var Rec: Record "LT MRB Line"; var xRec: Record "LT MRB Line"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT MRB Log";
    begin
        Log.Add('A rec=' + Format(Rec.Status) + '/' + Rec.Other + '/' + Format(Rec.Counter) + ' x=' + Format(xRec.Status) + '/' + xRec.Other + '/' + Format(xRec.Counter) + ' run=' + Format(RunTrigger));
    end;
}

codeunit 99674 "LT MRB Modify After Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT MRB Log";

    local procedure Seed(var Line: Record "LT MRB Line"; CommitAfterInsert: Boolean)
    var
        Old: Record "LT MRB Line";
    begin
        Old.DeleteAll();
        Commit();
        Line.Init();
        Line."No." := 'L1';
        Line.Insert();
        if CommitAfterInsert then
            Commit();
        Log.Take();
    end;

    local procedure Stored(): Text
    var
        Check: Record "LT MRB Line";
    begin
        if not Check.Get('L1') then
            exit('gone');
        exit(Format(Check.Status) + '/' + Check.Other + '/' + Format(Check.Counter));
    end;

    local procedure CleanUp()
    var
        Old: Record "LT MRB Line";
    begin
        Old.DeleteAll();
        Commit();
    end;

    // The report: Modify, a failing Validate under asserterror (the error rolls the Modify back), the same assignment, Modify again.
    [Test]
    procedure Modify_AfterRolledBackModify_BufferUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Validate(Status, Line.Status::Registered);
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Line.Validate(Other, 'X');
        Observer.ObserveError('validate');
        Observer.Observe('stored after rollback', Stored());
        Observer.Observe('buffer after rollback', Format(Line.Status) + '/' + Line.Other + '/' + Format(Line.Counter));
        Line.Validate(Status, Line.Status::Registered);
        Line.Modify();
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Modify_AfterRolledBackModify_BufferUnchanged_ModifyFalse()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Validate(Status, Line.Status::Registered);
        Line.Modify(false);
        Observer.Observe('first modify log', Log.Take());
        asserterror Line.Validate(Other, 'X');
        Observer.ObserveError('validate');
        Line.Validate(Status, Line.Status::Registered);
        Line.Modify(false);
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Modify_AfterRolledBackModify_NoAssignment()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Line.Modify();
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Modify_AfterRolledBackModify_FieldChanged()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Line.Validate(Other, 'X');
        Observer.ObserveError('validate');
        Line.Counter := 7;
        Line.Modify();
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Modify_AfterRolledBackModify_OtherFieldReset()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Line.Validate(Other, 'X');
        Observer.ObserveError('validate');
        Line.Status := Line.Status::Open;
        Line.Modify();
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Modify_AfterRolledBackModify_TwoModifiesBeforeTheError()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Line.Counter := 2;
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Observer.Observe('stored after rollback', Stored());
        Line.Modify();
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    // No Commit after the Insert: the error rolls the Insert back too, the buffer is a row the table no longer has.
    [Test]
    procedure Modify_AfterRolledBackInsertAndModify()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, false);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Observer.Observe('first modify log', Log.Take());
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Observer.Observe('stored after rollback', Stored());
        asserterror Line.Modify();
        Observer.ObserveError('second modify');
        Observer.Observe('second modify log', Log.Take());
        Observer.Observe('stored after second modify', Stored());
        CleanUp();
        Observer.Finish();
    end;

    // A Modify that is not the first change after the Commit: Commit, Modify, Commit, Modify, error, Modify.
    [Test]
    procedure Modify_AfterRolledBackModify_CommitBetweenModifies()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT MRB Line";
    begin
        Seed(Line, true);
        Line.Status := Line.Status::Registered;
        Line.Modify();
        Commit();
        Line.Counter := 3;
        Line.Modify();
        Observer.Observe('modifies log', Log.Take());
        asserterror Line.Validate(Other, 'X');
        Observer.ObserveError('validate');
        Observer.Observe('stored after rollback', Stored());
        Line.Modify();
        Observer.Observe('modify after rollback log', Log.Take());
        Observer.Observe('stored after modify', Stored());
        CleanUp();
        Observer.Finish();
    end;
}
