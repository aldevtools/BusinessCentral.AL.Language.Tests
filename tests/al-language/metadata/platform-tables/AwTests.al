// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), ALT Prompt Dialog Page (60879); objects in AwObjects.al
// Probe (corpus issue 648): platform tables, columns and rows on a fresh tenant of a test container: Session and Active Session
// host columns, Page Metadata SourceTableView with SORTING, ORDER and two conditions, Page Action rows of a page with two containers,
// nested groups, actionrefs and of a page with system actions, Report Layout List for ExcelLayoutMultipleDataSheets, obsolete and
// caption-less layouts, Record Link after RecordRef.AddLink and DeleteLink from another company, a table declared ObsoleteState = Moved,
// Modify of a Feature Key row, and the rows of Agent Creation Control (2000000297).
// Object ids 80350-80356.

codeunit 80350 "LT AW Row Text"
{
    procedure RowText(var RR: RecordRef; Skip: Text): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class = FieldClass::Normal) and (FR.Type <> FieldType::Blob) and (FR.Type <> FieldType::Media) and (FR.Type <> FieldType::MediaSet) then
                if not ('|' + Skip + '|').Contains('|' + FR.Name + '|') then
                    Result += FR.Name + '=' + Format(FR.Value, 0, 9) + ';';
        end;
        exit(Result);
    end;
}

codeunit 80351 "LT AW Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Session_OwnRow_HostColumnValues()
    var
        SessionRec: Record Session;
        Observer: Codeunit "Probe Observer";
    begin
        SessionRec.SetRange("My Session", true);
        Observer.Observe('count', Format(SessionRec.Count()));
        if SessionRec.FindFirst() then begin
            Observer.Observe('database_name', SessionRec."Database Name");
            Observer.Observe('login_type', Format(SessionRec."Login Type"));
            Observer.Observe('application_name', SessionRec."Application Name");
            Observer.Observe('host_name', SessionRec."Host Name");
        end;
        Observer.Expect('count', '1');
        Observer.Expect('database_name', 'CRONUS');
        Observer.Expect('login_type', 'Username and Password');
        // Application Name, Client Computer Name and Client Type name the client that opened the test session (the test runner: Web Client /
        // VSCodeTestClient on the BC 28 and 29 legs, Client Service / blank on 27.5); Host Name is the container's host name. Recorded, not compared.
        Observer.Ignore('application_name');
        Observer.Ignore('host_name');
        Observer.Verify();
    end;

    [Test]
    procedure ActiveSession_OwnRow_HostColumnValues()
    var
        ActiveSession: Record "Active Session";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', Format(ActiveSession.Get(ServiceInstanceId(), SessionId())));
        Observer.Observe('database_name', ActiveSession."Database Name");
        Observer.Observe('server_instance_name', ActiveSession."Server Instance Name");
        Observer.Observe('client_computer_name', ActiveSession."Client Computer Name");
        Observer.Observe('client_type', Format(ActiveSession."Client Type"));
        Observer.Observe('server_computer_name_blank', Format(ActiveSession."Server Computer Name" = ''));
        Observer.Expect('get', 'Yes');
        Observer.Expect('database_name', 'CRONUS');
        Observer.Expect('server_instance_name', 'BC');
        // Client Computer Name and Client Type depend on the test runner's client (see the Session test above): recorded, not compared.
        Observer.Ignore('client_computer_name');
        Observer.Ignore('client_type');
        Observer.Expect('server_computer_name_blank', 'No');
        Observer.Verify();
    end;
}

codeunit 80352 "LT AW Page Meta Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ViewOf(PageId: Integer): Text
    var
        Meta: Record "Page Metadata";
    begin
        if not Meta.Get(PageId) then
            exit('<no row>');
        exit(Meta.SourceTableView);
    end;

    local procedure ObserveActionRows(var Observer: Codeunit "Probe Observer"; PageId: Integer)
    var
        PageAction: Record "Page Action";
    begin
        PageAction.SetRange("Page ID", PageId);
        Observer.Observe('count', Format(PageAction.Count()));
        if PageAction.FindSet() then
            repeat
                // One row as Action ID/Indentation/Parent Action ID/Action Type/Action Subtype/Name (short, so 32 rows fit one observation message).
                Observer.Observe(Format(PageAction."Action Index"), StrSubstNo('%1/%2/%3/%4/%5/%6', PageAction."Action ID", PageAction.Indentation,
                    PageAction."Parent Action ID", Format(PageAction."Action Type", 0, 9), Format(PageAction."Action Subtype", 0, 9), PageAction.Name));
            until PageAction.Next() = 0;
    end;

    [Test]
    procedure PageMetadata_SourceTableView_SortingOrderTwoConditions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ascending', ViewOf(Page::"LT AW View Asc"));
        Observer.Observe('descending', ViewOf(Page::"LT AW View Desc"));
        Observer.Expect('ascending', 'SORTING(Field2,Field3) WHERE(Field1=FILTER(1..10),Field2=CONST(A))');
        Observer.Expect('descending', 'SORTING(Field3) ORDER(1) WHERE(Field4=CONST(1),Field3=FILTER(>0))');
        Observer.Verify();
    end;

    [Test]
    procedure PageAction_ContainersGroupsActionRefs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActionRows(Observer, Page::"LT AW Actions");
        Observer.Expect('count', '32');
        Observer.Expect('0', '2039005642/0/0/0/2/');
        Observer.Expect('1', '1437660517/1/2039005642/3/0/GOuter');
        Observer.Expect('2', '1086194027/2/1437660517/1/0/A1');
        Observer.Expect('3', '476030324/2/1437660517/3/0/GInner');
        Observer.Expect('4', '448497410/3/476030324/1/0/A2');
        Observer.Expect('5', '189199207/1/2039005642/1/0/A3');
        Observer.Expect('6', '739154711/0/0/0/3/');
        Observer.Expect('7', '493045366/1/739154711/1/0/N1');
        Observer.Expect('8', '137697713/0/0/0/11/');
        Observer.Expect('9', '1503733921/1/137697713/3/0/Category_Process');
        Observer.Expect('10', '1790343546/1/137697713/3/0/Category_New');
        Observer.Expect('11', '1801023324/1/137697713/3/0/Category_Report');
        Observer.Expect('12', '1336437194/1/137697713/3/0/Category_Category4');
        Observer.Expect('13', '698740577/1/137697713/3/0/Category_Category5');
        Observer.Expect('14', '1683136868/1/137697713/3/0/Category_Category6');
        Observer.Expect('15', '1974133811/1/137697713/3/0/Category_Category7');
        Observer.Expect('16', '1214349274/1/137697713/3/0/Category_Category8');
        Observer.Expect('17', '1852045891/1/137697713/3/0/Category_Category9');
        Observer.Expect('18', '821208899/1/137697713/3/0/Category_Category10');
        Observer.Expect('19', '183512282/1/137697713/3/0/Category_Category11');
        Observer.Expect('20', '454184335/1/137697713/3/0/Category_Category12');
        Observer.Expect('21', '1091880952/1/137697713/3/0/Category_Category13');
        Observer.Expect('22', '922971929/1/137697713/3/0/Category_Category14');
        Observer.Expect('23', '1560668546/1/137697713/3/0/Category_Category15');
        Observer.Expect('24', '2096602133/1/137697713/3/0/Category_Category16');
        Observer.Expect('25', '1458905516/1/137697713/3/0/Category_Category17');
        Observer.Expect('26', '14603259/1/137697713/3/0/Category_Category18');
        Observer.Expect('27', '623093358/1/137697713/3/0/Category_Category19');
        Observer.Expect('28', '2124689040/1/137697713/3/0/Category_Category20');
        Observer.Expect('29', '1944767284/0/0/0/1/');
        Observer.Expect('30', '1546131159/0/0/0/13/');
        Observer.Expect('31', '1902933979/0/0/0/4/');
        Observer.Verify();
    end;

    [Test]
    procedure PageAction_SystemActions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActionRows(Observer, Page::"ALT Prompt Dialog Page");
        Observer.Expect('count', '9');
        Observer.Expect('0', '1108029291/0/0/0/12/');
        Observer.Expect('1', '770390674/1/1108029291/1/0/Generate');
        Observer.Expect('2', '874487081/1/1108029291/1/0/Ok');
        Observer.Expect('3', '512114499/1/1108029291/1/0/Cancel');
        Observer.Expect('4', '1443543236/0/0/0/1/');
        Observer.Expect('5', '1751769759/0/0/0/3/');
        Observer.Expect('6', '203214370/0/0/0/2/');
        Observer.Expect('7', '1139857661/0/0/0/14/');
        Observer.Expect('8', '1447053501/0/0/0/4/');
        Observer.Verify();
    end;
}

codeunit 80353 "LT AW Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LayoutRow(LayoutName: Text): Text
    var
        LayoutList: Record "Report Layout List";
        RowTexts: Codeunit "LT AW Row Text";
        RR: RecordRef;
    begin
        LayoutList.SetRange("Report ID", Report::"LT AW Layouts");
        LayoutList.SetRange(Name, LayoutName);
        if not LayoutList.FindFirst() then
            exit('<no row>');
        RR.GetTable(LayoutList);
        exit(RowTexts.RowText(RR, 'Report ID|Name|Runtime Package ID|Application ID'));
    end;

    [Test]
    procedure LayoutList_RowCount()
    var
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        LayoutList.SetRange("Report ID", Report::"LT AW Layouts");
        Observer.Observe('count', Format(LayoutList.Count()));
        if LayoutList.FindSet() then
            repeat
                Names += LayoutList.Name + ',';
            until LayoutList.Next() = 0;
        Observer.Observe('names', Names);
        Observer.Expect('count', '5');
        Observer.Expect('names', 'XlCaptioned,XlFalse,XlOmit,XlPending,XlTrue,');
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlTrue', LayoutRow('XlTrue'));
#if BC29PLUS
        Observer.Expect('XlTrue', 'Caption=XlTrue;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlTrue;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=2;Layout Status=0;Layout Subtype=0;HeaderFooterPart=;ThemePart=;');
#elif BC28PLUS
        Observer.Expect('XlTrue', 'Caption=XlTrue;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlTrue;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=2;Layout Status=0;');
#else
        Observer.Expect('XlTrue', 'Caption=XlTrue;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlTrue;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=2;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlFalse', LayoutRow('XlFalse'));
#if BC29PLUS
        Observer.Expect('XlFalse', 'Caption=XlFalse;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlFalse;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=1;Layout Status=0;Layout Subtype=0;HeaderFooterPart=;ThemePart=;');
#elif BC28PLUS
        Observer.Expect('XlFalse', 'Caption=XlFalse;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlFalse;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=1;Layout Status=0;');
#else
        Observer.Expect('XlFalse', 'Caption=XlFalse;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlFalse;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=1;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_ExcelSheetsOmittedNoCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlOmit', LayoutRow('XlOmit'));
#if BC29PLUS
        Observer.Expect('XlOmit', 'Caption=XlOmit;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlOmit;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;Layout Status=0;Layout Subtype=0;HeaderFooterPart=;ThemePart=;');
#elif BC28PLUS
        Observer.Expect('XlOmit', 'Caption=XlOmit;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlOmit;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;Layout Status=0;');
#else
        Observer.Expect('XlOmit', 'Caption=XlOmit;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlOmit;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_ObsoletePending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlPending', LayoutRow('XlPending'));
#if BC29PLUS
        Observer.Expect('XlPending', 'Caption=XlPending;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlPending;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=true;ExcelLayoutMultipleDataSheets=0;Layout Status=0;Layout Subtype=0;HeaderFooterPart=;ThemePart=;');
#elif BC28PLUS
        Observer.Expect('XlPending', 'Caption=XlPending;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlPending;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=true;ExcelLayoutMultipleDataSheets=0;Layout Status=0;');
#else
        Observer.Expect('XlPending', 'Caption=XlPending;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlPending;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=true;ExcelLayoutMultipleDataSheets=0;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_Captioned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('XlCaptioned', LayoutRow('XlCaptioned'));
#if BC29PLUS
        Observer.Expect('XlCaptioned', 'Caption=LT AW captioned layout;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlCaptioned;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;Layout Status=0;Layout Subtype=0;HeaderFooterPart=;ThemePart=;');
#elif BC28PLUS
        Observer.Expect('XlCaptioned', 'Caption=LT AW captioned layout;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlCaptioned;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;Layout Status=0;');
#else
        Observer.Expect('XlCaptioned', 'Caption=LT AW captioned layout;CaptionML=;Layout Format=2;Custom Type={00000000-0000-0000-0000-000000000000};MIME Type=;Description=XlCaptioned;Report Name=LT AW Layouts;Layout Publisher=AL Language Coverage Tests by AL Language;User Defined=false;ReportIsInstalled=true;IsObsolete=false;ExcelLayoutMultipleDataSheets=0;');
#endif
        Observer.Verify();
    end;
}

codeunit 80354 "LT AW Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OtherCompanyTok: Label 'LT AW OTHER CO', Locked = true;

    local procedure Seed(var RR: RecordRef)
    var
        Host: Record "LT AW Link Host";
    begin
        Host.DeleteAll();
        Host.Id := 1;
        Host.Name := 'one';
        Host.Insert();
        RR.GetTable(Host);
    end;

    [Test]
    procedure RecordRef_AddLink_CreatedAndCompany()
    var
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Before: DateTime;
        After: DateTime;
        LinkId: Integer;
    begin
        Seed(RR);
        Before := CurrentDateTime();
        LinkId := RR.AddLink('https://example.com/aw', 'aw link');
        After := CurrentDateTime();
        Observer.Observe('get', Format(RecordLink.Get(LinkId)));
        Observer.Observe('company_is_session_company', Format(RecordLink.Company = CompanyName()));
        Observer.Observe('company_blank', Format(RecordLink.Company = ''));
        Observer.Observe('created_set', Format(RecordLink.Created <> 0DT));
        Observer.Observe('created_in_call_window', Format((RecordLink.Created >= Before - 1000) and (RecordLink.Created <= After + 1000)));
        Observer.Observe('type', Format(RecordLink.Type));
        Observer.Observe('description', RecordLink.Description);
        Observer.Observe('user_id_is_session_user', Format(RecordLink."User ID" = UserId()));
        Observer.Observe('record_id_matches', Format(RecordLink."Record ID" = RR.RecordId()));
        Observer.Expect('get', 'Yes');
        Observer.Expect('company_is_session_company', 'Yes');
        Observer.Expect('company_blank', 'No');
        Observer.Expect('created_set', 'Yes');
        Observer.Expect('created_in_call_window', 'Yes');
        Observer.Expect('type', 'Link');
        Observer.Expect('description', 'aw link');
        Observer.Expect('user_id_is_session_user', 'Yes');
        Observer.Expect('record_id_matches', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_DeleteLink_FromAnotherCompany()
    var
        Company: Record Company;
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        OtherRR: RecordRef;
        LinkId: Integer;
    begin
        Seed(RR);
        LinkId := RR.AddLink('https://example.com/aw2', 'aw link 2');
        if not Company.Get(OtherCompanyTok) then begin
            Company.Init();
            Company.Name := OtherCompanyTok;
            Company.Insert();
        end;
        OtherRR.Open(Database::"LT AW Link Host", false, OtherCompanyTok);
        Observer.Observe('other_current_company', OtherRR.CurrentCompany());
        Observer.Observe('other_has_links_before', Format(OtherRR.HasLinks()));
        OtherRR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete_from_other', Format(RecordLink.Get(LinkId)));
        Observer.Observe('own_has_links_after', Format(RR.HasLinks()));
        RR.ChangeCompany(OtherCompanyTok);
        RR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete_changed_company', Format(RecordLink.Get(LinkId)));
        Observer.Expect('other_current_company', 'LT AW OTHER CO');
        Observer.Expect('other_has_links_before', 'No');
        Observer.Expect('link_row_after_delete_from_other', 'Yes');
        Observer.Expect('own_has_links_after', 'Yes');
        Observer.Expect('link_row_after_delete_changed_company', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_DeleteLink_SameCompany()
    var
        RecordLink: Record "Record Link";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        LinkId: Integer;
    begin
        Seed(RR);
        LinkId := RR.AddLink('https://example.com/aw3', 'aw link 3');
        RR.DeleteLink(LinkId);
        Observer.Observe('link_row_after_delete', Format(RecordLink.Get(LinkId)));
        Observer.Expect('link_row_after_delete', 'No');
        Observer.Verify();
    end;
}

codeunit 80355 "LT AW Moved Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MovedTable_OwnApp_AllObj()
    var
        AllObj: Record AllObj;
        Observer: Codeunit "Probe Observer";
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 80301);
        Observer.Observe('allobj_rows', Format(AllObj.Count()));
        Observer.Expect('allobj_rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MovedTable_OwnApp_ReadAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        // The table is declared in this app with ObsoleteState = Moved: it is not in the runtime app, so RecordRef.Open fails.
        asserterror RR.Open(80301);
        Observer.Observe('open_error_code', GetLastErrorCode());
        // Windows names 'Test Runner - Mgt.' on 27.5/28.5/29.0 (Windows check runs 39232594469/39232598079/39232601421).
        // Before the bc-linux #140 fix Linux BC 28/29 named the test codeunit instead.
        Observer.Observe('open_error', GetLastErrorText());
        Observer.Expect('open_error_code', 'AL:MetadataNotFound');
        Observer.Expect('open_error', 'You tried to invoke the Table object with the ID 80301 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Verify();
    end;

    [Test]
    procedure MovedTable_BaseApp_NoSeries_AllObjRows()
    var
        AllObj: Record AllObj;
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 308);
        Observer.Observe('rows_308', Format(AllObj.Count()));
        if AllObj.FindSet() then
            repeat
                Names += AllObj."Object Name" + ',';
            until AllObj.Next() = 0;
        Observer.Observe('names_308', Names);
        AllObj.SetRange("Object ID");
        AllObj.SetRange("Object Name", 'No. Series');
        Observer.Observe('rows_named_no_series', Format(AllObj.Count()));
        Observer.Expect('rows_308', '1');
        Observer.Expect('names_308', 'No. Series,');
        Observer.Expect('rows_named_no_series', '1');
        Observer.Verify();
    end;
}

codeunit 80356 "LT AW Feature Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FeatureTok: Label 'ConcurrentResourcePosting', Locked = true;

    local procedure State(): Text
    var
        FeatureKey: Record "Feature Key";
        Result: Text;
    begin
        if not FeatureKey.Get(FeatureTok) then
            exit('<no row>');
        Result := 'get=' + Format(FeatureKey.Enabled);
        FeatureKey.SetRange(ID, FeatureTok);
        if FeatureKey.FindSet() then
            Result += ' findset=' + Format(FeatureKey.Enabled);
        FeatureKey.SetRange(Enabled, FeatureKey.Enabled::None);
        Result += ' count_none=' + Format(FeatureKey.Count());
        exit(Result);
    end;

    local procedure Restore()
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(FeatureTok) then
            if FeatureKey.Enabled <> FeatureKey.Enabled::"All Users" then begin
                FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                FeatureKey.Modify();
            end;
    end;

    [Test]
    procedure FeatureKey_A_ModifyEnabled_ReadBack()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('before', State());
        FeatureKey.Get(FeatureTok);
        FeatureKey.Enabled := FeatureKey.Enabled::None;
        Observer.Observe('modify', Format(FeatureKey.Modify()));
        Observer.Observe('after', State());
        // Left changed on purpose: the next test reads it and restores it.
        Observer.Expect('before', 'get=All Users findset=All Users count_none=0');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('after', 'get=None findset=None count_none=1');
        Observer.Verify();
    end;

    [Test]
    procedure FeatureKey_B_NextTest_SeesChange_ThenRestore()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('next_test', State());
        Restore();
        Observer.Observe('restored', State());
        Observer.Expect('next_test', 'get=None findset=None count_none=1');
        Observer.Expect('restored', 'get=All Users findset=All Users count_none=0');
        Observer.Verify();
    end;

    [Test]
    procedure FeatureKey_C_ModifyUnchanged()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Restore();
        FeatureKey.Get(FeatureTok);
        Observer.Observe('modify_nothing_changed', Format(FeatureKey.Modify()));
        Observer.Observe('after_nothing', State());
        FeatureKey.Get(FeatureTok);
        FeatureKey.Enabled := FeatureKey.Enabled;
        Observer.Observe('modify_same_value', Format(FeatureKey.Modify()));
        Observer.Observe('after_same', State());
        Observer.Expect('modify_nothing_changed', 'Yes');
        Observer.Expect('after_nothing', 'get=All Users findset=All Users count_none=0');
        Observer.Expect('modify_same_value', 'Yes');
        Observer.Expect('after_same', 'get=All Users findset=All Users count_none=0');
        Observer.Verify();
    end;

    [Test]
    procedure FeatureKey_D_ModifyThenRollback()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Restore();
        asserterror
        begin
            FeatureKey.Get(FeatureTok);
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
            Error('LT AW rollback');
        end;
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('after_rollback', State());
        Restore();
        Observer.Expect('error', 'LT AW rollback');
        Observer.Expect('after_rollback', 'get=None findset=None count_none=1');
        Observer.Verify();
    end;
}

codeunit 80357 "LT AW Agent Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TryOpen(var RR: RecordRef)
    begin
        RR.Open(2000000297);
    end;

    [Test]
    procedure AgentCreationControl_Rows()
    var
        RowTexts: Codeunit "LT AW Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Rows: Text;
    begin
        ClearLastError();
        asserterror
        begin
            TryOpen(RR);
            Rows := 'name=' + RR.Name + ' count=' + Format(RR.Count()) + ';';
            if RR.FindSet() then
                repeat
                    Rows += '[' + RowTexts.RowText(RR, 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion') + ']';
                until RR.Next() = 0;
            Error('LT AW done');
        end;
        Observer.Observe('rows', Rows);
        Observer.Observe('error', GetLastErrorText());
        Observer.Expect('rows', '');
#if BC28PLUS
        Observer.Expect('error', 'You cannot open record 2000000297 from a RecordRef data type when you are using target Cloud.');
#else
        Observer.Expect('error', 'You tried to invoke the Table object with the ID 2000000297 from the object LT AW Agent Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#endif
        Observer.Verify();
    end;
}
