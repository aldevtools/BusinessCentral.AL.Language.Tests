// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (OnPrem app: the User, User Property and Access Control platform tables are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained test codeunit 98400
// Probe: corpus issue 647 items 19 and 20 (writer AV). TestUserAuthEmailTrigger.al pins parts of these texts; this file records the full text and code.
//   One refused step per test. Every test removes the users it created (names start with LTAV) first and last.
// Facts: full error text and code for an Authentication Email without '@', an email another enabled user carries (Insert), a user name another user carries
//   (Modify and Insert); the User Property, User Personalization and Access Control rows of a user after Insert(true) and after Delete(true).
// BC versions: 27, 28, 29
codeunit 98400 "LT AV User Insert Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cleanup()
    var
        UserRec: Record User;
    begin
        UserRec.SetFilter("User Name", 'LTAV*');
        UserRec.DeleteAll(true);
    end;

    local procedure NewUser(var UserRec: Record User; Name: Code[50]; Email: Text)
    begin
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := Name;
        UserRec."Full Name" := 'LT AV Person';
        UserRec."Authentication Email" := CopyStr(Email, 1, MaxStrLen(UserRec."Authentication Email"));
        UserRec.State := UserRec.State::Enabled;
    end;

    local procedure Rows(Sid: Guid): Text
    var
        UserProperty: Record "User Property";
        UserPers: Record "User Personalization";
        Acl: Record "Access Control";
    begin
        UserProperty.SetRange("User Security ID", Sid);
        UserPers.SetRange("User SID", Sid);
        Acl.SetRange("User Security ID", Sid);
        exit(StrSubstNo('user property=%1 user personalization=%2 access control=%3', UserProperty.Count(), UserPers.Count(), Acl.Count()));
    end;

    [Test]
    procedure Insert_AuthenticationEmailWithoutAt()
    var
        Observer: Codeunit "Probe Observer";
        UserRec: Record User;
    begin
        Cleanup();
        NewUser(UserRec, 'LTAV-NOAT', 'ltav.no.at.example.com');
        asserterror UserRec.Insert(true);
        Observer.ObserveError('insert');
        Observer.Expect('insert|text', 'You must specify a valid email address.');
        Observer.Expect('insert|code', 'CannotSpecifyAuthenticationEmail');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_EmailOfAnotherEnabledUser()
    var
        Observer: Codeunit "Probe Observer";
        First: Record User;
        Second: Record User;
    begin
        Cleanup();
        NewUser(First, 'LTAV-MAIL1', 'ltav.taken@example.com');
        First.Insert(true);
        NewUser(Second, 'LTAV-MAIL2', 'ltav.taken@example.com');
        asserterror Second.Insert(true);
        Observer.ObserveError('insert');
        Cleanup();
        Observer.Expect('insert|text', 'The specified authentication email address ''ltav.taken@example.com'' is already being used by another user. You must specify a unique email address.');
        Observer.Expect('insert|code', 'UserTableAuthEmailMustBeUnique');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_UserNameOfAnotherUser()
    var
        Observer: Codeunit "Probe Observer";
        First: Record User;
        Second: Record User;
    begin
        Cleanup();
        NewUser(First, 'LTAV-NAME1', '');
        First.Insert(true);
        NewUser(Second, 'LTAV-NAME2', '');
        Second.Insert(true);
        Second."User Name" := 'LTAV-NAME1';
        asserterror Second.Modify(true);
        Observer.ObserveError('modify');
        Cleanup();
        Observer.Expect('modify|text', 'The user name must be unique.');
        Observer.Expect('modify|code', 'UserTableUserNameMustBeUnique');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_UserNameOfAnotherUser()
    var
        Observer: Codeunit "Probe Observer";
        First: Record User;
        Second: Record User;
        Ok: Boolean;
    begin
        Cleanup();
        NewUser(First, 'LTAV-DUP', '');
        First.Insert(true);
        NewUser(Second, 'LTAV-DUP', '');
        asserterror begin
            Ok := Second.Insert(true);
            Error('LTAV no error, Insert returned %1', Ok);
        end;
        Observer.ObserveError('insert');
        Cleanup();
        Observer.Expect('insert|text', 'The user name must be unique.');
        Observer.Expect('insert|code', 'UserTableUserNameMustBeUnique');
        Observer.Verify();
    end;

    [Test]
    procedure InsertTrue_ThenDeleteTrue_RelatedRows()
    var
        Observer: Codeunit "Probe Observer";
        UserRec: Record User;
        Sid: Guid;
    begin
        Cleanup();
        NewUser(UserRec, 'LTAV-ROWS', 'ltav.rows@example.com');
        Sid := UserRec."User Security ID";
        Observer.Observe('before insert', Rows(Sid));
        UserRec.Insert(true);
        Observer.Observe('after insert', Rows(Sid));
        UserRec.Get(Sid);
        UserRec.Delete(true);
        Observer.Observe('after delete', Rows(Sid));
        Observer.Expect('before insert', 'user property=0 user personalization=0 access control=0');
        Observer.Expect('after insert', 'user property=1 user personalization=0 access control=0');
        Observer.Expect('after delete', 'user property=0 user personalization=0 access control=0');
        Observer.Verify();
    end;
}
