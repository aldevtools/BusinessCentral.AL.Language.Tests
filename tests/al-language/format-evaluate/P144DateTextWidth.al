// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: <Month Text,N> and <Weekday Text,N> for N = 0, 1, 3, 5, 10, 20 (padding or truncation, shown inside brackets); <Month Text>, <Weekday Text> in de-DE (GlobalLanguage 1031, restored)
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70233 "LT P144 Date Text Width"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(D: Date; Spec: Text; var Result: Text)
    begin
        Result := Format(D, 0, Spec);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date; Spec: Text)
    var
        Result: Text;
    begin
        if TryFmt(D, Spec, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else
            Observer.ObserveError(Name);
    end;

    // sets the language, formats inside a TryFunction and restores the language on every path
    local procedure FormatDe(D: Date; Spec: Text): Text
    var
        OldLanguage: Integer;
        Result: Text;
        Ok: Boolean;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Ok := TryFmt(D, Spec, Result);
        GlobalLanguage(OldLanguage);
        if Ok then
            exit('[' + Result + ']');
        exit('ERR ' + GetLastErrorText() + ' / ' + GetLastErrorCode());
    end;

    [Test]
    procedure P144_MonthText_March()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(15, 3, 2027);
        Obs(Observer, 'plain', D, '<Month Text>');
        Obs(Observer, 'n0', D, '<Month Text,0>');
        Obs(Observer, 'n1', D, '<Month Text,1>');
        Obs(Observer, 'n3', D, '<Month Text,3>');
        Obs(Observer, 'n5', D, '<Month Text,5>');
        Obs(Observer, 'n10', D, '<Month Text,10>');
        Obs(Observer, 'n20', D, '<Month Text,20>');
        Obs(Observer, 'n20_then_x', D, '<Month Text,20>x');
        Obs(Observer, 'lower_n10', D, '<month text,10>');
        Obs(Observer, 'spaced_n10', D, '<Month Text, 10>');
        Observer.Expect('plain', '[March]');
        Observer.Expect('n0', '[March]');
        Observer.Expect('n1', '[M]');
        Observer.Expect('n3', '[Mar]');
        Observer.Expect('n5', '[March]');
        Observer.Expect('n10', '[March     ]');
        Observer.Expect('n20', '[March               ]');
        Observer.Expect('n20_then_x', '[March               x]');
        Observer.Expect('lower_n10', '[March     ]');
        Observer.Expect('spaced_n10', '[March     ]');
        Observer.Verify();
    end;

    [Test]
    procedure P144_MonthText_December()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(31, 12, 2026);
        Obs(Observer, 'plain', D, '<Month Text>');
        Obs(Observer, 'n1', D, '<Month Text,1>');
        Obs(Observer, 'n3', D, '<Month Text,3>');
        Obs(Observer, 'n5', D, '<Month Text,5>');
        Obs(Observer, 'n10', D, '<Month Text,10>');
        Obs(Observer, 'n20', D, '<Month Text,20>');
        Observer.Expect('plain', '[December]');
        Observer.Expect('n1', '[D]');
        Observer.Expect('n3', '[Dec]');
        Observer.Expect('n5', '[Decem]');
        Observer.Expect('n10', '[December  ]');
        Observer.Expect('n20', '[December            ]');
        Observer.Verify();
    end;

    [Test]
    procedure P144_WeekdayText_Monday()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(15, 3, 2027);
        Obs(Observer, 'plain', D, '<Weekday Text>');
        Obs(Observer, 'n0', D, '<Weekday Text,0>');
        Obs(Observer, 'n1', D, '<Weekday Text,1>');
        Obs(Observer, 'n3', D, '<Weekday Text,3>');
        Obs(Observer, 'n5', D, '<Weekday Text,5>');
        Obs(Observer, 'n10', D, '<Weekday Text,10>');
        Obs(Observer, 'n20', D, '<Weekday Text,20>');
        Obs(Observer, 'n20_then_x', D, '<Weekday Text,20>x');
        Obs(Observer, 'lower_n10', D, '<weekday text,10>');
        Obs(Observer, 'spaced_n10', D, '<Weekday Text, 10>');
        Observer.Expect('plain', '[Monday]');
        Observer.Expect('n0', '[Monday]');
        Observer.Expect('n1', '[M]');
        Observer.Expect('n3', '[Mon]');
        Observer.Expect('n5', '[Monda]');
        Observer.Expect('n10', '[Monday    ]');
        Observer.Expect('n20', '[Monday              ]');
        Observer.Expect('n20_then_x', '[Monday              x]');
        Observer.Expect('lower_n10', '[Monday    ]');
        Observer.Expect('spaced_n10', '[Monday    ]');
        Observer.Verify();
    end;

    [Test]
    procedure P144_WeekdayText_Thursday()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(31, 12, 2026);
        Obs(Observer, 'plain', D, '<Weekday Text>');
        Obs(Observer, 'n1', D, '<Weekday Text,1>');
        Obs(Observer, 'n3', D, '<Weekday Text,3>');
        Obs(Observer, 'n5', D, '<Weekday Text,5>');
        Obs(Observer, 'n10', D, '<Weekday Text,10>');
        Obs(Observer, 'n20', D, '<Weekday Text,20>');
        Observer.Expect('plain', '[Thursday]');
        Observer.Expect('n1', '[T]');
        Observer.Expect('n3', '[Thu]');
        Observer.Expect('n5', '[Thurs]');
        Observer.Expect('n10', '[Thursday  ]');
        Observer.Expect('n20', '[Thursday            ]');
        Observer.Verify();
    end;

    [Test]
    procedure P144_TextCodes_German()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
        March: Date;
        December: Date;
    begin
        OldLanguage := GlobalLanguage();
        March := DMY2Date(15, 3, 2027);
        December := DMY2Date(31, 12, 2026);
        Observer.Observe('de_month_march', FormatDe(March, '<Month Text>'));
        Observer.Observe('de_month_dec', FormatDe(December, '<Month Text>'));
        Observer.Observe('de_month_march_n3', FormatDe(March, '<Month Text,3>'));
        Observer.Observe('de_month_march_n10', FormatDe(March, '<Month Text,10>'));
        Observer.Observe('de_month_dec_n20', FormatDe(December, '<Month Text,20>'));
        Observer.Observe('de_weekday_march', FormatDe(March, '<Weekday Text>'));
        Observer.Observe('de_weekday_dec', FormatDe(December, '<Weekday Text>'));
        Observer.Observe('de_weekday_march_n3', FormatDe(March, '<Weekday Text,3>'));
        Observer.Observe('de_weekday_march_n20', FormatDe(March, '<Weekday Text,20>'));
        Observer.Observe('de_full_date', FormatDe(March, '<Weekday Text>, <Day>. <Month Text> <Year4>'));
        Observer.Observe('language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('de_month_march', '[März]');
        Observer.Expect('de_month_dec', '[Dezember]');
        Observer.Expect('de_month_march_n3', '[Mär]');
        Observer.Expect('de_month_march_n10', '[März      ]');
        Observer.Expect('de_month_dec_n20', '[Dezember            ]');
        Observer.Expect('de_weekday_march', '[Montag]');
        Observer.Expect('de_weekday_dec', '[Donnerstag]');
        Observer.Expect('de_weekday_march_n3', '[Mon]');
        Observer.Expect('de_weekday_march_n20', '[Montag              ]');
        Observer.Expect('de_full_date', '[Montag, 15. März 2027]');
        Observer.Expect('language_restored', 'Yes');
        Observer.Verify();
    end;
}
