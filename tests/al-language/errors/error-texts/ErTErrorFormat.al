// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), none
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: error text formatting and StrSubstNo
// BC versions: 29 (27 and 28 by CI)

codeunit 70076 "LT ErT Error Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LblTwo: Label '%1 of %2';
        LblComment: Label 'Hello %1', Comment = '%1 = name';
        LblLocked: Label 'Locked', Locked = true;

    [Test]
    procedure StrSubstNoPlaceholders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('one', StrSubstNo('a %1', 'x'));
        Observer.Observe('two', StrSubstNo(LblTwo, 1, 2));
        Observer.Observe('missing', StrSubstNo('a %1 b %2', 'x'));
        Observer.Observe('unused', StrSubstNo('a', 'x'));
        Observer.Observe('reversed', StrSubstNo('%2%1', 'a', 'b'));
        Observer.Observe('percentEnd', StrSubstNo('100%', 1));
        Observer.Observe('hash', StrSubstNo('%1', '#'));
        Observer.Observe('commentLabel', StrSubstNo(LblComment, 'Bob'));
        Observer.Observe('locked', LblLocked);
        Observer.Expect('one', 'a x');
        Observer.Expect('two', '1 of 2');
        Observer.Expect('missing', 'a x b %2');
        Observer.Expect('unused', 'a');
        Observer.Expect('reversed', 'ba');
        Observer.Expect('percentEnd', '100%');
        Observer.Expect('hash', '#');
        Observer.Expect('commentLabel', 'Hello Bob');
        Observer.Expect('locked', 'Locked');
        Observer.Verify();
    end;

    [Test]
    procedure PlaceholderValueFormatting()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('%1', 1234567.891);
        Observer.ObserveError('decimal');
        asserterror Error('%1', 0D);
        Observer.ObserveError('dateZero');
        asserterror Error('%1', 0T);
        Observer.ObserveError('timeZero');
        asserterror Error('%1', false);
        Observer.ObserveError('boolFalse');
        asserterror Error('%1', '');
        Observer.ObserveError('emptyText');
        asserterror Error('%1', 0);
        Observer.ObserveError('zero');
        asserterror Error('%1 %2 %3 %4 %5 %6 %7 %8 %9', 1, 2, 3, 4, 5, 6, 7, 8, 9);
        Observer.ObserveError('nine');
        Observer.Expect('decimal|text', '1,234,567.891');
        Observer.Expect('decimal|code', 'Dialog');
        Observer.Expect('dateZero|text', '');
        Observer.Expect('dateZero|code', 'Dialog');
        Observer.Expect('timeZero|text', '');
        Observer.Expect('timeZero|code', 'Dialog');
        Observer.Expect('boolFalse|text', 'No');
        Observer.Expect('boolFalse|code', 'Dialog');
        Observer.Expect('emptyText|text', '');
        Observer.Expect('emptyText|code', 'Dialog');
        Observer.Expect('zero|text', '0');
        Observer.Expect('zero|code', 'Dialog');
        Observer.Expect('nine|text', '1 2 3 4 5 6 7 8 9');
        Observer.Expect('nine|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorWithLabelCommentAndLocked()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(LblComment, 'Ann');
        Observer.ObserveError('comment');
        asserterror Error(LblLocked);
        Observer.ObserveError('locked');
        Observer.Expect('comment|text', 'Hello Ann');
        Observer.Expect('comment|code', 'Dialog');
        Observer.Expect('locked|text', 'Locked');
        Observer.Expect('locked|code', 'Dialog');
        Observer.Verify();
    end;
}
