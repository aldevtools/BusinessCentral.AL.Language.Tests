// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-asserterror-statement
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained table 68240, page 68242 and codeunit 68241
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what a Validate that raises leaves on the record (the whole record goes back to its values
// from before the Validate, not just the validated field), how a chained Validate and a direct
// assignment inside a trigger behave, and how far an asserterror inside a modal page handler rolls
// the database back (to the last Commit: the writes made before the page opened and the handler's
// own writes are all lost).
// BC versions: 27.5

table 68240 "Probe Validate Rollback"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Text[20])
        {
            trigger OnValidate()
            begin
                B := 'set-by-A-trigger';
                C := C + 1;
                if A = 'bad' then
                    Error('A rejected');
            end;
        }
        field(3; B; Text[20]) { }
        field(4; C; Integer) { }
        field(5; D; Text[20])
        {
            trigger OnValidate()
            begin
                A := 'set-A-direct';
                Validate(B, 'chained');
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68242 "Probe AH Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
}

codeunit 68241 "Probe Validate Rollback Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Validate_ThatRaises_RestoresTheWholeRecord()
    // CLAIM: after the error A, B and C hold their values from before the Validate; the changes the trigger made to B and C are undone too.
    var
        Rec: Record "Probe Validate Rollback";
    begin
        Rec.Id := 1;
        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;

        asserterror Rec.Validate(A, 'bad');

        Assert.AreEqual('A rejected', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
        Assert.AreEqual('old', Rec.A, 'the validated field');
        Assert.AreEqual('orig-B', Rec.B, 'a field the trigger set');
        Assert.AreEqual(10, Rec.C, 'a field the trigger incremented');
    end;

    [Test]
    procedure Validate_ThatSucceeds_KeepsWhatTheTriggerChanged_AndAssignmentInATriggerRunsNoTrigger()
    var
        Rec: Record "Probe Validate Rollback";
    begin
        Rec.Id := 1;
        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;

        Rec.Validate(A, 'good');
        Assert.AreEqual('good', Rec.A, 'A');
        Assert.AreEqual('set-by-A-trigger', Rec.B, 'B');
        Assert.AreEqual(11, Rec.C, 'C');

        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;
        Rec.Validate(D, 'dval');
        Assert.AreEqual('set-A-direct', Rec.A, 'D''s trigger assigned A directly: A''s trigger did not run');
        Assert.AreEqual('chained', Rec.B, 'D''s trigger validated B');
        Assert.AreEqual(10, Rec.C, 'so C was not incremented');
        Assert.AreEqual('dval', Rec.D, 'D');
    end;

    local procedure Cnt(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    [Test]
    [HandlerFunctions('DialogWithAsserterror')]
    procedure Asserterror_InAModalHandler_RollsBackToTheLastCommit()
    var
        ALTUniversal: Record "ALT Universal";
        Result: Action;
    begin
        Cleanup.Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal.Insert();

        Result := Page.RunModal(Page::"Probe AH Dialog");

        Assert.AreEqual(1, Cnt(1), 'the committed row stays');
        Assert.AreEqual(0, Cnt(2), 'the write pending before the page opened is lost');
        Assert.AreEqual(0, Cnt(3), 'the handler''s write before its asserterror is lost too');
        Assert.AreEqual(0, Cnt(4), 'and the one inside it');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'no write transaction is left');
    end;

    [ModalPageHandler]
    procedure DialogWithAsserterror(var Dialog: TestPage "Probe AH Dialog")
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 3;
        ALTUniversal.Insert();
        asserterror begin
            ALTUniversal.Init();
            ALTUniversal."Entry No." := 4;
            ALTUniversal.Insert();
            Error('in handler');
        end;
    end;

    // Tests below (al-runner issue 6978): an error raised by the OnBeforeValidate or OnAfterValidate trigger a table extension adds to a
    // field (table 95780 and tableextension 95781 at the end of this file). Observed with the Probe Observer.

    [Test]
    procedure ExtOnBeforeValidate_Raises_RecordAfterwards()
    var
        Rec: Record "REC ExtValidate Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Rec.Validate(Qty, 5);
        Observer.Observe('after ok', StateOf(Rec));
        Rec.Note := 'orig';
        Rec.Hits := 10;
        asserterror Rec.Validate(Qty, 4);
        Observer.ObserveError('err');
        Observer.Observe('after error', StateOf(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure ExtOnAfterValidate_Raises_RecordAfterwards()
    var
        Rec: Record "REC ExtValidate Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Rec.Validate(Amount, 50);
        Observer.Observe('after ok', StateOf(Rec));
        Rec.Note := 'orig';
        Rec.Hits := 10;
        asserterror Rec.Validate(Amount, 500);
        Observer.ObserveError('err');
        Observer.Observe('after error', StateOf(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure ExtFieldOnValidate_Raises_RecordAfterwards()
    var
        Rec: Record "REC ExtValidate Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Rec.Validate(ExtCode, 'GOOD');
        Observer.Observe('after ok', StateOf(Rec));
        Rec.Note := 'orig';
        Rec.Hits := 10;
        asserterror Rec.Validate(ExtCode, 'BAD');
        Observer.ObserveError('err');
        Observer.Observe('after error', StateOf(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure ExtOnBeforeValidate_Raises_InsertedRow()
    var
        Rec: Record "REC ExtValidate Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 2;
        Rec.Validate(Qty, 10);
        Rec.Note := 'stored';
        Rec.Insert();
        Rec.Note := 'unsaved';
        asserterror Rec.Validate(Qty, 7);
        Observer.ObserveError('err');
        Observer.Observe('rec', StateOf(Rec));
        Observer.Observe('xrec qty', Format(Rec.GetXRecQty()));
        Observer.Finish();
    end;

    [Test]
    procedure ExtOnAfterValidate_Raises_FieldOnValidateChangesUndone()
    var
        Rec: Record "REC ExtValidate Row";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 3;
        Rec.Note := 'orig';
        Rec.Hits := 1;
        asserterror Rec.Validate(Amount, 101);
        Observer.ObserveError('err');
        Observer.Observe('amount', Format(Rec.Amount, 0, 9));
        Observer.Observe('note', Rec.Note);
        Observer.Observe('hits', Format(Rec.Hits));
        Observer.Observe('base trigger mark', Rec.Mark);
        Observer.Finish();
    end;

    local procedure StateOf(var Rec: Record "REC ExtValidate Row"): Text
    begin
        exit(StrSubstNo('qty=%1 amount=%2 code=%3 note=%4 hits=%5 mark=%6', Rec.Qty, Format(Rec.Amount, 0, 9), Rec.ExtCode, Rec.Note, Rec.Hits, Rec.Mark));
    end;
}

// local object: the test checks what an error in a table extension's field triggers leaves on the record (al-runner issue 6978).
table 95780 "REC ExtValidate Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            begin
                Mark := 'base-ran';
                Hits += 100;
            end;
        }
        field(4; Note; Text[30]) { }
        field(5; Hits; Integer) { }
        field(6; Mark; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        XQty: Integer;

    procedure SetXRecQty(Value: Integer)
    begin
        XQty := Value;
    end;

    procedure GetXRecQty(): Integer
    begin
        exit(XQty);
    end;
}

// local object: the field triggers this extension adds are what the tests above check.
tableextension 95781 "REC ExtValidate Row Ext" extends "REC ExtValidate Row"
{
    fields
    {
        modify(Qty)
        {
            trigger OnBeforeValidate()
            begin
                Note := 'set-by-before';
                Hits += 1;
                SetXRecQty(xRec.Qty);
                if Qty mod 5 <> 0 then
                    Error('Qty %1 is not a step of 5', Qty);
            end;
        }
        modify(Amount)
        {
            trigger OnAfterValidate()
            begin
                Note := 'set-by-after';
                Hits += 1;
                if Amount > 100 then
                    Error('Amount %1 is too big', Amount);
            end;
        }
        field(95780; ExtCode; Code[10])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Note := 'set-by-ext-field';
                Hits += 1;
                if ExtCode = 'BAD' then
                    Error('ExtCode %1 rejected', ExtCode);
            end;
        }
    }
}
