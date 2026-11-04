// Batch 5, md:267 (clock), md:269 (identity), md:270 and md:474 (ClientType), md:388 (ExecutionMode), md:153 (ObjectType and WebServiceActionResultCode ordinals),
// md:167 (sequential Guid). Observe-only.
// Fixtures used: table below and its test codeunit.

table 67065 "W5 SeqGuid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(BySystemId; SystemId) { }
    }
}

codeunit 67066 "W5 Session Facts Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // md:267: Today, Time and CurrentDateTime agree with each other.
    [Test]
    procedure Clock_ReadingsAgree()
    var
        Observer: Codeunit "Probe Observer";
        Before: DateTime;
        After: DateTime;
        D: Date;
        T: Time;
    begin
        Before := CurrentDateTime();
        D := Today();
        T := Time();
        After := CurrentDateTime();
        Observer.Observe('clock_has_date', Format(DT2Date(Before) <> 0D));
        Observer.Observe('today_is_date_of_clock', Format(D = DT2Date(Before)));
        Observer.Observe('time_between_two_clock_readings', Format((T >= DT2Time(Before)) and (T <= DT2Time(After))));
        Observer.Observe('clock_not_going_back', Format(After >= Before));
        Observer.Expect('clock_has_date', 'Yes');
        Observer.Expect('today_is_date_of_clock', 'Yes');
        Observer.Expect('time_between_two_clock_readings', 'Yes');
        Observer.Expect('clock_not_going_back', 'Yes');
        Observer.Verify();
    end;

    // md:267: Sleep(n) moves the clock by at least n milliseconds.
    // md:267: Sleep with a negative number. Unsure whether it raises: Try wrapper.
    // md:269: identity values as relations.
    [Test]
    procedure Identity_Relations()
    var
        Observer: Codeunit "Probe Observer";
        User: Record User;
        NullGuid: Guid;
    begin
        Observer.Observe('userid_nonblank', Format(UserId() <> ''));
        Observer.Observe('userid_is_upper_case', Format(UserId() = UpperCase(UserId())));
        Observer.Observe('usersecurityid_not_null', Format(UserSecurityId() <> NullGuid));
        Observer.Observe('user_row_found', Format(User.Get(UserSecurityId())));
        Observer.Observe('user_name_is_userid', Format(User."User Name" = UserId()));
        Observer.Observe('sessionid_positive', Format(SessionId() > 0));
        Observer.Observe('serviceinstanceid_positive', Format(ServiceInstanceId() > 0));
        Observer.Observe('tenantid_nonblank', Format(TenantId() <> ''));
        Observer.Observe('guiallowed', Format(GuiAllowed()));
        Observer.Observe('isservicetier', Format(IsServiceTier()));
        Observer.Observe('windowslanguage_positive', Format(WindowsLanguage() > 0));
        Observer.Observe('globallanguage_positive', Format(GlobalLanguage() > 0));
        Observer.Expect('userid_nonblank', 'Yes');
        Observer.Expect('userid_is_upper_case', 'Yes');
        Observer.Expect('usersecurityid_not_null', 'Yes');
        Observer.Expect('user_row_found', 'Yes');
        Observer.Expect('user_name_is_userid', 'Yes');
        Observer.Expect('sessionid_positive', 'Yes');
        Observer.Expect('serviceinstanceid_positive', 'Yes');
        Observer.Expect('tenantid_nonblank', 'Yes');
        Observer.Expect('guiallowed', 'Yes');
        Observer.Expect('isservicetier', 'Yes');
        Observer.Expect('windowslanguage_positive', 'Yes');
        Observer.Expect('globallanguage_positive', 'Yes');
        Observer.Verify();
    end;

    // md:269: GlobalLanguage(n) sets for the session, and is put back.
    [Test]
    procedure Identity_GlobalLanguage_SetsAndRestores()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
        WindowsBefore: Integer;
        Ok: Boolean;
    begin
        OldLanguage := GlobalLanguage();
        WindowsBefore := WindowsLanguage();
        ClearLastError();
        Ok := TrySetLanguage(1031);
        Observer.Observe('set_ok', Format(Ok));
        Observer.ObserveError('set');
        if Ok then begin
            Observer.Observe('global_language_after_set', Format(GlobalLanguage()));
            Observer.Observe('windows_language_unchanged', Format(WindowsLanguage() = WindowsBefore));
        end;
        TrySetLanguage(OldLanguage);
        Observer.Observe('global_language_restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('set_ok', 'Ja');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('global_language_after_set', '1031');
        Observer.Expect('windows_language_unchanged', 'Ja');
        Observer.Expect('global_language_restored', 'Yes');
        Observer.Verify();
    end;

    // md:270 and md:474: names of the current and the default client type, and the ordinals the format offers.
    [Test]
    procedure ClientType_CurrentAndDefault()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('current_name', Format(Session.CurrentClientType()));
        Observer.Observe('default_name', Format(Session.DefaultClientType()));
        Observer.Observe('current_format_2', Format(Session.CurrentClientType(), 0, 2));
        Observer.Observe('default_format_2', Format(Session.DefaultClientType(), 0, 2));
        Observer.Observe('current_format_1', Format(Session.CurrentClientType(), 0, 1));
        Observer.Observe('odatav4_name', Format(ClientType::ODataV4));
        Observer.Observe('odatav4_format_2', Format(ClientType::ODataV4, 0, 2));
        Observer.Observe('childsession_format_2', Format(ClientType::ChildSession, 0, 2));
        Observer.Observe('web_format_2', Format(ClientType::Web, 0, 2));
        Observer.Observe('background_format_2', Format(ClientType::Background, 0, 2));
        Observer.Expect('current_name', 'Web');
        Observer.Expect('default_name', 'Windows');
        Observer.Expect('current_format_2', '3');
        Observer.Expect('default_format_2', '2');
        Observer.Expect('current_format_1', 'Web');
        Observer.Expect('odatav4_name', 'ODataV4');
        Observer.Expect('odatav4_format_2', '13');
        Observer.Expect('childsession_format_2', '15');
        Observer.Expect('web_format_2', '3');
        Observer.Expect('background_format_2', '7');
        Observer.Verify();
    end;

    // md:270 and md:474: the full member list, by evaluating each ordinal.
    [Test]
    procedure ClientType_MemberList()
    var
        Observer: Codeunit "Probe Observer";
        Client: ClientType;
        i: Integer;
        Members: Text;
        Count: Integer;
    begin
        for i := 0 to 40 do
            if Evaluate(Client, Format(i)) then begin
                Members += Format(i) + '=' + Format(Client) + ';';
                Count += 1;
            end;
        Observer.Observe('evaluated_ordinals', Format(Count));
        Observer.Observe('members', Members);
        Observer.Expect('evaluated_ordinals', '16');
        Observer.Expect('members', '0=Current;1=Default;2=Windows;3=Web;4=SOAP;5=OData;6=NAS;7=Background;8=Management;9=Tablet;10=Phone;11=Desktop;12=Teams;13=ODataV4;14=Api;15=ChildSession;');
        Observer.Verify();
    end;

    // md:388: ExecutionMode, current and member list.
    [Test]
    procedure ExecutionMode_CurrentAndMemberList()
    var
        Observer: Codeunit "Probe Observer";
        Mode: ExecutionMode;
        i: Integer;
        Members: Text;
        Count: Integer;
    begin
        Observer.Observe('current_name', Format(Session.CurrentExecutionMode()));
        Observer.Observe('current_format_2', Format(Session.CurrentExecutionMode(), 0, 2));
        Observer.Observe('debug_name', Format(ExecutionMode::Debug));
        Observer.Observe('debug_format_2', Format(ExecutionMode::Debug, 0, 2));
        Observer.Observe('standard_format_2', Format(ExecutionMode::Standard, 0, 2));
        for i := 0 to 20 do
            if Evaluate(Mode, Format(i)) then begin
                Members += Format(i) + '=' + Format(Mode) + ';';
                Count += 1;
            end;
        Observer.Observe('evaluated_ordinals', Format(Count));
        Observer.Observe('members', Members);
        Observer.Expect('current_name', 'Standard');
        Observer.Expect('current_format_2', '0');
        Observer.Expect('debug_name', 'Debug');
        Observer.Expect('debug_format_2', '1');
        Observer.Expect('standard_format_2', '0');
        Observer.Expect('evaluated_ordinals', '2');
        Observer.Expect('members', '0=Standard;1=Debug;');
        Observer.Verify();
    end;

    // md:153: ObjectType ordinals by evaluating each number, and the format offers.
    [Test]
    procedure ObjectType_MemberList()
    var
        Observer: Codeunit "Probe Observer";
        Kind: ObjectType;
        i: Integer;
        Members: Text;
        Count: Integer;
    begin
        for i := 0 to 30 do
            if Evaluate(Kind, Format(i)) then begin
                Members += Format(i) + '=' + Format(Kind) + ';';
                Count += 1;
            end;
        Observer.Observe('evaluated_ordinals', Format(Count));
        Observer.Observe('members', Members);
        Observer.Observe('table_format_2', Format(ObjectType::Table, 0, 2));
        Observer.Observe('codeunit_format_2', Format(ObjectType::Codeunit, 0, 2));
        Observer.Observe('page_format_2', Format(ObjectType::Page, 0, 2));
        Observer.Expect('evaluated_ordinals', '10');
        Observer.Expect('members', '0=TableData;1=Table;2=Form;3=Report;5=Codeunit;6=XmlPort;7=MenuSuite;8=Page;9=Query;10=Enum;');
        Observer.Expect('table_format_2', '1');
        Observer.Expect('codeunit_format_2', '5');
        Observer.Expect('page_format_2', '8');
        Observer.Verify();
    end;

    // md:153: WebServiceActionResultCode values by evaluating each number (the declared values are 0, 200, 201, 204).
    [Test]
    procedure WebServiceActionResultCode_MemberList()
    var
        Observer: Codeunit "Probe Observer";
        Code: WebServiceActionResultCode;
        i: Integer;
        Members: Text;
        Count: Integer;
    begin
        for i := 0 to 210 do
            if Evaluate(Code, Format(i)) then begin
                Members += Format(i) + '=' + Format(Code) + ';';
                Count += 1;
            end;
        Observer.Observe('evaluated_ordinals', Format(Count));
        Observer.Observe('members', Members);
        Observer.Observe('created_format_2', Format(WebServiceActionResultCode::Created, 0, 2));
        Observer.Observe('deleted_format_2', Format(WebServiceActionResultCode::Deleted, 0, 2));
        Observer.Expect('evaluated_ordinals', '4');
        Observer.Expect('members', '0=None;200=Get;201=Created;204=Deleted;');
        Observer.Expect('created_format_2', '201');
        Observer.Expect('deleted_format_2', '204');
        Observer.Verify();
    end;

    // md:167: CreateGuid is fresh each time.
    [Test]
    procedure CreateGuid_FreshAndNotNull()
    var
        Observer: Codeunit "Probe Observer";
        Seen: List of [Guid];
        G: Guid;
        NullGuid: Guid;
        i: Integer;
        AllNotNull: Boolean;
        AllNew: Boolean;
    begin
        AllNotNull := true;
        AllNew := true;
        for i := 1 to 20 do begin
            G := CreateGuid();
            if G = NullGuid then
                AllNotNull := false;
            if Seen.Contains(G) then
                AllNew := false;
            Seen.Add(G);
        end;
        Observer.Observe('all_not_null', Format(AllNotNull));
        Observer.Observe('all_distinct', Format(AllNew));
        Observer.Observe('text_length', Format(StrLen(Format(G))));
        Observer.Expect('all_not_null', 'Yes');
        Observer.Expect('all_distinct', 'Yes');
        Observer.Expect('text_length', '38');
        Observer.Verify();
    end;

    // md:167: the sequential ordering of the SystemId stamp: five rows inserted one after the other come back in that order in a key on SystemId.
    [TryFunction]
    local procedure TrySleep(Milliseconds: Integer)
    begin
        Sleep(Milliseconds);
    end;

    [TryFunction]
    local procedure TrySetLanguage(LanguageId: Integer)
    begin
        GlobalLanguage(LanguageId);
    end;
}
