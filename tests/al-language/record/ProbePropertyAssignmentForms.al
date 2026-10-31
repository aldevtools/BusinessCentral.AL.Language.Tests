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
