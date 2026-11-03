// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y93WildObjects.al (94980-94999); xapp-a Y93XaObjects.al; Permissions Mock (131006).
// Probe, writer Y93 (outside issue 6867): does a wildcard grant in a permission set apply to every object of the installation or only to the objects of the
//   app that declares the set? Each case calls an object that no other case uses (Execute is checked the first time a session loads an object); a control
//   set (a wildcard of another kind) runs first on the same object, the set under test runs second.
// BC versions: 27, 28, 29

codeunit 94998 "LT Y93 Wild Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    // Own app, set declared in the same app, one set per object kind.
    [Test]
    procedure Y93_Main_PerKind_A_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('cu|control', 'E:LT Y93 W Sys', 1);
        Run('cu|W Cu', 'E:LT Y93 W Cu', 1);
        Run('page|control', 'E:LT Y93 W Sys', 10);
        Run('page|W Page', 'E:LT Y93 W Page', 10);
        Run('table|control', 'E:LT Y93 W Sys', 20);
        Run('table|W Table', 'E:LT Y93 W Table', 20);
        RestoreMock(WasStarted);
        Observer.Expect('cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 94980 LT Y93 Cu M1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('cu|W Cu',
            'LT Y93 ok ping');
        Observer.Expect('page|control',
            'Page LT Y93 Page M1 has to close. | FormAbort:Permission');
        Observer.Expect('page|W Page',
            'LT Y93 ok opened');
        Observer.Expect('table|control',
            'Sorry, the current permissions prevented the action. (Table 94982 LT Y93 Tab M1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('table|W Table',
            'LT Y93 ok ping');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Main_PerKind_A_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('tabledata|control', 'E:LT Y93 W Sys', 60);
        Run('tabledata|W Data insert', 'E:LT Y93 W Data', 60);
        Run('tabledata|W Data read', 'E:LT Y93 W Data', 61);
        RestoreMock(WasStarted);
        Observer.Expect('tabledata|control',
            'Sorry, the current permissions prevented the action. (TableData 94980 LT Y93 Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('tabledata|W Data insert',
            'LT Y93 ok inserted');
        Observer.Expect('tabledata|W Data read',
            'LT Y93 ok find No');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Main_PerKind_B_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('report|control', 'E:LT Y93 W Sys', 30);
        Run('report|W Report', 'E:LT Y93 W Report', 30);
        Run('report|W Report+Cu', 'E:LT Y93 W Rep Cu', 30);
        Run('query|control', 'E:LT Y93 W Sys', 40);
        Run('query|W Query', 'E:LT Y93 W Query', 40);
        Run('query|W Query+Data', 'E:LT Y93 W Qry Data', 40);
        RestoreMock(WasStarted);
        Observer.Expect('report|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 44 ReportManagement Execute: ) | DB:ExecuteObjDenied');
        Observer.Expect('report|W Report',
            'Sorry, the current permissions prevented the action. (CodeUnit 44 ReportManagement Execute: ) | DB:ExecuteObjDenied');
        Observer.Expect('report|W Report+Cu',
            'LT Y93 ok ran');
        Observer.Expect('query|control',
            'Sorry, the current permissions prevented the action. (Query 94980 LT Y93 Query M1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('query|W Query',
            'LT Y93 ok read No');
        Observer.Expect('query|W Query+Data',
            'LT Y93 ok read No');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Main_PerKind_B_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xmlport|control', 'E:LT Y93 W Sys', 50);
        Run('xmlport|W Xml', 'E:LT Y93 W Xml', 50);
        Run('xmlport|W Xml+Data', 'E:LT Y93 W Xml Data', 50);
        RestoreMock(WasStarted);
        Observer.Expect('xmlport|control',
            'Sorry, the current permissions prevented the action. (XmlPort 94980 LT Y93 Xml M1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xmlport|W Xml',
            'LT Y93 ok exported');
        Observer.Expect('xmlport|W Xml+Data',
            'LT Y93 ok exported');
        Observer.Verify();
    end;

    // A wildcard next to an explicit lower grant on one object, and an excluded permission set.
    [Test]
    procedure Y93_Main_Mixed_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('mixdata|row insert', 'E:LT Y93 W Mix Data', 60);
        Run('mixdata|narrow insert', 'E:LT Y93 W Mix Data', 62);
        Run('mixdata|narrow read', 'E:LT Y93 W Mix Data', 63);
        Run('plaindata|narrow insert', 'E:LT Y93 W Data', 62);
        Run('mixcu|M3 explicit x', 'E:LT Y93 W Mix Cu', 3);
        Run('mixcu|M5 wildcard only', 'E:LT Y93 W Mix Cu', 5);
        RestoreMock(WasStarted);
        Observer.Expect('mixdata|row insert',
            'LT Y93 ok inserted');
        Observer.Expect('mixdata|narrow insert',
            'LT Y93 ok inserted');
        Observer.Expect('mixdata|narrow read',
            'LT Y93 ok find No');
        Observer.Expect('plaindata|narrow insert',
            'LT Y93 ok inserted');
        Observer.Expect('mixcu|M3 explicit x',
            'LT Y93 ok ping');
        Observer.Expect('mixcu|M5 wildcard only',
            'LT Y93 ok ping');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Main_Mixed_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('excl|M4 excluded', 'E:LT Y93 W Excl', 4);
        Run('excl|M6 other', 'E:LT Y93 W Excl', 6);
        Run('excl|row insert', 'E:LT Y93 W Excl', 60);
        Run('excl|row read', 'E:LT Y93 W Excl', 61);
        RestoreMock(WasStarted);
        Observer.Expect('excl|M4 excluded',
            'Sorry, the current permissions prevented the action. (CodeUnit 94983 LT Y93 Cu M4 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('excl|M6 other',
            'LT Y93 ok ping');
        Observer.Expect('excl|row insert',
            'Sorry, the current permissions prevented the action. (TableData 94980 LT Y93 Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('excl|row read',
            'LT Y93 ok find No');
        Observer.Verify();
    end;

    // A set declared in the main app (LT Y93 W All) used on objects of xapp-a and of Base Application.
    [Test]
    procedure Y93_Cross_SetInMain_A_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa cu|control', 'E:LT Y93 W Sys', 100);
        Run('xa cu|W All', 'E:LT Y93 W All', 100);
        Run('xa page|control', 'E:LT Y93 W Sys', 102);
        Run('xa page|W All', 'E:LT Y93 W All', 102);
        Run('xa table|control', 'E:LT Y93 W Sys', 104);
        Run('xa table|W All', 'E:LT Y93 W All', 104);
        RestoreMock(WasStarted);
        Observer.Expect('xa cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 61170 LT Y93 XA Cu 1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa cu|W All',
            'LT Y93 ok ping');
        Observer.Expect('xa page|control',
            'Page LT Y93 XA Page 1 has to close. | FormAbort:Permission');
        Observer.Expect('xa page|W All',
            'LT Y93 ok opened');
        Observer.Expect('xa table|control',
            'Sorry, the current permissions prevented the action. (Table 61174 LT Y93 XA Tab 1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa table|W All',
            'LT Y93 ok ping');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInMain_A_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa td insert|control', 'E:LT Y93 W Sys', 112);
        Run('xa td insert|W Data', 'E:LT Y93 W Data', 112);
        Run('xa td read|W Data', 'E:LT Y93 W Data', 113);
        Run('xa report|control', 'E:LT Y93 W Sys', 106);
        Run('xa report|W All', 'E:LT Y93 W All', 106);
        RestoreMock(WasStarted);
        Observer.Expect('xa td insert|control',
            'Sorry, the current permissions prevented the action. (TableData 61173 LT Y93 XA Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('xa td insert|W Data',
            'LT Y93 ok inserted');
        Observer.Expect('xa td read|W Data',
            'LT Y93 ok find No');
        Observer.Expect('xa report|control',
            'Sorry, the current permissions prevented the action. (Report 61170 LT Y93 XA Report 1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa report|W All',
            'LT Y93 ok ran');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInMain_B_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa query|control', 'E:LT Y93 W Sys', 108);
        Run('xa query|W All', 'E:LT Y93 W All', 108);
        Run('xa xmlport|control', 'E:LT Y93 W Sys', 110);
        Run('xa xmlport|W All', 'E:LT Y93 W All', 110);
        Run('base cu|control', 'E:LT Y93 W Sys', 201);
        Run('base cu|W All', 'E:LT Y93 W All', 201);
        RestoreMock(WasStarted);
        Observer.Expect('xa query|control',
            'Sorry, the current permissions prevented the action. (Query 61170 LT Y93 XA Query 1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa query|W All',
            'LT Y93 ok read No');
        Observer.Expect('xa xmlport|control',
            'Sorry, the current permissions prevented the action. (XmlPort 61170 LT Y93 XA Xml 1 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa xmlport|W All',
            'LT Y93 ok exported');
        Observer.Expect('base cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 7600 Calendar Management Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('base cu|W All',
            'LT Y93 ok 12/31/9999');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInMain_B_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('sysapp cu|control', 'E:LT Y93 W Sys', 200);
        Run('sysapp cu|W All', 'E:LT Y93 W All', 200);
        Run('base page|control', 'E:LT Y93 W Sys', 204);
        Run('base page|W All', 'E:LT Y93 W All', 204);
        Run('base table|control', 'E:LT Y93 W Sys', 206);
        Run('base table|W All', 'E:LT Y93 W All', 206);
        RestoreMock(WasStarted);
        Observer.Expect('sysapp cu|control',
            'LT Y93 ok YQ==');
        Observer.Expect('sysapp cu|W All',
            'LT Y93 ok YQ==');
        Observer.Expect('base page|control',
            'Page Units of Measure has to close. | FormAbort:Permission');
        Observer.Expect('base page|W All',
            'LT Y93 ok opened');
        Observer.Ignore('base table|control');
        Observer.Ignore('base table|W All');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInMain_B_3()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('base td insert|control', 'E:LT Y93 W Sys', 208);
        Run('base td insert|W Data', 'E:LT Y93 W Data', 208);
        Run('base td read|W Data', 'E:LT Y93 W Data', 209);
        RestoreMock(WasStarted);
        Observer.Expect('base td insert|control',
            'Sorry, the current permissions prevented the action. (TableData 204 Unit of Measure Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('base td insert|W Data',
            'LT Y93 ok inserted');
        Observer.Expect('base td read|W Data',
            'LT Y93 ok find Yes');
        Observer.Verify();
    end;

    // A set declared in xapp-a (LT Y93 XA All) used on objects of the main app, of xapp-a and of Base Application.
    [Test]
    procedure Y93_Cross_SetInXapp_A_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('main cu|control', 'E:LT Y93 W Sys', 2);
        Run('main cu|XA All', 'E:LT Y93 XA All', 2);
        Run('main page|control', 'E:LT Y93 W Sys', 11);
        Run('main page|XA All', 'E:LT Y93 XA All', 11);
        Run('main table|control', 'E:LT Y93 W Sys', 21);
        Run('main table|XA All', 'E:LT Y93 XA All', 21);
        RestoreMock(WasStarted);
        Observer.Expect('main cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 94981 LT Y93 Cu M2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('main cu|XA All',
            'LT Y93 ok ping');
        Observer.Expect('main page|control',
            'Page LT Y93 Page M2 has to close. | FormAbort:Permission');
        Observer.Expect('main page|XA All',
            'LT Y93 ok opened');
        Observer.Expect('main table|control',
            'Sorry, the current permissions prevented the action. (Table 94983 LT Y93 Tab M2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('main table|XA All',
            'LT Y93 ok ping');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_A_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('main td insert|control', 'E:LT Y93 W Sys', 62);
        Run('main td insert|XA All', 'E:LT Y93 XA All', 62);
        Run('main report|control', 'E:LT Y93 W Sys', 31);
        Run('main report|XA All', 'E:LT Y93 XA All', 31);
        Run('main query|control', 'E:LT Y93 W Sys', 41);
        Run('main query|XA All', 'E:LT Y93 XA All', 41);
        RestoreMock(WasStarted);
        Observer.Expect('main td insert|control',
            'Sorry, the current permissions prevented the action. (TableData 94981 LT Y93 Row Narrow Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('main td insert|XA All',
            'LT Y93 ok inserted');
        Observer.Expect('main report|control',
            'Sorry, the current permissions prevented the action. (Report 94981 LT Y93 Report M2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('main report|XA All',
            'LT Y93 ok ran');
        Observer.Expect('main query|control',
            'Sorry, the current permissions prevented the action. (Query 94981 LT Y93 Query M2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('main query|XA All',
            'LT Y93 ok read No');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_A_3()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('main xmlport|control', 'E:LT Y93 W Sys', 51);
        Run('main xmlport|XA All', 'E:LT Y93 XA All', 51);
        RestoreMock(WasStarted);
        Observer.Expect('main xmlport|control',
            'Sorry, the current permissions prevented the action. (XmlPort 94981 LT Y93 Xml M2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('main xmlport|XA All',
            'LT Y93 ok exported');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_B_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa cu|control', 'E:LT Y93 W Sys', 101);
        Run('xa cu|XA All', 'E:LT Y93 XA All', 101);
        Run('xa page|control', 'E:LT Y93 W Sys', 103);
        Run('xa page|XA All', 'E:LT Y93 XA All', 103);
        Run('xa table|control', 'E:LT Y93 W Sys', 105);
        Run('xa table|XA All', 'E:LT Y93 XA All', 105);
        RestoreMock(WasStarted);
        Observer.Expect('xa cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 61171 LT Y93 XA Cu 2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa cu|XA All',
            'LT Y93 ok ping');
        Observer.Expect('xa page|control',
            'Page LT Y93 XA Page 2 has to close. | FormAbort:Permission');
        Observer.Expect('xa page|XA All',
            'LT Y93 ok opened');
        Observer.Expect('xa table|control',
            'Sorry, the current permissions prevented the action. (Table 61175 LT Y93 XA Tab 2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa table|XA All',
            'LT Y93 ok ping');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_B_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa td insert|XA All', 'E:LT Y93 XA All', 112);
        Run('xa report|control', 'E:LT Y93 W Sys', 107);
        Run('xa report|XA All', 'E:LT Y93 XA All', 107);
        Run('xa query|control', 'E:LT Y93 W Sys', 109);
        Run('xa query|XA All', 'E:LT Y93 XA All', 109);
        Run('xa xmlport|control', 'E:LT Y93 W Sys', 111);
        RestoreMock(WasStarted);
        Observer.Expect('xa td insert|XA All',
            'LT Y93 ok inserted');
        Observer.Expect('xa report|control',
            'Sorry, the current permissions prevented the action. (Report 61171 LT Y93 XA Report 2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa report|XA All',
            'LT Y93 ok ran');
        Observer.Expect('xa query|control',
            'Sorry, the current permissions prevented the action. (Query 61171 LT Y93 XA Query 2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xa query|XA All',
            'LT Y93 ok read No');
        Observer.Expect('xa xmlport|control',
            'Sorry, the current permissions prevented the action. (XmlPort 61171 LT Y93 XA Xml 2 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_B_3()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('xa xmlport|XA All', 'E:LT Y93 XA All', 111);
        RestoreMock(WasStarted);
        Observer.Expect('xa xmlport|XA All',
            'LT Y93 ok exported');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_C_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('base cu|control', 'E:LT Y93 W Sys', 203);
        Run('base cu|XA All', 'E:LT Y93 XA All', 203);
        Run('sysapp cu|control', 'E:LT Y93 W Sys', 202);
        Run('sysapp cu|XA All', 'E:LT Y93 XA All', 202);
        Run('base page|control', 'E:LT Y93 W Sys', 205);
        Run('base page|XA All', 'E:LT Y93 XA All', 205);
        RestoreMock(WasStarted);
        Observer.Expect('base cu|control',
            'Sorry, the current permissions prevented the action. (CodeUnit 365 Format Address Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('base cu|XA All',
            'LT Y93 ok 1 Y93');
        Observer.Expect('sysapp cu|control',
            'LT Y93 ok Web');
        Observer.Expect('sysapp cu|XA All',
            'LT Y93 ok Web');
        Observer.Expect('base page|control',
            'Page Payment Terms has to close. | FormAbort:Permission');
        Observer.Expect('base page|XA All',
            'LT Y93 ok opened');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Cross_SetInXapp_C_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('base table|control', 'E:LT Y93 W Sys', 207);
        Run('base table|XA All', 'E:LT Y93 XA All', 207);
        Run('base td insert|XA All', 'E:LT Y93 XA All', 210);
        RestoreMock(WasStarted);
        Observer.Ignore('base table|control');
        Observer.Expect('base table|XA All',
            'LT Y93 ok Yes');
        Observer.Expect('base td insert|XA All',
            'LT Y93 ok inserted');
        Observer.Verify();
    end;

    // Set (adds all objects) and Assign next to SetExactPermissionSet, with a set that names no object of the call.
    [Test]
    procedure Y93_SetAndAssign_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('set W Sys|cu', 'S:LT Y93 W Sys', 7);
        Run('assign W Sys|cu', 'A:LT Y93 W Sys', 8);
        Run('set W Sys|row insert', 'S:LT Y93 W Sys', 60);
        Run('set W Data|row insert', 'S:LT Y93 W Data', 60);
        Run('set W Data|xa row insert', 'S:LT Y93 W Data', 112);
        Run('set W Data|base insert', 'S:LT Y93 W Data', 208);
        RestoreMock(WasStarted);
        Observer.Expect('set W Sys|cu',
            'LT Y93 ok ping');
        Observer.Expect('assign W Sys|cu',
            'Sorry, the current permissions prevented the action. (CodeUnit 94987 LT Y93 Cu M8 Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('set W Sys|row insert',
            'Sorry, the current permissions prevented the action. (TableData 94980 LT Y93 Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('set W Data|row insert',
            'LT Y93 ok inserted');
        Observer.Expect('set W Data|xa row insert',
            'LT Y93 ok inserted');
        Observer.Expect('set W Data|base insert',
            'LT Y93 ok inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_SetAndAssign_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('assign W Data|row insert', 'A:LT Y93 W Data', 60);
        Run('assign W Data|xa row insert', 'A:LT Y93 W Data', 112);
        Run('assign W Data|base insert', 'A:LT Y93 W Data', 208);
        RestoreMock(WasStarted);
        Observer.Expect('assign W Data|row insert',
            'LT Y93 ok inserted');
        Observer.Expect('assign W Data|xa row insert',
            'LT Y93 ok inserted');
        Observer.Expect('assign W Data|base insert',
            'LT Y93 ok inserted');
        Observer.Verify();
    end;

    // tabledata * = rimd (indirect) and a codeunit with the Permissions property.
    [Test]
    procedure Y93_IndirectWildcard_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('ind|row insert', 'E:LT Y93 W Ind Cu', 60);
        Run('ind|xa row insert', 'E:LT Y93 W Ind Cu', 112);
        Run('ind|base insert', 'E:LT Y93 W Ind Cu', 208);
        Run('ind|row read', 'E:LT Y93 W Ind Cu', 61);
        Run('indcu|no cu grant', 'E:LT Y93 W Ind', 300);
        Run('indcu|via own', 'E:LT Y93 W Ind Cu', 300);
        RestoreMock(WasStarted);
        Observer.Expect('ind|row insert',
            'Sorry, the current permissions prevented the action. (TableData 94980 LT Y93 Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('ind|xa row insert',
            'Sorry, the current permissions prevented the action. (TableData 61173 LT Y93 XA Row Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('ind|base insert',
            'Sorry, the current permissions prevented the action. (TableData 204 Unit of Measure Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('ind|row read',
            'LT Y93 ok find No');
        Observer.Expect('indcu|no cu grant',
            'Sorry, the current permissions prevented the action. (CodeUnit 94988 LT Y93 Cu Ind Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('indcu|via own',
            'LT Y93 ok inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_IndirectWildcard_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('indcu|via xa', 'E:LT Y93 W Ind Cu', 301);
        Run('indcu|via base', 'E:LT Y93 W Ind Cu', 302);
        Run('indcu|no ind set', 'E:LT Y93 W Cu', 300);
        RestoreMock(WasStarted);
        Observer.Expect('indcu|via xa',
            'LT Y93 ok inserted');
        Observer.Expect('indcu|via base',
            'LT Y93 ok inserted');
        Observer.Expect('indcu|no ind set',
            'Sorry, the current permissions prevented the action. (TableData 94980 LT Y93 Row IndirectInsert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Verify();
    end;

    // The neighbour of al-runner issue 6867: a page whose OnOpenPage calls a codeunit of the test app.
    [Test]
    procedure Y93_OpenPage_Neighbour()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('q1 Set basic', 'S:D365 BASIC', 70);
        Run('q2 Set basic + Assign W Cu', 'S:D365 BASIC;A:LT Y93 W Cu', 71);
        Run('q3 Exact basic + Assign W All', 'E:D365 BASIC;A:LT Y93 W All', 72);
        Run('q4 Exact W All', 'E:LT Y93 W All', 73);
        Run('q5 Exact basic', 'E:D365 BASIC', 74);
        RestoreMock(WasStarted);
        Observer.Expect('q1 Set basic',
            'LT Y93 ok opened');
        Observer.Expect('q2 Set basic + Assign W Cu',
            'LT Y93 ok opened');
        Observer.Expect('q3 Exact basic + Assign W All',
            'LT Y93 ok opened');
        Observer.Expect('q4 Exact W All',
            'LT Y93 ok opened');
        Observer.Expect('q5 Exact basic',
            'LT Y93 ok opened');
        Observer.Verify();
    end;

    local procedure Run(Tag: Text; Spec: Text; Which: Integer)
    var
        Part: Text;
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        foreach Part in Spec.Split(';') do
            case CopyStr(Part, 1, 1) of
                'E':
                    Mock.SetExactPermissionSet(CopyStr(CopyStr(Part, 3), 1, 20));
                'S':
                    Mock.Set(CopyStr(CopyStr(Part, 3), 1, 20));
                'A':
                    Mock.Assign(CopyStr(CopyStr(Part, 3), 1, 20));
            end;
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        if ErrorText.StartsWith('LT Y93 ok') then
            Observer.Observe(Tag, ErrorText)
        else
            Observer.Observe(Tag, ErrorText + ' | ' + ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        Result: Text;
    begin
        case Which of
            1 .. 8:
                Result := OpMainCu(Which);
            10, 11, 20, 21, 30, 31, 40, 41, 50, 51:
                Result := OpMainObject(Which);
            60 .. 63:
                Result := OpMainData(Which);
            70 .. 74:
                Result := OpOpenPage(Which);
            100 .. 113:
                Result := OpXapp(Which);
            200 .. 210:
                Result := OpBase(Which);
            300 .. 302:
                Result := OpIndirect(Which);
        end;
        Error('LT Y93 ok %1', Result);
    end;

    local procedure OpMainCu(Which: Integer): Text
    var
        C1: Codeunit "LT Y93 Cu M1";
        C2: Codeunit "LT Y93 Cu M2";
        C3: Codeunit "LT Y93 Cu M3";
        C4: Codeunit "LT Y93 Cu M4";
        C5: Codeunit "LT Y93 Cu M5";
        C6: Codeunit "LT Y93 Cu M6";
        C7: Codeunit "LT Y93 Cu M7";
        C8: Codeunit "LT Y93 Cu M8";
    begin
        case Which of
            1:
                exit(C1.Ping());
            2:
                exit(C2.Ping());
            3:
                exit(C3.Ping());
            4:
                exit(C4.Ping());
            5:
                exit(C5.Ping());
            6:
                exit(C6.Ping());
            7:
                exit(C7.Ping());
            8:
                exit(C8.Ping());
        end;
    end;

    local procedure OpMainObject(Which: Integer): Text
    var
        T1: Record "LT Y93 Tab M1";
        T2: Record "LT Y93 Tab M2";
        P1: TestPage "LT Y93 Page M1";
        P2: TestPage "LT Y93 Page M2";
        Q1: Query "LT Y93 Query M1";
        Q2: Query "LT Y93 Query M2";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        case Which of
            10:
                begin
                    P1.OpenView();
                    P1.Close();
                    exit('opened');
                end;
            11:
                begin
                    P2.OpenView();
                    P2.Close();
                    exit('opened');
                end;
            20:
                exit(T1.Ping());
            21:
                exit(T2.Ping());
            30:
                begin
                    Report.Run(Report::"LT Y93 Report M1", false);
                    exit('ran');
                end;
            31:
                begin
                    Report.Run(Report::"LT Y93 Report M2", false);
                    exit('ran');
                end;
            40:
                begin
                    Q1.Open();
                    exit('read ' + Format(Q1.Read()));
                end;
            41:
                begin
                    Q2.Open();
                    exit('read ' + Format(Q2.Read()));
                end;
            50:
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Xmlport.Export(Xmlport::"LT Y93 Xml M1", OutStr);
                    exit('exported');
                end;
            51:
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Xmlport.Export(Xmlport::"LT Y93 Xml M2", OutStr);
                    exit('exported');
                end;
        end;
    end;

    local procedure OpMainData(Which: Integer): Text
    var
        Row: Record "LT Y93 Row";
        Narrow: Record "LT Y93 Row Narrow";
    begin
        case Which of
            60:
                begin
                    Row.Id := 1;
                    Row.Insert();
                    exit('inserted');
                end;
            61:
                exit('find ' + Format(Row.FindFirst()));
            62:
                begin
                    Narrow.Id := 1;
                    Narrow.Insert();
                    exit('inserted');
                end;
            63:
                exit('find ' + Format(Narrow.FindFirst()));
        end;
    end;

    local procedure OpOpenPage(Which: Integer): Text
    var
        P1: TestPage "LT Y93 Open 1";
        P2: TestPage "LT Y93 Open 2";
        P3: TestPage "LT Y93 Open 3";
        P4: TestPage "LT Y93 Open 4";
        P5: TestPage "LT Y93 Open 5";
    begin
        case Which of
            70:
                P1.OpenView();
            71:
                P2.OpenView();
            72:
                P3.OpenView();
            73:
                P4.OpenView();
            74:
                P5.OpenView();
        end;
        exit('opened');
    end;

    local procedure OpXapp(Which: Integer): Text
    var
        C1: Codeunit "LT Y93 XA Cu 1";
        C2: Codeunit "LT Y93 XA Cu 2";
        T1: Record "LT Y93 XA Tab 1";
        T2: Record "LT Y93 XA Tab 2";
        P1: TestPage "LT Y93 XA Page 1";
        P2: TestPage "LT Y93 XA Page 2";
        Q1: Query "LT Y93 XA Query 1";
        Q2: Query "LT Y93 XA Query 2";
        Row: Record "LT Y93 XA Row";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        case Which of
            100:
                exit(C1.Ping());
            101:
                exit(C2.Ping());
            102:
                begin
                    P1.OpenView();
                    P1.Close();
                    exit('opened');
                end;
            103:
                begin
                    P2.OpenView();
                    P2.Close();
                    exit('opened');
                end;
            104:
                exit(T1.Ping());
            105:
                exit(T2.Ping());
            106:
                begin
                    Report.Run(Report::"LT Y93 XA Report 1", false);
                    exit('ran');
                end;
            107:
                begin
                    Report.Run(Report::"LT Y93 XA Report 2", false);
                    exit('ran');
                end;
            108:
                begin
                    Q1.Open();
                    exit('read ' + Format(Q1.Read()));
                end;
            109:
                begin
                    Q2.Open();
                    exit('read ' + Format(Q2.Read()));
                end;
            110:
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Xmlport.Export(Xmlport::"LT Y93 XA Xml 1", OutStr);
                    exit('exported');
                end;
            111:
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Xmlport.Export(Xmlport::"LT Y93 XA Xml 2", OutStr);
                    exit('exported');
                end;
            112:
                begin
                    Row.Id := 1;
                    Row.Insert();
                    exit('inserted');
                end;
            113:
                exit('find ' + Format(Row.FindFirst()));
        end;
    end;

    local procedure OpBase(Which: Integer): Text
    var
        Base64: Codeunit "Base64 Convert";
        CalendarMgt: Codeunit "Calendar Management";
        ClientType: Codeunit "Client Type Management";
        FormatAddr: Codeunit "Format Address";
        Uom: Record "Unit of Measure";
        Terms: Record "Payment Terms";
        UomPage: TestPage "Units of Measure";
        TermsPage: TestPage "Payment Terms";
        PostCodeCity: Text[100];
        County: Text[50];
    begin
        case Which of
            200:
                exit(Base64.ToBase64('a'));
            201:
                exit(Format(CalendarMgt.GetMaxDate()));
            202:
                exit(Format(ClientType.GetCurrentClientType()));
            203:
                begin
                    FormatAddr.FormatPostCodeCity(PostCodeCity, County, 'Y93', '1', '', '');
                    exit(PostCodeCity);
                end;
            204:
                begin
                    UomPage.OpenView();
                    UomPage.Close();
                    exit('opened');
                end;
            205:
                begin
                    TermsPage.OpenView();
                    TermsPage.Close();
                    exit('opened');
                end;
            206:
                exit(Uom.GetDescriptionInCurrentLanguage());
            207:
                exit(Format(Terms.UsePaymentDiscount()));
            208:
                begin
                    Uom.Code := 'Y93';
                    Uom.Insert();
                    exit('inserted');
                end;
            209:
                exit('find ' + Format(Uom.FindFirst()));
            210:
                begin
                    Terms.Code := 'Y93';
                    Terms.Insert();
                    exit('inserted');
                end;
        end;
    end;

    local procedure OpIndirect(Which: Integer): Text
    var
        Ind: Codeunit "LT Y93 Cu Ind";
    begin
        case Which of
            300:
                Ind.InsertOwn();
            301:
                Ind.InsertXapp();
            302:
                Ind.InsertBase();
        end;
        exit('inserted');
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
