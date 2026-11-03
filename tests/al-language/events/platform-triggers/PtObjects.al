// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: self-contained, log 69880 and subscribers 69881 are in PtFixtures.al; this file holds the runner 69882, table 69883, pages 69884 and 69885 and enum extension 70480
// BC versions: 27.0 to 29.0

table 69883 "LT W Pt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code Value"; Code[20]) { }
        field(3; Txt; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; D; Date) { }
        field(6; DT; DateTime) { }
        field(7; T; Time) { }
        field(8; Cnt; Integer) { }
        field(9; Cap; Code[20]) { CaptionClass = '3,Caption three'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69884 "LT W Pt List"
{
    PageType = List;
    SourceTable = "LT W Pt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(CodeCtl; Rec."Code Value") { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(AmountCtl; Rec.Amount) { ApplicationArea = All; AutoFormatType = 1; AutoFormatExpression = ''; }
                field(DCtl; Rec.D) { ApplicationArea = All; }
                field(DTCtl; Rec.DT) { ApplicationArea = All; }
                field(TCtl; Rec.T) { ApplicationArea = All; }
                field(CapCtl; Rec.Cap) { ApplicationArea = All; }
            }
        }
    }
}

page 69885 "LT W Pt Card"
{
    PageType = Card;
    SourceTable = "LT W Pt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(AmountCtl; Rec.Amount) { ApplicationArea = All; AutoFormatType = 2; AutoFormatExpression = ''; }
            cuegroup(Cues)
            {
                field(CntCue; Rec.Cnt) { ApplicationArea = All; }
            }
        }
    }
}

enumextension 70480 "LT W Pt Copilot Cap" extends "Copilot Capability"
{
    value(69880; "LT W Pt Cap") { Caption = 'LT W Pt Cap'; }
}

codeunit 69882 "LT W Pt Runner"
{
    trigger OnRun()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        Log.SetResult(Run(Log.Which()));
    end;

    local procedure Run(Which: Text): Text
    var
        Row: Record "LT W Pt Row";
        Privacy: Codeunit "Privacy Notice";
        Capability: Codeunit "Copilot Capability";
        UserSettingsMgt: Codeunit "User Settings";
        FeatureMgt: Codeunit "Feature Management Facade";
        TempSettings: Record "User Settings" temporary;
        Notif: Notification;
        Dec: Decimal;
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        MyNotif: Record "My Notifications";
        Blob: Codeunit "Temp Blob";
        Id: Guid;
        AppConstants: Codeunit "Application System Constants";
    begin
        case Which of
            'appver':
                exit(AppConstants.ApplicationVersion());
            'appbuild':
                exit(AppConstants.ApplicationBuild());
            'buildfile':
                exit(AppConstants.BuildFileVersion());
            'platfile':
                exit(AppConstants.PlatformFileVersion());
            'round':
                exit(Format(Round(1.2345)) + ';' + Format(Round(1.2345, 0.1)) + ';' + Format(Round(2.5, 1, '=')));
            'format':
                exit(Format(1234.5) + ';' + Format(1234.5, 0, '<Precision,2:2><Standard Format,0>') + ';' + Format(1234.5, 0, 9));
            'evaluate':
                begin
                    Evaluate(Dec, '12,5');
                    exit(Format(Dec));
                end;
            'fieldcap':
                exit(Row.FieldCaption(Cap));
            'fieldcaptxt':
                exit(Row.FieldCaption(Txt));
            'datefilter':
                begin
                    Row.SetFilter(D, '>=%1', DMY2Date(1, 1, 2020));
                    exit(Row.GetFilter(D));
                end;
            'datefiltertext':
                begin
                    Row.SetFilter(D, '010120..311220');
                    exit(Row.GetFilter(D));
                end;
            'datetimefilter':
                begin
                    Row.SetFilter(DT, '>=%1', CreateDateTime(DMY2Date(1, 1, 2020), 120000T));
                    exit(Row.GetFilter(DT));
                end;
            'timefilter':
                begin
                    Row.SetFilter(T, '>=%1', 120000T);
                    exit(Row.GetFilter(T));
                end;
            'baddate':
                begin
                    Row.SetFilter(D, 'abc');
                    exit(Row.GetFilter(D));
                end;
            'baddatetime':
                begin
                    Row.SetFilter(DT, 'abc');
                    exit(Row.GetFilter(DT));
                end;
            'badtime':
                begin
                    Row.SetFilter(T, 'abc');
                    exit(Row.GetFilter(T));
                end;
            'badint':
                begin
                    Row.SetFilter(Id, 'abc');
                    exit(Row.GetFilter(Id));
                end;
            'baddec':
                begin
                    Row.SetFilter(Amount, 'abc');
                    exit(Row.GetFilter(Amount));
                end;
            'baddate2':
                begin
                    Row.SetFilter(D, '010120..311220');
                    exit(Row.GetFilter(D));
                end;
            'mynotif':
                begin
                    Id := '{22222222-3333-4444-5555-666666666666}';
                    MyNotif.InsertDefault(Id, 'LT W Pt', 'LT W Pt notification', true);
                    exit(Format(MyNotif.IsEnabled(Id)));
                end;
            'mynotifoff':
                begin
                    Id := '{22222222-3333-4444-5555-666666666666}';
                    MyNotif.InsertDefault(Id, 'LT W Pt', 'LT W Pt notification', true);
                    MyNotif.Disable(Id);
                    exit(Format(MyNotif.IsEnabled(Id)));
                end;
            'download':
                begin
                    Blob.CreateOutStream(OutStr);
                    OutStr.WriteText('x');
                    FileName := 'a.txt';
                    Blob.CreateInStream(InStr);
                    exit(Format(DownloadFromStream(InStr, '', '', '', FileName)));
                end;
            'pagerun0':
                begin
                    Row.Id := 1;
                    Page.Run(0, Row);
                    exit('done');
                end;
            'view':
                begin
                    Row.SetView('WHERE(D=FILTER(010120..))');
                    exit(Row.GetFilter(D));
                end;
            'notifsend':
                begin
                    Notif.Id := CreateGuid();
                    Notif.Message := 'LT W Pt';
                    Notif.Send();
                    Notif.Recall();
                    exit('sent');
                end;
            'hyperlink':
                begin
                    Hyperlink('https://example.com/');
                    exit('done');
                end;
            'geturl':
                exit(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 69884));
            'copilotactive':
                exit(Format(Capability.IsCapabilityActive(Enum::"Copilot Capability"::"LT W Pt Cap")) + ';' + Format(Capability.IsCapabilityRegistered(Enum::"Copilot Capability"::"LT W Pt Cap")));
            'privstate':
                exit(Format(Privacy.GetPrivacyNoticeApprovalState('LT-W-PRIV')));
            'privconfirm':
                exit(Format(Privacy.ConfirmPrivacyNoticeApproval('LT-W-PRIV')));
            'usersettings':
                begin
                    UserSettingsMgt.GetUserSettings(UserSecurityId(), TempSettings);
                    exit(Dump(TempSettings));
                end;
            'legacybar':
                begin
                    UserSettingsMgt.DisableLegacyActionBar(UserSecurityId());
                    exit('done');
                end;
            'feature':
                exit(Format(FeatureMgt.IsEnabled('LT-W-FEATURE')));
            'saveasxml':
                begin
                    Blob.CreateOutStream(OutStr);
                    exit(Format(Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Xml, OutStr)));
                end;
            'saveaspdf':
                begin
                    Blob.CreateOutStream(OutStr);
                    exit(Format(Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Pdf, OutStr)));
                end;
            'guid':
                begin
                    Id := CreateGuid();
                    exit('guid');
                end;
        end;
        Error('unknown action %1', Which);
    end;

    local procedure Dump(var Rec: Record "User Settings" temporary): Text
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        I: Integer;
        Result: Text;
    begin
        RecRef.GetTable(Rec);
        for I := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(I);
            Result += FRef.Name() + '=' + Format(FRef.Value()) + ';';
        end;
        exit(Result);
    end;
}
