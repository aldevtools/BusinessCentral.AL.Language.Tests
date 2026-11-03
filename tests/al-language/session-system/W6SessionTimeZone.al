// Batch 6, md:347 [Session, Active Session] the columns "Database Name", "Login Type", "Server Instance Name", "Client Computer Name";
// md:345 [Time Zone] the host's list and its display names. Observe-only. Host names and database names are tier data: only blank / not blank
// and lengths are observed; the Login Type is observed as text and ordinal.

codeunit 67325 "W6 Session TimeZone"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Session_OwnRow_HostColumns()
    var
        SessionRec: Record Session;
        Observer: Codeunit "Probe Observer";
    begin
        SessionRec.SetRange("My Session", true);
        Observer.Observe('own_row_count', Format(SessionRec.Count()));
        SessionRec.FindFirst();
        Observer.Observe('database_name_blank', Format(SessionRec."Database Name" = ''));
        Observer.Observe('login_type', Format(SessionRec."Login Type"));
        Observer.Observe('login_type_ordinal', Format(SessionRec."Login Type", 0, 2));
        Observer.Expect('own_row_count', '1');
        Observer.Expect('database_name_blank', 'No');
        Observer.Expect('login_type', 'Username and Password');
        Observer.Expect('login_type_ordinal', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ActiveSession_OwnRow_HostColumns()
    var
        ActiveSession: Record "Active Session";
        Observer: Codeunit "Probe Observer";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Observer.Observe('database_name_blank', Format(ActiveSession."Database Name" = ''));
        Observer.Observe('server_instance_name_blank', Format(ActiveSession."Server Instance Name" = ''));
        Observer.Observe('server_computer_name_blank', Format(ActiveSession."Server Computer Name" = ''));
        Observer.Expect('database_name_blank', 'No');
        Observer.Expect('server_instance_name_blank', 'No');
        Observer.Expect('server_computer_name_blank', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ActiveSession_DatabaseName_EqualsSessionDatabaseName()
    var
        ActiveSession: Record "Active Session";
        SessionRec: Record Session;
        Observer: Codeunit "Probe Observer";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        SessionRec.SetRange("My Session", true);
        SessionRec.FindFirst();
        Observer.Observe('database_names_equal', Format(ActiveSession."Database Name" = SessionRec."Database Name"));
        Observer.Observe('active_session_database_name_length_gt_0', Format(StrLen(ActiveSession."Database Name") > 0));
        Observer.Expect('database_names_equal', 'Yes');
        Observer.Expect('active_session_database_name_length_gt_0', 'Yes');
        Observer.Verify();
    end;

    local procedure ZoneText(ZoneId: Text): Text
    var
        TimeZone: Record "Time Zone";
    begin
        TimeZone.SetRange(ID, ZoneId);
        if not TimeZone.FindFirst() then
            exit('<no row>');
        exit(TimeZone."Display Name");
    end;

    [Test]
    procedure TimeZone_NumberingAndOrder()
    var
        TimeZone: Record "Time Zone";
        Previous: Integer;
        InOrder: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        TimeZone.FindFirst();
        Observer.Observe('first_no', Format(TimeZone."No."));
        TimeZone.FindLast();
        Observer.Observe('last_no_equals_count', Format(TimeZone."No." = TimeZone.Count()));
        InOrder := true;
        if TimeZone.FindSet() then
            repeat
                if TimeZone."No." <> Previous + 1 then
                    InOrder := false;
                Previous := TimeZone."No.";
            until TimeZone.Next() = 0;
        Observer.Observe('numbers_run_1_to_n_without_gaps', Format(InOrder));
        TimeZone.SetRange(ID, 'UTC');
        Observer.Observe('utc_rows', Format(TimeZone.Count()));
        Observer.Expect('first_no', '1');
        Observer.Expect('last_no_equals_count', 'Yes');
        Observer.Expect('numbers_run_1_to_n_without_gaps', 'Yes');
        Observer.Expect('utc_rows', '1');
        Observer.Verify();
    end;

    local procedure ColumnList(TableId: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.Open(TableId);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            Result += Format(FldRef.Number()) + '=' + FldRef.Name() + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure ColumnNames_Session_ActiveSession_TimeZone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('session_columns', ColumnList(Database::Session));
        Observer.Observe('active_session_columns', ColumnList(Database::"Active Session"));
        Observer.Observe('time_zone_columns', ColumnList(Database::"Time Zone"));
        Observer.Expect('session_columns', '1=Connection ID;2=User ID;3=My Session;5=Login Time;6=Login Date;16=Database Name;17=Application Name;18=Login Type;19=Host Name;');
        Observer.Expect('active_session_columns', '2=Server Instance ID;3=Session ID;1=User SID;4=Server Instance Name;5=Server Computer Name;6=User ID;7=Client Type;8=Client Computer Name;9=Login Datetime;10=Database Name;11=Session Unique ID;');
        Observer.Expect('time_zone_columns', '3=No.;1=ID;2=Display Name;');
        Observer.Verify();
    end;
}
