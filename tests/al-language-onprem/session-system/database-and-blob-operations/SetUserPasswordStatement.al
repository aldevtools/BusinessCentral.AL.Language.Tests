// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-setuserpassword-method
// Scope: in-scope (OnPrem app only: Database.SetUserPassword has scope OnPrem, must-not-compile case 0568)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98001
// Probe (values pinned): al-runner issue 7447. SetUserPasswordExistingUser.al showed that Database.SetUserPassword on an existing user writes (in a
//   TryFunction it raises the TryFunction write error for MODIFY). This probe calls it as a plain statement, outside any TryFunction:
//     for a user row the test inserts (User Name, License Type Full User, State Enabled, no Windows Security ID): the User Property row before the
//     call, then a strong password, a second strong password, the same password twice, a blank password, a short one, one without digits or
//     symbols, one of 300 characters, the user name as the password; a disabled user, a user with a blank User Name; and as controls an unknown
//     user and the null GUID.
//   After each call: whether the User Property row exists, whether Password is filled, its length, whether it holds the plain text (plain), and
//   whether a second call changes it.
//   Each case runs inside asserterror on a procedure that ends with the error LtSupRollbackErr, so every write (the inserted user, the password)
//   is rolled back and the session user's password is never set. The last error tells where the procedure stopped: the marker, or the error
//   SetUserPassword raised. The observations made before the error are kept by the observer.
// Measured on BC 27.5, 28.5 and 29.0 (corpus PR CI, first round): a user row inserted by AL already has a User Property row with a blank
//   Password. Every password, also blank, short, without digits or symbols, 300 characters long or the user name, is accepted for an enabled
//   and a disabled user: Password then holds 27 characters that are not the plain text; a different password changes it, the same password
//   again does not. A user with a blank User Name raises the TestField error of User Name. An unknown user and the null GUID raise the
//   NothingInsideFilter error of User Property, as in a TryFunction (ODatabaseOps.al).
// Second round: "Identity Management".IsUserPasswordSet (NavUserAccountHelper.IsPasswordSet), which the User Card reaches, for a new user,
//   after a strong and after a blank password, for an unknown user, the null GUID and the session user.
// BC versions: 27, 28, 29

codeunit 98001 "LT SUP SetUserPassword Stmt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LtSupRollbackErr: Label 'LT SUP rollback marker', Locked = true;

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
        exit('row filled=' + Format(UserProperty.Password <> '') + ' len=' + Format(StrLen(UserProperty.Password)) +
            ' plain=' + Format(UserProperty.Password = Plain));
    end;

    local procedure StoredPassword(UserSecurityId: Guid): Text
    var
        UserProperty: Record "User Property";
    begin
        if not UserProperty.Get(UserSecurityId) then
            exit('');
        exit(UserProperty.Password);
    end;

    local procedure SetAndObserve(var Log: Text; Name: Text; UserSecurityId: Guid; Password: Text)
    begin
        Database.SetUserPassword(UserSecurityId, Password);
        Log += Name + ': ok, ' + PropertyState(UserSecurityId, Password) + ' / ';
    end;

    local procedure StrongBody(var Log: Text)
    var
        Sid: Guid;
        First: Text;
    begin
        Sid := NewUser('LT-SUPS-STRONG', true);
        Log += 'before: ' + PropertyState(Sid, '') + ' / ';
        SetAndObserve(Log, 'strong', Sid, 'LT-Sup3r!Passw0rd#1');
        First := StoredPassword(Sid);
        SetAndObserve(Log, 'second strong', Sid, 'LT-Oth3r!Passw0rd#2');
        Log += 'second changes it: ' + Format(StoredPassword(Sid) <> First) + ' / ';
        First := StoredPassword(Sid);
        SetAndObserve(Log, 'same again', Sid, 'LT-Oth3r!Passw0rd#2');
        Log += 'same again changes it: ' + Format(StoredPassword(Sid) <> First) + ' / ';
        Error(LtSupRollbackErr);
    end;

    local procedure OneCallBody(var Log: Text; UserName: Code[50]; Enabled: Boolean; Password: Text)
    var
        Sid: Guid;
    begin
        Sid := NewUser(UserName, Enabled);
        SetAndObserve(Log, 'call', Sid, Password);
        Error(LtSupRollbackErr);
    end;

    local procedure UnknownBody(var Log: Text; Sid: Guid)
    begin
        SetAndObserve(Log, 'call', Sid, 'LT-Sup3r!Passw0rd#1');
        Error(LtSupRollbackErr);
    end;

    local procedure MaskUserSecurityId(ErrorText: Text): Text
    var
        Marker: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Marker := 'User Security ID=';
        StartPos := ErrorText.IndexOf(Marker);
        if StartPos = 0 then
            exit(ErrorText);
        StartPos += StrLen(Marker);
        EndPos := ErrorText.Substring(StartPos).IndexOf('}');
        if EndPos = 0 then
            exit(ErrorText);
        exit(ErrorText.Substring(1, StartPos - 1) + '<sid>' + ErrorText.Substring(StartPos + EndPos));
    end;

    // One observation per test, so that a mismatch shows everything the test saw.
    local procedure ObserveEnd(var Observer: Codeunit "Probe Observer"; Log: Text)
    begin
        Observer.Observe('result', Log + 'end: ' + GetLastErrorCode() + ' | ' + GetLastErrorText());
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_StrongPasswords()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror StrongBody(Log);
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'before: row filled=No len=0 plain=Yes / strong: ok, row filled=Yes len=27 plain=No / second strong: ok, row filled=Yes len=27 plain=No / second changes it: Yes / same again: ok, row filled=Yes len=27 plain=No / same again changes it: No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_Blank()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-BLANK', true, '');
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_Short()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-SHORT', true, 'Ab1!');
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_LowerCaseOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-LOWER', true, 'abcdefghij');
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_ThreeHundredCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-LONG', true, 'Aa1!' + PadStr('', 296, 'x'));
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_ExistingUser_UserNameAsPassword()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-NAME', true, 'LT-SUPS-NAME');
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_DisabledUser()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, 'LT-SUPS-DISABLED', false, 'LT-Sup3r!Passw0rd#1');
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'call: ok, row filled=Yes len=27 plain=No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_UserWithBlankName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror OneCallBody(Log, '', true, 'LT-Sup3r!Passw0rd#1');
        // The text names the inserted user's random User Security ID: masked.
        Observer.Observe('result', Log + 'end: ' + GetLastErrorCode() + ' | ' + MaskUserSecurityId(GetLastErrorText()));
        Observer.Expect('result', 'end: TestField | User Name must have a value in User: User Security ID=<sid>. It cannot be zero or empty.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_UnknownUser()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
        Unknown: Guid;
    begin
        Evaluate(Unknown, '{7E57C0DE-0000-4000-8000-00000000A0A1}');
        asserterror UnknownBody(Log, Unknown);
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'end: DB:NothingInsideFilter | There is no User Property within the filter.\\Filters: User Security ID: {7E57C0DE-0000-4000-8000-00000000A0A1}');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPasswordStmt_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
        NullGuid: Guid;
    begin
        asserterror UnknownBody(Log, NullGuid);
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'end: DB:NothingInsideFilter | There is no User Property within the filter.\\Filters: User Security ID: {00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    // Base Application's "Identity Management".IsUserPasswordSet asks NavUserAccountHelper.IsPasswordSet; the User Card reaches it.
    local procedure PasswordSetBody(var Log: Text)
    var
        IdentityManagement: Codeunit "Identity Management";
        Sid: Guid;
        Unknown: Guid;
        NullGuid: Guid;
    begin
        Sid := NewUser('LT-SUPS-ISSET', true);
        Log += 'new user: ' + Format(IdentityManagement.IsUserPasswordSet(Sid)) + ' / ';
        Database.SetUserPassword(Sid, 'LT-Sup3r!Passw0rd#1');
        Log += 'after a strong password: ' + Format(IdentityManagement.IsUserPasswordSet(Sid)) + ' / ';
        Database.SetUserPassword(Sid, '');
        Log += 'after a blank password: ' + Format(IdentityManagement.IsUserPasswordSet(Sid)) + ' / ';
        Evaluate(Unknown, '{7E57C0DE-0000-4000-8000-00000000A0A2}');
        Log += 'unknown user: ' + Format(IdentityManagement.IsUserPasswordSet(Unknown)) + ' / ';
        Log += 'null guid: ' + Format(IdentityManagement.IsUserPasswordSet(NullGuid)) + ' / ';
        Log += 'session user: ' + Format(IdentityManagement.IsUserPasswordSet(UserSecurityId())) + ' / ';
        Error(LtSupRollbackErr);
    end;

    [Test]
    procedure SetUserPasswordStmt_IsUserPasswordSet()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        asserterror PasswordSetBody(Log);
        ObserveEnd(Observer, Log);
        Observer.Expect('result', 'new user: No / after a strong password: Yes / after a blank password: Yes / unknown user: No / null guid: No / session user: No / end: Dialog | LT SUP rollback marker');
        Observer.Verify();
    end;
}
