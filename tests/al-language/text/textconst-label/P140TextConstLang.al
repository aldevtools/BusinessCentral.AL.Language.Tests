// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-globallanguage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70901 "LT P140 TextConst Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DeuFra: TextConst DEU = 'Hallo', FRA = 'Bonjour';
        OnlyDeu: TextConst DEU = 'Nur Deutsch';
        OnlyFra: TextConst FRA = 'Seulement';
        EnuEmptyDeu: TextConst ENU = '', DEU = 'Leer';
        All3: TextConst DEU = 'Hallo', ENU = 'Hello World', FRA = 'Bonjour';
        DeuFraPct: TextConst DEU = 'Wert %1 und %2', FRA = 'Valeur %1 et %2';

    [Test]
    procedure P140_ReadAsText_Deu()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        T: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        T := DeuFra;
        Observer.Observe('deu_deufra', T);
        Observer.Observe('deu_onlydeu', OnlyDeu);
        Observer.Observe('deu_onlyfra', OnlyFra);
        Observer.Observe('deu_enuempty_deu', '[' + EnuEmptyDeu + ']');
        Observer.Observe('deu_all3', All3);
        Observer.Observe('deu_pct', StrSubstNo(DeuFraPct, 'a', 'b'));
        Observer.Observe('deu_format_deufra', Format(DeuFra));
        Observer.Observe('deu_format_onlyfra', Format(OnlyFra));
        Observer.Observe('deu_language_is_1031', Format(GlobalLanguage()));
        GlobalLanguage(Orig);
        Observer.Observe('restored_deufra', DeuFra);
        Observer.Observe('restored_onlyfra', OnlyFra);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('deu_deufra', 'Hallo');
        Observer.Expect('deu_onlydeu', 'Nur Deutsch');
        Observer.Expect('deu_onlyfra', 'Seulement');
        Observer.Expect('deu_enuempty_deu', '[Leer]');
        Observer.Expect('deu_all3', 'Hallo');
        Observer.Expect('deu_pct', 'Wert a und b');
        Observer.Expect('deu_format_deufra', 'Hallo');
        Observer.Expect('deu_format_onlyfra', 'Seulement');
        Observer.Expect('deu_language_is_1031', '1031');
        Observer.Expect('restored_deufra', 'Hallo');
        Observer.Expect('restored_onlyfra', 'Seulement');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P140_ReadAsText_Fra()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        T: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1036);
        T := DeuFra;
        Observer.Observe('fra_deufra', T);
        Observer.Observe('fra_onlydeu', OnlyDeu);
        Observer.Observe('fra_onlyfra', OnlyFra);
        Observer.Observe('fra_enuempty_deu', '[' + EnuEmptyDeu + ']');
        Observer.Observe('fra_all3', All3);
        Observer.Observe('fra_pct', StrSubstNo(DeuFraPct, 'a', 'b'));
        Observer.Observe('fra_format_deufra', Format(DeuFra));
        Observer.Observe('fra_format_onlydeu', Format(OnlyDeu));
        GlobalLanguage(Orig);
        Observer.Observe('restored_deufra', DeuFra);
        Observer.Expect('fra_deufra', 'Bonjour');
        Observer.Expect('fra_onlydeu', 'Nur Deutsch');
        Observer.Expect('fra_onlyfra', 'Seulement');
        Observer.Expect('fra_enuempty_deu', '[]');
        Observer.Expect('fra_all3', 'Bonjour');
        Observer.Expect('fra_pct', 'Valeur a et b');
        Observer.Expect('fra_format_deufra', 'Bonjour');
        Observer.Expect('fra_format_onlydeu', 'Nur Deutsch');
        Observer.Expect('restored_deufra', 'Hallo');
        Observer.Verify();
    end;

    [Test]
    procedure P140_Error_Languages()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        asserterror Error(DeuFra);
        Observer.ObserveError('deu_err_deufra');
        asserterror Error(OnlyFra);
        Observer.ObserveError('deu_err_onlyfra');
        asserterror Error(All3);
        Observer.ObserveError('deu_err_all3');
        asserterror Error(DeuFraPct, 'a', 'b');
        Observer.ObserveError('deu_err_pct');
        GlobalLanguage(1036);
        asserterror Error(DeuFra);
        Observer.ObserveError('fra_err_deufra');
        asserterror Error(OnlyDeu);
        Observer.ObserveError('fra_err_onlydeu');
        asserterror Error(All3);
        Observer.ObserveError('fra_err_all3');
        asserterror Error(DeuFraPct, 'a', 'b');
        Observer.ObserveError('fra_err_pct');
        GlobalLanguage(Orig);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('deu_err_deufra|text', 'Hallo');
        Observer.Expect('deu_err_deufra|code', 'Dialog');
        Observer.Expect('deu_err_onlyfra|text', 'Seulement');
        Observer.Expect('deu_err_onlyfra|code', 'Dialog');
        Observer.Expect('deu_err_all3|text', 'Hallo');
        Observer.Expect('deu_err_all3|code', 'Dialog');
        Observer.Expect('deu_err_pct|text', 'Wert a und b');
        Observer.Expect('deu_err_pct|code', 'Dialog');
        Observer.Expect('fra_err_deufra|text', 'Bonjour');
        Observer.Expect('fra_err_deufra|code', 'Dialog');
        Observer.Expect('fra_err_onlydeu|text', 'Nur Deutsch');
        Observer.Expect('fra_err_onlydeu|code', 'Dialog');
        Observer.Expect('fra_err_all3|text', 'Bonjour');
        Observer.Expect('fra_err_all3|code', 'Dialog');
        Observer.Expect('fra_err_pct|text', 'Valeur a et b');
        Observer.Expect('fra_err_pct|code', 'Dialog');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P140_Error_RestoreAfterErrorPath()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        asserterror begin
            GlobalLanguage(1036);
            Error(DeuFra);
        end;
        Observer.ObserveError('err_inside_fra');
        Observer.Observe('language_after_error', Format(GlobalLanguage()));
        GlobalLanguage(Orig);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('err_inside_fra|text', 'Bonjour');
        Observer.Expect('err_inside_fra|code', 'Dialog');
        Observer.Expect('language_after_error', '1036');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;

    // Corpus #664 item 26: Text methods called on a TextConst compile (AL 30 beta) and read the text of the current language.
    // Methods on a Text literal and on a Label are pinned in text/lt-label-textbuilder/TxCLabel.al (Label_Constant_Methods).
    [Test]
    procedure BM_TextConst_Methods()
    var
        Observer: Codeunit "Probe Observer";
        C: TextConst ENU = 'test', DEU = 'Prüfung';
        Orig: Integer;
    begin
        Observer.Observe('contains_e', Format(C.Contains('e')));
        Observer.Observe('contains_x', Format(C.Contains('x')));
        Observer.Observe('upper', C.ToUpper());
        Observer.Observe('startswith', Format(C.StartsWith('te')));
        Observer.Observe('indexof', Format(C.IndexOf('s')));
        Observer.Observe('substring', C.Substring(2, 2));
        Observer.Observe('strlen', Format(StrLen(C)));
        Observer.Observe('only_deu_contains', Format(OnlyDeu.Contains('Deutsch')));
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('deu_upper', C.ToUpper());
        Observer.Observe('deu_contains_e', Format(C.Contains('e')));
        Observer.Observe('deu_contains_u_umlaut', Format(C.Contains('ü')));
        GlobalLanguage(Orig);
        Observer.Expect('contains_e', 'Yes');
        Observer.Expect('contains_x', 'No');
        Observer.Expect('upper', 'TEST');
        Observer.Expect('startswith', 'Yes');
        Observer.Expect('indexof', '3');
        Observer.Expect('substring', 'es');
        Observer.Expect('strlen', '4');
        Observer.Expect('only_deu_contains', 'Yes');
        Observer.Expect('deu_upper', 'PRÜFUNG');
        Observer.Expect('deu_contains_e', 'Nein');
        Observer.Expect('deu_contains_u_umlaut', 'Ja');
        Observer.Verify();
    end;
}

