// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-sid-method
// Scope: in-scope (OnPrem app only: Database.SID)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61246
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: none
//
// Complements session/PXDatabaseSid.al (which pins the shape for UserId() and an unknown name): the no-argument form, blank and long names, case, and the relation to a second call. Only shapes and relations.
// BC versions: 29 (27 and 28 by CI)
codeunit 61246 "LT P109 Sid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ShapeOf(Sid: Text): Text
    var
        Parts: List of [Text];
    begin
        Parts := Sid.Split('-');
        exit('parts=' + Format(Parts.Count()) + ' prefix=' + CopyStr(Sid, 1, 9));
    end;

    [TryFunction]
    local procedure TrySid(Name: Text; var Sid: Text)
    begin
        Sid := Database.SID(Name);
    end;

    local procedure Outcome(Name: Text): Text
    var
        Sid: Text;
    begin
        if TrySid(Name, Sid) then
            exit(ShapeOf(Sid));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_Sid_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Text;
    begin
        Sid := Database.SID();
        Observer.Observe('noarg_shape', ShapeOf(Sid));
        Observer.Observe('noarg_equals_userid', Format(Sid = Database.SID(UserId())));
        Observer.Observe('noarg_equals_blank', Format(Sid = Database.SID('')));
        Observer.Expect('noarg_shape', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('noarg_equals_userid', 'No');
        Observer.Expect('noarg_equals_blank', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P109_Sid_Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blank', Outcome(''));
        Observer.Observe('space', Outcome(' '));
        Observer.Observe('domain_backslash', Outcome('LTP109DOM\LTP109USER'));
        Observer.Observe('at_sign', Outcome('ltp109@example.invalid'));
        Observer.Observe('long_name', Outcome(PadStr('', 300, 'x')));
        Observer.Observe('unicode', Outcome('LTP109-ÄÖÜ-日本'));
        Observer.Observe('upper_equals_lower', Format(Database.SID('LTP109X') = Database.SID('ltp109x')));
        Observer.Observe('two_names_differ', Format(Database.SID('LTP109A') = Database.SID('LTP109B')));
        Observer.Observe('same_name_equal', Format(Database.SID('LTP109A') = Database.SID('LTP109A')));
        Observer.Expect('blank', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('space', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('domain_backslash', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('at_sign', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('long_name', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('unicode', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('upper_equals_lower', 'Yes');
        Observer.Expect('two_names_differ', 'No');
        Observer.Expect('same_name_equal', 'Yes');
        Observer.Verify();
    end;
}
