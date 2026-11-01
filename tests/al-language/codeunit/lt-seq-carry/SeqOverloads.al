// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (al-runner issue 6638): which sequence the overloads without CompanyWide reach. Exists(Name) with one argument answers No for
//   a sequence made with Insert(Name, Seed, Increment, false) (SeqCarry.al, Y35OnRunStorage.al).
// BC versions: 27.5, 28.5, 29.0
codeunit 93610 "LT Y56 Seq Overloads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(Name: Text)
    begin
        if NumberSequence.Exists(Name, false) then
            NumberSequence.Delete(Name, false);
        if NumberSequence.Exists(Name, true) then
            NumberSequence.Delete(Name, true);
    end;

    local procedure Seen(Name: Text): Text
    begin
        exit(Format(NumberSequence.Exists(Name)) + '|' + Format(NumberSequence.Exists(Name, false)) + '|' + Format(NumberSequence.Exists(Name, true)));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure Overloads_InsertExists()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Clean('Y56-OV-S');
        Clean('Y56-OV-F');
        Clean('Y56-OV-T');
        Observer.Observe('none', Seen('Y56-OV-S'));
        NumberSequence.Insert('Y56-OV-S', 1, 1);
        Observer.Observe('short', Seen('Y56-OV-S'));
        NumberSequence.Insert('Y56-OV-F', 1, 1, false);
        Observer.Observe('false', Seen('Y56-OV-F'));
        NumberSequence.Insert('Y56-OV-T', 1, 1, true);
        Observer.Observe('true', Seen('Y56-OV-T'));
        Observer.Observe('next_short_false', Format(NumberSequence.Next('Y56-OV-S', false)));
        Observer.Observe('next_false_false', Format(NumberSequence.Next('Y56-OV-F', false)));
        Observer.Observe('next_true_true', Format(NumberSequence.Next('Y56-OV-T', true)));
        Observer.Observe('current_short_false', Format(NumberSequence.Current('Y56-OV-S', false)));
        Clean('Y56-OV-S');
        Clean('Y56-OV-F');
        Clean('Y56-OV-T');
        Observer.Observe('after_clean', Seen('Y56-OV-S') + ';' + Seen('Y56-OV-F') + ';' + Seen('Y56-OV-T'));
        Observer.Finish();
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}
