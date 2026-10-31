// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datasourcecontext/datasourcecontext-data-type
// Scope: in-scope
// Fixtures used: Assert (the main app); resource files in res/ (cases.json, cases.csv, bom.csv); own objects 81600 - 81612, 81630 - 81638
// Corpus issues 629 item 16, 626 items 9 and 10, 627 item 19: data-driven tests. A test procedure with [TestDataSource(<codeunit id>, '<data set>')]
// and one parameter of type Interface ITestContext; the source codeunit implements ITestDataSource (ListTestCases, GetTestCase).
// Reference run: BC SaaS sandbox (Windows), BC 29, 2026-10-30, through the TestRunnerHub. Everything asserted below is that run's answer.
// BC versions: 29
// Probe: observed values.
//
// WHAT BC DOES (sandbox reference)
// 1. Order inside a test codeunit: all plain [Test] procedures first, in declaration order (not alphabetical: PlainZ ran before PlainA);
//    then the data-driven procedures, in ALPHABETICAL order of the procedure name (Alpha, Mid, Zeta although declared Zeta, Alpha, Mid).
// 2. Calls per data-driven procedure: ListTestCases(DataSetIdentifier, context) once, then for every case in list order
//    GetTestCase(DataSetIdentifier, TestCaseIndex, TestCaseIdentifier, context) immediately followed by the test run for that case:
//    list, get 1, run 1, get 2, run 2, get 3, run 3. TestCaseIndex is 1-based; TestCaseIdentifier is the list entry unchanged
//    (spaces, upper case, non-ASCII, 155 characters all pass through). DataSetIdentifier is the second attribute argument.
//    Two procedures that name the same source and data set call it twice (the list is not cached across procedures).
//    The ITestContext that GetTestCase returns is what the test procedure receives (Context as <own interface> works).
// 3. Results: one result per case, NAMED '<procedure name>[<case identifier>]', for example 'Rows[alpha]' or 'Id_space[ padded ]'.
//    A procedure whose data set is empty produces NO result at all (no pass, no failure, the body does not run).
// 4. State: the codeunit instance and its global variables are shared by all cases of a codeunit (a counter kept in a global grew 2, 4, 6
//    over three cases); database writes of one case are visible to the next case (rows before the cases: 0, 1, 2). HandlerFunctions work per
//    case (MessageHandler and ConfirmHandler ran for every case).
// 5. Identifier rules, checked when the list is read: the whole procedure then ends with ONE failed result named after the procedure
//    (no brackets) and none of its cases run. The message texts are quoted in the red section below. Rules: not blank (empty and spaces only),
//    no '[' or ']', no duplicate. 'same' and 'Same' are different identifiers (both ran).
// 6. A failing case fails only its own result ('Rows[beta]' with the test's error text); the other cases run. An error in GetTestCase fails the
//    result of that case with the error text and the test does not run for it; later cases still run.
// 7. An error raised in ListTestCases, and a call of DataSourceContext.AppId() or CodeunitId() in ListTestCases or GetTestCase, end the
//    session: "session killed twice by this codeunit: hub connection closed", and no result is reported for the codeunit's data-driven
//    procedures. More: a source codeunit whose ListTestCases merely CONTAINS such a context call (in a branch that the data set never reaches)
//    ended the session of every codeunit that uses it. So the context members cannot be called from a data source at all on this runner.
//    The crash that the Linux CI logged for the old probe BiTestDataSource.al is this behavior, not a Linux fault: that probe calls
//    context.CodeunitId() in both methods. (tests/al-language/lt-ac/ACContexts.al: outside a handler these calls end the session.)
// 8. NavApp.GetResourceAsText with TextEncoding::UTF8 keeps the file's characters (a UTF-8 BOM stays as U+FEFF, length +1); without an
//    encoding, the bytes are read as single-byte characters (the UTF-8 pair of a German umlaut counts as two characters). NavApp.GetResource
//    without an encoding hands the raw bytes to the InStream. ListResources() returns the file names, folder prefix removed.
// 9. TestPermissions = Restrictive: the sandbox has no Permissions Mock; reading a table was not blocked in a plain or a data-driven test.
//    Not pinned.
// The names in (3) and the failures in (5) to (7) cannot be asserted from AL: the red part below (symbol LTBI_TESTDATASOURCE_PROBE, which no
// CI leg defines) reproduces them. The Linux status of the part that is compiled: see the corpus CI of the pull request that added this file.
#if BC29PLUS

interface "LT BI DD Case Data"
{
    procedure CaseText(): Text;
}

codeunit 81600 "LT BI DD Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Peek(): Text
    begin
        exit(Entries);
    end;
}

codeunit 81601 "LT BI DD Case" implements ITestContext, "LT BI DD Case Data"
{
    var
        Value: Text;

    procedure SetText(NewValue: Text)
    begin
        Value := NewValue;
    end;

    procedure CaseText(): Text
    begin
        exit(Value);
    end;
}

// Data sets: Set1 (alpha, beta, gamma), Empty (no case), Ids (identifiers that pass through unchanged).
codeunit 81602 "LT BI DD Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Log: Codeunit "LT BI DD Log";
        IdList: Codeunit "LT BI DD Id List";
        Cases: List of [Text];
    begin
        Log.Reset();
        Log.Add('list(' + DataSetIdentifier + ')');
        case DataSetIdentifier of
            'Set1':
                begin
                    Cases.Add('alpha');
                    Cases.Add('beta');
                    Cases.Add('gamma');
                end;
            'Ids':
                IdList.IdList(Cases);
        end;
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        Log: Codeunit "LT BI DD Log";
        TestCase: Codeunit "LT BI DD Case";
    begin
        Log.Add('get(' + DataSetIdentifier + ',' + Format(TestCaseIndex) + ',' + TestCaseIdentifier + ')');
        TestCase.SetText(TestCaseIdentifier);
        exit(TestCase);
    end;
}

codeunit 81612 "LT BI DD Id List"
{
    procedure IdList(var Cases: List of [Text])
    var
        Umlaut: Text[1];
        Han: Text[1];
    begin
        Umlaut[1] := 228;
        Han[1] := 26085;
        Cases.Add('same');
        Cases.Add('Same');
        Cases.Add(' padded ');
        Cases.Add(Umlaut + ' ' + Han);
        Cases.Add('long ' + PadStr('', 150, 'x'));
    end;
}

codeunit 81603 "LT BI DD Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [TestDataSource(81602, 'Set1')]
    procedure Rows(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI DD Log";
        CaseData: Interface "LT BI DD Case Data";
        Id: Text;
    begin
        CaseData := Context as "LT BI DD Case Data";
        Id := CaseData.CaseText();
        // list once, then get and run alternate, indexes start at 1
        case Id of
            'alpha':
                Assert.AreEqual('list(Set1);get(Set1,1,alpha);', Log.Peek(), 'calls before the first case');
            'beta':
                Assert.AreEqual('list(Set1);get(Set1,1,alpha);run(alpha);get(Set1,2,beta);', Log.Peek(), 'calls before the second case');
            'gamma':
                Assert.AreEqual('list(Set1);get(Set1,1,alpha);run(alpha);get(Set1,2,beta);run(beta);get(Set1,3,gamma);', Log.Peek(), 'calls before the third case');
            else
                Assert.Fail('unexpected case ' + Id);
        end;
        Log.Add('run(' + Id + ')');
    end;

    // The old log is replaced only by the next list call: a plain test sees whatever the last data-driven procedure left (nothing asserted).
    [Test]
    procedure BiDd_Plain_Runs()
    begin
        Assert.IsTrue(true, 'a plain test next to a data-driven procedure runs');
    end;
}

codeunit 81604 "LT BI DD Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // An empty data set: the body never runs (it would fail this codeunit) and no result is reported for it.
    [TestDataSource(81602, 'Empty')]
    procedure NoCases(Context: Interface ITestContext)
    begin
        Error('a data set without cases must not run the test procedure');
    end;

    [Test]
    procedure BiDd_Empty_PlainRuns()
    begin
    end;
}

codeunit 81605 "LT BI DD Ids"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Seen: List of [Text];

    // Identifiers reach GetTestCase and the test unchanged, in list order.
    [TestDataSource(81602, 'Ids')]
    procedure Id(Context: Interface ITestContext)
    var
        IdList: Codeunit "LT BI DD Id List";
        CaseData: Interface "LT BI DD Case Data";
        Expected: List of [Text];
    begin
        CaseData := Context as "LT BI DD Case Data";
        IdList.IdList(Expected);
        Assert.AreEqual(Expected.Get(Seen.Count() + 1), CaseData.CaseText(), 'identifier ' + Format(Seen.Count() + 1));
        Seen.Add(CaseData.CaseText());
    end;
}

codeunit 81606 "LT BI DD Flags"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Peek(): Text
    begin
        exit(Entries);
    end;
}

codeunit 81607 "LT BI DD Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [TestDataSource(81602, 'Set1')]
    procedure Zeta(Context: Interface ITestContext)
    var
        Flags: Codeunit "LT BI DD Flags";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        if CaseData.CaseText() = 'gamma' then
            Assert.AreEqual('plain Z;plain A;Alpha alpha;Alpha beta;Alpha gamma;Mid alpha;Mid beta;Mid gamma;Zeta alpha;Zeta beta;', Flags.Peek(),
              'plain tests in declaration order, then data-driven procedures in alphabetical order');
        Flags.Add('Zeta ' + CaseData.CaseText());
    end;

    [Test]
    procedure PlainZ()
    var
        Flags: Codeunit "LT BI DD Flags";
    begin
        Flags.Reset();
        Flags.Add('plain Z');
    end;

    [TestDataSource(81602, 'Set1')]
    procedure Alpha(Context: Interface ITestContext)
    var
        Flags: Codeunit "LT BI DD Flags";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Flags.Add('Alpha ' + CaseData.CaseText());
    end;

    [Test]
    procedure PlainA()
    var
        Flags: Codeunit "LT BI DD Flags";
    begin
        Flags.Add('plain A');
    end;

    [TestDataSource(81602, 'Set1')]
    procedure Mid(Context: Interface ITestContext)
    var
        Flags: Codeunit "LT BI DD Flags";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Flags.Add('Mid ' + CaseData.CaseText());
    end;
}

table 81610 "LT BI DD Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// State shared by the cases of one codeunit: a global variable, a database row, handlers.
codeunit 81608 "LT BI DD State"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerHits: Integer;
        LastMessage: Text;

    [TestDataSource(81602, 'Set1')]
    [HandlerFunctions('MsgHandler,ConfirmHandler')]
    procedure Rows(Context: Interface ITestContext)
    var
        CaseData: Interface "LT BI DD Case Data";
        Row: Record "LT BI DD Row";
        Position: Integer;
        Answer: Boolean;
    begin
        CaseData := Context as "LT BI DD Case Data";
        case CaseData.CaseText() of
            'alpha':
                Position := 1;
            'beta':
                Position := 2;
            'gamma':
                Position := 3;
        end;
        // Both the global variable and the table keep their values from case to case.
        Assert.AreEqual((Position - 1) * 2, HandlerHits, 'handler hits before case ' + Format(Position));
        Assert.AreEqual(Position - 1, Row.Count(), 'rows before case ' + Format(Position));
        Row.Id := Position;
        Row.Insert();
        Message('hello %1', CaseData.CaseText());
        Answer := Confirm('sure?');
        Assert.IsTrue(Answer, 'the confirm handler answered Yes');
        Assert.AreEqual('hello ' + CaseData.CaseText(), LastMessage, 'message of the case');
        Assert.AreEqual(Position * 2, HandlerHits, 'handler hits after case ' + Format(Position));
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        HandlerHits += 1;
        LastMessage := Msg;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        HandlerHits += 1;
        Reply := true;
    end;

    [Test]
    procedure BiDd_State_PlainRuns()
    begin
    end;
}

// Cases read from files that ship in the app (resourceFolders lt-bi-test-framework/res): data set 'json' reads cases.json
// ({"cases":[{"id":..,"value":..}]}), data set 'csv' reads cases.csv (header row id,value; one case per row).
codeunit 81609 "LT BI DD Resource Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
        Ids: List of [Text];
        Values: List of [Text];
        i: Integer;
    begin
        Load(DataSetIdentifier, Ids, Values);
        for i := 1 to Ids.Count() do
            Cases.Add(Ids.Get(i));
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        TestCase: Codeunit "LT BI DD Case";
        Ids: List of [Text];
        Values: List of [Text];
    begin
        Load(DataSetIdentifier, Ids, Values);
        TestCase.SetText(TestCaseIdentifier + '=' + Values.Get(Ids.IndexOf(TestCaseIdentifier)));
        exit(TestCase);
    end;

    local procedure Load(DataSetIdentifier: Text; var Ids: List of [Text]; var Values: List of [Text])
    var
        Json: JsonObject;
        Tok: JsonToken;
        Item: JsonToken;
        Lines: List of [Text];
        Fields: List of [Text];
        Line: Text;
        Lf: Text[1];
        i: Integer;
    begin
        if DataSetIdentifier = 'json' then begin
            Json.ReadFrom(NavApp.GetResourceAsText('cases.json', TextEncoding::UTF8));
            Json.Get('cases', Tok);
            foreach Item in Tok.AsArray() do begin
                Item.AsObject().Get('id', Tok);
                Ids.Add(Tok.AsValue().AsText());
                Item.AsObject().Get('value', Tok);
                Values.Add(Tok.AsValue().AsText());
            end;
            exit;
        end;
        Lf[1] := 10;
        Lines := NavApp.GetResourceAsText('cases.csv', TextEncoding::UTF8).Split(Lf);
        for i := 2 to Lines.Count() do begin
            Line := Lines.Get(i).TrimEnd();
            if Line <> '' then begin
                Fields := Line.Split(',');
                Ids.Add(Fields.Get(1));
                Values.Add(Fields.Get(2));
            end;
        end;
    end;
}

codeunit 81611 "LT BI DD Resource Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [TestDataSource(81609, 'json')]
    procedure FromJson(Context: Interface ITestContext)
    var
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Assert.IsTrue(CaseData.CaseText() in ['first=one', 'second=two', 'third=three ' + UmlautOe()], 'json row ' + CaseData.CaseText());
    end;

    [TestDataSource(81609, 'csv')]
    procedure FromCsv(Context: Interface ITestContext)
    var
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Assert.IsTrue(CaseData.CaseText() in ['first=one', 'second=two', 'third=three ' + UmlautOe()], 'csv row ' + CaseData.CaseText());
    end;

    local procedure UmlautOe(): Text
    var
        Chars: Text[2];
    begin
        Chars[1] := 228;
        Chars[2] := 246;
        exit(Chars);
    end;

    [Test]
    procedure BiDd_Resource_TextEncodings()
    var
        Text1: Text;
    begin
        // cases.csv: "id,value", "first,one", "second,two", "third,three " + a-umlaut + o-umlaut, each line ended by LF: 45 characters.
        Assert.AreEqual(45, StrLen(NavApp.GetResourceAsText('cases.csv', TextEncoding::UTF8)), 'UTF8 length');
        // Without an encoding the two UTF-8 pairs count as four characters.
        Assert.AreEqual(47, StrLen(NavApp.GetResourceAsText('cases.csv')), 'default encoding length');
        // bom.csv starts with a UTF-8 byte order mark: U+FEFF stays in the text.
        Text1 := NavApp.GetResourceAsText('bom.csv', TextEncoding::UTF8);
        Assert.AreEqual(18, StrLen(Text1), 'bom.csv length');
        Assert.AreEqual(65279, FirstChar(Text1), 'bom.csv first character');
        Assert.AreEqual(114, StrLen(NavApp.GetResourceAsText('cases.json')), 'cases.json length');
    end;

    [Test]
    procedure BiDd_Resource_RawStream()
    var
        InS: InStream;
        Line: Text;
        B1: Byte;
        B2: Byte;
        B3: Byte;
        I1: Integer;
        I2: Integer;
        I3: Integer;
    begin
        NavApp.GetResource('cases.csv', InS);
        InS.Read(B1);
        InS.Read(B2);
        InS.Read(B3);
        I1 := B1;
        I2 := B2;
        I3 := B3;
        Assert.AreEqual(105, I1, 'first byte i');
        Assert.AreEqual(100, I2, 'second byte d');
        Assert.AreEqual(44, I3, 'third byte comma');
        Clear(InS);
        NavApp.GetResource('cases.csv', InS, TextEncoding::UTF8);
        InS.ReadText(Line);
        Assert.AreEqual('id,value', Line, 'first line without the line break');
    end;

    [Test]
    procedure BiDd_Resource_List()
    var
        Names: List of [Text];
    begin
        Names := NavApp.ListResources();
        Assert.AreEqual(3, Names.Count(), 'resource count');
        Assert.IsTrue(Names.Contains('bom.csv'), 'bom.csv listed');
        Assert.IsTrue(Names.Contains('cases.csv'), 'cases.csv listed');
        Assert.IsTrue(Names.Contains('cases.json'), 'cases.json listed');
        Names := NavApp.ListResources('*.csv');
        Assert.AreEqual(2, Names.Count(), 'csv resource count');
    end;

    local procedure FirstChar(Value: Text): Integer
    var
        Code: Integer;
    begin
        Code := Value[1];
        exit(Code);
    end;
}
#endif

// Red part: reproduces what cannot be a passing test. Compiled only with the symbol LTBI_TESTDATASOURCE_PROBE, which no CI leg defines.
// Each codeunit shows the reference result in its comment.
#if LTBI_TESTDATASOURCE_PROBE
codeunit 81630 "LT BI DD Red Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        case DataSetIdentifier of
            'ListError':
                Error('list failed');
            'dup':
                begin
                    Cases.Add('same');
                    Cases.Add('same');
                end;
            'blank':
                Cases.Add('   ');
            'bracket':
                Cases.Add('a[b');
            else begin
                Cases.Add('alpha');
                Cases.Add('beta');
                Cases.Add('gamma');
            end;
        end;
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        TestCase: Codeunit "LT BI DD Case";
    begin
        if (DataSetIdentifier = 'GetError') and (TestCaseIndex = 2) then
            Error('get failed');
        TestCase.SetText(TestCaseIdentifier);
        exit(TestCase);
    end;
}

codeunit 81638 "LT BI DD Red Context Source" implements ITestDataSource
{
    procedure ListTestCases(DataSetIdentifier: Text; context: DataSourceContext): List of [Text]
    var
        Cases: List of [Text];
    begin
        case DataSetIdentifier of
            'CodeunitId':
                Cases.Add(Format(context.CodeunitId()));
            'AppId':
                Cases.Add(Format(context.AppId()));
        end;
        exit(Cases);
    end;

    procedure GetTestCase(DataSetIdentifier: Text; TestCaseIndex: Integer; TestCaseIdentifier: Text; context: DataSourceContext): Interface ITestContext
    var
        TestCase: Codeunit "LT BI DD Case";
    begin
        TestCase.SetText(TestCaseIdentifier);
        exit(TestCase);
    end;
}

codeunit 81631 "LT BI DD Red Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Results: Failing[alpha] passed, Failing[beta] failed with "case failed: beta", Failing[gamma] passed.
    [TestDataSource(81630, 'Set')]
    procedure Failing(Context: Interface ITestContext)
    var
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        if CaseData.CaseText() = 'beta' then
            Error('case failed: %1', CaseData.CaseText());
    end;

    // Results: GetError[alpha] passed, GetError[beta] failed with "get failed", GetError[gamma] passed.
    [TestDataSource(81630, 'GetError')]
    procedure GetError(Context: Interface ITestContext)
    begin
    end;

}

codeunit 81635 "LT BI DD Red Dup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One failed result 'Dup': ListTestCases returned the duplicate identifier 'same'. Every test case must have a distinct identifier.
    [TestDataSource(81630, 'dup')]
    procedure Dup(Context: Interface ITestContext)
    begin
    end;

}

codeunit 81636 "LT BI DD Red Blank"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One failed result 'Blank': ListTestCases returned a blank identifier. Every test case must have a non-blank, distinct identifier that contains no square brackets.
    [TestDataSource(81630, 'blank')]
    procedure Blank(Context: Interface ITestContext)
    begin
    end;

}

codeunit 81637 "LT BI DD Red Bracket"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One failed result 'Bracket': ListTestCases returned the identifier 'a[b', which contains a square bracket ('[' or ']'). Test case identifiers must not contain square brackets; they delimit the case name in 'Method[identifier]'.
    [TestDataSource(81630, 'bracket')]
    procedure Bracket(Context: Interface ITestContext)
    begin
    end;
}

// An error in ListTestCases ends the session: "session killed twice by this codeunit: hub connection closed".
codeunit 81632 "LT BI DD Red ListError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(81630, 'ListError')]
    procedure ListError(Context: Interface ITestContext)
    begin
    end;
}

// DataSourceContext.CodeunitId() in ListTestCases ends the session in the same way; so does AppId().
codeunit 81633 "LT BI DD Red CodeunitId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(81638, 'CodeunitId')]
    procedure ContextCall(Context: Interface ITestContext)
    begin
    end;
}

codeunit 81634 "LT BI DD Red AppId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(81638, 'AppId')]
    procedure ContextCall(Context: Interface ITestContext)
    begin
    end;
}
#endif
