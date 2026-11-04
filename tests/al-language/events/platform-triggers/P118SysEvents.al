// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: self-contained (71208-71214)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// P118 platform events of the System Action / Company / UI Helper / Filter Helper trigger codeunits: own subscribers log when the platform raises them.
// BC versions: 29 (27 and 28 by CI)

table 71211 "LT P118 Filter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code Value"; Code[20]) { }
        field(3; Amount; Decimal) { }
        field(4; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71212 "LT P118 AutoFmt Card"
{
    PageType = Card;
    SourceTable = "LT P118 Filter Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Cur; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
            }
            field(Cust; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 11;
                AutoFormatExpression = '<Precision,3:3><Standard Format,0>';
            }
        }
    }
}

codeunit 71208 "LT P118 Sys Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure CountOf(Entry: Text): Integer
    var
        E: Text;
        N: Integer;
    begin
        foreach E in Entries do
            if E = Entry then
                N += 1;
        exit(N);
    end;

    procedure Total(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;
}

codeunit 71209 "LT P118 Sys Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnOpenInExcel', '', false, false)]
    local procedure OnOpenInExcel(Location: Text)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('OnOpenInExcel');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenLastErrorPage', '', false, false)]
    local procedure OpenLastErrorPage()
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('OpenLastErrorPage');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'SetNotificationStatus', '', false, false)]
    local procedure SetNotificationStatus(NotificationId: Guid; Enable: Boolean)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('SetNotificationStatus');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'ChangeCompany', '', false, false)]
    local procedure ChangeCompanyEvent(var NewCompanyName: Text)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('ChangeCompany');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetAutoStartTours', '', false, false)]
    local procedure GetAutoStartTours(var IsEnabled: Boolean)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('GetAutoStartTours');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPowerPlatformEnvironmentId', '', false, false)]
    local procedure GetPowerPlatformEnvironmentId(Scenario: Text; var EnvironmentId: Text)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('GetPowerPlatformEnvironmentId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetFindEntriesPageId', '', false, false)]
    local procedure GetFindEntriesPageId(var PageId: Integer)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('GetFindEntriesPageId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('OnCompanyOpenCompleted');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'AutoFormatTranslate', '', false, false)]
    local procedure AutoFormatTranslate(AutoFormatType: Integer; AutoFormatExpr: Text[80]; var Translation: Text[80])
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('AutoFormatTranslate:' + Format(AutoFormatType) + ':' + AutoFormatExpr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetApplicationLanguage', '', false, false)]
    local procedure GetApplicationLanguage(var Language: Integer)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('GetApplicationLanguage');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeCodeFilter', '', false, false)]
    local procedure MakeCodeFilter(var TextFilterText: Text)
    var
        Log: Codeunit "LT P118 Sys Log";
    begin
        Log.Add('MakeCodeFilter:' + TextFilterText);
    end;
}

codeunit 71210 "LT P118 Sys Events Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P118_NoCauseForUiEvents()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Sys Log";
    begin
        // The events that only a client action raises: observe whether the test session sees them.
        Log.Reset();
        Observer.Observe('OnOpenInExcel', Format(Log.CountOf('OnOpenInExcel')));
        Observer.Observe('OpenLastErrorPage', Format(Log.CountOf('OpenLastErrorPage')));
        Observer.Observe('SetNotificationStatus', Format(Log.CountOf('SetNotificationStatus')));
        Observer.Observe('ChangeCompany', Format(Log.CountOf('ChangeCompany')));
        Observer.Observe('GetAutoStartTours', Format(Log.CountOf('GetAutoStartTours')));
        Observer.Observe('GetPowerPlatformEnvironmentId', Format(Log.CountOf('GetPowerPlatformEnvironmentId')));
        Observer.Observe('GetFindEntriesPageId', Format(Log.CountOf('GetFindEntriesPageId')));
        Observer.Observe('OnCompanyOpenCompleted', Format(Log.CountOf('OnCompanyOpenCompleted')));
        Observer.Observe('total', Format(Log.Total()));
        Observer.Expect('OnOpenInExcel', '0');
        Observer.Expect('OpenLastErrorPage', '0');
        Observer.Expect('SetNotificationStatus', '0');
        Observer.Expect('ChangeCompany', '0');
        Observer.Expect('GetAutoStartTours', '0');
        Observer.Expect('GetPowerPlatformEnvironmentId', '0');
        Observer.Expect('GetFindEntriesPageId', '0');
        Observer.Expect('OnCompanyOpenCompleted', '0');
        Observer.Expect('total', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P118_MakeCodeFilter_SetFilterOnCode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Sys Log";
        Row: Record "LT P118 Filter Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Code Value" := 'ABC';
        Row.Insert();
        Log.Reset();
        Row.SetFilter("Code Value", 'ab*');
        Observer.Observe('log-after-wildcard', Log.Joined());
        Observer.Observe('count-wildcard', Format(Row.Count()));
        Row.SetFilter("Code Value", '<>%1', 'X');
        Observer.Observe('log-after-neq', Log.Joined());
        Row.SetRange("Code Value", 'ABC');
        Observer.Observe('log-after-range', Log.Joined());
        Row.Reset();
        Row.SetFilter("Code Value", 'a..b|c');
        Observer.Observe('log-after-complex', Log.Joined());
        Observer.Observe('MakeCodeFilter-count', Format(Log.CountOf('MakeCodeFilter:ab*')));
        Observer.Expect('log-after-wildcard', '');
        Observer.Expect('count-wildcard', '1');
        Observer.Expect('log-after-neq', '');
        Observer.Expect('log-after-range', '');
        Observer.Expect('log-after-complex', '');
        Observer.Expect('MakeCodeFilter-count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P118_MakeCodeFilter_GetFilterAndCopy()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Sys Log";
        Row: Record "LT P118 Filter Row";
        Other: Record "LT P118 Filter Row";
    begin
        Row.DeleteAll();
        Log.Reset();
        Row.SetFilter("Code Value", '1|2');
        Observer.Observe('filter', Row.GetFilter("Code Value"));
        Other.CopyFilters(Row);
        Observer.Observe('log-after-copy', Log.Joined());
        Row.SetFilter(Amount, '>0');
        Observer.Observe('log-after-decimal', Log.Joined());
        Observer.Expect('filter', '1|2');
        Observer.Expect('log-after-copy', '');
        Observer.Expect('log-after-decimal', '');
        Observer.Verify();
    end;

    [Test]
    procedure P118_GetApplicationLanguage_Reads()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P118 Sys Log";
        Dec: Decimal;
        Txt: Text;
    begin
        Log.Reset();
        Dec := 1234.5;
        Txt := Format(Dec);
        Observer.Observe('after-format', Format(Log.CountOf('GetApplicationLanguage')));
        Txt := Format(Dec, 0, 9);
        Observer.Observe('after-format-xml', Format(Log.CountOf('GetApplicationLanguage')));
        Txt := Format(CurrentDateTime(), 0, '<Year4>');
        Observer.Observe('after-datetime', Format(Log.CountOf('GetApplicationLanguage')));
        Observer.Observe('total', Format(Log.Total()));
        Observer.Expect('after-format', '0');
        Observer.Expect('after-format-xml', '0');
        Observer.Expect('after-datetime', '0');
        Observer.Expect('total', '0');
        Observer.Verify();
    end;
}
