// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-working-with-labels
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70900 "LT P140 TextConst NoEnu"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DeuFra: TextConst DEU = 'Hallo', FRA = 'Bonjour';
        OnlyDeu: TextConst DEU = 'Nur Deutsch';
        OnlyFra: TextConst FRA = 'Seulement';
        EnuEmpty: TextConst ENU = '';
        EnuEmptyDeu: TextConst ENU = '', DEU = 'Leer';
        All3: TextConst DEU = 'Hallo', ENU = 'Hello World', FRA = 'Bonjour';
        DeuFraPct: TextConst DEU = 'Wert %1 und %2', FRA = 'Valeur %1 et %2';
        OnlyDeuPct: TextConst DEU = 'Nur %1';

    [Test]
    procedure P140_ReadAsText_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := DeuFra;
        Observer.Observe('deufra_text', T);
        Observer.Observe('deufra_len', Format(StrLen(T)));
        T := OnlyDeu;
        Observer.Observe('onlydeu_text', T);
        T := OnlyFra;
        Observer.Observe('onlyfra_text', T);
        T := EnuEmpty;
        Observer.Observe('enuempty_text', '[' + T + ']');
        T := EnuEmptyDeu;
        Observer.Observe('enuempty_deu_text', '[' + T + ']');
        T := All3;
        Observer.Observe('all3_text', T);
        T := DeuFraPct;
        Observer.Observe('deufrapct_text', T);
        T := OnlyDeuPct;
        Observer.Observe('onlydeupct_text', T);
        Observer.Observe('deufra_format', Format(DeuFra));
        Observer.Observe('onlydeu_format', Format(OnlyDeu));
        Observer.Observe('onlyfra_format', Format(OnlyFra));
        Observer.Observe('enuempty_format', '[' + Format(EnuEmpty) + ']');
        Observer.Observe('all3_format', Format(All3));
        Observer.Observe('deufra_strlen', Format(StrLen(DeuFra)));
        Observer.Observe('onlydeu_strlen', Format(StrLen(OnlyDeu)));
        Observer.Observe('onlyfra_strlen', Format(StrLen(OnlyFra)));
        Observer.Observe('enuempty_strlen', Format(StrLen(EnuEmpty)));
        Observer.Observe('deufra_concat', DeuFra + '!');
        Observer.Observe('onlydeu_upper', UpperCase(OnlyDeu));
        Observer.Expect('deufra_text', 'Hallo');
        Observer.Expect('deufra_len', '5');
        Observer.Expect('onlydeu_text', 'Nur Deutsch');
        Observer.Expect('onlyfra_text', 'Seulement');
        Observer.Expect('enuempty_text', '[]');
        Observer.Expect('enuempty_deu_text', '[]');
        Observer.Expect('all3_text', 'Hello World');
        Observer.Expect('deufrapct_text', 'Wert %1 und %2');
        Observer.Expect('onlydeupct_text', 'Nur %1');
        Observer.Expect('deufra_format', 'Hallo');
        Observer.Expect('onlydeu_format', 'Nur Deutsch');
        Observer.Expect('onlyfra_format', 'Seulement');
        Observer.Expect('enuempty_format', '[]');
        Observer.Expect('all3_format', 'Hello World');
        Observer.Expect('deufra_strlen', '5');
        Observer.Expect('onlydeu_strlen', '11');
        Observer.Expect('onlyfra_strlen', '9');
        Observer.Expect('enuempty_strlen', '0');
        Observer.Expect('deufra_concat', 'Hallo!');
        Observer.Expect('onlydeu_upper', 'NUR DEUTSCH');
        Observer.Verify();
    end;

    [Test]
    procedure P140_StrSubstNo_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('deufrapct', StrSubstNo(DeuFraPct, 'a', 'b'));
        Observer.Observe('onlydeupct', StrSubstNo(OnlyDeuPct, 'x'));
        Observer.Observe('onlydeupct_two_args', StrSubstNo(OnlyDeuPct, 'x', 'y'));
        Observer.Observe('deufra_noargs', StrSubstNo(DeuFra));
        Observer.Observe('deufra_extra_arg', StrSubstNo(DeuFra, 'z'));
        Observer.Observe('all3pct_none', StrSubstNo(DeuFraPct, 1, 2));
        Observer.Observe('onlydeu_noargs', StrSubstNo(OnlyDeu));
        Observer.Observe('onlyfra_noargs', StrSubstNo(OnlyFra));
        Observer.Observe('enuempty_noargs', '[' + StrSubstNo(EnuEmpty) + ']');
        Observer.Expect('deufrapct', 'Wert a und b');
        Observer.Expect('onlydeupct', 'Nur x');
        Observer.Expect('onlydeupct_two_args', 'Nur x');
        Observer.Expect('deufra_noargs', 'Hallo');
        Observer.Expect('deufra_extra_arg', 'Hallo');
        Observer.Expect('all3pct_none', 'Wert 1 und 2');
        Observer.Expect('onlydeu_noargs', 'Nur Deutsch');
        Observer.Expect('onlyfra_noargs', 'Seulement');
        Observer.Expect('enuempty_noargs', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P140_Error_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(DeuFra);
        Observer.ObserveError('err_deufra');
        asserterror Error(OnlyDeu);
        Observer.ObserveError('err_onlydeu');
        asserterror Error(OnlyFra);
        Observer.ObserveError('err_onlyfra');
        asserterror Error(DeuFraPct, 'a', 'b');
        Observer.ObserveError('err_deufrapct');
        asserterror Error(OnlyDeuPct, 'q');
        Observer.ObserveError('err_onlydeupct');
        asserterror Error(All3);
        Observer.ObserveError('err_all3');
        asserterror Error(EnuEmptyDeu);
        Observer.ObserveError('err_enuempty_deu');
        Observer.Expect('err_deufra|text', 'Hallo');
        Observer.Expect('err_deufra|code', 'Dialog');
        Observer.Expect('err_onlydeu|text', 'Nur Deutsch');
        Observer.Expect('err_onlydeu|code', 'Dialog');
        Observer.Expect('err_onlyfra|text', 'Seulement');
        Observer.Expect('err_onlyfra|code', 'Dialog');
        Observer.Expect('err_deufrapct|text', 'Wert a und b');
        Observer.Expect('err_deufrapct|code', 'Dialog');
        Observer.Expect('err_onlydeupct|text', 'Nur q');
        Observer.Expect('err_onlydeupct|code', 'Dialog');
        Observer.Expect('err_all3|text', 'Hello World');
        Observer.Expect('err_all3|code', 'Dialog');
        Observer.Expect('err_enuempty_deu|text', '');
        Observer.Expect('err_enuempty_deu|code', 'Dialog');
        Observer.Verify();
    end;
}
