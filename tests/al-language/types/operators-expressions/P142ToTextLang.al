// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74545 "LT P142 ToText Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetLanguage(Lang: Integer)
    begin
        GlobalLanguage(Lang);
    end;

    local procedure DateLine(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        D: Date;
        Z: Date;
    begin
        D := 20240315D;
        Observer.Observe(Prefix + 'date_totext', D.ToText());
        Observer.Observe(Prefix + 'date_format', Format(D));
        Observer.Observe(Prefix + 'date_totext_inv', D.ToText(true));
        Observer.Observe(Prefix + 'date_format9', Format(D, 0, 9));
        Observer.Observe(Prefix + 'date_format4', Format(D, 0, 4));
        Z := 0D;
        Observer.Observe(Prefix + 'zero_totext', '[' + Z.ToText() + ']');
        Observer.Observe(Prefix + 'zero_format', '[' + Format(Z) + ']');
    end;

    local procedure BoolLine(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        B: Boolean;
    begin
        B := true;
        Observer.Observe(Prefix + 'true_totext', B.ToText());
        Observer.Observe(Prefix + 'true_format', Format(B));
        Observer.Observe(Prefix + 'true_totext_inv', B.ToText(true));
        B := false;
        Observer.Observe(Prefix + 'false_totext', B.ToText());
        Observer.Observe(Prefix + 'false_format', Format(B));
        Observer.Observe(Prefix + 'false_totext_inv', B.ToText(true));
    end;

    local procedure TimeLine(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        T: Time;
        Dt: DateTime;
        Du: Duration;
    begin
        T := 134501T;
        Observer.Observe(Prefix + 'time_totext', T.ToText());
        Observer.Observe(Prefix + 'time_format', Format(T));
        Observer.Observe(Prefix + 'time_totext_inv', T.ToText(true));
        Dt := CreateDateTime(20240315D, 134501T);
        Observer.Observe(Prefix + 'dt_totext', Dt.ToText());
        Observer.Observe(Prefix + 'dt_format', Format(Dt));
        Observer.Observe(Prefix + 'dt_totext_inv', Dt.ToText(true));
        Du := 3723000;
        Observer.Observe(Prefix + 'dur_totext', Du.ToText());
        Observer.Observe(Prefix + 'dur_format', Format(Du));
    end;

    local procedure DecimalLine(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        D: Decimal;
    begin
        D := 1234567.891;
        Observer.Observe(Prefix + 'dec_totext', D.ToText());
        Observer.Observe(Prefix + 'dec_format', Format(D));
        Observer.Observe(Prefix + 'dec_totext_inv', D.ToText(true));
        D := -0.5;
        Observer.Observe(Prefix + 'neg_totext', D.ToText());
        Observer.Observe(Prefix + 'neg_format', Format(D));
        D := 1000;
        Observer.Observe(Prefix + 'k_totext', D.ToText());
        Observer.Observe(Prefix + 'k_format', Format(D));
    end;

    [Test]
    procedure P142_Date_Language()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        DateLine(Observer, 'def_');
        Observer.Observe('set1031', Format(TrySetLanguage(1031)));
        DateLine(Observer, 'deu_');
        Observer.Observe('set1036', Format(TrySetLanguage(1036)));
        DateLine(Observer, 'fra_');
        GlobalLanguage(Orig);
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('def_date_totext', '03/15/24');
        Observer.Expect('def_date_format', '03/15/24');
        Observer.Expect('def_date_totext_inv', '2024-03-15');
        Observer.Expect('def_date_format9', '2024-03-15');
        Observer.Expect('def_date_format4', 'March 15, 2024');
        Observer.Expect('def_zero_totext', '[]');
        Observer.Expect('def_zero_format', '[]');
        Observer.Expect('set1031', 'Ja');
        Observer.Expect('deu_date_totext', '03/15/24');
        Observer.Expect('deu_date_format', '03/15/24');
        Observer.Expect('deu_date_totext_inv', '2024-03-15');
        Observer.Expect('deu_date_format9', '2024-03-15');
        Observer.Expect('deu_date_format4', 'März 15, 2024');
        Observer.Expect('deu_zero_totext', '[]');
        Observer.Expect('deu_zero_format', '[]');
        Observer.Expect('set1036', 'Oui');
        Observer.Expect('fra_date_totext', '03/15/24');
        Observer.Expect('fra_date_format', '03/15/24');
        Observer.Expect('fra_date_totext_inv', '2024-03-15');
        Observer.Expect('fra_date_format9', '2024-03-15');
        Observer.Expect('fra_date_format4', 'mars 15, 2024');
        Observer.Expect('fra_zero_totext', '[]');
        Observer.Expect('fra_zero_format', '[]');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Boolean_Language()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        BoolLine(Observer, 'def_');
        Observer.Observe('set1031', Format(TrySetLanguage(1031)));
        BoolLine(Observer, 'deu_');
        Observer.Observe('set1036', Format(TrySetLanguage(1036)));
        BoolLine(Observer, 'fra_');
        GlobalLanguage(Orig);
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('def_true_totext', 'Yes');
        Observer.Expect('def_true_format', 'Yes');
        Observer.Expect('def_true_totext_inv', 'true');
        Observer.Expect('def_false_totext', 'No');
        Observer.Expect('def_false_format', 'No');
        Observer.Expect('def_false_totext_inv', 'false');
        Observer.Expect('set1031', 'Ja');
        Observer.Expect('deu_true_totext', 'Ja');
        Observer.Expect('deu_true_format', 'Ja');
        Observer.Expect('deu_true_totext_inv', 'true');
        Observer.Expect('deu_false_totext', 'Nein');
        Observer.Expect('deu_false_format', 'Nein');
        Observer.Expect('deu_false_totext_inv', 'false');
        Observer.Expect('set1036', 'Oui');
        Observer.Expect('fra_true_totext', 'Oui');
        Observer.Expect('fra_true_format', 'Oui');
        Observer.Expect('fra_true_totext_inv', 'true');
        Observer.Expect('fra_false_totext', 'Non');
        Observer.Expect('fra_false_format', 'Non');
        Observer.Expect('fra_false_totext_inv', 'false');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P142_TimeDateTimeDuration_Language()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        TimeLine(Observer, 'def_');
        Observer.Observe('set1031', Format(TrySetLanguage(1031)));
        TimeLine(Observer, 'deu_');
        GlobalLanguage(Orig);
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('def_time_totext', ' 1:45:01 PM');
        Observer.Expect('def_time_format', ' 1:45:01 PM');
        Observer.Expect('def_time_totext_inv', '13:45:01');
        Observer.Expect('def_dt_totext', '03/15/24 01:45 PM');
        Observer.Expect('def_dt_format', '03/15/24 01:45 PM');
        Observer.Expect('def_dt_totext_inv', '2024-03-15T13:45:01Z');
        Observer.Expect('def_dur_totext', '1 hour 2 minutes 3 seconds');
        Observer.Expect('def_dur_format', '1 hour 2 minutes 3 seconds');
        Observer.Expect('set1031', 'Ja');
        Observer.Expect('deu_time_totext', ' 1:45:01 PM');
        Observer.Expect('deu_time_format', ' 1:45:01 PM');
        Observer.Expect('deu_time_totext_inv', '13:45:01');
        Observer.Expect('deu_dt_totext', '03/15/24 01:45 PM');
        Observer.Expect('deu_dt_format', '03/15/24 01:45 PM');
        Observer.Expect('deu_dt_totext_inv', '2024-03-15T13:45:01Z');
        Observer.Expect('deu_dur_totext', '1 Stunde 2 Minuten 3 Sekunden');
        Observer.Expect('deu_dur_format', '1 Stunde 2 Minuten 3 Sekunden');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P142_TimeDateTimeDuration_Language_French()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        Observer.Observe('set1036', Format(TrySetLanguage(1036)));
        TimeLine(Observer, 'fra_');
        GlobalLanguage(Orig);
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('set1036', 'Oui');
        Observer.Expect('fra_time_totext', ' 1:45:01 PM');
        Observer.Expect('fra_time_format', ' 1:45:01 PM');
        Observer.Expect('fra_time_totext_inv', '13:45:01');
        Observer.Expect('fra_dt_totext', '03/15/24 01:45 PM');
        Observer.Expect('fra_dt_format', '03/15/24 01:45 PM');
        Observer.Expect('fra_dt_totext_inv', '2024-03-15T13:45:01Z');
        Observer.Expect('fra_dur_totext', '1 heure 2 minutes 3 secondes');
        Observer.Expect('fra_dur_format', '1 heure 2 minutes 3 secondes');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Decimal_Language()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        DecimalLine(Observer, 'def_');
        Observer.Observe('set1031', Format(TrySetLanguage(1031)));
        DecimalLine(Observer, 'deu_');
        Observer.Observe('set1036', Format(TrySetLanguage(1036)));
        DecimalLine(Observer, 'fra_');
        GlobalLanguage(Orig);
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('def_dec_totext', '1,234,567.891');
        Observer.Expect('def_dec_format', '1,234,567.891');
        Observer.Expect('def_dec_totext_inv', '1234567.891');
        Observer.Expect('def_neg_totext', '-0.5');
        Observer.Expect('def_neg_format', '-0.5');
        Observer.Expect('def_k_totext', '1,000');
        Observer.Expect('def_k_format', '1,000');
        Observer.Expect('set1031', 'Ja');
        Observer.Expect('deu_dec_totext', '1,234,567.891');
        Observer.Expect('deu_dec_format', '1,234,567.891');
        Observer.Expect('deu_dec_totext_inv', '1234567.891');
        Observer.Expect('deu_neg_totext', '-0.5');
        Observer.Expect('deu_neg_format', '-0.5');
        Observer.Expect('deu_k_totext', '1,000');
        Observer.Expect('deu_k_format', '1,000');
        Observer.Expect('set1036', 'Oui');
        Observer.Expect('fra_dec_totext', '1,234,567.891');
        Observer.Expect('fra_dec_format', '1,234,567.891');
        Observer.Expect('fra_dec_totext_inv', '1234567.891');
        Observer.Expect('fra_neg_totext', '-0.5');
        Observer.Expect('fra_neg_format', '-0.5');
        Observer.Expect('fra_k_totext', '1,000');
        Observer.Expect('fra_k_format', '1,000');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Language_RestoredOnErrorPath()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        D: Date;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        D := 20240315D;
        asserterror Error('boom %1', D.ToText());
        Observer.ObserveError('error_text_deu');
        GlobalLanguage(Orig);
        asserterror Error('boom %1', D.ToText());
        Observer.ObserveError('error_text_restored');
        Observer.Observe('restored', Format(GlobalLanguage() = Orig));
        Observer.Expect('error_text_deu|text', 'boom 03/15/24');
        Observer.Expect('error_text_deu|code', 'Dialog');
        Observer.Expect('error_text_restored|text', 'boom 03/15/24');
        Observer.Expect('error_text_restored|code', 'Dialog');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;
}
