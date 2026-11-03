// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope (OnPrem app only: System.GetUrl, Scope = OnPrem members are written for the OnPrem app)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; table 61231 and codeunit 61232
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// GetUrl overloads #1 to #4 with a nonexistent company name; only the query part of the URL is observed (host and port are the runner's).
// BC versions: 29 (27 and 28 by CI)
table 61231 "LT P109 Tab"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Name) { }
    }
}

codeunit 61232 "LT P109 GetUrl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tail(Url: Text): Text
    var
        Pos: Integer;
    begin
        Pos := Url.IndexOf('?');
        if Pos = 0 then
            exit('noquery:' + Format(StrLen(Url) > 0));
        exit(CopyStr(Url, Pos, 800));
    end;

    [Test]
    procedure P109_GetUrl_Overload1_Basic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('web_page', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999)));
        Observer.Observe('web_codeunit', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Codeunit, 99999)));
        Observer.Observe('web_report', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999)));
        Observer.Observe('web_table', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Table, 61231)));
        Observer.Observe('web_nocompany_has_query', Format(StrLen(Tail(GetUrl(ClientType::Web))) > 0));
        Observer.Observe('web_blank_company', Tail(GetUrl(ClientType::Web, '', ObjectType::Page, 99999)));
        Observer.Observe('web_company_space', Tail(GetUrl(ClientType::Web, 'LT P109 CO', ObjectType::Page, 99999)));
        Observer.Observe('web_company_special', Tail(GetUrl(ClientType::Web, 'LT&P109/CO', ObjectType::Page, 99999)));
        Observer.Observe('web_page_zero', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 0)));
        Observer.Expect('web_page', '?company=LTP109CO&page=99999');
        Observer.Expect('web_codeunit', 'noquery:No');
        Observer.Expect('web_report', '?company=LTP109CO&report=99999');
        Observer.Expect('web_table', '?company=LTP109CO&table=61231');
        Observer.Expect('web_nocompany_has_query', 'Yes');
        Observer.Expect('web_blank_company', '?page=99999');
        Observer.Expect('web_company_space', '?company=LT%20P109%20CO&page=99999');
        Observer.Expect('web_company_special', '?company=LT%26P109%2FCO&page=99999');
        Observer.Expect('web_page_zero', 'noquery:No');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetUrl_Overload1_ClientTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tablet', Tail(GetUrl(ClientType::Tablet, 'LTP109CO', ObjectType::Page, 99999)));
        Observer.Observe('phone', Tail(GetUrl(ClientType::Phone, 'LTP109CO', ObjectType::Page, 99999)));
        Observer.Observe('default', Tail(GetUrl(ClientType::Default, 'LTP109CO', ObjectType::Page, 99999)));
        Observer.Observe('windows', Tail(GetUrl(ClientType::Windows, 'LTP109CO', ObjectType::Page, 99999)));
        Observer.Expect('tablet', '?company=LTP109CO&page=99999');
        Observer.Expect('phone', '?company=LTP109CO&page=99999');
        Observer.Expect('default', '?page=99999');
        Observer.Expect('windows', '?page=99999');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryUrl(Client: ClientType; Obj: ObjectType)
    var
        Url: Text;
    begin
        Url := GetUrl(Client, 'LTP109CO', Obj, 99999);
    end;

    local procedure Outcome(Client: ClientType; Obj: ObjectType): Text
    begin
        if TryUrl(Client, Obj) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_GetUrl_Overload1_ClientTypes_Errors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('soap_page', Outcome(ClientType::SOAP, ObjectType::Page));
        Observer.Observe('odata_page', Outcome(ClientType::OData, ObjectType::Page));
        Observer.Observe('api_page', Outcome(ClientType::Api, ObjectType::Page));
        Observer.Observe('background_page', Outcome(ClientType::Background, ObjectType::Page));
        Observer.Observe('management_page', Outcome(ClientType::Management, ObjectType::Page));
        Observer.Observe('childsession_page', Outcome(ClientType::ChildSession, ObjectType::Page));
        Observer.Observe('web_query', Outcome(ClientType::Web, ObjectType::Query));
        Observer.Observe('web_xmlport', Outcome(ClientType::Web, ObjectType::XmlPort));
        Observer.Expect('soap_page', 'ok');
        Observer.Expect('odata_page', 'ok');
        Observer.Expect('api_page', 'ok');
        Observer.Expect('background_page', 'ok');
        Observer.Expect('management_page', 'ok');
        Observer.Expect('childsession_page', 'ok');
        Observer.Expect('web_query', 'ok');
        Observer.Expect('web_xmlport', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetUrl_Overload2_Record()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P109 Tab";
    begin
        Rec.DeleteAll();
        Rec.Id := 7;
        Rec.Name := 'Seven';
        Rec.Insert();
        Observer.Observe('rec_page', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec)));
        Observer.Observe('rec_page_nofilters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, false)));
        Observer.Observe('rec_page_filters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, true)));
        Rec.SetRange(Name, 'Seven');
        Observer.Observe('rec_page_filtered_nofilters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, false)));
        Observer.Observe('rec_page_filtered_filters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, true)));
        Observer.Observe('rec_page_layout', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, true, 'LTLayout')));
        Observer.Observe('rec_page_layout_blank', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, true, '')));
        Observer.Observe('rec_report_layout', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999, Rec, true, 'LTLayout')));
        Rec.Reset();
        Rec.DeleteAll();
        Observer.Expect('rec_page', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHBw%3d%3d');
        Observer.Expect('rec_page_nofilters', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHBw%3d%3d');
        Observer.Expect('rec_page_filters', '?company=LTP109CO&page=99999');
        Observer.Expect('rec_page_filtered_nofilters', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHBw%3d%3d');
        Observer.Expect('rec_page_filtered_filters', '?company=LTP109CO&page=99999&filter=%27Name%27%20IS%20%27Seven%27');
        Observer.Expect('rec_page_layout', '?company=LTP109CO&page=99999&filter=%27Name%27%20IS%20%27Seven%27');
        Observer.Expect('rec_page_layout_blank', '?company=LTP109CO&page=99999&filter=%27Name%27%20IS%20%27Seven%27');
        Observer.Expect('rec_report_layout', 'noquery:No');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetUrl_Overload2_EmptyRecord()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P109 Tab";
    begin
        Rec.DeleteAll();
        Observer.Observe('empty_rec', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec)));
        Observer.Observe('empty_rec_filters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, Rec, true)));
        Observer.Expect('empty_rec', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACH');
        Observer.Expect('empty_rec_filters', '?company=LTP109CO&page=99999');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetUrl_Overload3_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P109 Tab";
        RecRef: RecordRef;
    begin
        Rec.DeleteAll();
        Rec.Id := 8;
        Rec.Name := 'Eight';
        Rec.Insert();
        RecRef.GetTable(Rec);
        Observer.Observe('rr', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef)));
        Observer.Observe('rr_nofilters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef, false)));
        Observer.Observe('rr_filters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef, true)));
        RecRef.Field(2).SetRange('Eight');
        Observer.Observe('rr_filtered_filters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef, true)));
        Observer.Observe('rr_filtered_nofilters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef, false)));
        RecRef.Close();
        Rec.DeleteAll();
        Observer.Expect('rr', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHCA%3d%3d');
        Observer.Expect('rr_nofilters', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHCA%3d%3d');
        Observer.Expect('rr_filters', '?company=LTP109CO&page=99999');
        Observer.Expect('rr_filtered_filters', '?company=LTP109CO&page=99999&filter=%27Name%27%20IS%20%27Eight%27');
        Observer.Expect('rr_filtered_nofilters', '?company=LTP109CO&page=99999&bookmark=12%3bL%2b8AAACHCA%3d%3d');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClosed()
    var
        RecRef: RecordRef;
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef);
    end;

    [Test]
    procedure P109_GetUrl_Overload3_ClosedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('closed_rr_ok', Format(TryClosed()));
        Observer.Observe('closed_rr_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('closed_rr_ok', 'Yes');
        Observer.Expect('closed_rr_error', 'The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetUrl_Overload4_RecordRefLayout()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P109 Tab";
        RecRef: RecordRef;
    begin
        Rec.DeleteAll();
        Rec.Id := 9;
        Rec.Name := 'Nine';
        Rec.Insert();
        RecRef.GetTable(Rec);
        Observer.Observe('rr_layout_page', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Page, 99999, RecRef, true, 'LTLayout')));
        Observer.Observe('rr_layout_report', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999, RecRef, true, 'LTLayout')));
        Observer.Observe('rr_layout_blank', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999, RecRef, true, '')));
        Observer.Observe('rr_layout_nofilters', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999, RecRef, false, 'LTLayout')));
        Observer.Observe('rr_layout_space', Tail(GetUrl(ClientType::Web, 'LTP109CO', ObjectType::Report, 99999, RecRef, true, 'LT Layout&x')));
        RecRef.Close();
        Rec.DeleteAll();
        Observer.Expect('rr_layout_page', '?company=LTP109CO&page=99999');
        Observer.Expect('rr_layout_report', 'noquery:No');
        Observer.Expect('rr_layout_blank', 'noquery:No');
        Observer.Expect('rr_layout_nofilters', 'noquery:No');
        Observer.Expect('rr_layout_space', 'noquery:No');
        Observer.Verify();
    end;
}
