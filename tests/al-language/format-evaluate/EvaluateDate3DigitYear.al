// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 67554
// Probe: Evaluate of a Date text whose year has three digits ('01/02/026', '1.2.026') and of the neighbouring one, two and four digit years, in an English (1033) and a German (1031) session; the session language is set explicitly and put back (issue 581 item 6). No input depends on the run date.
// BC versions: 27+

codeunit 67554 "LT Evaluate Date 3 Digit Year"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Try(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        D: Date;
        Ok: Boolean;
    begin
        D := 0D;
        Ok := Evaluate(D, Input);
        Observer.Observe(Name, '[' + Input + '] ' + Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    local procedure TryAll(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        Try(Observer, Prefix + 'slash_3digit', '01/02/026');
        Try(Observer, Prefix + 'dot_3digit', '1.2.026');
        Try(Observer, Prefix + 'slash_3digit_other', '01/02/999');
        Try(Observer, Prefix + 'dot_3digit_other', '1.2.999');
        Try(Observer, Prefix + 'dot_3digit_padded', '01.02.026');
        Try(Observer, Prefix + 'slash_1digit', '01/02/6');
        Try(Observer, Prefix + 'slash_2digit', '01/02/26');
        Try(Observer, Prefix + 'dot_2digit', '1.2.26');
        Try(Observer, Prefix + 'slash_4digit_leading_zero', '01/02/0026');
        Try(Observer, Prefix + 'dot_4digit_leading_zero', '1.2.0026');
        Try(Observer, Prefix + 'slash_4digit', '01/02/2026');
        Try(Observer, Prefix + 'dot_4digit', '1.2.2026');
        Try(Observer, Prefix + 'slash_5digit', '01/02/12026');
        Try(Observer, Prefix + 'dash_3digit', '01-02-026');
    end;

    [Test]
    procedure Evaluate_Date_ThreeDigitYear_English()
    var
        Observer: Codeunit "Probe Observer";
        Previous: Integer;
    begin
        Previous := GlobalLanguage();
        GlobalLanguage(1033);
        TryAll(Observer, 'en_');
        Observer.Observe('en_language', Format(GlobalLanguage()));
        GlobalLanguage(Previous);
        Observer.Expect('en_slash_3digit', '[01/02/026] Yes 0026-01-02');
        Observer.Expect('en_dot_3digit', '[1.2.026] Yes 0026-01-02');
        Observer.Expect('en_slash_3digit_other', '[01/02/999] Yes 0999-01-02');
        Observer.Expect('en_dot_3digit_other', '[1.2.999] Yes 0999-01-02');
        Observer.Expect('en_dot_3digit_padded', '[01.02.026] Yes 0026-01-02');
        Observer.Expect('en_slash_1digit', '[01/02/6] Yes 2006-01-02');
        Observer.Expect('en_slash_2digit', '[01/02/26] Yes 2026-01-02');
        Observer.Expect('en_dot_2digit', '[1.2.26] Yes 2026-01-02');
        Observer.Expect('en_slash_4digit_leading_zero', '[01/02/0026] Yes 0026-01-02');
        Observer.Expect('en_dot_4digit_leading_zero', '[1.2.0026] Yes 0026-01-02');
        Observer.Expect('en_slash_4digit', '[01/02/2026] Yes 2026-01-02');
        Observer.Expect('en_dot_4digit', '[1.2.2026] Yes 2026-01-02');
        Observer.Expect('en_slash_5digit', '[01/02/12026] No ');
        Observer.Expect('en_dash_3digit', '[01-02-026] Yes 0026-01-02');
        Observer.Expect('en_language', '1033');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Date_ThreeDigitYear_German()
    var
        Observer: Codeunit "Probe Observer";
        Previous: Integer;
    begin
        Previous := GlobalLanguage();
        GlobalLanguage(1031);
        TryAll(Observer, 'de_');
        Observer.Observe('de_language', Format(GlobalLanguage()));
        GlobalLanguage(Previous);
        Observer.Expect('de_slash_3digit', '[01/02/026] Ja 0026-01-02');
        Observer.Expect('de_dot_3digit', '[1.2.026] Ja 0026-01-02');
        Observer.Expect('de_slash_3digit_other', '[01/02/999] Ja 0999-01-02');
        Observer.Expect('de_dot_3digit_other', '[1.2.999] Ja 0999-01-02');
        Observer.Expect('de_dot_3digit_padded', '[01.02.026] Ja 0026-01-02');
        Observer.Expect('de_slash_1digit', '[01/02/6] Ja 2006-01-02');
        Observer.Expect('de_slash_2digit', '[01/02/26] Ja 2026-01-02');
        Observer.Expect('de_dot_2digit', '[1.2.26] Ja 2026-01-02');
        Observer.Expect('de_slash_4digit_leading_zero', '[01/02/0026] Ja 0026-01-02');
        Observer.Expect('de_dot_4digit_leading_zero', '[1.2.0026] Ja 0026-01-02');
        Observer.Expect('de_slash_4digit', '[01/02/2026] Ja 2026-01-02');
        Observer.Expect('de_dot_4digit', '[1.2.2026] Ja 2026-01-02');
        Observer.Expect('de_slash_5digit', '[01/02/12026] Nein ');
        Observer.Expect('de_dash_3digit', '[01-02-026] Ja 0026-01-02');
        Observer.Expect('de_language', '1031');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Date_ThreeDigitYear_BritishEnglish()
    var
        Observer: Codeunit "Probe Observer";
        Previous: Integer;
    begin
        Previous := GlobalLanguage();
        GlobalLanguage(2057);
        TryAll(Observer, 'gb_');
        Observer.Observe('gb_language', Format(GlobalLanguage()));
        GlobalLanguage(Previous);
        Observer.Expect('gb_slash_3digit', '[01/02/026] Yes 0026-01-02');
        Observer.Expect('gb_dot_3digit', '[1.2.026] Yes 0026-01-02');
        Observer.Expect('gb_slash_3digit_other', '[01/02/999] Yes 0999-01-02');
        Observer.Expect('gb_dot_3digit_other', '[1.2.999] Yes 0999-01-02');
        Observer.Expect('gb_dot_3digit_padded', '[01.02.026] Yes 0026-01-02');
        Observer.Expect('gb_slash_1digit', '[01/02/6] Yes 2006-01-02');
        Observer.Expect('gb_slash_2digit', '[01/02/26] Yes 2026-01-02');
        Observer.Expect('gb_dot_2digit', '[1.2.26] Yes 2026-01-02');
        Observer.Expect('gb_slash_4digit_leading_zero', '[01/02/0026] Yes 0026-01-02');
        Observer.Expect('gb_dot_4digit_leading_zero', '[1.2.0026] Yes 0026-01-02');
        Observer.Expect('gb_slash_4digit', '[01/02/2026] Yes 2026-01-02');
        Observer.Expect('gb_dot_4digit', '[1.2.2026] Yes 2026-01-02');
        Observer.Expect('gb_slash_5digit', '[01/02/12026] No ');
        Observer.Expect('gb_dash_3digit', '[01-02-026] Yes 0026-01-02');
        Observer.Expect('gb_language', '2057');
        Observer.Verify();
    end;
}
