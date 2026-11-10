// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-setuserpassword-method
// Scope: in-scope (OnPrem app only: Database.SetUserPassword has scope OnPrem, must-not-compile case 0568)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98000
// Probe (values pinned): al-runner issue 7447. ODatabaseOps.al pins the error of Database.SetUserPassword for an unknown user. This probe asks what it does
//   for a user that exists: a user row the test inserts (User Name, License Type Full User, State Enabled, no Windows Security ID), then
//     a strong password, a second strong password after the first, a blank password, a short one, one without digits or symbols,
//     one of 300 characters, the user name as the password, a disabled user, a user with a blank User Name,
//   and after each call the User Property row of the user: whether it exists, whether Password is filled, its length, whether it holds the
//   plain text, and whether a second call changes it. Unknown user and null GUID are the controls.
//   Only users the test inserts are touched; the test ends in an error, so the rows are rolled back. The session user's password is never set.
//   Each call runs in a TryFunction: `ok` or the error text and code.
// Measured on BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): for every user the test inserts (enabled, disabled, blank name) and every
//   password, the first call raises "Call to the function 'MODIFY' is not allowed inside the call to '<test>' when it is used as a
//   TryFunction." The TryFunction does not catch it and the test stops. So each test now asserts that error for its first call with
//   asserterror (the method name in the text is masked) and the later calls of each test, never reached, are removed. What
//   SetUserPassword stores for an existing user needs a probe without a TryFunction.
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

    local procedure ObserveSet(var Observer: Codeunit "Probe Observer"; Name: Text; UserSecurityId: Guid; Password: Text)
    begin
        ClearLastError();
        if TrySetPassword(UserSecurityId, Password) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' property', PropertyState(UserSecurityId, Password));
    end;

    // The error names the outermost method of the test runner under asserterror, not this codeunit's test ('RunTests' or
    // 'RootMethodScope', depending on the runner; see errors/CuTryTests.al): the name is masked so the pin holds under either runner.
    local procedure MaskRunnerScope(ErrorText: Text): Text
    var
        Marker: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Marker := 'inside the call to ''';
        StartPos := ErrorText.IndexOf(Marker);
        if StartPos = 0 then
            exit(ErrorText);
        StartPos += StrLen(Marker);
        EndPos := ErrorText.Substring(StartPos).IndexOf('''');
        if EndPos = 0 then
            exit(ErrorText);
        exit(ErrorText.Substring(1, StartPos - 1) + '<scope>' + ErrorText.Substring(StartPos + EndPos - 1));
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_StrongPassword()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-STRONG', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'strong password', Sid, 'LT-Sup3r!Passw0rd#1');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_BlankAndShortPasswords()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK1', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'blank', Sid, '');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_PasswordsWithoutAClass()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK2', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'eight lower case letters', Sid, 'abcdefgh');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_UserNameAndSpaces()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-WEAK3', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'the user name', Sid, 'LT-SUP-WEAK3');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_ExistingUser_LongAndNonAsciiPassword()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-LONG', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, '300 characters', Sid, 'Aa1!' + PadStr('', 296, 'x'));
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_DisabledUser_UnknownUser_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('LT-SUP-DISABLED', false);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'disabled user', Sid, 'LT-Sup3r!Passw0rd#1');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;

    [Test]
    procedure SetUserPassword_UserWithBlankName()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Guid;
    begin
        Sid := NewUser('', true);
        // BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882): Database.SetUserPassword in the TryFunction raises the TryFunction write
        // error for MODIFY, which the TryFunction does not catch; the test stopped here, so the calls after this one were never reached.
        asserterror ObserveSet(Observer, 'user with a blank name', Sid, 'LT-Sup3r!Passw0rd#1');
        Observer.Observe('first call', MaskRunnerScope(GetLastErrorText()));
        Observer.Expect('first call', 'Call to the function ''MODIFY'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Verify();
    end;
}
