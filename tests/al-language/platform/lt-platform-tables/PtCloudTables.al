// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope; the platform tables that have Scope = Cloud (or no scope) in the system symbols, opened by RecordRef in a Cloud app.
// Fixtures used: PtHelper.al (LT PT Arg, LT PT Runner, LT PT Ops)
// Probe: platform tables that have no row provider in the AL runtime. For each table: the column list, whether rows exist, the first row, an Insert, a
// second Insert of the same key, a Modify, a Delete and an Insert without triggers. Every request runs in its own Codeunit.Run, so an error is observed
// as text and code. Object id 67107.
// Writer QX (Microsoft's DemoTool): Media Resources codes of a fresh tenant, Media Reference.ImportStream and Blob rows by Code; Tenant Report
//   Layout Selection rows of a fresh tenant and the Insert(true)-else-Modify(true) of a report layout; OData Edm Type keys and the Edm Xml Blob.
// Writer RE (Microsoft's DemoTool): Description and Edm Xml text of the 6 OData Edm Type rows of a fresh tenant (the same on BC 27, 28 and 29).
// Writer Y17 (gap cycle 1 G8, BC 29 only): Tenant Report Layout Cfg rows: a valid row needs a Body-subtype layout as '<app id>::<name>' (or a blank
//   Layout Name) and parts that are HeaderFooter / Theme layouts of the same report or of "Tenant Report Defaults" (report 91874, reportextension 91875).

codeunit 67107 "LT PT Cloud Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";
        Y17Inserted: Boolean;
        Y17Observer: Codeunit "Probe Observer";

    local procedure Standard(var Observer: Codeunit "Probe Observer"; TableNo: Integer; InsertRequest: Text; FilterRequest: Text; ChangeRequest: Text)
    begin
        Observer.Observe('columns', Ops.Perform(TableNo, 'columns', '', false));
        Observer.Observe('has_rows', Ops.Perform(TableNo, 'hasrows', '', false));
        Observer.Observe('first_row', Ops.Perform(TableNo, 'first', '', false));
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', InsertRequest, true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', FilterRequest + '|' + ChangeRequest, true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', FilterRequest, false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', FilterRequest, true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', FilterRequest, false));
        Observer.Observe('insert_no_triggers', Ops.Perform(TableNo, 'insert', InsertRequest, false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', FilterRequest, false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', FilterRequest, false));
    end;

    [Test]
    procedure LanguageSelection_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000050, '1=LT PT Language;2=99999;3=99999;4=LTP;5=true;6=lt-PT', '1=LT PT Language;6=lt-PT', '5=false');
        Observer.Expect('columns', 'ok:1:Name:Text:80:Normal;6:Language Tag:Text:80:Normal;2:Language ID:Integer:4:Normal;3:Primary Language ID:Integer:4:Normal;4:Abbreviated Name:Text:3:Normal;5:Enabled:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=Afrikaans (South Africa);6=af-ZA;2=1078;3=1078;4=AFK;5=No;');
        Observer.Expect('insert', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('find_inserted', 'ok:none');
        Observer.Expect('count_inserted', 'ok:0');
        Observer.Expect('insert_duplicate', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('modify', 'error:There is no Language Selection within the filter.\\Filters: Name: LT PT Language, Region: lt-PT|DB:NothingInsideFilter');
        Observer.Expect('find_modified', 'ok:none');
        Observer.Expect('delete', 'error:There is no Language Selection within the filter.\\Filters: Name: LT PT Language, Region: lt-PT|DB:NothingInsideFilter');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('delete_all_no_triggers', 'error:The Language Selection table is read-only.|DB:Ok');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure LicensePermission_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000043, '1=1;2=99999;10=1', '1=1;2=99999', '10=2');
        Observer.Expect('columns', 'ok:1:Object Type:Option:4:Normal;2:Object Number:Integer:4:Normal;10:Read Permission:Option:4:Normal;11:Insert Permission:Option:4:Normal;12:Modify Permission:Option:4:Normal;13:Delete Permission:Option:4:Normal;14:Execute Permission:Option:4:Normal;15:Limited Usage Permission:Option:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=TableData;2=0;10= ;11= ;12= ;13= ;14= ;15= ;');
        Observer.Expect('insert', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('find_inserted', 'ok:1=Table;2=99999;10=Yes;11=Yes;12=Yes;13=Yes;14=Yes;15= ;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('modify', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('find_modified', 'ok:1=Table;2=99999;10=Yes;11=Yes;12=Yes;13=Yes;14=Yes;15= ;');
        Observer.Expect('delete', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('count_deleted', 'ok:1');
        Observer.Expect('insert_no_triggers', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('delete_all_no_triggers', 'error:The License Permission table is read-only.|DB:Ok');
        Observer.Expect('count_after_delete_all', 'ok:1');
        Observer.Verify();
    end;

    [Test]
    procedure EntityText_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000132, '1=LTPT;2=18;3={11111111-1111-1111-1111-111111111111};4=0;5=preview', '1=LTPT;2=18', '5=changed');
        Observer.Expect('columns', 'ok:1:Company:Text:30:Normal;2:Source Table Id:Integer:4:Normal;3:Source System Id:GUID:16:Normal;4:Scenario:Option:4:Normal;5:Preview Text:Text:1024:Normal;6:Text:BLOB:8:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=LTPT;2=18;3=<guid>;4=Marketing Text;5=preview;6=<BLOB>;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=LTPT;2=18;3=<guid>;4=Marketing Text;5=changed;6=<BLOB>;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantReportLayoutSelection_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000233, '1=99999;2=LTPT Layout;3={22222222-2222-2222-2222-222222222222};4=LTPT;5={33333333-3333-3333-3333-333333333333}', '1=99999;4=LTPT', '2=Changed');
#if BC29PLUS
        Observer.Expect('columns', 'ok:1:Report ID:Integer:4:Normal;4:Company Name:Text:30:Normal;5:User ID:GUID:16:Normal;2:Layout Name:Text:250:Normal;3:App ID:GUID:16:Normal;6:Header Part Name:Text:300:Normal;7:Theme Part Name:Text:300:Normal;');
#else
        Observer.Expect('columns', 'ok:1:Report ID:Integer:4:Normal;4:Company Name:Text:30:Normal;5:User ID:GUID:16:Normal;2:Layout Name:Text:250:Normal;3:App ID:GUID:16:Normal;');
#endif
        Observer.Expect('has_rows', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('first_row', 'ok:1=1302;4=;5=<blank guid>;2=StandardSalesProFormaInv.docx;3=<guid>;6=;7=;');
#else
        Observer.Expect('first_row', 'ok:1=1302;4=;5=<blank guid>;2=StandardSalesProFormaInv.docx;3=<guid>;');
#endif
        Observer.Expect('insert', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('find_inserted', 'ok:1=99999;4=LTPT;5=<guid>;2=LTPT Layout;3=<guid>;6=;7=;');
#else
        Observer.Expect('find_inserted', 'ok:1=99999;4=LTPT;5=<guid>;2=LTPT Layout;3=<guid>;');
#endif
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
#if BC29PLUS
        Observer.Expect('find_modified', 'ok:1=99999;4=LTPT;5=<guid>;2=Changed;3=<guid>;6=;7=;');
#else
        Observer.Expect('find_modified', 'ok:1=99999;4=LTPT;5=<guid>;2=Changed;3=<guid>;');
#endif
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure MediaResources_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000182, '1=LTPT1', '1=LTPT1', '');
        Observer.Expect('columns', 'ok:1:Code:Code:50:Normal;2:MediaSet Reference:MediaSet:16:Normal;3:Media Reference:Media:16:Normal;4:Blob:BLOB:8:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:1=1305-1-DEFAULT.PNG;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=LTPT1;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=LTPT1;2=<MediaSet>;3=<Media>;4=<BLOB>;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectAccessIntentOverride_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000205, '1=3;2=99999;3=1', '1=3;2=99999', '3=2');
        Observer.Expect('columns', 'ok:1:Object Type:Option:4:Normal;2:Object ID:Integer:4:Normal;3:Access Intent:Option:4:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=Report;2=99999;3=ReadOnly;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=Report;2=99999;3=ReadWrite;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_ExistingObject_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Page 10 exists in every Cronus database.
        Standard(Observer, 2000000168, '3=8;6=10;9=LTPTSvc;12=true', '3=8;9=LTPTSvc', '12=false');
        Observer.Expect('columns', 'ok:3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('has_rows', 'ok:Yes');
        Observer.Expect('first_row', 'ok:3=Codeunit;9=WorkflowActionResponse;6=1544;12=Yes;13=No;14=No;');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:3=Page;9=LTPTSvc;6=10;12=Yes;13=No;14=No;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:3=Page;9=LTPTSvc;6=10;12=No;13=No;14=No;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure TenantWebService_Edges()
    var
        Observer: Codeunit "Probe Observer";
        T: Integer;
    begin
        T := 2000000168;
        Observer.Observe('insert_nonexistent_object', Ops.Perform(T, 'insert', '3=8;6=99999;9=LTPTMissing;12=true', true));
        Observer.Observe('insert_nonexistent_object_no_triggers', Ops.Perform(T, 'insert', '3=8;6=99998;9=LTPTMissing2;12=true', false));
        Observer.Observe('insert_blank_name', Ops.Perform(T, 'insert', '3=8;6=10', true));
        Observer.Observe('insert_type_blank', Ops.Perform(T, 'insert', '3=0;6=10;9=LTPTBlankType', true));
        Observer.Observe('insert_type_codeunit', Ops.Perform(T, 'insert', '3=5;6=1;9=LTPTCodeunit', true));
        Observer.Observe('insert_type_query', Ops.Perform(T, 'insert', '3=9;6=10;9=LTPTQuery', true));
        Observer.Observe('insert_one', Ops.Perform(T, 'insert', '3=8;6=10;9=LTPTOne', true));
        Observer.Observe('insert_same_object_other_name', Ops.Perform(T, 'insert', '3=8;6=10;9=LTPTTwo', true));
        Observer.Observe('count_same_object', Ops.Perform(T, 'count', '3=8;6=10', false));
        Observer.Observe('insert_name_case', Ops.Perform(T, 'insert', '3=8;6=10;9=ltptone', true));
        Observer.Expect('insert_nonexistent_object', 'ok:Yes');
        Observer.Expect('insert_nonexistent_object_no_triggers', 'ok:Yes');
        Observer.Expect('insert_blank_name', 'ok:Yes');
        Observer.Expect('insert_type_blank', 'ok:Yes');
        Observer.Expect('insert_type_codeunit', 'ok:Yes');
        Observer.Expect('insert_type_query', 'ok:Yes');
        Observer.Expect('insert_one', 'ok:Yes');
        Observer.Expect('insert_same_object_other_name', 'ok:Yes');
        Observer.Expect('count_same_object', 'ok:3');
        Observer.Expect('insert_name_case', 'ok:Yes');
        Observer.Verify();
    end;

    // ---- Writer QX (Microsoft's DemoTool: Media Resources Mgt. (Base App 9755) InsertMediaFromInstream / InsertBlobFromText, Create Custom
    // Report Layout's Tenant Report Layout Selection Insert(true)-else-Modify(true), Graph Mgt - General Tools InsertOrUpdateODataType) ----

    local procedure QxPngStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', OutS);
        TempBlob.CreateInStream(InS);
    end;

    local procedure QxTenantMedia(Id: Guid): Text
    var
        TenantMedia: Record "Tenant Media";
    begin
        if not TenantMedia.Get(Id) then
            exit('no tenant media row');
        TenantMedia.CalcFields(Content);
        exit('description=[' + TenantMedia.Description + '] mime=[' + TenantMedia."Mime Type" + '] width=' + Format(TenantMedia.Width) + ' height=' +
            Format(TenantMedia.Height) + ' hascontent=' + Format(TenantMedia.Content.HasValue()));
    end;

    [Test]
    procedure QX_MediaResources_FreshTenantCodes()
    var
        MediaResources: Record "Media Resources";
        Observer: Codeunit "Probe Observer";
        Codes: Text;
        WithMedia: Integer;
        WithMediaSet: Integer;
        WithBlob: Integer;
    begin
        MediaResources.SetAutoCalcFields(Blob);
        if MediaResources.FindSet() then
            repeat
                Codes += MediaResources.Code + ',';
                if MediaResources."Media Reference".HasValue() then
                    WithMedia += 1;
                if MediaResources."MediaSet Reference".Count() > 0 then
                    WithMediaSet += 1;
                if MediaResources.Blob.HasValue() then
                    WithBlob += 1;
            until MediaResources.Next() = 0;
        Observer.Observe('count', Format(MediaResources.Count()));
        Observer.Observe('with media', Format(WithMedia));
        Observer.Observe('with mediaset', Format(WithMediaSet));
        Observer.Observe('with blob', Format(WithBlob));
        Observer.Observe('codes', Codes);
        Observer.Expect('count', '46');
        Observer.Expect('with media', '20');
        Observer.Expect('with mediaset', '6');
        Observer.Expect('with blob', '20');
        Observer.Expect('codes', '1305-1-DEFAULT.PNG,1306-1-DEFAULT.PNG,1307-1-DEFAULT.PNG,1307-1-PHONE.PNG,1309-1-DEFAULT.PNG,APPLICATIONCOUNTRY,ASSISTEDSETUPDONE-NOTEXT-400PX.PNG,ASSISTEDSETUPINFO-NOTEXT.PNG,ASSISTEDSETUP-NOTEXT-400PX.PNG,CANCELED INVOICE,COPILOTNOTAVAILABLE.PNG,DRAFT INVOICE,EXCELTEMPLATEAGEDACCOUNTSPAYABLE.XLTM,EXCELTEMPLATEAGEDACCOUNTSRECEIVABLE.XLTM,EXCELTEMPLATEBALANCESHEET.XLTM,EXCELTEMPLATECASHFLOWSTATEMENT.XLTM,EXCELTEMPLATEINCOMESTATEMENT.XLTM,EXCELTEMPLATERETAINEDEARNINGS.XLTM,EXCELTEMPLATETRIALBALANCE.XLTM,EXTERNALSYNC-NOTEXT.PNG,FIRSTINVOICE1.PNG,FIRSTINVOICE2.PNG,FIRSTINVOICE3.PNG,FIRSTINVOICESPLASH.PNG,IMAGEANALYSIS-SETUP-NOTEXT.PNG,INVOICING - SALESMAIL.HTML,LATEPAYMENTSTANDARDMODEL.TXT,OUTLOOKADDINILLUSTRATION.PNG,OVERDUE INVOICE,PAID INVOICE,PAYMENT SERVICE - MICROSOFT-LOGO.PNG,PAYMENT SERVICE - PAYPAL-LOGO.PNG,PAYMENT SERVICE - WORLDPAY-LOGO.PNG,POWERBI-OPTIN-480PX.PNG,QUOTE,SOCIAL - FACEBOOK.PNG,SOCIAL - INSTAGRAM.PNG,SOCIAL - LINKEDIN.PNG,SOCIAL - PINTEREST.PNG,SOCIAL - TWITTER.PNG,SOCIAL - YELP.PNG,SOCIAL - YOUTUBE.PNG,TEAMSAPPILLUSTRATION.PNG,UNPAID INVOICE,WHATSNEWWIZARD-BANNER-FIRST.PNG,WHATSNEWWIZARD-BANNER-SECOND.PNG,');
        Observer.Verify();
    end;

    [Test]
    procedure QX_MediaResources_ImportStreamAndBlob()
    var
        MediaResources: Record "Media Resources";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        MediaResources.SetFilter(Code, 'LTQX*');
        MediaResources.DeleteAll();
        MediaResources.Reset();
        Observer.Observe('get missing', Format(MediaResources.Get('LTQX-MEDIA')));
        MediaResources.Init();
        MediaResources.Validate(Code, 'LTQX-MEDIA');
        QxPngStream(TempBlob, InS);
        MediaResources."Media Reference".ImportStream(InS, 'LTQX-MEDIA');
        Observer.Observe('media hasvalue before insert', Format(MediaResources."Media Reference".HasValue()));
        Observer.Observe('insert(true)', Format(MediaResources.Insert(true)));
        Clear(MediaResources);
        Observer.Observe('get', Format(MediaResources.Get('LTQX-MEDIA')));
        Observer.Observe('media hasvalue', Format(MediaResources."Media Reference".HasValue()));
        Observer.Observe('tenant media', QxTenantMedia(MediaResources."Media Reference".MediaId()));
        Observer.Observe('get lower case', Format(MediaResources.Get('ltqx-media')));
        MediaResources.Init();
        MediaResources.Validate(Code, 'LTQX-BLOB');
        MediaResources.Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('{"blob":"text"}');
        Observer.Observe('blob insert(true)', Format(MediaResources.Insert(true)));
        Clear(MediaResources);
        MediaResources.Get('LTQX-BLOB');
        Observer.Observe('blob hasvalue without calcfields', Format(MediaResources.Blob.HasValue()));
        MediaResources.CalcFields(Blob);
        MediaResources.Blob.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Txt);
        Observer.Observe('blob text', Txt);
        Observer.Observe('blob media hasvalue', Format(MediaResources."Media Reference".HasValue()));
        MediaResources.Init();
        MediaResources.Code := 'LTQX-MEDIA';
        Observer.Observe('insert duplicate', Format(MediaResources.Insert(true)));
        MediaResources.SetFilter(Code, 'LTQX*');
        Observer.Observe('count mine', Format(MediaResources.Count()));
        MediaResources.DeleteAll(true);
        Observer.Observe('count mine after deleteall', Format(MediaResources.Count()));
        Observer.Expect('get missing', 'No');
        Observer.Expect('media hasvalue before insert', 'Yes');
        Observer.Expect('insert(true)', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('media hasvalue', 'Yes');
        Observer.Expect('tenant media', 'no tenant media row');
        Observer.Expect('get lower case', 'Yes');
        Observer.Expect('blob insert(true)', 'Yes');
        Observer.Expect('blob hasvalue without calcfields', 'Yes');
        Observer.Expect('blob text', '{"blob":"text"}');
        Observer.Expect('blob media hasvalue', 'No');
        Observer.Expect('insert duplicate', 'No');
        Observer.Expect('count mine', '2');
        Observer.Expect('count mine after deleteall', '0');
        Observer.Verify();
    end;

    local procedure QxSelectionRows(): Text
    var
        Selection: Record "Tenant Report Layout Selection";
        Result: Text;
    begin
        if Selection.FindSet() then
            repeat
                Result += '[' + Format(Selection."Report ID") + '|' + Selection."Company Name" + '|' + Format(IsNullGuid(Selection."User ID")) + '|' +
                    Selection."Layout Name" + '|' + Format(IsNullGuid(Selection."App ID")) + ']';
            until Selection.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QX_TenantReportLayoutSelection_RowsAndDemoShape()
    var
        Selection: Record "Tenant Report Layout Selection";
        LayoutList: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
        Names: Text;
        LayoutName: Text[250];
        OldName: Text[250];
        OldAppId: Guid;
        BlankGuid: Guid;
        HadRow: Boolean;
    begin
        Observer.Observe('rows', QxSelectionRows());
        Observer.Observe('get 1302 blank company', Format(Selection.Get(1302, '', BlankGuid)));
        Observer.Observe('get 1302 this company', Format(Selection.Get(1302, CompanyName(), BlankGuid)));
        LayoutList.SetRange("Report ID", 1306);
        if LayoutList.FindSet() then
            repeat
                Names += LayoutList.Name + '|' + Format(LayoutList."Layout Format") + ',';
            until LayoutList.Next() = 0;
        Observer.Observe('report layout list 1306', Names);
        if LayoutList.FindFirst() then begin
            LayoutName := LayoutList.Name;
            HadRow := Selection.Get(1306, '', BlankGuid);
            if HadRow then begin
                OldName := Selection."Layout Name";
                OldAppId := Selection."App ID";
            end;
            Selection.Init();
            Selection."Report ID" := 1306;
            Selection."Layout Name" := LayoutName;
            Selection."App ID" := LayoutList."Application ID";
            Observer.Observe('had 1306 row', Format(HadRow));
            Observer.Observe('insert(true) 1306', Format(Selection.Insert(true)));
            Observer.Observe('modify(true) 1306', Format(Selection.Modify(true)));
            Observer.Observe('rows after', QxSelectionRows());
            if HadRow then begin
                Selection.Get(1306, '', BlankGuid);
                Selection."Layout Name" := OldName;
                Selection."App ID" := OldAppId;
                Selection.Modify();
            end else
                if Selection.Get(1306, '', BlankGuid) then
                    Selection.Delete();
        end;
        Observer.Expect('rows', '[1302||Yes|StandardSalesProFormaInv.docx|No][1303||Yes|StandardDraftSalesInvoiceBlue.docx|No][1304||Yes|StandardSalesQuoteBlue.docx|No][1306||Yes|StandardSalesInvoiceBlueSimple.docx|No]');
        Observer.Expect('get 1302 blank company', 'Yes');
        Observer.Expect('get 1302 this company', 'No');
        Observer.Expect('report layout list 1306', 'StandardSalesInvoice.docx|Word,StandardSalesInvoice.rdlc|RDLC,StandardSalesInvoiceBlueSimple.docx|Word,StandardSalesInvoiceBlueSimpleThemable.docx|Word,StandardSalesInvoiceDefEmail.docx|Word,StandardSalesInvoiceVatSpec.docx|Word,');
        Observer.Expect('had 1306 row', 'Yes');
        Observer.Expect('insert(true) 1306', 'No');
        Observer.Expect('modify(true) 1306', 'Yes');
        Observer.Expect('rows after', '[1302||Yes|StandardSalesProFormaInv.docx|No][1303||Yes|StandardDraftSalesInvoiceBlue.docx|No][1304||Yes|StandardSalesQuoteBlue.docx|No][1306||Yes|StandardSalesInvoice.docx|No]');
        Observer.Verify();
    end;

    [Test]
    procedure QX_ODataEdmType_RowsAndEdmXml()
    var
        EdmType: Record "OData Edm Type";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Keys: Text;
        Txt: Text;
    begin
        EdmType.SetFilter("Key", '<>LTQX*');
        if EdmType.FindSet() then
            repeat
                Keys += EdmType."Key" + ',';
            until EdmType.Next() = 0;
        Observer.Observe('fresh count', Format(EdmType.Count()));
        Observer.Observe('fresh keys', CopyStr(Keys, 1, 1000));
        EdmType.Reset();
        Observer.Observe('write permission', Format(EdmType.WritePermission()));
        if EdmType.Get('LTQX-EDM') then
            EdmType.Delete();
        EdmType.SetAutoCalcFields("Edm Xml");
        Observer.Observe('get missing', Format(EdmType.Get('LTQX-EDM')));
        Clear(EdmType);
        EdmType."Key" := 'LTQX-EDM';
        EdmType.Description := 'first';
        EdmType."Edm Xml".CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<ComplexType Name="ltqx"><Property Name="a" Type="Edm.String" /></ComplexType>');
        Observer.Observe('insert(true)', Format(EdmType.Insert(true)));
        Clear(EdmType);
        EdmType.SetAutoCalcFields("Edm Xml");
        Observer.Observe('get', Format(EdmType.Get('LTQX-EDM')));
        Observer.Observe('edm xml hasvalue', Format(EdmType."Edm Xml".HasValue()));
        EdmType."Edm Xml".CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Txt);
        Observer.Observe('edm xml text', Txt);
        EdmType.Description := 'second';
        EdmType."Edm Xml".CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<x/>');
        Observer.Observe('modify(true)', Format(EdmType.Modify(true)));
        Clear(EdmType);
        EdmType.Get('LTQX-EDM');
        EdmType.CalcFields("Edm Xml");
        EdmType."Edm Xml".CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Txt);
        Observer.Observe('after modify', EdmType.Description + '|' + Txt);
        Observer.Observe('delete', Format(EdmType.Delete()));
        Observer.Expect('fresh count', '6');
        Observer.Expect('fresh keys', 'BOOKINGSDATE,DIMENSION,DOCUMENTLINEOBJECTDETAILS,ITEM-UOM,ITEM-UOM-CONVERSION,POSTALADDRESS,');
        Observer.Expect('write permission', 'Yes');
        Observer.Expect('get missing', 'No');
        Observer.Expect('insert(true)', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('edm xml hasvalue', 'Yes');
        Observer.Expect('edm xml text', '<ComplexType Name="ltqx"><Property Name="a" Type="Edm.String" /></ComplexType>');
        Observer.Expect('modify(true)', 'Yes');
        Observer.Ignore('after modify');
        Observer.Expect('delete', 'Yes');
        Observer.Verify();
    end;

    // ---- Writer RE (Microsoft's DemoTool, Graph Mgt - General Tools.InsertOrUpdateODataType from UpdateAPIData): Description and Edm Xml of the
    // 6 OData Edm Type rows of a fresh tenant (their keys are pinned in QX_ODataEdmType_RowsAndEdmXml). Each Edm Xml text is one line. ----

    local procedure ReEdmXml(EdmKey: Code[50]): Text
    var
        EdmType: Record "OData Edm Type";
        InS: InStream;
        Line: Text;
        Txt: Text;
        Lf: Text[1];
    begin
        if not EdmType.Get(EdmKey) then
            exit('<no row>');
        EdmType.CalcFields("Edm Xml");
        if not EdmType."Edm Xml".HasValue() then
            exit('<no value>');
        Lf[1] := 10;
        EdmType."Edm Xml".CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            if Txt <> '' then
                Txt += Lf;
            Txt += Line;
        end;
        exit(Txt);
    end;

    local procedure ReVerifyEdmXml(EdmKey: Code[50]; Expected: Text)
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('edm xml', ReEdmXml(EdmKey));
        Observer.Expect('edm xml', Expected);
        Observer.Verify();
    end;

    [Test]
    procedure RE_ODataEdmType_FreshDescriptions()
    var
        EdmType: Record "OData Edm Type";
        Observer: Codeunit "Probe Observer";
    begin
        if EdmType.Get('BOOKINGSDATE') then
            Observer.Observe('BOOKINGSDATE', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('BOOKINGSDATE', '<no row>');
        if EdmType.Get('DIMENSION') then
            Observer.Observe('DIMENSION', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('DIMENSION', '<no row>');
        if EdmType.Get('DOCUMENTLINEOBJECTDETAILS') then
            Observer.Observe('DOCUMENTLINEOBJECTDETAILS', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('DOCUMENTLINEOBJECTDETAILS', '<no row>');
        if EdmType.Get('ITEM-UOM') then
            Observer.Observe('ITEM-UOM', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('ITEM-UOM', '<no row>');
        if EdmType.Get('ITEM-UOM-CONVERSION') then
            Observer.Observe('ITEM-UOM-CONVERSION', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('ITEM-UOM-CONVERSION', '<no row>');
        if EdmType.Get('POSTALADDRESS') then
            Observer.Observe('POSTALADDRESS', 'description=[' + EdmType.Description + '] edm xml length=' + Format(StrLen(ReEdmXml(EdmType."Key"))))
        else
            Observer.Observe('POSTALADDRESS', '<no row>');
        Observer.Expect('BOOKINGSDATE', 'description=[Graph CDM - Bookings Date complex type] edm xml length=168');
        Observer.Expect('DIMENSION', 'description=[Graph CDM - Dimension complex type.] edm xml length=306');
        Observer.Expect('DOCUMENTLINEOBJECTDETAILS', 'description=[Graph API - Complex type exposing details of the line object that is being sold.] edm xml length=218');
        Observer.Expect('ITEM-UOM', 'description=[Graph CDM - Unit of Measure complex type on Item Entity page] edm xml length=357');
        Observer.Expect('ITEM-UOM-CONVERSION', 'description=[Graph CDM - Unit of Measure Conversions complex type on Item Entity page] edm xml length=225');
        Observer.Expect('POSTALADDRESS', 'description=[Graph CDM - Postal Address complex type] edm xml length=440');
        Observer.Verify();
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_BookingsDate()
    begin
        ReVerifyEdmXml('BOOKINGSDATE', '<ComplexType Name="dateTimeTimeZoneType">  <Property Name="dateTime" Type="Edm.String" Nullable="false" />  <Property Name="timeZone" Type="Edm.String" /></ComplexType>');
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_Dimension()
    begin
        ReVerifyEdmXml('DIMENSION', '<ComplexType Name="dimensionType"><Property Name="code" Type="Edm.String" Nullable="false" /><Property Name="displayName" Type="Edm.String" Nullable="true" /><Property Name="valueCode" Type="Edm.String" Nullable="false" /><Property Name="valueDisplayName" Type="Edm.String" Nullable="true" /></ComplexType>');
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_DocumentLineObjectDetails()
    begin
        ReVerifyEdmXml('DOCUMENTLINEOBJECTDETAILS', '<ComplexType Name="documentLineObjectDetailsType"><Property Name="number" Type="Edm.String" Nullable="true" MaxLength="20"/><Property Name="displayName" Type="Edm.String" Nullable="true" MaxLength="100"/></ComplexType>');
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_ItemUom()
    begin
        ReVerifyEdmXml('ITEM-UOM', '<ComplexType Name="unitOfMeasureType"><Property Name="code" Type="Edm.String" Nullable="true" MaxLength="10" /><Property Name="displayName" Type="Edm.String" Nullable="true" MaxLength="50" /><Property Name="symbol" Type="Edm.String" Nullable="true" MaxLength="10" /><Property Name="unitConversion" Type="ITEM-UOM-CONVERSION" Nullable="true" /></ComplexType>');
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_ItemUomConversion()
    begin
        ReVerifyEdmXml('ITEM-UOM-CONVERSION', '<ComplexType Name="itemUnitOfMeasureConversionType"><Property Name="toUnitOfMeasure" Type="Edm.String" Nullable="true" MaxLength="10" /><Property Name="fromToConversionRate" Type="Edm.Decimal" Nullable="true" /></ComplexType>');
    end;

    [Test]
    procedure RE_ODataEdmType_EdmXml_PostalAddress()
    begin
        ReVerifyEdmXml('POSTALADDRESS', '<ComplexType Name="postalAddressType"><Property Name="street" Type="Edm.String" Nullable="true" MaxLength="152" /><Property Name="city" Type="Edm.String" Nullable="true" MaxLength="30" /><Property Name="state" Type="Edm.String" Nullable="true" MaxLength="30" /><Property Name="countryLetterCode" Type="Edm.String" Nullable="true" MaxLength="10" /><Property Name="postalCode" Type="Edm.String" Nullable="true" MaxLength="20" /></ComplexType>');
    end;

#if BC29PLUS
    // Writer Y17 (gap cycle 1 G8): Tenant Report Layout Cfg (2000000249, from BC 29), the table Microsoft's Composite Layout tests fill
    // (Report ID, Layout Name, Company Name; Header Part Name and Theme Part Name as '<app id lower case>::<layout name>'). The parts are
    // the layouts of report 91874 below; report 91873 (UgReportLayoutList.al) has a layout of the Default subtype.
    local procedure Y17Part(LayoutName: Text): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(LowerCase(Format(Info.Id(), 0, 4)) + '::' + LayoutName);
    end;

    [Test]
    procedure Y17_TenantReportLayoutCfg_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Standard(Observer, 2000000249, '1=91874;2=' + Y17Part('Y17Body') + ';3=;4=' + Y17Part('Y17HF') + ';5=' + Y17Part('Y17Theme'), '1=91874;2=' + Y17Part('Y17Body') + ';3=', '4=');
        Observer.Expect('columns', 'ok:1:Report ID:Integer:4:Normal;2:Layout Name:Text:250:Normal;3:Company Name:Text:30:Normal;4:Header Part Name:Text:300:Normal;5:Theme Part Name:Text:300:Normal;');
        Observer.Expect('has_rows', 'ok:No');
        Observer.Expect('first_row', 'ok:none');
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('find_inserted', 'ok:1=91874;2=a1b2c3d4-e5f6-7890-abcd-ef1234567890::Y17Body;3=;4=a1b2c3d4-e5f6-7890-abcd-ef1234567890::Y17HF;5=a1b2c3d4-e5f6-7890-abcd-ef1234567890::Y17Theme;');
        Observer.Expect('count_inserted', 'ok:1');
        Observer.Expect('insert_duplicate', 'ok:No');
        Observer.Expect('modify', 'ok:Yes');
        Observer.Expect('find_modified', 'ok:1=91874;2=a1b2c3d4-e5f6-7890-abcd-ef1234567890::Y17Body;3=;4=;5=a1b2c3d4-e5f6-7890-abcd-ef1234567890::Y17Theme;');
        Observer.Expect('delete', 'ok:Yes');
        Observer.Expect('count_deleted', 'ok:0');
        Observer.Expect('insert_no_triggers', 'ok:Yes');
        Observer.Expect('delete_all_no_triggers', 'ok:done');
        Observer.Expect('count_after_delete_all', 'ok:0');
        Observer.Verify();
    end;

    // No TryFunction: a write inside a TryFunction is refused on the Linux CI containers (server setting); errors are caught with asserterror.
    local procedure Y17InsertCfg(ReportId: Integer; LayoutName: Text[250]; Company: Text[30]; HeaderPart: Text; ThemePart: Text)
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        Cfg.Init();
        Cfg."Report ID" := ReportId;
        Cfg."Layout Name" := LayoutName;
        Cfg."Company Name" := Company;
        Cfg."Header Part Name" := CopyStr(HeaderPart, 1, 300);
        Cfg."Theme Part Name" := CopyStr(ThemePart, 1, 300);
        // Insert with a return value: a duplicate key answers false instead of an error (an error of a duplicate is not caught here).
        Y17Inserted := Cfg.Insert(true);
    end;

    local procedure Y17Shorten(Value: Text): Text
    begin
        exit(Value.Replace(Y17Part(''), '<this app>::'));
    end;

    local procedure Y17CfgRows(): Text
    var
        Cfg: Record "Tenant Report Layout Cfg";
        Result: Text;
        Company: Text;
    begin
        if Cfg.FindSet() then
            repeat
                Company := Cfg."Company Name";
                if Company = CompanyName() then
                    Company := '<current company>';
                Result += Format(Cfg."Report ID") + '|' + Y17Shorten(Cfg."Layout Name") + '|' + Company + '|' + Y17Shorten(Cfg."Header Part Name") + '|' + Y17Shorten(Cfg."Theme Part Name") + ';';
            until Cfg.Next() = 0;
        exit(Result);
    end;

    local procedure Y17Returned(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name, 'returned ' + Format(Y17Inserted));
        Y17Inserted := false;
    end;

    local procedure Y17Failed(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name, 'No');
        Observer.Observe(Name + '|text', Y17Shorten(GetLastErrorText()));
        ClearLastError();
    end;

    [Test]
    procedure Y17_TenantReportLayoutCfg_Shapes()
    var
        Cfg: Record "Tenant Report Layout Cfg";
        Layouts: Record "Report Layout List";
        Text1: Text;
        HF: Text;
        Th: Text;
        DHF: Text;
        DTh: Text;
    begin
        HF := Y17Part('Y17HF');
        Th := Y17Part('Y17Theme');
        DHF := Y17Part('Y17DefHF');
        DTh := Y17Part('Y17DefTheme');
        Layouts.SetFilter("Report ID", '%1|%2', 91874, 2000000001);
        Layouts.SetFilter(Name, 'Y17*');
        if Layouts.FindSet() then
            repeat
                Text1 += Format(Layouts."Report ID") + '|' + Layouts.Name + '|' + Format(Layouts."Layout Format") + '|' + Format(Layouts."Layout Subtype") + ';';
            until Layouts.Next() = 0;
        Y17Observer.Observe('part layouts', Text1);
        Y17Observer.Observe('fresh rows', Format(Cfg.Count()));
        Cfg.DeleteAll();
        // Inserts the platform refuses first (asserterror rolls back; the table is still empty), then the ones it accepts.
        asserterror Y17InsertCfg(0, '', '', 'x::A', 'y::B');
        Y17Failed(Y17Observer, 'invalid header part');
        asserterror Y17InsertCfg(0, '', '', DTh, DTh);
        Y17Failed(Y17Observer, 'header part of the theme subtype');
        asserterror Y17InsertCfg(0, '', '', HF, Th);
        Y17Failed(Y17Observer, 'global default, parts of an ordinary report');
        asserterror Y17InsertCfg(91874, 'Y17Body', '', HF, '');
        Y17Failed(Y17Observer, 'body layout by plain name');
        asserterror Y17InsertCfg(91873, CopyStr(Y17Part('Rdl'), 1, 250), '', DHF, DTh);
        Y17Failed(Y17Observer, 'default subtype layout');
        asserterror Y17InsertCfg(91874, CopyStr(Y17Part('NoSuchLayout'), 1, 250), '', HF, Th);
        Y17Failed(Y17Observer, 'undeclared layout');
        Y17InsertCfg(0, '', '', DHF, DTh);
        Y17Returned(Y17Observer, 'global default');
        Y17InsertCfg(0, '', CopyStr(CompanyName(), 1, 30), DHF, '');
        Y17Returned(Y17Observer, 'current company');
        Y17InsertCfg(91874, '', '', HF, Th);
        Y17Returned(Y17Observer, 'report level, own parts');
        Y17InsertCfg(91873, '', '', DHF, DTh);
        Y17Returned(Y17Observer, 'report level, default parts');
        Y17InsertCfg(91874, CopyStr(Y17Part('Y17Body'), 1, 250), '', HF, '');
        Y17Returned(Y17Observer, 'body layout by composite name');
        Y17InsertCfg(99999990, '', '', DHF, DTh);
        Y17Returned(Y17Observer, 'unknown report');
        Y17InsertCfg(0, '', '', DHF, DTh);
        Y17Returned(Y17Observer, 'duplicate');
        Y17Observer.Observe('rows', Y17CfgRows());
        Cfg.SetRange("Header Part Name", HF);
        Y17Observer.Observe('count header', Format(Cfg.Count()));
        Cfg.ModifyAll("Header Part Name", '');
        Y17Observer.Observe('modifyall header blank', 'Yes');
        Cfg.Reset();
        Y17Observer.Observe('rows after modifyall', Y17CfgRows());
        Y17Observer.Observe('get current company', Format(Cfg.Get(0, '', CopyStr(CompanyName(), 1, 30))) + '|' + Y17Shorten(Cfg."Header Part Name") + '|' + Y17Shorten(Cfg."Theme Part Name"));
        Cfg.DeleteAll();
        Y17Observer.Expect('part layouts', '91874|Y17Body|Word|Body;91874|Y17HF|Word|Header/Footer;91874|Y17Theme|Word|Theme;2000000001|Y17DefHF|Word|Header/Footer;2000000001|Y17DefTheme|Word|Theme;');
        Y17Observer.Expect('fresh rows', '0');
        Y17Observer.Expect('invalid header part', 'No');
        Y17Observer.Expect('invalid header part|text', 'The Header/Footer part ''x::A'' must reference a Header/Footer-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('header part of the theme subtype', 'No');
        Y17Observer.Expect('header part of the theme subtype|text', 'The Header/Footer part ''<this app>::Y17DefTheme'' must reference a Header/Footer-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('global default, parts of an ordinary report', 'No');
        Y17Observer.Expect('global default, parts of an ordinary report|text', 'The Header/Footer part ''<this app>::Y17HF'' must reference a Header/Footer-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('body layout by plain name', 'No');
        Y17Observer.Expect('body layout by plain name|text', 'The Body part ''Y17Body'' must reference a Body-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('default subtype layout', 'No');
        Y17Observer.Expect('default subtype layout|text', 'The Body part ''<this app>::Rdl'' must reference a Body-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('undeclared layout', 'No');
        Y17Observer.Expect('undeclared layout|text', 'The Body part ''<this app>::NoSuchLayout'' must reference a Body-subtype layout in the tenants Report Layout List.');
        Y17Observer.Expect('global default', 'returned Yes');
        Y17Observer.Expect('current company', 'returned Yes');
        Y17Observer.Expect('report level, own parts', 'returned Yes');
        Y17Observer.Expect('report level, default parts', 'returned Yes');
        Y17Observer.Expect('body layout by composite name', 'returned Yes');
        Y17Observer.Expect('unknown report', 'returned Yes');
        Y17Observer.Expect('duplicate', 'returned No');
        Y17Observer.Expect('rows', '0|||<this app>::Y17DefHF|<this app>::Y17DefTheme;0||<current company>|<this app>::Y17DefHF|;91873|||<this app>::Y17DefHF|<this app>::Y17DefTheme;91874|||<this app>::Y17HF|<this app>::Y17Theme;91874|<this app>::Y17Body||<this app>::Y17HF|;99999990|||<this app>::Y17DefHF|<this app>::Y17DefTheme;');
        Y17Observer.Expect('count header', '2');
        Y17Observer.Expect('modifyall header blank', 'Yes');
        Y17Observer.Expect('rows after modifyall', '0|||<this app>::Y17DefHF|<this app>::Y17DefTheme;0||<current company>|<this app>::Y17DefHF|;91873|||<this app>::Y17DefHF|<this app>::Y17DefTheme;91874||||<this app>::Y17Theme;91874|<this app>::Y17Body|||;99999990|||<this app>::Y17DefHF|<this app>::Y17DefTheme;');
        Y17Observer.Expect('get current company', 'Yes|<this app>::Y17DefHF|');
        Y17Observer.Verify();
    end;
#endif
}

#if BC29PLUS
// Writer Y17 (gap cycle 1 G8): a report with a Body, a HeaderFooter and a Theme layout (Word; the compiler writes the layout files at build).
report 91874 "LT Y17 Composite Parts"
{
    UsageCategory = None;
    DefaultRenderingLayout = Y17Body;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(Y17Body)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = './LtY17Body.docx';
        }
        layout(Y17HF)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './LtY17HF.docx';
        }
        layout(Y17Theme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './LtY17Theme.dotx';
        }
    }
}

// Header/footer and theme parts on the platform report "Tenant Report Defaults" (2000000001), where Microsoft's composite layout parts live.
reportextension 91875 "LT Y17 Default Parts" extends "Tenant Report Defaults"
{
    rendering
    {
        layout(Y17DefHF)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './LtY17DefHF.docx';
        }
        layout(Y17DefTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './LtY17DefTheme.dotx';
        }
    }
}
#endif
