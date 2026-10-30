// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90986 (writer Y5); Base Application table "Machine Center" (read only, no writes)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6378 (follow-up to 5955). The Base Application table "Machine Center" has a Caption of its own; the
//   tableextension below sets another Caption over it from this app (in one app the same shape gives AL0839, so a table of
//   another app is needed). Which caption do the TestField, FieldError, Get and TableRelation error texts, TableCaption and
//   RecordRef.Caption use? Only in-memory records of Machine Center; nothing is inserted into a Microsoft table.
// Result: OBSERVED_RESULT
// Source: al-runner issue 6378 (the reporter's repro passed on a real BC 28.5 container).
// BC versions: 27, 28, 29

table 90986 "LT Y5 MC Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Machine Center No."; Code[20])
        {
            TableRelation = "Machine Center";
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

tableextension 90986 "LT Y5 MC Ext" extends "Machine Center"
{
    Caption = 'LT Y5 Machine Center Extension';
}

codeunit 90986 "LT Y5 MC Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y5_ExtCaption_TestFieldBooleanErrorText()
    var
        MachineCenter: Record "Machine Center";
        Observer: Codeunit "Probe Observer";
    begin
        MachineCenter."No." := 'LTY5MC';
        MachineCenter.Blocked := true;
        asserterror MachineCenter.TestField(Blocked, false);
        Observer.ObserveError('testfield blocked');
        Observer.Observe('field caption', MachineCenter.FieldCaption(Blocked));
        Observer.Observe('format false', Format(false));
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ExtCaption_TestFieldBlankAndValueErrorTexts()
    var
        MachineCenter: Record "Machine Center";
        Observer: Codeunit "Probe Observer";
    begin
        MachineCenter."No." := 'LTY5MC';
        MachineCenter.Name := '';
        asserterror MachineCenter.TestField(Name);
        Observer.ObserveError('testfield blank name');
        asserterror MachineCenter.TestField("No.", 'OTHER');
        Observer.ObserveError('testfield no value');
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ExtCaption_FieldErrorText()
    var
        MachineCenter: Record "Machine Center";
        Observer: Codeunit "Probe Observer";
    begin
        MachineCenter."No." := 'LTY5MC';
        MachineCenter.Blocked := true;
        asserterror MachineCenter.FieldError(Blocked);
        Observer.ObserveError('fielderror');
        asserterror MachineCenter.FieldError(Blocked, 'is not allowed');
        Observer.ObserveError('fielderror with text');
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ExtCaption_TableCaptionAndRecordRefCaption()
    var
        MachineCenter: Record "Machine Center";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tablecaption', MachineCenter.TableCaption());
        Observer.Observe('tablename', MachineCenter.TableName());
        RecRef.Open(Database::"Machine Center");
        Observer.Observe('recordref caption', RecRef.Caption());
        Observer.Observe('recordref name', RecRef.Name());
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ExtCaption_GetMissingRowErrorText()
    var
        MachineCenter: Record "Machine Center";
        Observer: Codeunit "Probe Observer";
    begin
        asserterror MachineCenter.Get('LTY5NOMC');
        Observer.ObserveError('get missing');
        Observer.Finish();
    end;

    [Test]
    procedure Y5_ExtCaption_TableRelationErrorText()
    var
        ReproRef: Record "LT Y5 MC Ref";
        Observer: Codeunit "Probe Observer";
    begin
        asserterror ReproRef.Validate("Machine Center No.", 'LTY5NOMC');
        Observer.ObserveError('validate relation');
        Observer.Finish();
    end;
}
