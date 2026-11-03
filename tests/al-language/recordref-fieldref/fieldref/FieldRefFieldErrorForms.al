// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-fielderror-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: FieldRef.FieldError() and FieldRef.FieldError(Text) (issue 589): error text and code, with and without text, field and table captions
// BC versions: 27 and later (values by CI matrix)

codeunit 67906 "LT R FRFE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldRef_FieldError_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        asserterror Fld.FieldError();
        Observer.ObserveError('integer_no_text');
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('integer_text');
        asserterror Fld.FieldError('');
        Observer.ObserveError('integer_empty_text');
        Fld := RecRef.Field(9);
        asserterror Fld.FieldError();
        Observer.ObserveError('text_no_text');
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('text_text');
        Fld := RecRef.Field(3);
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('boolean_text');
        Fld := RecRef.Field(8);
        asserterror Fld.FieldError('custom reason');
        Observer.ObserveError('enum_text');
        RecRef.Close();
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
