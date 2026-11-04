// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/message/message-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70902 "LT P140 TextConst Message"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DeuFra: TextConst DEU = 'Hallo', FRA = 'Bonjour';
        OnlyDeu: TextConst DEU = 'Nur Deutsch';
        OnlyFra: TextConst FRA = 'Seulement';
        All3: TextConst DEU = 'Hallo', ENU = 'Hello World', FRA = 'Bonjour';
        DeuFraPct: TextConst DEU = 'Wert %1 und %2', FRA = 'Valeur %1 et %2';
        LastMessage: Text;
        MessageCount: Integer;

    [MessageHandler]
    procedure P140Handler(Msg: Text)
    begin
        LastMessage := Msg;
        MessageCount += 1;
    end;

    [Test]
    [HandlerFunctions('P140Handler')]
    procedure P140_Message_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message(DeuFra);
        Observer.Observe('msg_deufra', LastMessage);
        Message(OnlyDeu);
        Observer.Observe('msg_onlydeu', LastMessage);
        Message(OnlyFra);
        Observer.Observe('msg_onlyfra', LastMessage);
        Message(All3);
        Observer.Observe('msg_all3', LastMessage);
        Message(DeuFraPct, 'a', 'b');
        Observer.Observe('msg_pct', LastMessage);
        Observer.Observe('msg_count', Format(MessageCount));
        Observer.Expect('msg_deufra', 'Hallo');
        Observer.Expect('msg_onlydeu', 'Nur Deutsch');
        Observer.Expect('msg_onlyfra', 'Seulement');
        Observer.Expect('msg_all3', 'Hello World');
        Observer.Expect('msg_pct', 'Wert a und b');
        Observer.Expect('msg_count', '5');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('P140Handler')]
    procedure P140_Message_GlobalLanguages()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        Message(DeuFra);
        Observer.Observe('deu_msg_deufra', LastMessage);
        Message(OnlyFra);
        Observer.Observe('deu_msg_onlyfra', LastMessage);
        Message(DeuFraPct, 'a', 'b');
        Observer.Observe('deu_msg_pct', LastMessage);
        GlobalLanguage(1036);
        Message(DeuFra);
        Observer.Observe('fra_msg_deufra', LastMessage);
        Message(OnlyDeu);
        Observer.Observe('fra_msg_onlydeu', LastMessage);
        Message(DeuFraPct, 'a', 'b');
        Observer.Observe('fra_msg_pct', LastMessage);
        Message(All3);
        Observer.Observe('fra_msg_all3', LastMessage);
        GlobalLanguage(Orig);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('deu_msg_deufra', 'Hallo');
        Observer.Expect('deu_msg_onlyfra', 'Seulement');
        Observer.Expect('deu_msg_pct', 'Wert a und b');
        Observer.Expect('fra_msg_deufra', 'Bonjour');
        Observer.Expect('fra_msg_onlydeu', 'Nur Deutsch');
        Observer.Expect('fra_msg_pct', 'Valeur a et b');
        Observer.Expect('fra_msg_all3', 'Bonjour');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;
}
