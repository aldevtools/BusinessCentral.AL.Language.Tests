// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, with every column, of the platform table MediaResources on the fresh tenant of a test container (read through RecordRef by
// table name). The rows are named by Code; where a row differs between BC 27, 28 and 29 (or is missing in one), the expected text is guarded with BC28PLUS and BC29PLUS.
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78110.

codeunit 78110 "LT AD Plat Rows Media"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        if TableName = 'MediaResources' then
            exit(2000000182);
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef; MaxField: Integer): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class() = FieldClass::Normal) and ((MaxField = 0) or (FR.Number() <= MaxField)) then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure KeyText(var RR: RecordRef; KeyField: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = KeyField then
                exit(Format(FR.Value()));
        end;
    end;

    // Observes the rows whose KeyField value is in Keys (separated by ~), named by that value and not by position, because the rows of a platform
    // table differ between BC versions. A key without a row is observed as <absent>.
    local procedure DumpKeys(var Observer: Codeunit "Probe Observer"; TableName: Text; KeyField: Text; MaxField: Integer; Keys: Text)
    var
        RR: RecordRef;
        Rows: Dictionary of [Text, Text];
        RowKey: Text;
        Id: Integer;
    begin
        Id := TableIdByName(TableName);
        RR.Open(Id);
        if RR.FindSet() then
            repeat
                Rows.Set(KeyText(RR, KeyField), RowText(RR, MaxField));
            until RR.Next() = 0;
        foreach RowKey in Keys.Split('~') do
            if Rows.ContainsKey(RowKey) then
                Observer.Observe(TableName + ' row ' + RowKey, Rows.Get(RowKey))
            else
                Observer.Observe(TableName + ' row ' + RowKey, '<absent>');
    end;

    [Test]
    procedure Rows_MediaResources_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'MediaResources', 'Code', 0, '1305-1-DEFAULT.PNG~1306-1-DEFAULT.PNG~1307-1-DEFAULT.PNG~1307-1-PHONE.PNG~1309-1-DEFAULT.PNG~APPLICATIONCOUNTRY~ASSISTEDSETUP-NOTEXT-400PX.PNG~ASSISTEDSETUPDONE-NOTEXT-400PX.PNG~ASSISTEDSETUPINFO-NOTEXT.PNG~CANCELED INVOICE~COPILOTNOTAVAILABLE.PNG~DRAFT INVOICE');
        Observer.Expect('MediaResources row 1305-1-DEFAULT.PNG', 'Code=1305-1-DEFAULT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row 1306-1-DEFAULT.PNG', 'Code=1306-1-DEFAULT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row 1307-1-DEFAULT.PNG', 'Code=1307-1-DEFAULT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row 1307-1-PHONE.PNG', 'Code=1307-1-PHONE.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row 1309-1-DEFAULT.PNG', 'Code=1309-1-DEFAULT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row APPLICATIONCOUNTRY', 'Code=APPLICATIONCOUNTRY|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row ASSISTEDSETUP-NOTEXT-400PX.PNG', 'Code=ASSISTEDSETUP-NOTEXT-400PX.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row ASSISTEDSETUPDONE-NOTEXT-400PX.PNG', 'Code=ASSISTEDSETUPDONE-NOTEXT-400PX.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row ASSISTEDSETUPINFO-NOTEXT.PNG', 'Code=ASSISTEDSETUPINFO-NOTEXT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row CANCELED INVOICE', 'Code=CANCELED INVOICE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row COPILOTNOTAVAILABLE.PNG', 'Code=COPILOTNOTAVAILABLE.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row DRAFT INVOICE', 'Code=DRAFT INVOICE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_MediaResources_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'MediaResources', 'Code', 0, 'EXCELTEMPLATEAGEDACCOUNTSPAYABLE.XLTM~EXCELTEMPLATEAGEDACCOUNTSRECEIVABLE.XLTM~EXCELTEMPLATEBALANCESHEET.XLTM~EXCELTEMPLATECASHFLOWSTATEMENT.XLTM~EXCELTEMPLATEINCOMESTATEMENT.XLTM~EXCELTEMPLATERETAINEDEARNINGS.XLTM~EXCELTEMPLATETRIALBALANCE.XLTM~EXTERNALSYNC-NOTEXT.PNG~FIRSTINVOICE1.PNG~FIRSTINVOICE2.PNG~FIRSTINVOICE3.PNG~IMAGEANALYSIS-SETUP-NOTEXT.PNG');
        Observer.Expect('MediaResources row EXCELTEMPLATEAGEDACCOUNTSPAYABLE.XLTM', 'Code=EXCELTEMPLATEAGEDACCOUNTSPAYABLE.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATEAGEDACCOUNTSRECEIVABLE.XLTM', 'Code=EXCELTEMPLATEAGEDACCOUNTSRECEIVABLE.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATEBALANCESHEET.XLTM', 'Code=EXCELTEMPLATEBALANCESHEET.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATECASHFLOWSTATEMENT.XLTM', 'Code=EXCELTEMPLATECASHFLOWSTATEMENT.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATEINCOMESTATEMENT.XLTM', 'Code=EXCELTEMPLATEINCOMESTATEMENT.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATERETAINEDEARNINGS.XLTM', 'Code=EXCELTEMPLATERETAINEDEARNINGS.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXCELTEMPLATETRIALBALANCE.XLTM', 'Code=EXCELTEMPLATETRIALBALANCE.XLTM|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row EXTERNALSYNC-NOTEXT.PNG', 'Code=EXTERNALSYNC-NOTEXT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row FIRSTINVOICE1.PNG', 'Code=FIRSTINVOICE1.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row FIRSTINVOICE2.PNG', 'Code=FIRSTINVOICE2.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row FIRSTINVOICE3.PNG', 'Code=FIRSTINVOICE3.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row IMAGEANALYSIS-SETUP-NOTEXT.PNG', 'Code=IMAGEANALYSIS-SETUP-NOTEXT.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_MediaResources_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'MediaResources', 'Code', 0, 'INVOICING - SALESMAIL.HTML~LATEPAYMENTSTANDARDMODEL.TXT~OUTLOOKADDINILLUSTRATION.PNG~OVERDUE INVOICE~PAID INVOICE~PAYMENT SERVICE - MICROSOFT-LOGO.PNG~PAYMENT SERVICE - PAYPAL-LOGO.PNG~PAYMENT SERVICE - WORLDPAY-LOGO.PNG~POWERBI-OPTIN-480PX.PNG~QUOTE~SOCIAL - FACEBOOK.PNG~SOCIAL - INSTAGRAM.PNG');
        Observer.Expect('MediaResources row INVOICING - SALESMAIL.HTML', 'Code=INVOICING - SALESMAIL.HTML|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row LATEPAYMENTSTANDARDMODEL.TXT', 'Code=LATEPAYMENTSTANDARDMODEL.TXT|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row OUTLOOKADDINILLUSTRATION.PNG', 'Code=OUTLOOKADDINILLUSTRATION.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row OVERDUE INVOICE', 'Code=OVERDUE INVOICE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row PAID INVOICE', 'Code=PAID INVOICE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row PAYMENT SERVICE - MICROSOFT-LOGO.PNG', 'Code=PAYMENT SERVICE - MICROSOFT-LOGO.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row PAYMENT SERVICE - PAYPAL-LOGO.PNG', 'Code=PAYMENT SERVICE - PAYPAL-LOGO.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row PAYMENT SERVICE - WORLDPAY-LOGO.PNG', 'Code=PAYMENT SERVICE - WORLDPAY-LOGO.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row POWERBI-OPTIN-480PX.PNG', 'Code=POWERBI-OPTIN-480PX.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row QUOTE', 'Code=QUOTE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - FACEBOOK.PNG', 'Code=SOCIAL - FACEBOOK.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - INSTAGRAM.PNG', 'Code=SOCIAL - INSTAGRAM.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_MediaResources_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'MediaResources', 'Code', 0, 'SOCIAL - LINKEDIN.PNG~SOCIAL - PINTEREST.PNG~SOCIAL - TWITTER.PNG~SOCIAL - YELP.PNG~SOCIAL - YOUTUBE.PNG~TEAMSAPPILLUSTRATION.PNG~UNPAID INVOICE~WHATSNEWWIZARD-BANNER-FIRST.PNG~WHATSNEWWIZARD-BANNER-SECOND.PNG');
        Observer.Expect('MediaResources row SOCIAL - LINKEDIN.PNG', 'Code=SOCIAL - LINKEDIN.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - PINTEREST.PNG', 'Code=SOCIAL - PINTEREST.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - TWITTER.PNG', 'Code=SOCIAL - TWITTER.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - YELP.PNG', 'Code=SOCIAL - YELP.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row SOCIAL - YOUTUBE.PNG', 'Code=SOCIAL - YOUTUBE.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row TEAMSAPPILLUSTRATION.PNG', 'Code=TEAMSAPPILLUSTRATION.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row UNPAID INVOICE', 'Code=UNPAID INVOICE|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row WHATSNEWWIZARD-BANNER-FIRST.PNG', 'Code=WHATSNEWWIZARD-BANNER-FIRST.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Expect('MediaResources row WHATSNEWWIZARD-BANNER-SECOND.PNG', 'Code=WHATSNEWWIZARD-BANNER-SECOND.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_MediaResources_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'MediaResources', 'Code', 0, 'FIRSTINVOICESPLASH.PNG');
        Observer.Expect('MediaResources row FIRSTINVOICESPLASH.PNG', 'Code=FIRSTINVOICESPLASH.PNG|MediaSet Reference=<MediaSet>|Media Reference=<Media>|Blob=<BLOB>|');
        Observer.Verify();
    end;

    [Test]
    procedure Count_MediaResources()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(TableIdByName('MediaResources'));
        Observer.Observe('count', Format(RR.Count()));
        Observer.Expect('count', '46');
        Observer.Verify();
    end;
}
