// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-setuserpassword-method
// Scope: in-scope (OnPrem app only: Database.SetUserPassword has scope OnPrem, must-not-compile case 0568)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98000
// Probe (observe only): al-runner issue 7447. ODatabaseOps.al pins the error of Database.SetUserPassword for an unknown user. This probe asks what it does
//   for a user that exists: a user row the test inserts (User Name, License Type Full User, State Enabled, no Windows Security ID), then
//     a strong password, a second strong password after the first, a blank password, a short one, one without digits or symbols,
//     one of 300 characters, the user name as the password, a disabled user, a user with a blank User Name,
//   and after each call the User Property row of the user: whether it exists, whether Password is filled, its length, whether it holds the
//   plain text, and whether a second call changes it. Unknown user and null GUID are the controls.
//   Only users the test inserts are touched; the test ends in an error, so the rows are rolled back. The session user's password is never set.
//   Each call runs in a TryFunction: `ok` or the error text and code.
// BC versions: 27, 28, 29

codeunit 98000 "LT SUP SetUserPassword"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetPassword(UserSecurityId: Guid; Password: Text)
    begin
        Database.SetUserPassword(UserSecurityId, Password);
    end;

    local procedure NewUser(Name: Code[50]; Enabled: Boolean): Guid
    var
        User: Record User;
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := Name;
        User."License Type" := User."License Type"::"Full User";
        if Enabled then
            User.State := User.State::Enabled
        else
            User.State := User.State::Disabled;
        User.Insert();
        exit(User."User Security ID");
    end;

    local procedure PropertyState(UserSecurityId: Guid; Plain: Text): Text
    var
        UserProperty: Record "User Property";
    begin
        if not UserProperty.Get(UserSecurityId) then
            exit('no User Property row');
        exit('row: password filled=' + Format(UserProperty.Password <> '') + ' length=' + Format(StrLen(UserProperty.Password)) +
            ' is the plain text=' + Format(UserProperty.Password = Plain));
    end;

    local procedure StoredPassword(UserSecurityId: Guid): Text
    var
        UserProperty: Record "User Property";
    begin
        if UserProperty.Get(UserSecurityId) then
            exit(UserProperty.Password);
        exit('');
    end;

    local procedure ObserveSet(var Observer: Codeunit "Probe Observer"; Name: Text; UserSecurityId: Guid; Password: Text)
    begin
        ClearLastError();
        if TrySetPassword(UserSecurityId, Password) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' property', PropertyState(UserSecurityId, Password));
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_StrongPassword()
    var
        Observer: Codeunit "Probe Observer";
        User: Record User;
        Sid: Guid;
        First: Text;
    begin
        Sid := NewUser('LT-SUP-STRONG', true);
        Observer.Observe('before property', PropertyState(Sid, ''));
        ObserveSet(Observer, 'strong password', Sid, 'LT-Sup3r!Passw0rd#1');
        First := StoredPassword(Sid);
        ObserveSet(Observer, 'second strong password', Sid, 'LT-0ther!Passw0rd#2');
        Observer.Observe('second call changed the stored value', Format(StoredPassword(Sid) <> First));
        First := StoredPassword(Sid);
        ObserveSet(Observer, 'same password again', Sid, 'LT-0ther!Passw0rd#2');
        Observer.Observe('same password stores the same value', Format(StoredPassword(Sid) = First));
        User.Get(Sid);
        Observer.Observe('user row after', User."User Name" + ' state=' + Format(User.State) + ' change password=' + Format(User."Change Password"));
        Observer.Observe('in write transaction', Format(Database.IsInWriteTransaction()));
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_BlankAndShortPasswords()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK1', true);
        ObserveSet(Observer, 'blank', Sid, '');
        ObserveSet(Observer, 'three letters', Sid, 'abc');
        ObserveSet(Observer, 'seven characters with all classes', Sid, 'Ab1!xyz');
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_PasswordsWithoutAClass()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK2', true);
        ObserveSet(Observer, 'eight lower case letters', Sid, 'abcdefgh');
        ObserveSet(Observer, 'letters and digits only', Sid, 'Abcdefgh1234');
        ObserveSet(Observer, 'no upper case', Sid, 'abcdefgh1234!');
        ObserveSet(Observer, 'no digit', Sid, 'Abcdefgh!!!!');
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_UserNameAndSpaces()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK3', true);
        ObserveSet(Observer, 'the user name', Sid, 'LT-SUP-WEAK3');
        ObserveSet(Observer, 'spaces only', Sid, '        ');
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_LongAndNonAsciiPassword()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-LONG', true);
        ObserveSet(Observer, '300 characters', Sid, 'Aa1!' + PadStr('', 296, 'x'));
        ObserveSet(Observer, 'non ASCII', Sid, 'Pässwörd-1234!€');
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_DisabledUser_UnknownUser_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
        Unknown: Guid;
        Empty: Guid;
    begin
        Sid := NewUser('LT-SUP-DISABLED', false);
        ObserveSet(Observer, 'disabled user', Sid, 'LT-Sup3r!Passw0rd#1');
        Evaluate(Unknown, '{7E57C0DE-0000-4000-8000-00000000A0A1}');
        ObserveSet(Observer, 'unknown user', Unknown, 'LT-Sup3r!Passw0rd#1');
        ObserveSet(Observer, 'null guid', Empty, 'LT-Sup3r!Passw0rd#1');
        Observer.Finish();
    end;

    [Test]
    procedure SetUserPassword_UserWithBlankName()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('', true);
        ObserveSet(Observer, 'user with a blank name', Sid, 'LT-Sup3r!Passw0rd#1');
        Observer.Finish();
    end;
}
