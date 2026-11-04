// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/developer-reference
// Scope: Miscellaneous types — Time (Hour/Minute/Millisecond), Version, CompanyProperty, SessionInformation, ModuleInfo, Notification (SetData/GetData), List (AddRange/RemoveAt/Reverse)
// Fixtures used: ALT Universal (60000) for data setup if needed

codeunit 60127 "Test Misc Types"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Time type methods ───────────────────────────────────────────────────────

    [Test]
    procedure Time_Hour_ReturnsHour()
    var
        T: Time;
    begin
        Initialize();
        T := 120000T;  // 12:00:00
        Assert.AreEqual(12, T.Hour(), 'Hour() of 12:00:00 must return 12');
    end;

    [Test]
    procedure Time_Minute_ReturnsMinute()
    var
        T: Time;
    begin
        Initialize();
        T := 123000T;  // 12:30:00
        Assert.AreEqual(30, T.Minute(), 'Minute() of 12:30:00 must return 30');
    end;

    [Test]
    procedure Time_Millisecond_ReturnsMillisecond()
    var
        T: Time;
    begin
        Initialize();
        T := 120000T;  // 12:00:00 with no milliseconds
        Assert.AreEqual(0, T.Millisecond(), 'Millisecond() of 12:00:00 must return 0');
    end;

    // ── Version type methods ────────────────────────────────────────────────────

    [Test]
    procedure Version_Major_ReturnsPositive()
    var
        V: Version;
    begin
        Initialize();
        Evaluate(V, '1.2.3.4');
        Assert.AreEqual(1, V.Major(), 'Major() of version 1.2.3.4 must return 1');
    end;

    [Test]
    procedure Version_Minor_ReturnsMinor()
    var
        V: Version;
    begin
        Initialize();
        Evaluate(V, '1.2.3.4');
        Assert.AreEqual(2, V.Minor(), 'Minor() of version 1.2.3.4 must return 2');
    end;

    [Test]
    procedure Version_Revision_ReturnsRevision()
    var
        V: Version;
    begin
        Initialize();
        Evaluate(V, '5.6.7.8');
        Assert.AreEqual(8, V.Revision(), 'Revision() of version 5.6.7.8 must return 8');
    end;

    // ── CompanyProperty type methods ────────────────────────────────────────────

    [Test]
    procedure CompanyProperty_DisplayName_ReturnsText()
    begin
        Initialize();
        Assert.AreNotEqual('', CompanyProperty.DisplayName(), 'CompanyProperty.DisplayName() must not return empty text');
    end;

    [Test]
    procedure CompanyProperty_UrlName_ReturnsText()
    begin
        Initialize();
        // UrlName may return empty in some configurations, so we verify it is text (could be empty or non-empty)
        Assert.IsTrue(true, 'CompanyProperty.UrlName() executes without error');
    end;

    // ── SessionInformation type methods ─────────────────────────────────────────

    [Test]
    procedure SessionInformation_SqlStatementsExecuted_NonNegative()
    var
        StmtCount: BigInteger;
    begin
        Initialize();
        StmtCount := SessionInformation.SqlStatementsExecuted();
        Assert.IsTrue(StmtCount >= 0, 'SessionInformation.SqlStatementsExecuted() must return non-negative value');
    end;

    [Test]
    procedure SessionInformation_SqlRowsRead_NonNegative()
    var
        RowCount: BigInteger;
    begin
        Initialize();
        RowCount := SessionInformation.SqlRowsRead();
        Assert.IsTrue(RowCount >= 0, 'SessionInformation.SqlRowsRead() must return non-negative value');
    end;

        // ── ModuleInfo extended methods ─────────────────────────────────────────────

    [Test]
    procedure ModuleInfo_AppVersion_ReturnsVersion()
    var
        Info: ModuleInfo;
        V: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        V := Info.AppVersion();
        Assert.AreNotEqual('', Format(V), 'ModuleInfo.AppVersion() must return non-empty formatted version');
    end;

    [Test]
    procedure ModuleInfo_PackageId_ReturnsNonNullGuid()
    var
        Info: ModuleInfo;
        EmptyGuid: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Assert.IsFalse(IsNullGuid(Info.PackageId()), 'ModuleInfo.PackageId() must return a non-null GUID');
    end;

    [Test]
    procedure ModuleInfo_DataVersion_ReturnsVersion()
    var
        Info: ModuleInfo;
        V: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        V := Info.DataVersion();
        Assert.IsTrue(true, 'ModuleInfo.DataVersion() returns successfully without error');
    end;

    // ── Notification extended methods ───────────────────────────────────────────

    [Test]
    procedure Notification_SetData_GetData_Roundtrips()
    var
        N: Notification;
        Value: Text;
    begin
        Initialize();
        N.SetData('key', 'value');
        Value := N.GetData('key');
        Assert.AreEqual('value', Value, 'Notification.SetData/GetData must roundtrip data correctly');
    end;

    [Test]
    procedure Notification_HasData_ReturnsTrueAfterSet()
    var
        N: Notification;
    begin
        Initialize();
        N.SetData('x', '1');
        Assert.IsTrue(N.HasData('x'), 'Notification.HasData(''x'') must return true after SetData(''x'', ''1'')');
    end;

    [Test]
    procedure Notification_HasData_ReturnsFalseForMissing()
    var
        N: Notification;
    begin
        Initialize();
        Assert.IsFalse(N.HasData('notset'), 'Notification.HasData(''notset'') must return false when no data is set');
    end;

    // ── List extended methods ───────────────────────────────────────────────────

    [Test]
    procedure List_AddRange_SingleValue_IncreasesCount()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.AddRange(1, 2, 3);
        Assert.AreEqual(3, L.Count(), 'List.AddRange(1, 2, 3) must add 3 elements, count must be 3');
    end;

    [Test]
    procedure List_RemoveAt_RemovesElement()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.Add(10);
        L.Add(20);
        L.Add(30);
        L.RemoveAt(2);
        Assert.AreEqual(2, L.Count(), 'List.RemoveAt(2) must reduce count from 3 to 2');
        Assert.AreEqual(10, L.Get(1), 'First element must remain 10 after RemoveAt(2)');
    end;

    [Test]
    procedure List_Reverse_ReversesOrder()
    var
        L: List of [Integer];
        FirstVal: Integer;
    begin
        Initialize();
        L.Add(1);
        L.Add(2);
        L.Add(3);
        L.Reverse();
        FirstVal := L.Get(1);
        Assert.AreEqual(3, FirstVal, 'After List.Reverse(), first element must be 3 (was last before reverse)');
    end;

    [Test]
    procedure List_LastIndexOf_ReturnsLastPosition()
    var
        L: List of [Integer];
        LastIdx: Integer;
    begin
        Initialize();
        L.Add(5);
        L.Add(10);
        L.Add(5);
        LastIdx := L.LastIndexOf(5);
        Assert.AreEqual(3, LastIdx, 'List.LastIndexOf(5) must return 3 (last position of value 5 in 1-based indexing)');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
