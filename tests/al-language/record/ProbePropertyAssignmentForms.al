// Probe: assignment forms of Record / Report / ErrorInfo members (lowering table, probes-needed.md "Property forms").
// Observe-only: every value is recorded through "Probe Observer", the test then fails with OBSERVE:name=value;...
table 69450 "Probe Pf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Sec; Txt) { }
    }

    procedure MarkOnImplicitRec(): Text
    begin
        // unqualified assignment inside the table: acts on the implicit Rec
        Mark := true;
        exit(Format(Mark()) + '/' + Format(Rec.Mark()));
    end;

    procedure MarkedOnlyOnImplicitRec(): Text
    begin
        MarkedOnly := true;
        exit(Format(MarkedOnly) + '/' + Format(Rec.MarkedOnly()));
    end;

    procedure AscendingOnImplicitRec(): Text
    begin
        Ascending := false;
        exit(Format(Ascending) + '/' + Format(Rec.Ascending()));
    end;

    procedure FilterGroupOnImplicitRec(): Text
    begin
        FilterGroup := 3;
        exit(Format(FilterGroup) + '/' + Format(Rec.FilterGroup()));
    end;
}

report 69452 "Probe Pf Report"
{
    ProcessingOnly = true;
    UseRequestPage = true;
}

codeunit 69451 "Probe Property Assign Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "Probe Pf Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Txt := 'row' + Format(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure RecordMark_AssignThenReadBothForms()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(2);
        Row.Mark := true;
        Observer.Observe('markAfterAssignTrue_callForm', Format(Row.Mark()));
        Observer.Observe('markAfterAssignTrue_propertyForm', Format(Row.Mark));
        Row.Mark(false);
        Observer.Observe('markAfterCallFalse_propertyForm', Format(Row.Mark));
        Row.Mark(true);
        Row.Get(1);
        Observer.Observe('markOfOtherRow', Format(Row.Mark));
        Row.MarkedOnly(true);
        Observer.Observe('markedOnlyCount', Format(Row.Count()));
        Observer.Expect('markAfterAssignTrue_callForm', 'Yes');
        Observer.Expect('markAfterAssignTrue_propertyForm', 'Yes');
        Observer.Expect('markAfterCallFalse_propertyForm', 'No');
        Observer.Expect('markOfOtherRow', 'No');
        Observer.Expect('markedOnlyCount', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RecordMarkedOnly_AssignThenReadBothForms()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Row.Mark(true);
        Row.Get(3);
        Row.Mark(true);
        Row.MarkedOnly := true;
        Observer.Observe('countAfterAssignTrue', Format(Row.Count()));
        Observer.Observe('markedOnlyPropertyForm', Format(Row.MarkedOnly));
        Observer.Observe('markedOnlyCallForm', Format(Row.MarkedOnly()));
        Row.MarkedOnly(false);
        Observer.Observe('countAfterCallFalse', Format(Row.Count()));
        Observer.Observe('markedOnlyPropertyFormAfterCallFalse', Format(Row.MarkedOnly));
        Observer.Expect('countAfterAssignTrue', '2');
        Observer.Expect('markedOnlyPropertyForm', 'Yes');
        Observer.Expect('markedOnlyCallForm', 'Yes');
        Observer.Expect('countAfterCallFalse', '3');
        Observer.Expect('markedOnlyPropertyFormAfterCallFalse', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RecordAscending_AssignThenReadBothForms()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('defaultAscending', Format(Row.Ascending));
        Row.Ascending := false;
        Row.FindFirst();
        Observer.Observe('firstIdAfterAssignFalse', Format(Row.Id));
        Observer.Observe('ascendingPropertyForm', Format(Row.Ascending));
        Observer.Observe('ascendingCallForm', Format(Row.Ascending()));
        Row.Ascending(true);
        Row.FindFirst();
        Observer.Observe('firstIdAfterCallTrue', Format(Row.Id));
        Observer.Observe('ascendingPropertyFormAfterCallTrue', Format(Row.Ascending));
        Observer.Expect('defaultAscending', 'Yes');
        Observer.Expect('firstIdAfterAssignFalse', '3');
        Observer.Expect('ascendingPropertyForm', 'No');
        Observer.Expect('ascendingCallForm', 'No');
        Observer.Expect('firstIdAfterCallTrue', '1');
        Observer.Expect('ascendingPropertyFormAfterCallTrue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFilterGroup_AssignThenReadBothForms()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('defaultFilterGroup', Format(Row.FilterGroup));
        Row.FilterGroup := 2;
        Row.SetRange(Id, 1);
        Observer.Observe('propertyFormAfterAssign2', Format(Row.FilterGroup));
        Observer.Observe('callFormAfterAssign2', Format(Row.FilterGroup()));
        Row.FilterGroup := 0;
        Observer.Observe('countInGroup0', Format(Row.Count()));
        Observer.Observe('filterTextInGroup0', Row.GetFilters());
        Row.FilterGroup(2);
        Observer.Observe('countInGroup2', Format(Row.Count()));
        Observer.Observe('filterTextInGroup2', Row.GetFilters());
        Observer.Expect('defaultFilterGroup', '0');
        Observer.Expect('propertyFormAfterAssign2', '2');
        Observer.Expect('callFormAfterAssign2', '2');
        Observer.Expect('countInGroup0', '1');
        Observer.Expect('filterTextInGroup0', '');
        Observer.Expect('countInGroup2', '1');
        Observer.Expect('filterTextInGroup2', 'Id: 1');
        Observer.Verify();
    end;

    [Test]
    procedure TableCode_UnqualifiedMarkAssignment_ActsOnImplicitRec()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('markOnImplicitRec', Row.MarkOnImplicitRec());
        Observer.Observe('markOfCallerAfter', Format(Row.Mark()));
        Observer.Expect('markOnImplicitRec', 'Yes/Yes');
        Observer.Expect('markOfCallerAfter', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TableCode_UnqualifiedMarkedOnlyAscendingFilterGroupAssignment()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('markedOnlyOnImplicitRec', Row.MarkedOnlyOnImplicitRec());
        Observer.Observe('ascendingOnImplicitRec', Row.AscendingOnImplicitRec());
        Observer.Observe('filterGroupOnImplicitRec', Row.FilterGroupOnImplicitRec());
        Observer.Observe('callerFilterGroupAfter', Format(Row.FilterGroup()));
        Observer.Expect('markedOnlyOnImplicitRec', 'Yes/Yes');
        Observer.Expect('ascendingOnImplicitRec', 'No/No');
        Observer.Expect('filterGroupOnImplicitRec', '3/3');
        Observer.Expect('callerFilterGroupAfter', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Report_UseRequestPage_AssignThenReadBothForms()
    var
        Rep: Report "Probe Pf Report";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Rep.UseRequestPage()));
        Rep.UseRequestPage := false;
        Observer.Observe('propertyFormAfterAssignFalse', Format(Rep.UseRequestPage));
        Observer.Observe('callFormAfterAssignFalse', Format(Rep.UseRequestPage()));
        Rep.UseRequestPage(true);
        Observer.Observe('propertyFormAfterCallTrue', Format(Rep.UseRequestPage));
        Observer.Expect('default', 'Yes');
        Observer.Expect('propertyFormAfterAssignFalse', 'No');
        Observer.Expect('callFormAfterAssignFalse', 'No');
        Observer.Expect('propertyFormAfterCallTrue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WorkDate_AssignThenReadBothForms()
    var
        Observer: Codeunit "Probe Observer";
        Original: Date;
    begin
        Original := WorkDate();
        WorkDate := DMY2Date(15, 3, 2031);
        Observer.Observe('assignedPropertyForm', Format(WorkDate, 0, 9));
        Observer.Observe('assignedCallForm', Format(WorkDate(), 0, 9));
        WorkDate(DMY2Date(1, 2, 2032));
        Observer.Observe('afterCallForm', Format(WorkDate, 0, 9));
        WorkDate(Original);
        Observer.Expect('assignedPropertyForm', '2031-03-15');
        Observer.Expect('assignedCallForm', '2031-03-15');
        Observer.Expect('afterCallForm', '2032-02-01');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_TextProperties_AssignThenReadBothForms()
    var
        Err: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Err := ErrorInfo.Create();
        Err.Message := 'msg-assigned';
        Err.DetailedMessage := 'detail-assigned';
        Err.Title := 'title-assigned';
        Observer.Observe('message_callForm', Err.Message());
        Observer.Observe('message_propertyForm', Err.Message);
        Observer.Observe('detailedMessage_callForm', Err.DetailedMessage());
        Observer.Observe('title_callForm', Err.Title());
        Err.Message('msg-call');
        Observer.Observe('message_propertyFormAfterCall', Err.Message);
        Observer.Expect('message_callForm', 'msg-assigned');
        Observer.Expect('message_propertyForm', 'msg-assigned');
        Observer.Expect('detailedMessage_callForm', 'detail-assigned');
        Observer.Expect('title_callForm', 'title-assigned');
        Observer.Expect('message_propertyFormAfterCall', 'msg-call');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_NumericProperties_AssignThenReadBothForms()
    var
        Err: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Err := ErrorInfo.Create();
        Observer.Observe('default_fieldNo', Format(Err.FieldNo()));
        Observer.Observe('default_pageNo', Format(Err.PageNo()));
        Observer.Observe('default_tableId', Format(Err.TableId()));
        Observer.Observe('default_controlName', Err.ControlName());
        Err.FieldNo := 2;
        Err.PageNo := 21;
        Err.TableId := 18;
        Err.ControlName := 'Name';
        Observer.Observe('fieldNo', Format(Err.FieldNo()));
        Observer.Observe('pageNo', Format(Err.PageNo()));
        Observer.Observe('tableId', Format(Err.TableId()));
        Observer.Observe('controlName', Err.ControlName());
        Observer.Expect('default_fieldNo', '0');
        Observer.Expect('default_pageNo', '0');
        Observer.Expect('default_tableId', '0');
        Observer.Expect('default_controlName', '');
        Observer.Expect('fieldNo', '2');
        Observer.Expect('pageNo', '21');
        Observer.Expect('tableId', '18');
        Observer.Expect('controlName', 'Name');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_EnumProperties_AssignThenReadBothForms()
    var
        Err: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Err := ErrorInfo.Create();
        Observer.Observe('default_verbosity', Format(Err.Verbosity()));
        Observer.Observe('default_dataClassification', Format(Err.DataClassification()));
        Observer.Observe('default_collectible', Format(Err.Collectible()));
        Observer.Observe('default_errorType', Format(Err.ErrorType()));
        Err.Verbosity := Verbosity::Warning;
        Err.DataClassification := DataClassification::SystemMetadata;
        Err.Collectible := true;
        Err.ErrorType := ErrorType::Client;
        Observer.Observe('verbosity', Format(Err.Verbosity()));
        Observer.Observe('dataClassification', Format(Err.DataClassification()));
        Observer.Observe('collectible', Format(Err.Collectible()));
        Observer.Observe('errorType', Format(Err.ErrorType()));
        Observer.Expect('default_verbosity', 'Error');
        Observer.Expect('default_dataClassification', 'CustomerContent');
        Observer.Expect('default_collectible', 'Yes');
        Observer.Expect('default_errorType', 'Client');
        Observer.Expect('verbosity', 'Warning');
        Observer.Expect('dataClassification', 'SystemMetadata');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('errorType', 'Client');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_CustomDimensions_Assign()
    var
        Err: ErrorInfo;
        Dims: Dictionary of [Text, Text];
        Observer: Codeunit "Probe Observer";
    begin
        Err := ErrorInfo.Create();
        Dims.Add('k', 'v');
        Err.CustomDimensions := Dims;
        Observer.Observe('count', Format(Err.CustomDimensions().Count()));
        Observer.Observe('value', Err.CustomDimensions().Get('k'));
        Dims.Add('k2', 'v2');
        Observer.Observe('countAfterSourceChanged', Format(Err.CustomDimensions().Count()));
        Observer.Expect('count', '1');
        Observer.Expect('value', 'v');
        Observer.Expect('countAfterSourceChanged', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_RecordId_AssignAndDefault()
    var
        Err: ErrorInfo;
        Row: Record "Probe Pf Row";
        Rid: RecordId;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(2);
        Err := ErrorInfo.Create();
        Observer.Observe('default_recordId', Format(Err.RecordId()));
        Observer.Observe('default_tableId', Format(Err.TableId()));
        Rid := Row.RecordId();
        Err.RecordId := Rid;
        Observer.Observe('recordId', Format(Err.RecordId()));
        Observer.Observe('tableIdAfterAssign', Format(Err.TableId()));
        Observer.Expect('default_recordId', '');
        Observer.Expect('default_tableId', '0');
        Observer.Expect('recordId', 'Probe Pf Row: 2');
        Observer.Expect('tableIdAfterAssign', '0');
        Observer.Verify();
    end;

    // al-runner 6526 (writer Y29): `X.M := v` compiles for any built-in method M with exactly one overload that takes one
    // required parameter (alc 18.1 with runtime 16.0 and alc 30 with runtime 18.0 alike) and is checked as M(v); the
    // refused shapes are tests/must-not-compile/cases/2365-2372. These tests read back what the assignment form did.
    [Test]
    procedure Y29_HttpClient_AssignForms()
    var
        C: HttpClient;
        Observer: Codeunit "Probe Observer";
    begin
        C.Timeout := 5000;
        Observer.Observe('timeout', Format(C.Timeout()));
        C.Timeout := C.Timeout;
        Observer.Observe('timeout_self', Format(C.Timeout));
        C.SetBaseAddress := 'https://example.com/y29/';
        Observer.Observe('baseAddress', C.GetBaseAddress());
        C.UseResponseCookies := true;
        Observer.Observe('useResponseCookies', 'ran');
        Observer.Expect('timeout', '5 seconds');
        Observer.Expect('timeout_self', '5 seconds');
        Observer.Expect('baseAddress', 'https://example.com/y29/');
        Observer.Expect('useResponseCookies', 'ran');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_HttpRequestMessage_AssignForms()
    var
        R: HttpRequestMessage;
        Ct: HttpContent;
        Body: Text;
        Observer: Codeunit "Probe Observer";
    begin
        R.Method := 'POST';
        Observer.Observe('method', R.Method());
        R.SetRequestUri := 'https://example.com/y29?b=1';
        Observer.Observe('requestUri', R.GetRequestUri());
        Ct.WriteFrom('body-y29');
        R.Content := Ct;
        R.Content().ReadAs(Body);
        Observer.Observe('content', Body);
        Observer.Expect('method', 'POST');
        Observer.Expect('requestUri', 'https://example.com/y29?b=1');
        Observer.Expect('content', 'body-y29');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_XmlNodes_AssignForms()
    var
        A: XmlAttribute;
        Tx: XmlText;
        Cm: XmlComment;
        Cd: XmlCData;
        Decl: XmlDeclaration;
        E: XmlElement;
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        A := XmlAttribute.Create('a', '1');
        A.Value := '2';
        Observer.Observe('attribute', A.Value());
        Tx := XmlText.Create('t');
        Tx.Value := 'u';
        Observer.Observe('text', Tx.Value());
        Cm := XmlComment.Create('c');
        Cm.Value := 'd';
        Observer.Observe('comment', Cm.Value());
        Cd := XmlCData.Create('x');
        Cd.Value := 'y';
        Observer.Observe('cdata', Cd.Value());
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Decl.Version := '1.0';
        Decl.Encoding := 'utf-16';
        Decl.Standalone := 'no';
        Observer.Observe('declaration', Decl.Version() + '|' + Decl.Encoding() + '|' + Decl.Standalone());
        E := XmlElement.Create('e');
        E.Add := 'txt-y29';
        E.WriteTo(Xml);
        Observer.Observe('element_add', E.InnerText() + '|' + Xml);
        Observer.Expect('attribute', '2');
        Observer.Expect('text', 'u');
        Observer.Expect('comment', 'd');
        Observer.Expect('cdata', 'y');
        Observer.Expect('declaration', '1.0|utf-16|no');
        Observer.Expect('element_add', 'txt-y29|<e>txt-y29</e>');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_XmlOptions_AssignForms()
    var
        WO: XmlWriteOptions;
        RO: XmlReadOptions;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('write_default', Format(WO.PreserveWhitespace()));
        WO.PreserveWhitespace := true;
        Observer.Observe('write', Format(WO.PreserveWhitespace()));
        Observer.Observe('read_default', Format(RO.PreserveWhitespace()));
        RO.PreserveWhitespace := true;
        Observer.Observe('read', Format(RO.PreserveWhitespace()));
        Observer.Expect('write_default', 'No');
        Observer.Expect('write', 'Yes');
        Observer.Expect('read_default', 'No');
        Observer.Expect('read', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_TextBuilder_AssignForms()
    var
        B: TextBuilder;
        Observer: Codeunit "Probe Observer";
    begin
        B.Append := 'abc';
        B.Append := 'def';
        Observer.Observe('append', B.ToText());
        B.Length := 2;
        Observer.Observe('length', B.ToText() + '|' + Format(B.Length()));
        B.Capacity := 200;
        Observer.Observe('capacity', Format(B.Capacity()));
        Observer.Expect('append', 'abcdef');
        Observer.Expect('length', 'ab|2');
        Observer.Expect('capacity', '200');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_Notification_AssignForms()
    var
        N: Notification;
        G: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        N.Message := 'm-y29';
        Observer.Observe('message', N.Message());
        N.Scope := NotificationScope::LocalScope;
        Observer.Observe('scope', Format(N.Scope()));
        Evaluate(G, '{29292929-0000-0000-0000-000000006526}');
        N.Id := G;
        Observer.Observe('id', Format(N.Id()));
        Observer.Expect('message', 'm-y29');
        Observer.Expect('scope', 'LocalScope');
        Observer.Expect('id', '{29292929-0000-0000-0000-000000006526}');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_RecordRef_FilterPage_Session_AssignForms()
    var
        RR: RecordRef;
        F: FilterPageBuilder;
        S: SessionSettings;
        Observer: Codeunit "Probe Observer";
    begin
        RR.Open(Database::"Probe Pf Row");
        RR.CurrentKeyIndex := 2;
        Observer.Observe('currentKeyIndex', Format(RR.CurrentKeyIndex()));
        RR.Close();
        F.PageCaption := 'cap-y29';
        Observer.Observe('pageCaption', F.PageCaption());
        S.Init();
        S.LanguageId := 1031;
        Observer.Observe('languageId', Format(S.LanguageId()));
        Observer.Expect('currentKeyIndex', '2');
        Observer.Expect('pageCaption', 'cap-y29');
        Observer.Expect('languageId', '1031');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_Collections_Text_Sleep_AssignForms()
    var
        L: List of [Integer];
        D: Dictionary of [Integer, Text];
        Txt: Text;
        Dlg: Dialog;
        Observer: Codeunit "Probe Observer";
    begin
        L.Add := 5;
        L.Add := 6;
        Observer.Observe('list', Format(L.Count()) + '|' + Format(L.Get(2)));
        D.Add(1, 'a');
        D.Add(2, 'b');
        D.Remove := 1;
        Observer.Observe('dictionary', Format(D.Count()) + '|' + Format(D.ContainsKey(1)));
        Txt := 'abc';
        Txt.Contains := 'b';
        Observer.Observe('contains', Txt);
        Sleep := 1;
        Observer.Observe('sleep', 'ran');
        Dlg.HideSubsequentDialogs := true;
        Observer.Observe('hideSubsequentDialogs', 'ran');
        Observer.Expect('list', '2|6');
        Observer.Expect('dictionary', '1|No');
        Observer.Expect('contains', 'abc');
        Observer.Expect('sleep', 'ran');
        Observer.Expect('hideSubsequentDialogs', 'ran');
        Observer.Verify();
    end;

    [Test]
    procedure Y29_XmlDocument_GetRoot_AssignForm()
    var
        Doc: XmlDocument;
        E: XmlElement;
        Observer: Codeunit "Probe Observer";
    begin
        XmlDocument.ReadFrom('<root-y29><c/></root-y29>', Doc);
        Doc.GetRoot := E;
        Observer.Observe('getRoot', E.Name());
        Observer.Observe('getRoot_empty', Format(TryGetRootAssign()));
        Observer.ObserveError('getRoot_empty');
        Observer.Expect('getRoot', 'root-y29');
        Observer.Expect('getRoot_empty', 'No');
        Observer.Expect('getRoot_empty|text', 'The XML node is not set.');
        Observer.Expect('getRoot_empty|code', 'XmlNodeNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetRootAssign()
    var
        Doc: XmlDocument;
        E: XmlElement;
    begin
        Doc := XmlDocument.Create();
        Doc.GetRoot := E;
    end;

    [Test]
    procedure Y29_Record_AssignForms()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get := 2;
        Observer.Observe('get', Format(Row.Id) + '|' + Row.Txt);
        Observer.Observe('get_missing_assign', Format(TryGetAssign(99)));
        Observer.ObserveError('get_missing_assign');
        Observer.Observe('get_missing_call', Format(TryGetCall(99)));
        Observer.ObserveError('get_missing_call');
        Row.ReadIsolation := IsolationLevel::ReadCommitted;
        Observer.Observe('readIsolation', Format(Row.ReadIsolation()));
        Row.SecurityFiltering := SecurityFilter::Filtered;
        Observer.Observe('securityFiltering', Format(Row.SecurityFiltering()));
        Observer.Expect('get', '2|row2');
        Observer.Expect('get_missing_assign', 'No');
        Observer.Expect('get_missing_assign|text', 'The Probe Pf Row does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('get_missing_assign|code', 'DB:RecordNotFound');
        Observer.Expect('get_missing_call', 'No');
        Observer.Expect('get_missing_call|text', 'The Probe Pf Row does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('get_missing_call|code', 'DB:RecordNotFound');
        Observer.Expect('readIsolation', 'ReadCommitted');
        Observer.Expect('securityFiltering', 'Filtered');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetAssign(Id: Integer)
    var
        Row: Record "Probe Pf Row";
    begin
        Row.Get := Id;
    end;

    [TryFunction]
    local procedure TryGetCall(Id: Integer)
    var
        Row: Record "Probe Pf Row";
    begin
        Row.Get(Id);
    end;

    [Test]
    procedure Y29_OwnProcedure_AssignForms()
    var
        Target: Codeunit "LT Y29 Assign Target";
        Observer: Codeunit "Probe Observer";
    begin
        Target.SetCounter := 7;
        Observer.Observe('member', Format(Target.Counter()));
        Observer.Observe('unqualified', Format(Target.RunUnqualified()));
        Target.SetAndAnswer := 3;
        Observer.Observe('withReturnValue', Format(Target.Counter()));
        Observer.Expect('member', '7');
        Observer.Expect('unqualified', '8');
        Observer.Expect('withReturnValue', '30');
        Observer.Verify();
    end;

    // Writer Y36 (gap cycle 3, C3-09): the assignment form on a RecordRef (Mark, MarkedOnly, Ascending, FilterGroup,
    // SecurityFiltering, ReadIsolation, ChangeCompany) and on a FieldRef (Validate), next to the call form. Compile (alc 18.1
    // runtime 16.0 and alc 30 runtime 18.0, same result): these compile; RecordRef.LockTable := and ReadConsistency := (AL0129),
    // FieldRef.SetRange := (AL0129) and FieldRef.SetFilter := (AL0135) do not (must-not-compile cases 2501 to 2504).
    // BC (SaaS BC 29): every assignment form does what the call form does: marks set by RR.Mark := true in a loop on a var RecordRef
    // are seen by MarkedOnly(true) (2 of 4 rows) and kept by Duplicate() and a copy; MarkedOnly := true with no marks finds 0 rows.
    local procedure Y36SeedRows()
    var
        Row: Record "Probe Pf Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 4 do begin
            Row.Init();
            Row.Id := I;
            Row.Txt := CopyStr('dcba', I, 1);
            Row.Insert();
        end;
    end;

    local procedure Y36SetMarks(var RR: RecordRef; Value: Boolean)
    begin
        if RR.FindSet() then
            repeat
                RR.Mark := Value;
            until RR.Next() = 0;
    end;

    local procedure Y36Ids(var RR: RecordRef): Text
    var
        Result: Text;
    begin
        if RR.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(RR.Field(1).Value());
            until RR.Next() = 0;
        exit(Format(RR.Count()) + ':' + Result);
    end;

    [Test]
    procedure Y36_RecordRef_Mark_AssignInLoop_ThenMarkedOnly()
    var
        RR: RecordRef;
        FR: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Y36SeedRows();
        RR.Open(Database::"Probe Pf Row");
        FR := RR.Field(1);
        FR.SetRange(2, 3);
        Y36SetMarks(RR, true);
        FR.SetRange();
        Observer.Observe('all_rows_before_markedonly', Y36Ids(RR));
        RR.MarkedOnly(true);
        Observer.Observe('markedonly_call_true', Y36Ids(RR));
        RR.MarkedOnly := false;
        Observer.Observe('markedonly_assign_false', Y36Ids(RR));
        Observer.Observe('markedonly_getter_after_assign_false', Format(RR.MarkedOnly()));
        RR.MarkedOnly := true;
        Observer.Observe('markedonly_assign_true', Y36Ids(RR));
        Observer.Observe('markedonly_getter_after_assign_true', Format(RR.MarkedOnly()));
        RR.MarkedOnly(false);
        FR.SetRange(3);
        Y36SetMarks(RR, false);
        FR.SetRange();
        RR.MarkedOnly(true);
        Observer.Observe('markedonly_after_unmark_3', Y36Ids(RR));
        RR.Close();
        Observer.Expect('all_rows_before_markedonly', '4:1,2,3,4');
        Observer.Expect('markedonly_call_true', '2:2,3');
        Observer.Expect('markedonly_assign_false', '4:1,2,3,4');
        Observer.Expect('markedonly_getter_after_assign_false', 'No');
        Observer.Expect('markedonly_assign_true', '2:2,3');
        Observer.Expect('markedonly_getter_after_assign_true', 'Yes');
        Observer.Expect('markedonly_after_unmark_3', '1:2');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_RecordRef_Mark_AssignThenReadBothForms()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Y36SeedRows();
        RR.Open(Database::"Probe Pf Row");
        RR.FindFirst();
        Observer.Observe('mark_initial', Format(RR.Mark()));
        RR.Mark := true;
        Observer.Observe('mark_after_assign_true', Format(RR.Mark()));
        RR.Mark(false);
        Observer.Observe('mark_after_call_false', Format(RR.Mark()));
        RR.Mark := true;
        RR.Mark := false;
        Observer.Observe('mark_after_assign_true_then_false', Format(RR.Mark()));
        RR.Next();
        RR.Mark := false;
        Observer.Observe('mark_assign_false_on_unmarked', Format(RR.Mark()));
        RR.MarkedOnly(true);
        Observer.Observe('markedonly_after_all_cleared', Y36Ids(RR));
        RR.Close();
        Observer.Expect('mark_initial', 'No');
        Observer.Expect('mark_after_assign_true', 'Yes');
        Observer.Expect('mark_after_call_false', 'No');
        Observer.Expect('mark_after_assign_true_then_false', 'No');
        Observer.Expect('mark_assign_false_on_unmarked', 'No');
        Observer.Expect('markedonly_after_all_cleared', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_RecordRef_Ascending_MarkedOnly_Assign()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Y36SeedRows();
        RR.Open(Database::"Probe Pf Row");
        Observer.Observe('ascending_initial', Format(RR.Ascending()));
        RR.Ascending := false;
        Observer.Observe('ascending_after_assign_false', Format(RR.Ascending()));
        RR.FindFirst();
        Observer.Observe('findfirst_descending', Format(RR.Field(1).Value()));
        RR.CurrentKeyIndex := 2;
        RR.Ascending := true;
        RR.FindFirst();
        Observer.Observe('findfirst_key2_ascending', Format(RR.Field(1).Value()) + ' ' + Format(RR.Field(2).Value()));
        RR.Ascending := false;
        RR.FindFirst();
        Observer.Observe('findfirst_key2_descending', Format(RR.Field(1).Value()) + ' ' + Format(RR.Field(2).Value()));
        RR.Close();
        RR.Open(Database::"Probe Pf Row");
        RR.MarkedOnly := true;
        Observer.Observe('markedonly_assign_no_marks', Y36Ids(RR));
        Observer.Observe('markedonly_getter_no_marks', Format(RR.MarkedOnly()));
        RR.Close();
        Observer.Expect('ascending_initial', 'Yes');
        Observer.Expect('ascending_after_assign_false', 'No');
        Observer.Expect('findfirst_descending', '4');
        Observer.Expect('findfirst_key2_ascending', '4 a');
        Observer.Expect('findfirst_key2_descending', '1 d');
        Observer.Expect('markedonly_assign_no_marks', '0:');
        Observer.Expect('markedonly_getter_no_marks', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_RecordRef_Mark_AfterDuplicate()
    var
        RR: RecordRef;
        RR2: RecordRef;
        RR3: RecordRef;
        FR: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Y36SeedRows();
        RR.Open(Database::"Probe Pf Row");
        FR := RR.Field(1);
        FR.SetRange(1, 2);
        Y36SetMarks(RR, true);
        FR.SetRange();
        RR2 := RR.Duplicate();
        RR2.MarkedOnly(true);
        Observer.Observe('duplicate_markedonly', Y36Ids(RR2));
        RR3 := RR;
        RR3.MarkedOnly := true;
        Observer.Observe('copy_markedonly', Y36Ids(RR3));
        Observer.Observe('original_markedonly_after_copy', Format(RR.MarkedOnly()));
        RR.Close();
        Observer.Expect('duplicate_markedonly', '2:1,2');
        Observer.Expect('copy_markedonly', '2:1,2');
        Observer.Expect('original_markedonly_after_copy', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_RecordRef_Other_AssignForms()
    var
        RR: RecordRef;
        FR: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Y36SeedRows();
        RR.Open(Database::"Probe Pf Row");
        RR.FilterGroup := 2;
        Observer.Observe('filtergroup', Format(RR.FilterGroup()));
        RR.FilterGroup := 0;
        RR.SecurityFiltering := SecurityFilter::Filtered;
        Observer.Observe('securityfiltering', Format(RR.SecurityFiltering()));
        RR.ReadIsolation := IsolationLevel::ReadCommitted;
        Observer.Observe('readisolation', Format(RR.ReadIsolation()));
        Observer.Observe('changecompany_result_before', Format(RR.CurrentCompany() = CompanyName()));
        RR.ChangeCompany := CompanyName();
        Observer.Observe('changecompany_same', Format(RR.CurrentCompany() = CompanyName()) + ' ' + Format(RR.Count()));
        RR.FindFirst();
        FR := RR.Field(2);
        FR.Validate := 'v';
        Observer.Observe('fieldref_validate_assign', Format(FR.Value()));
        FR.Value := 'w';
        Observer.Observe('fieldref_value_assign', Format(FR.Value()));
        RR.Close();
        Observer.Expect('filtergroup', '2');
        Observer.Expect('securityfiltering', 'Filtered');
        Observer.Expect('readisolation', 'ReadCommitted');
        Observer.Expect('changecompany_result_before', 'Yes');
        Observer.Expect('changecompany_same', 'Yes 4');
        Observer.Expect('fieldref_validate_assign', 'v');
        Observer.Expect('fieldref_value_assign', 'w');
        Observer.Verify();
    end;

    // al-runner 7597: assignment forms of builtins the right side or the place decides, next to the call form: an overload set whose
    // call without arguments picks an overload with one optional parameter (FindSet, FieldError, Split), Codeunit.Run (an optional `var`
    // parameter), GlobalLanguage, a static member with its type prefix, a bare member in page code, and a field or variable that has the
    // name of a method. Objects 96420 to 96422 are at the end of the file.
    // Values measured on BC 27.5, 28.5 and 29.0 (corpus CI runs 42876663156, 42876712578, 42876759234; identical). The assignment form
    // equals the call form in every cell, with two exceptions that are not calls at all: on a record whose table has a FIELD named Mark,
    // `Mark := true` (bare in table code and on a record variable) writes the field and does not mark the row, while `Mark(true)` marks
    // the row and leaves the field; and a variable named Sleep, Abs or WorkDate takes the assignment. The two page tests are measured on
    // BC 27.5 only (see the comment in each).
    local procedure AcOutcome(Ok: Boolean): Text
    var
        Result: Text;
    begin
        if Ok then
            exit('ok');
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure AcFindSetAssign(var Row: Record "Probe Pf Row"; ForUpdate: Boolean)
    begin
        Row.FindSet := ForUpdate;
    end;

    [TryFunction]
    local procedure AcFindSetCall(var Row: Record "Probe Pf Row"; ForUpdate: Boolean)
    begin
        Row.FindSet(ForUpdate);
    end;

    [Test]
    procedure AssignCall_FindSet_RowsAndEmptyTable()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        Clear(Row);
        Ok := AcFindSetAssign(Row, true);
        Observer.Observe('rows, assign true', AcOutcome(Ok) + ' ' + Format(Row.Id) + ' ' + Row.Txt);
        Clear(Row);
        Row.Ascending(false);
        Ok := AcFindSetAssign(Row, false);
        Observer.Observe('rows descending, assign false', AcOutcome(Ok) + ' ' + Format(Row.Id) + ' ' + Row.Txt);
        Observer.Observe('next after assign', Format(Row.Next()) + ' ' + Format(Row.Id));
        Row.Reset();
        Row.DeleteAll();
        Clear(Row);
        Ok := AcFindSetAssign(Row, true);
        Observer.Observe('empty, assign', AcOutcome(Ok));
        Clear(Row);
        Ok := AcFindSetCall(Row, true);
        Observer.Observe('empty, call', AcOutcome(Ok));
        Observer.Expect('rows, assign true', 'ok 1 row1');
        Observer.Expect('rows descending, assign false', 'ok 3 row3');
        Observer.Expect('next after assign', '1 2');
        Observer.Expect('empty, assign', 'error:The Probe Pf Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('empty, call', 'error:The Probe Pf Row table is empty.|DB:TableIsEmpty');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure AcFieldError(Shape: Integer)
    var
        RR: RecordRef;
        FR: FieldRef;
        Info: ErrorInfo;
    begin
        RR.Open(Database::"Probe Pf Row");
        FR := RR.Field(2);
        Info := ErrorInfo.Create('info text');
        case Shape of
            1:
                FR.FieldError := 'must be probed';
            2:
                FR.FieldError('must be probed');
            3:
                FR.FieldError := Info;
            4:
                FR.FieldError(Info);
        end;
    end;

    [Test]
    procedure AssignCall_FieldRefFieldError_TextAndErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Ok := AcFieldError(1);
        Observer.Observe('text, assign', AcOutcome(Ok));
        Ok := AcFieldError(2);
        Observer.Observe('text, call', AcOutcome(Ok));
        Ok := AcFieldError(3);
        Observer.Observe('errorinfo, assign', AcOutcome(Ok));
        Ok := AcFieldError(4);
        Observer.Observe('errorinfo, call', AcOutcome(Ok));
        Observer.Expect('text, assign', 'error:Txt must be probed in Probe Pf Row Id=''0''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('text, call', 'error:Txt must be probed in Probe Pf Row Id=''0''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('errorinfo, assign', 'error:Txt info text in Probe Pf Row Id=''0''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('errorinfo, call', 'error:Txt info text in Probe Pf Row Id=''0''.|NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure AssignCall_TextSplit_TextAndListOfText()
    var
        Observer: Codeunit "Probe Observer";
        Separators: List of [Text];
        Txt: Text;
    begin
        Txt := 'a,b;c';
        Txt.Split := ',';
        Observer.Observe('after text separator', Txt);
        Separators.Add(',');
        Separators.Add(';');
        Txt.Split := Separators;
        Observer.Observe('after list of separators', Txt);
        Observer.Observe('call form parts', Format(Txt.Split(Separators).Count()));
        Observer.Expect('after text separator', 'a,b;c');
        Observer.Expect('after list of separators', 'a,b;c');
        Observer.Expect('call form parts', '3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure AcRunAssign(var Row: Record "Probe Pf Row")
    var
        Runner: Codeunit "REC AssignCall Runner";
    begin
        Runner.Run := Row;
    end;

    [TryFunction]
    local procedure AcRunCall(var Row: Record "Probe Pf Row")
    var
        Runner: Codeunit "REC AssignCall Runner";
    begin
        Runner.Run(Row);
    end;

    [Test]
    procedure AssignCall_CodeunitRun_RecordArgument()
    var
        Row: Record "Probe Pf Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Row.Id := 1;
        Row.Txt := 'before';
        Ok := AcRunAssign(Row);
        Observer.Observe('assign', AcOutcome(Ok) + ' ' + Row.Txt);
        Row.Id := 2;
        Row.Txt := 'before';
        Ok := AcRunCall(Row);
        Observer.Observe('call', AcOutcome(Ok) + ' ' + Row.Txt);
        Row.Id := 99;
        Row.Txt := 'before';
        Ok := AcRunAssign(Row);
        Observer.Observe('OnRun raises, assign', AcOutcome(Ok) + ' ' + Row.Txt);
        Row.Txt := 'before';
        Ok := AcRunCall(Row);
        Observer.Observe('OnRun raises, call', AcOutcome(Ok) + ' ' + Row.Txt);
        Observer.Expect('assign', 'ok ran 1');
        Observer.Expect('call', 'ok ran 2');
        Observer.Expect('OnRun raises, assign', 'error:runner refuses 99|Dialog before');
        Observer.Expect('OnRun raises, call', 'error:runner refuses 99|Dialog before');
        Observer.Verify();
    end;

    [Test]
    procedure AssignCall_GlobalLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage := 1031;
        Observer.Observe('after assign 1031', Format(GlobalLanguage()));
        GlobalLanguage(1033);
        Observer.Observe('after call 1033', Format(GlobalLanguage()));
        GlobalLanguage := 1031;
        Observer.Observe('after a second assign 1031', Format(GlobalLanguage()));
        GlobalLanguage := Saved;
        Observer.Observe('restored', Format(GlobalLanguage() = Saved));
        Observer.Expect('after assign 1031', '1031');
        Observer.Expect('after call 1033', '1033');
        Observer.Expect('after a second assign 1031', '1031');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AssignCall_StaticMemberWithTypePrefix()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Sub: Codeunit "ALT Manual Event Sub";
        BareSub: Codeunit "ALT Manual Event Sub";
        Observer: Codeunit "Probe Observer";
    begin
        Session.BindSubscription := Sub;
        Publisher.TriggerBefore(1);
        Observer.Observe('bound by Session.BindSubscription :=', Format(Sub.GetFireCount()));
        Session.UnbindSubscription := Sub;
        Publisher.TriggerBefore(2);
        Observer.Observe('after Session.UnbindSubscription :=', Format(Sub.GetFireCount()));
        BindSubscription := BareSub;
        Publisher.TriggerBefore(3);
        Observer.Observe('bound by BindSubscription :=', Format(BareSub.GetFireCount()) + ' ' + Format(BareSub.GetLastEntryNo()));
        UnbindSubscription := BareSub;
        Publisher.TriggerBefore(4);
        Observer.Observe('after UnbindSubscription :=', Format(BareSub.GetFireCount()));
        Observer.Expect('bound by Session.BindSubscription :=', '1');
        Observer.Expect('after Session.UnbindSubscription :=', '1');
        Observer.Expect('bound by BindSubscription :=', '1 3');
        Observer.Expect('after UnbindSubscription :=', '1');
        Observer.Verify();
    end;

    [Test]
    procedure AssignCall_BarePageMembers_Caption()
    var
        Row: Record "Probe Pf Row";
        Card: TestPage "REC AssignCall Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('caption at open', Card.Caption());
        Card.BareCaption.Invoke();
        Observer.Observe('bare Caption :=', Card.Shown.Value() + ' | ' + Card.Caption());
        Card.CurrCaption.Invoke();
        Observer.Observe('CurrPage.Caption :=', Card.Shown.Value() + ' | ' + Card.Caption());
        Card.CallCaption.Invoke();
        Observer.Observe('CurrPage.Caption()', Card.Shown.Value() + ' | ' + Card.Caption());
        Card.Close();
#if BC28PLUS
        // BC 28.5 and 29.0 ended the first run of this test at the first action ("The action with ID = n is not found on the page.",
        // corpus CI runs 42876712578 and 42876759234): the page stated no ApplicationArea then. Not measured again yet.
        Observer.Finish();
#else
        Observer.Expect('caption at open', 'Designed Caption - 1');
        Observer.Expect('bare Caption :=', 'bare y | bare y - 1');
        Observer.Expect('CurrPage.Caption :=', 'curr x | curr x - 1');
        Observer.Expect('CurrPage.Caption()', 'call z | call z - 1');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure AssignCall_BarePageMembers_Update()
    var
        Row: Record "Probe Pf Row";
        Card: TestPage "REC AssignCall Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.AssignUpdateTrue.Invoke();
        Row.Get(1);
        Observer.Observe('CurrPage.Update := true', Row.Txt + ' | ' + Card.Txt.Value());
        Card.CallUpdateTrue.Invoke();
        Row.Get(1);
        Observer.Observe('CurrPage.Update(true)', Row.Txt + ' | ' + Card.Txt.Value());
        Card.BareUpdateFalse.Invoke();
        Row.Get(1);
        Observer.Observe('bare Update := false', Row.Txt + ' | ' + Card.Txt.Value());
        Card.CallUpdateFalse.Invoke();
        Row.Get(1);
        Observer.Observe('CurrPage.Update(false)', Row.Txt + ' | ' + Card.Txt.Value());
        Card.Close();
#if BC28PLUS
        // BC 28.5 and 29.0 ended the first run of this test at the first action ("The action with ID = n is not found on the page.",
        // corpus CI runs 42876712578 and 42876759234): the page stated no ApplicationArea then. Not measured again yet.
        Observer.Finish();
#else
        Observer.Expect('CurrPage.Update := true', 'assign-true | assign-true');
        Observer.Expect('CurrPage.Update(true)', 'call-true | call-true');
        Observer.Expect('bare Update := false', 'call-true | call-true');
        Observer.Expect('CurrPage.Update(false)', 'call-true | call-true');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure AssignCall_FieldNamedLikeMethod()
    var
        Named: Record "REC AssignCall Named";
        Assigned: Record "REC AssignCall Named";
        Called: Record "REC AssignCall Named";
        Observer: Codeunit "Probe Observer";
    begin
        Named.Id := 1;
        Observer.Observe('bare Mark := true in table code', Named.SetBare());
        Assigned.Id := 2;
        Assigned.Mark := true;
        Observer.Observe('Assigned.Mark := true on a record variable', Assigned.FieldAndMark());
        Called.Id := 3;
        Called.Mark(true);
        Observer.Observe('Called.Mark(true)', Called.FieldAndMark());
        Observer.Expect('bare Mark := true in table code', 'field Yes marked No');
        Observer.Expect('Assigned.Mark := true on a record variable', 'field Yes marked No');
        Observer.Expect('Called.Mark(true)', 'field No marked Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AssignCall_VariableNamedLikeBuiltin()
    var
        Observer: Codeunit "Probe Observer";
        Sleep: Integer;
        Abs: Integer;
        WorkDate: Date;
        Before: Date;
    begin
        Before := System.WorkDate();
        Sleep := 5;
        Abs := -1;
        WorkDate := DMY2Date(3, 4, 2031);
        Observer.Observe('Sleep', Format(Sleep));
        Observer.Observe('Abs', Format(Abs));
        Observer.Observe('WorkDate variable', Format(WorkDate, 0, 9));
        Observer.Observe('System.WorkDate unchanged', Format(System.WorkDate() = Before));
        Observer.Expect('Sleep', '5');
        Observer.Expect('Abs', '-1');
        Observer.Expect('WorkDate variable', '2031-04-03');
        Observer.Expect('System.WorkDate unchanged', 'Yes');
        Observer.Verify();
    end;
}

codeunit 92290 "LT Y29 Assign Target"
{
    var
        Value: Integer;

    procedure SetCounter(NewValue: Integer)
    begin
        Value := NewValue;
    end;

    procedure SetAndAnswer(NewValue: Integer): Boolean
    begin
        Value := NewValue * 10;
        exit(true);
    end;

    procedure Counter(): Integer
    begin
        exit(Value);
    end;

    procedure RunUnqualified(): Integer
    begin
        SetCounter := Value + 1;
        exit(Value);
    end;
}

// al-runner 7597 (the AssignCall_ tests of codeunit 69451).
// local object: the codeunit's OnRun and TableNo, the page's own code (bare members act on the page) and the table's field named like a
// method are the subject of the probe.
codeunit 96420 "REC AssignCall Runner"
{
    TableNo = "Probe Pf Row";

    trigger OnRun()
    begin
        if Rec.Id = 99 then
            Error('runner refuses %1', Rec.Id);
        Rec.Txt := 'ran ' + Format(Rec.Id);
    end;
}

page 96421 "REC AssignCall Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Probe Pf Row";
    Caption = 'Designed Caption';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Txt; Rec.Txt) { }
            field(Shown; Shown) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BareCaption)
            {
                trigger OnAction()
                begin
                    Caption := 'bare y';
                    Shown := CurrPage.Caption();
                end;
            }
            action(CurrCaption)
            {
                trigger OnAction()
                begin
                    CurrPage.Caption := 'curr x';
                    Shown := CurrPage.Caption();
                end;
            }
            action(CallCaption)
            {
                trigger OnAction()
                begin
                    CurrPage.Caption('call z');
                    Shown := CurrPage.Caption();
                end;
            }
            action(AssignUpdateTrue)
            {
                trigger OnAction()
                begin
                    Rec.Txt := 'assign-true';
                    CurrPage.Update := true;
                end;
            }
            action(CallUpdateTrue)
            {
                trigger OnAction()
                begin
                    Rec.Txt := 'call-true';
                    CurrPage.Update(true);
                end;
            }
            action(BareUpdateFalse)
            {
                trigger OnAction()
                begin
                    Rec.Txt := 'bare-false';
                    Update := false;
                end;
            }
            action(CallUpdateFalse)
            {
                trigger OnAction()
                begin
                    Rec.Txt := 'call-false';
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Shown: Text;
}

table 96422 "REC AssignCall Named"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mark; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    // Inside the table: the field Mark is written, or the method Mark(true) is called?
    procedure SetBare(): Text
    begin
        Mark := true;
        exit(FieldAndMark());
    end;

    // 'field <value of field 2> marked <Mark()>'.
    procedure FieldAndMark(): Text
    var
        RecRef: RecordRef;
        FieldValue: Boolean;
    begin
        RecRef.GetTable(Rec);
        FieldValue := RecRef.Field(2).Value();
        exit('field ' + Format(FieldValue) + ' marked ' + Format(Rec.Mark()));
    end;
}
