// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064 (ErTFixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField and FieldError messages
// BC versions: 29 (27 and 28 by CI)

codeunit 70073 "LT ErT Field Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestFieldForms()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        asserterror Rec.TestField(Name);
        Observer.ObserveError('textBlank');
        asserterror Rec.TestField(Amount);
        Observer.ObserveError('decimalZero');
        asserterror Rec.TestField(Id);
        Observer.ObserveError('integerZero');
        asserterror Rec.TestField(Code);
        Observer.ObserveError('codeBlank');
        Rec.Name := 'abc';
        asserterror Rec.TestField(Name, 'xyz');
        Observer.ObserveError('textMismatch');
        Rec.Amount := 5;
        asserterror Rec.TestField(Amount, 6);
        Observer.ObserveError('decimalMismatch');
        asserterror Rec.TestField(Id, 1);
        Observer.ObserveError('integerMismatch');
        Rec.TestField(Name, 'abc');
        Observer.Observe('matchOk', 'passed');
        Observer.Expect('textBlank|text', 'Name must have a value in LT ErT Rec: Id=0. It cannot be zero or empty.');
        Observer.Expect('textBlank|code', 'TestField');
        Observer.Expect('decimalZero|text', 'Amount must have a value in LT ErT Rec: Id=0. It cannot be zero or empty.');
        Observer.Expect('decimalZero|code', 'TestField');
        Observer.Expect('integerZero|text', 'Id must have a value in LT ErT Rec: Id=0. It cannot be zero or empty.');
        Observer.Expect('integerZero|code', 'TestField');
        Observer.Expect('codeBlank|text', 'Code must have a value in LT ErT Rec: Id=0. It cannot be zero or empty.');
        Observer.Expect('codeBlank|code', 'TestField');
        Observer.Expect('textMismatch|text', 'Name must be equal to ''xyz''  in LT ErT Rec: Id=0. Current value is ''abc''.');
        Observer.Expect('textMismatch|code', 'TestField');
        Observer.Expect('decimalMismatch|text', 'Amount must be equal to ''6''  in LT ErT Rec: Id=0. Current value is ''5''.');
        Observer.Expect('decimalMismatch|code', 'TestField');
        Observer.Expect('integerMismatch|text', 'Id must be equal to ''1''  in LT ErT Rec: Id=0. Current value is ''0''.');
        Observer.Expect('integerMismatch|code', 'TestField');
        Observer.Expect('matchOk', 'passed');
        Observer.Verify();
    end;

    [Test]
    procedure FieldErrorForms()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.Name := 'abc';
        asserterror Rec.FieldError(Name);
        Observer.ObserveError('noText');
        asserterror Rec.FieldError(Name, 'custom text');
        Observer.ObserveError('withText');
        asserterror Rec.FieldError(Amount, 'with 100% and %1');
        Observer.ObserveError('withPercent');
        asserterror Rec.FieldError(Id, '');
        Observer.ObserveError('emptyText');
        Observer.Expect('noText|text', 'Name must not be abc in LT ErT Rec Id=''0''.');
        Observer.Expect('noText|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('withText|text', 'Name custom text in LT ErT Rec Id=''0''.');
        Observer.Expect('withText|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('withPercent|text', 'Amount with 100% and %1 in LT ErT Rec Id=''0''.');
        Observer.Expect('withPercent|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('emptyText|text', 'Id must not be 0 in LT ErT Rec Id=''0''.');
        Observer.Expect('emptyText|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldErrorFromOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        asserterror Rec.Validate(Amount, -1);
        Observer.ObserveError('errorInValidate');
        asserterror Rec.Validate(Amount, -5);
        Observer.ObserveError('fieldErrorInValidate');
        Rec.Validate(Amount, 3);
        Observer.Observe('okAmount', Format(Rec.Amount));
        Rec.Amount := -1;
        Observer.Observe('assignNoTrigger', Format(Rec.Amount));
        Observer.Expect('errorInValidate|text', 'Amount -1 is not allowed');
        Observer.Expect('errorInValidate|code', 'Dialog');
        Observer.Expect('fieldErrorInValidate|text', 'Amount must not be below -1 in LT ErT Rec Id=''0''.');
        Observer.Expect('fieldErrorInValidate|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('okAmount', '3');
        Observer.Expect('assignNoTrigger', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure TestFieldOnTempRecordAndCaptions()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT ErT Rec" temporary;
    begin
        asserterror Tmp.TestField(Name);
        Observer.ObserveError('tempBlank');
        Observer.Observe('tableCaption', Tmp.TableCaption());
        Observer.Observe('fieldCaption', Tmp.FieldCaption(Name));
        Observer.Expect('tempBlank|text', 'Name must have a value in LT ErT Rec: Id=0. It cannot be zero or empty.');
        Observer.Expect('tempBlank|code', 'TestField');
        Observer.Expect('tableCaption', 'LT ErT Rec');
        Observer.Expect('fieldCaption', 'Name');
        Observer.Verify();
    end;
}
