// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fielderror-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: Record.FieldError(Field), Record.FieldError(Field, Text) (issue 591)
// BC versions: 27 and later (values by CI matrix)

codeunit 67908 "LT R RFE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Record_FieldError_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
    begin
        Helper.Seed();
        Rec.FindFirst();
        asserterror Rec.FieldError(Num);
        Observer.ObserveError('integer_no_text');
        asserterror Rec.FieldError(Num, 'custom reason');
        Observer.ObserveError('integer_text');
        asserterror Rec.FieldError(Num, '');
        Observer.ObserveError('integer_empty_text');
        asserterror Rec.FieldError(Txt);
        Observer.ObserveError('text_no_text');
        asserterror Rec.FieldError(Txt, 'custom reason');
        Observer.ObserveError('text_text');
        asserterror Rec.FieldError(Bool, 'custom reason');
        Observer.ObserveError('boolean_text');
        asserterror Rec.FieldError(En, 'custom reason');
        Observer.ObserveError('enum_text');
        Observer.Expect('integer_no_text|text', 'Num Cap must not be 5 in R Row Caption Code Cap=''K1''.');
        Observer.Expect('integer_no_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('integer_text|text', 'Num Cap custom reason in R Row Caption Code Cap=''K1''.');
        Observer.Expect('integer_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('integer_empty_text|text', 'Num Cap must not be 5 in R Row Caption Code Cap=''K1''.');
        Observer.Expect('integer_empty_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('text_no_text|text', 'Txt Cap must not be Hello in R Row Caption Code Cap=''K1''.');
        Observer.Expect('text_no_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('text_text|text', 'Txt Cap custom reason in R Row Caption Code Cap=''K1''.');
        Observer.Expect('text_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('boolean_text|text', 'Bool Cap custom reason in R Row Caption Code Cap=''K1''.');
        Observer.Expect('boolean_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('enum_text|text', 'En Cap custom reason in R Row Caption Code Cap=''K1''.');
        Observer.Expect('enum_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;
}
