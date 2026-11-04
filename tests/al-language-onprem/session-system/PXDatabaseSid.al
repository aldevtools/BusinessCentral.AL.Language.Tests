// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-sid-method
// Scope: in-scope (OnPrem only: Database.SID is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61290
// Probe: written against a real BC 27.5 service tier on Linux; only the SHAPE of the answer is pinned (the numbers are the machine's). Other BC versions were not measured.
//
// Database.SID(UserName) answers the Windows-style security identifier as Text: "S-1-5-21-<a>-<b>-<c>-<rid>" (eight parts separated by dashes, all but the first numeric).
// It answers the same text for the same name twice, is not the text of UserSecurityId() (a Guid) and also answers a SID of that shape for a user name that does not exist.
// BC versions: 27.5
codeunit 61290 "PX Database Sid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ShapeOf(Sid: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Number: Integer;
        Result: Text;
    begin
        Parts := Sid.Split('-');
        Result := 'parts=' + Format(Parts.Count());
        foreach Part in Parts do
            if Part <> 'S' then
                if not Evaluate(Number, Part) then
                    Result += ' notnumeric';
        exit(Result + ' prefix=' + CopyStr(Sid, 1, 9));
    end;

    [Test]
    procedure Database_SID_Shape()
    var
        Sid: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Sid := Database.SID(UserId());
        Observer.Observe('shape', ShapeOf(Sid));
        Observer.Observe('sid_twice_equal', Format(Sid = Database.SID(UserId())));
        Observer.Observe('sid_equals_usersecurityid_text', Format(Sid = Format(UserSecurityId())));
        Observer.Observe('unknown_user_shape', ShapeOf(Database.SID('NoSuchUser')));
        Observer.Expect('shape', 'parts=8 prefix=S-1-5-21-');
        Observer.Expect('sid_twice_equal', 'Yes');
        Observer.Expect('sid_equals_usersecurityid_text', 'No');
        Observer.Expect('unknown_user_shape', 'parts=8 prefix=S-1-5-21-');
        Observer.Verify();
    end;
}
