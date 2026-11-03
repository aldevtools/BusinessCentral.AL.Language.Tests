// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: what the table-field properties NotBlank, Numeric, MinValue/MaxValue, ExtendedDatatype, ClosingDates, BlankZero, BlankNumbers, DecimalPlaces and OptionCaption do to
// validation, Format and Evaluate of the field values on an own table.

table 71625 "LT P119 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; NotBlankCode; Code[20]) { NotBlank = true; }
        field(4; NumCode; Code[20]) { Numeric = true; }
        field(5; Phone; Text[30]) { ExtendedDatatype = PhoneNo; }
        field(6; Mail; Text[80]) { ExtendedDatatype = EMail; }
        field(7; Link; Text[100]) { ExtendedDatatype = URL; }
        field(8; RatioVal; Decimal) { ExtendedDatatype = Ratio; }
        field(9; Secret; Text[30]) { ExtendedDatatype = Masked; }
        field(11; Closing; Date) { ClosingDates = true; }
        field(12; BlankZ; Decimal) { BlankZero = true; }
        field(13; BlankNegN; Decimal) { BlankNumbers = BlankNeg; }
        field(14; BlankZP; Decimal) { BlankNumbers = BlankZeroAndPos; }
        field(15; Dec; Decimal) { DecimalPlaces = 3 : 3; }
        field(16; Ranged; Decimal) { MinValue = 1; MaxValue = 10; }
        field(17; Opt; Option)
        {
            OptionMembers = First,Second,Third;
            OptionCaption = 'Alpha,Beta,Gamma';
        }
        field(18; Level; Integer) { }
        field(19; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71626 "LT P119 Table Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_NotBlank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Observer.Observe('blank-validate-ok', Format(TryNotBlank(Row, '')));
        Observer.ObserveError('blank-validate');
        Observer.Observe('filled-validate-ok', Format(TryNotBlank(Row, 'A')));
        Observer.Observe('value', Row.NotBlankCode);
        Observer.Observe('reblank-validate-ok', Format(TryNotBlank(Row, '')));
        Observer.ObserveError('reblank-validate');
        Observer.Observe('value-after', Row.NotBlankCode);
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('insert-blank-notblank-count', Format(Row.Count()));
        Observer.Expect('blank-validate-ok', 'Yes');
        Observer.Expect('blank-validate|text', '');
        Observer.Expect('blank-validate|code', '');
        Observer.Expect('filled-validate-ok', 'Yes');
        Observer.Expect('value', 'A');
        Observer.Expect('reblank-validate-ok', 'Yes');
        Observer.Expect('reblank-validate|text', '');
        Observer.Expect('reblank-validate|code', '');
        Observer.Expect('value-after', '');
        Observer.Expect('insert-blank-notblank-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P119_Numeric()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Observer.Observe('digits-ok', Format(TryNumeric(Row, '123')));
        Observer.Observe('digits-value', Row.NumCode);
        Observer.Observe('letters-ok', Format(TryNumeric(Row, 'A1')));
        Observer.ObserveError('letters');
        Observer.Observe('empty-ok', Format(TryNumeric(Row, '')));
        Observer.Observe('space-ok', Format(TryNumeric(Row, '12 3')));
        Observer.ObserveError('space');
        Observer.Observe('dot-ok', Format(TryNumeric(Row, '1.5')));
        Observer.ObserveError('dot');
        Observer.Observe('minus-ok', Format(TryNumeric(Row, '-1')));
        Observer.ObserveError('minus');
        Observer.Observe('leading-zero-ok', Format(TryNumeric(Row, '007')));
        Observer.Observe('leading-zero-value', Row.NumCode);
        Observer.Observe('direct-assign-letters', Format(TryAssignNum(Row, 'ABC')));
        Observer.Observe('direct-assign-value', Row.NumCode);
        Observer.Expect('digits-ok', 'Yes');
        Observer.Expect('digits-value', '123');
        Observer.Expect('letters-ok', 'Yes');
        Observer.Expect('letters|text', '');
        Observer.Expect('letters|code', '');
        Observer.Expect('empty-ok', 'Yes');
        Observer.Expect('space-ok', 'Yes');
        Observer.Expect('space|text', '');
        Observer.Expect('space|code', '');
        Observer.Expect('dot-ok', 'Yes');
        Observer.Expect('dot|text', '');
        Observer.Expect('dot|code', '');
        Observer.Expect('minus-ok', 'Yes');
        Observer.Expect('minus|text', '');
        Observer.Expect('minus|code', '');
        Observer.Expect('leading-zero-ok', 'Yes');
        Observer.Expect('leading-zero-value', '007');
        Observer.Expect('direct-assign-letters', 'Yes');
        Observer.Expect('direct-assign-value', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure P119_MinMaxValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Observer.Observe('zero-ok', Format(TryRanged(Row, 0)));
        Observer.ObserveError('zero');
        Observer.Observe('below-ok', Format(TryRanged(Row, 0.99)));
        Observer.ObserveError('below');
        Observer.Observe('min-ok', Format(TryRanged(Row, 1)));
        Observer.Observe('mid-ok', Format(TryRanged(Row, 5)));
        Observer.Observe('max-ok', Format(TryRanged(Row, 10)));
        Observer.Observe('above-ok', Format(TryRanged(Row, 10.01)));
        Observer.ObserveError('above');
        Observer.Observe('negative-ok', Format(TryRanged(Row, -1)));
        Observer.ObserveError('negative');
        Observer.Observe('value-kept', Format(Row.Ranged));
        Row.Ranged := 99;
        Observer.Observe('direct-assign', Format(Row.Ranged));
        Observer.Expect('zero-ok', 'Yes');
        Observer.Expect('zero|text', '');
        Observer.Expect('zero|code', '');
        Observer.Expect('below-ok', 'Yes');
        Observer.Expect('below|text', '');
        Observer.Expect('below|code', '');
        Observer.Expect('min-ok', 'Yes');
        Observer.Expect('mid-ok', 'Yes');
        Observer.Expect('max-ok', 'Yes');
        Observer.Expect('above-ok', 'Yes');
        Observer.Expect('above|text', '');
        Observer.Expect('above|code', '');
        Observer.Expect('negative-ok', 'Yes');
        Observer.Expect('negative|text', '');
        Observer.Expect('negative|code', '');
        Observer.Expect('value-kept', '-1');
        Observer.Expect('direct-assign', '99');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtendedDatatype()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
        Back: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Observer.Observe('phone-ok', Format(TryPhone(Row, 'abc def')));
        Observer.Observe('phone', Row.Phone);
        Observer.Observe('mail-bad-ok', Format(TryMail(Row, 'not an email')));
        Observer.ObserveError('mail-bad');
        Observer.Observe('mail', Row.Mail);
        Observer.Observe('mail-good-ok', Format(TryMail(Row, 'a@b.example')));
        Observer.Observe('link-ok', Format(TryLink(Row, 'not a url')));
        Observer.Observe('link', Row.Link);
        Observer.Observe('ratio-ok', Format(TryRatio(Row, 250.5)));
        Observer.Observe('ratio', Format(Row.RatioVal));
        Row.Secret := 'top secret';
        Observer.Observe('secret', Row.Secret);
        Row.Insert();
        Back.Get(1);
        Observer.Observe('back-phone', Back.Phone);
        Observer.Observe('back-secret', Back.Secret);
        Observer.Observe('back-ratio', Format(Back.RatioVal));
        Observer.Expect('phone-ok', 'Yes');
        Observer.Expect('phone', 'abc def');
        Observer.Expect('mail-bad-ok', 'Yes');
        Observer.Expect('mail-bad|text', '');
        Observer.Expect('mail-bad|code', '');
        Observer.Expect('mail', 'not an email');
        Observer.Expect('mail-good-ok', 'Yes');
        Observer.Expect('link-ok', 'Yes');
        Observer.Expect('link', 'not a url');
        Observer.Expect('ratio-ok', 'Yes');
        Observer.Expect('ratio', '250.5');
        Observer.Expect('secret', 'top secret');
        Observer.Expect('back-phone', 'abc def');
        Observer.Expect('back-secret', 'top secret');
        Observer.Expect('back-ratio', '250.5');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ClosingDates()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
        Back: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Closing := ClosingDate(DMY2Date(31, 12, 2025));
        Observer.Observe('closing-format', Format(Row.Closing));
        Observer.Observe('closing-format-xml', Format(Row.Closing, 0, 9));
        Observer.Observe('normal-format', Format(NormalDate(Row.Closing)));
        Observer.Observe('is-closing', Format(Row.Closing <> NormalDate(Row.Closing)));
        Row.Insert();
        Back.Get(1);
        Observer.Observe('back-equal', Format(Back.Closing = Row.Closing));
        Observer.Observe('back-format', Format(Back.Closing));
        Observer.Observe('back-vs-normal', Format(Back.Closing = DMY2Date(31, 12, 2025)));
        Observer.Observe('validate-normal-ok', Format(TryClosing(Row, DMY2Date(1, 1, 2025))));
        Observer.Observe('validate-normal-format', Format(Row.Closing));
        Observer.Observe('validate-closing-ok', Format(TryClosing(Row, ClosingDate(DMY2Date(1, 1, 2025)))));
        Observer.Observe('validate-closing-format', Format(Row.Closing));
        Observer.Expect('closing-format', 'C12/31/25');
        Observer.Expect('closing-format-xml', '2025-12-31');
        Observer.Expect('normal-format', '12/31/25');
        Observer.Expect('is-closing', 'Yes');
        Observer.Expect('back-equal', 'Yes');
        Observer.Expect('back-format', 'C12/31/25');
        Observer.Expect('back-vs-normal', 'No');
        Observer.Expect('validate-normal-ok', 'Yes');
        Observer.Expect('validate-normal-format', '01/01/25');
        Observer.Expect('validate-closing-ok', 'Yes');
        Observer.Expect('validate-closing-format', 'C01/01/25');
        Observer.Verify();
    end;

    [Test]
    procedure P119_BlankZeroNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Observer.Observe('zero-blankz', Format(Row.BlankZ));
        Observer.Observe('zero-blankneg', Format(Row.BlankNegN));
        Observer.Observe('zero-blankzp', Format(Row.BlankZP));
        Row.BlankZ := 5;
        Row.BlankNegN := 5;
        Row.BlankZP := 5;
        Observer.Observe('pos-blankz', Format(Row.BlankZ));
        Observer.Observe('pos-blankneg', Format(Row.BlankNegN));
        Observer.Observe('pos-blankzp', Format(Row.BlankZP));
        Row.BlankZ := -5;
        Row.BlankNegN := -5;
        Row.BlankZP := -5;
        Observer.Observe('neg-blankz', Format(Row.BlankZ));
        Observer.Observe('neg-blankneg', Format(Row.BlankNegN));
        Observer.Observe('neg-blankzp', Format(Row.BlankZP));
        Row.BlankZ := 0;
        RecRef.GetTable(Row);
        Observer.Observe('fieldref-zero-blankz', Format(RecRef.Field(12).Value));
        Observer.Observe('xml-zero-blankz', Format(Row.BlankZ, 0, 9));
        Observer.Observe('plain-zero', Format(0));
        Observer.Expect('zero-blankz', '0');
        Observer.Expect('zero-blankneg', '0');
        Observer.Expect('zero-blankzp', '0');
        Observer.Expect('pos-blankz', '5');
        Observer.Expect('pos-blankneg', '5');
        Observer.Expect('pos-blankzp', '5');
        Observer.Expect('neg-blankz', '-5');
        Observer.Expect('neg-blankneg', '-5');
        Observer.Expect('neg-blankzp', '-5');
        Observer.Expect('fieldref-zero-blankz', '0');
        Observer.Expect('xml-zero-blankz', '0');
        Observer.Expect('plain-zero', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P119_DecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
        Back: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Dec := 1.5;
        Observer.Observe('one-point-five', Format(Row.Dec));
        Row.Dec := 1.23456;
        Observer.Observe('long', Format(Row.Dec));
        Observer.Observe('long-xml', Format(Row.Dec, 0, 9));
        Observer.Observe('long-times', Format(Row.Dec * 1000000));
        Row.Dec := 0;
        Observer.Observe('zero', Format(Row.Dec));
        Row.Dec := -2.5;
        Observer.Observe('negative', Format(Row.Dec));
        Observer.Observe('validate-ok', Format(TryDec(Row, 7.123456789)));
        Observer.Observe('validate-value', Format(Row.Dec));
        Row.Insert();
        Back.Get(1);
        Observer.Observe('back', Format(Back.Dec));
        Observer.Observe('back-times', Format(Back.Dec * 1000000000));
        Observer.Expect('one-point-five', '1.500');
        Observer.Expect('long', '1.235');
        Observer.Expect('long-xml', '1.235');
        Observer.Expect('long-times', '1,234,560');
        Observer.Expect('zero', '0.000');
        Observer.Expect('negative', '-2.500');
        Observer.Expect('validate-ok', 'Yes');
        Observer.Expect('validate-value', '7.123');
        Observer.Expect('back', '7.123');
        Observer.Expect('back-times', '7,123,456,789');
        Observer.Verify();
    end;

    [Test]
    procedure P119_OptionCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Opt := Row.Opt::Second;
        Observer.Observe('format', Format(Row.Opt));
        Observer.Observe('format-1', Format(Row.Opt, 0, 1));
        Observer.Observe('format-2', Format(Row.Opt, 0, 2));
        Observer.Observe('format-9', Format(Row.Opt, 0, 9));
        Observer.Observe('eval-member-ok', Format(Evaluate(Row.Opt, 'Third')));
        Observer.Observe('eval-caption-ok', Format(Evaluate(Row.Opt, 'Alpha')));
        Observer.Observe('eval-number-ok', Format(Evaluate(Row.Opt, '1')));
        Observer.Observe('eval-unknown-ok', Format(Evaluate(Row.Opt, 'Delta')));
        Row.Opt := Row.Opt::First;
        Observer.Observe('first', Format(Row.Opt));
        Observer.Expect('format', 'Beta');
        Observer.Expect('format-1', 'Beta');
        Observer.Expect('format-2', '1');
        Observer.Expect('format-9', '1');
        Observer.Expect('eval-member-ok', 'Yes');
        Observer.Expect('eval-caption-ok', 'Yes');
        Observer.Expect('eval-number-ok', 'Yes');
        Observer.Expect('eval-unknown-ok', 'No');
        Observer.Expect('first', 'Alpha');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNotBlank(var Row: Record "LT P119 Row"; V: Code[20])
    begin
        Row.Validate(NotBlankCode, V);
    end;

    [TryFunction]
    local procedure TryNumeric(var Row: Record "LT P119 Row"; V: Code[20])
    begin
        Row.Validate(NumCode, V);
    end;

    [TryFunction]
    local procedure TryAssignNum(var Row: Record "LT P119 Row"; V: Code[20])
    begin
        Row.NumCode := V;
    end;

    [TryFunction]
    local procedure TryRanged(var Row: Record "LT P119 Row"; V: Decimal)
    begin
        Row.Validate(Ranged, V);
    end;

    [TryFunction]
    local procedure TryPhone(var Row: Record "LT P119 Row"; V: Text[30])
    begin
        Row.Validate(Phone, V);
    end;

    [TryFunction]
    local procedure TryMail(var Row: Record "LT P119 Row"; V: Text[80])
    begin
        Row.Validate(Mail, V);
    end;

    [TryFunction]
    local procedure TryLink(var Row: Record "LT P119 Row"; V: Text[100])
    begin
        Row.Validate(Link, V);
    end;

    [TryFunction]
    local procedure TryRatio(var Row: Record "LT P119 Row"; V: Decimal)
    begin
        Row.Validate(RatioVal, V);
    end;

    [TryFunction]
    local procedure TryClosing(var Row: Record "LT P119 Row"; V: Date)
    begin
        Row.Validate(Closing, V);
    end;

    [TryFunction]
    local procedure TryDec(var Row: Record "LT P119 Row"; V: Decimal)
    begin
        Row.Validate(Dec, V);
    end;
}
