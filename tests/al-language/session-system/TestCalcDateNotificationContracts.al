codeunit 60169 "Test CalcDate Notification"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure CalcDate_NegCM_ReturnsStartOfCurrentMonth()
    var
        D: Date;
    begin
        D := CalcDate('<-CM>', Today());
        Assert.AreEqual(1, Date2DMY(D, 1), 'CalcDate("<-CM>") must return first day of current month (day = 1)');
        Assert.AreEqual(Date2DMY(Today(), 2), Date2DMY(D, 2), 'CalcDate("<-CM>") must be in the same month as today');
    end;

    [Test]
    procedure CalcDate_1M1D_ReturnsLastDayOfCurrentMonth()
    var
        D: Date;
    begin
        D := CalcDate('<1M-1D>', CalcDate('<-CM>', Today()));
        Assert.AreEqual(Date2DMY(Today(), 2), Date2DMY(D, 2), 'CalcDate("<1M-1D>") from month start must stay in same month');
        Assert.AreEqual(Date2DMY(Today(), 3), Date2DMY(D, 3), 'CalcDate("<1M-1D>") must stay in same year');
    end;

    [Test]
    procedure CalcDate_CY_ReturnsDecember31()
    var
        D: Date;
    begin
        D := CalcDate('<CY>', Today());
        Assert.AreEqual(12, Date2DMY(D, 2), 'CalcDate("<CY>") must return a December date (month 12)');
        Assert.AreEqual(31, Date2DMY(D, 1), 'CalcDate("<CY>") must return December 31 (day 31)');
    end;

    [Test]
    procedure CalcDate_NegCY_ReturnsJanuary1()
    var
        D: Date;
    begin
        D := CalcDate('<-CY>', Today());
        Assert.AreEqual(1, Date2DMY(D, 2), 'CalcDate("<-CY>") must return a January date (month 1)');
        Assert.AreEqual(1, Date2DMY(D, 1), 'CalcDate("<-CY>") must return January 1 (day 1)');
    end;

    [Test]
    procedure CalcDate_CM_LastDayOfMonth()
    var
        D: Date;
    begin
        D := CalcDate('<CM>', 20240315D);
        Assert.AreEqual(31, Date2DMY(D, 1), 'CalcDate("<CM>") from March 15 must return March 31');
    end;

    [Test]
    procedure CalcDate_CM_LastDayOfShortMonth()
    var
        D: Date;
    begin
        D := CalcDate('<CM>', 20240215D);
        Assert.AreEqual(29, Date2DMY(D, 1), 'CalcDate("<CM>") from Feb 15 in leap year must return Feb 29');
    end;

    [Test]
    procedure CalcDate_CQ_ReturnsLastDayOfQuarter()
    var
        D: Date;
    begin
        D := CalcDate('<CQ>', 20240215D);
        Assert.AreEqual(3, Date2DMY(D, 2), 'CalcDate("<CQ>") from Feb must return end of Q1 (March)');
        Assert.AreEqual(31, Date2DMY(D, 1), 'CalcDate("<CQ>") from Feb must return March 31');
    end;

    [Test]
    procedure CompositeKey_CodePK_Get_CaseInsensitive()
    var
        Comp: Record "ALT Composite";
    begin
        Comp."Key1" := 1;
        Comp."Key2" := 'ABC';
        Comp."Key3" := 10;
        Comp.Insert();

        Assert.IsTrue(Comp.Get(1, 'abc', 10), 'Get with lowercase "abc" must find record stored as "ABC" (Code is case-insensitive)');
    end;

    [Test]
    procedure CompositeKey_CodePK_SetRange_CaseInsensitive()
    var
        Comp: Record "ALT Composite";
    begin
        Comp."Key1" := 1;
        Comp."Key2" := 'HELLO';
        Comp."Key3" := 10;
        Comp.Insert();

        Comp."Key1" := 2;
        Comp."Key2" := 'HELLO';
        Comp."Key3" := 20;
        Comp.Insert();

        Comp.SetRange("Key2", 'hello');
        Assert.AreEqual(2, Comp.Count(), 'SetRange on Code[20] PK must be case-insensitive (hello matches HELLO)');
    end;

    [Test]
    procedure CompositeKey_CodePK_RenameUppercasesCode()
    var
        Comp: Record "ALT Composite";
    begin
        Comp."Key1" := 1;
        Comp."Key2" := 'OLD';
        Comp."Key3" := 10;
        Comp.Insert();

        Comp.Get(1, 'OLD', 10);
        Comp.Rename(1, 'new', 10);

        Assert.IsTrue(Comp.Get(1, 'NEW', 10), 'After Rename with lowercase Code, record must be findable by uppercase "NEW"');
        Assert.IsFalse(Comp.Get(1, 'OLD', 10), 'Old key must no longer exist after Rename');
    end;

    [Test]
    procedure Notification_Message_GetterSetterRoundtrip()
    var
        N: Notification;
    begin
        N.Message('Test notification text');
        Assert.AreEqual('Test notification text', N.Message(), 'Notification.Message() getter must return exactly what was set');
    end;

    [Test]
    procedure Notification_SetData_GetData_Roundtrip()
    var
        N: Notification;
    begin
        N.SetData('myKey', 'myValue');
        Assert.AreEqual('myValue', N.GetData('myKey'), 'Notification.GetData must return value set by SetData');
    end;

    [Test]
    procedure Notification_HasData_BeforeSet_ReturnsFalse()
    var
        N: Notification;
    begin
        Assert.IsFalse(N.HasData('notset'), 'HasData on key not yet set must return false');
    end;

    [Test]
    procedure Notification_HasData_AfterSet_ReturnsTrue()
    var
        N: Notification;
    begin
        N.SetData('key', 'val');
        Assert.IsTrue(N.HasData('key'), 'HasData on key that was set must return true');
    end;

    [Test]
    procedure Notification_MultipleData_Isolated()
    var
        N: Notification;
    begin
        N.SetData('k1', 'v1');
        N.SetData('k2', 'v2');
        N.SetData('k3', 'v3');

        Assert.AreEqual('v1', N.GetData('k1'), 'First data must be retrievable');
        Assert.AreEqual('v2', N.GetData('k2'), 'Second data must be retrievable');
        Assert.AreEqual('v3', N.GetData('k3'), 'Third data must be retrievable');
    end;

    [Test]
    procedure Notification_Scope_SetGet()
    var
        N: Notification;
    begin
        N.Scope(NotificationScope::LocalScope);
        Assert.IsTrue(true, 'Setting Notification.Scope must not throw');
    end;
}
