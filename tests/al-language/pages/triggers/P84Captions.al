// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 73037, page 73038, log codeunit 73039 (used only by test codeunit 73040), test codeunit 73040
// Probe: written against BC 29 ...; observed values are added by the lead after measuring (tag P84, GitHub issue #84)
// Facts: CaptionClass expressions on table fields and page controls, with no subscriber, with a logging subscriber and with a resolving subscriber of codeunit 'Caption Class' (OnResolveCaptionClass)
// BC versions: 29

table 73037 "LT P84 Cap Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Identifier'; }
        field(2; Plain; Text[30]) { Caption = 'Plain Field'; }
        field(11; F01; Text[30]) { Caption = 'Tbl Caption 01'; CaptionClass = '1,1,x'; }
        field(12; F02; Text[30]) { Caption = 'Tbl Caption 02'; CaptionClass = '1,2,x'; }
        field(13; F03; Text[30]) { Caption = 'Tbl Caption 03'; CaptionClass = '3,x'; }
        field(14; F04; Text[30]) { Caption = 'Tbl Caption 04'; CaptionClass = '2,x'; }
        field(15; F05; Text[30]) { Caption = 'Tbl Caption 05'; CaptionClass = '1,1,'; }
        field(16; F06; Text[30]) { Caption = 'Tbl Caption 06'; CaptionClass = '3,'; }
        field(17; F07; Text[30]) { Caption = 'Tbl Caption 07'; CaptionClass = '1,1'; }
        field(18; F08; Text[30]) { Caption = 'Tbl Caption 08'; CaptionClass = '1,3,x'; }
        field(19; F09; Text[30]) { Caption = 'Tbl Caption 09'; CaptionClass = '1,9,x'; }
        field(20; F10; Text[30]) { Caption = 'Tbl Caption 10'; CaptionClass = '2,x,y'; }
        field(21; F11; Text[30]) { Caption = 'Tbl Caption 11'; CaptionClass = '3,a,b'; }
        field(22; F12; Text[30]) { Caption = 'Tbl Caption 12'; CaptionClass = '4,x'; }
        field(23; F13; Text[30]) { Caption = 'Tbl Caption 13'; CaptionClass = '0,x'; }
        field(24; F14; Text[30]) { Caption = 'Tbl Caption 14'; CaptionClass = ',x'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 73038 "LT P84 Cap Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Cap Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(C01; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 01';
                    CaptionClass = '1,1,x';
                }
                field(C02; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 02';
                    CaptionClass = '1,2,x';
                }
                field(C03; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 03';
                    CaptionClass = '3,x';
                }
                field(C04; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 04';
                    CaptionClass = '2,x';
                }
                field(C05; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 05';
                    CaptionClass = '1,1,';
                }
                field(C06; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 06';
                    CaptionClass = '3,';
                }
                field(C07; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 07';
                    CaptionClass = '1,1';
                }
                field(C08; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 08';
                    CaptionClass = '1,3,x';
                }
                field(C09; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 09';
                    CaptionClass = '1,9,x';
                }
                field(C10; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 10';
                    CaptionClass = '2,x,y';
                }
                field(C11; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 11';
                    CaptionClass = '3,a,b';
                }
                field(C12; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 12';
                    CaptionClass = '4,x';
                }
                field(C13; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 13';
                    CaptionClass = '0,x';
                }
                field(C14; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Caption 14';
                    CaptionClass = ',x';
                }
                field(CPlain; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Ctl Plain';
                }
            }
        }
    }
}

codeunit 73039 "LT P84 Cap Log"
{
    SingleInstance = true;

    var
        Mode: Text;
        Calls: Text;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
        Calls := '';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if Mode = '' then
            exit;
        Calls += '[' + CaptionArea + '|' + CaptionExpr + ']';
        if Mode = 'resolve' then begin
            Caption := 'R(' + CaptionArea + '|' + CaptionExpr + ')';
            Resolved := true;
        end;
        if Mode = 'caption-only' then
            Caption := 'C(' + CaptionArea + '|' + CaptionExpr + ')';
        if Mode = 'resolved-only' then
            Resolved := true;
    end;
}

codeunit 73040 "LT P84 Cap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CapLog: Codeunit "LT P84 Cap Log";

    local procedure Tbl(var Observer: Codeunit "Probe Observer"; Name: Text; Caption: Text)
    begin
        Observer.Observe(Name, Caption);
        Observer.Observe(Name + '_calls', CapLog.Take());
    end;

    [Test]
    procedure Table_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('');
        Observer.Observe('id', Rec.FieldCaption(Id));
        Observer.Observe('plain', Rec.FieldCaption(Plain));
        Observer.Observe('f01', Rec.FieldCaption(F01));
        Observer.Observe('f02', Rec.FieldCaption(F02));
        Observer.Observe('f03', Rec.FieldCaption(F03));
        Observer.Observe('f04', Rec.FieldCaption(F04));
        Observer.Observe('f05', Rec.FieldCaption(F05));
        Observer.Observe('f06', Rec.FieldCaption(F06));
        Observer.Observe('f07', Rec.FieldCaption(F07));
        Observer.Observe('f08', Rec.FieldCaption(F08));
        Observer.Observe('f09', Rec.FieldCaption(F09));
        Observer.Observe('f10', Rec.FieldCaption(F10));
        Observer.Observe('f11', Rec.FieldCaption(F11));
        Observer.Observe('f12', Rec.FieldCaption(F12));
        Observer.Observe('f13', Rec.FieldCaption(F13));
        Observer.Observe('f14', Rec.FieldCaption(F14));
        Observer.Expect('id', 'Identifier');
        Observer.Expect('plain', 'Plain Field');
        Observer.Expect('f01', '1,1,x');
        Observer.Expect('f02', '1,2,x');
        Observer.Expect('f03', 'x');
        Observer.Expect('f04', '2,x');
        Observer.Expect('f05', '1,1,');
        Observer.Expect('f06', 'Tbl Caption 06');
        Observer.Expect('f07', '1,1');
        Observer.Expect('f08', '1,3,x');
        Observer.Expect('f09', '1,9,x');
        Observer.Expect('f10', '2,x,y');
        Observer.Expect('f11', 'a,b');
        Observer.Expect('f12', '4,x');
        Observer.Expect('f13', '0,x');
        Observer.Expect('f14', ',x');
        Observer.Verify();
    end;

    [Test]
    procedure Page_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('');
        Page.OpenNew();
        Observer.Observe('c01', Page.C01.Caption());
        Observer.Observe('c02', Page.C02.Caption());
        Observer.Observe('c03', Page.C03.Caption());
        Observer.Observe('c04', Page.C04.Caption());
        Observer.Observe('c05', Page.C05.Caption());
        Observer.Observe('c06', Page.C06.Caption());
        Observer.Observe('c07', Page.C07.Caption());
        Observer.Observe('c08', Page.C08.Caption());
        Observer.Observe('c09', Page.C09.Caption());
        Observer.Observe('c10', Page.C10.Caption());
        Observer.Observe('c11', Page.C11.Caption());
        Observer.Observe('c12', Page.C12.Caption());
        Observer.Observe('c13', Page.C13.Caption());
        Observer.Observe('c14', Page.C14.Caption());
        Observer.Observe('plain', Page.CPlain.Caption());
        Page.Close();
        Observer.Expect('c01', '1,1,x');
        Observer.Expect('c02', '1,2,x');
        Observer.Expect('c03', 'x');
        Observer.Expect('c04', '2,x');
        Observer.Expect('c05', '1,1,');
        Observer.Expect('c06', 'Ctl Plain');
        Observer.Expect('c07', '1,1');
        Observer.Expect('c08', '1,3,x');
        Observer.Expect('c09', '1,9,x');
        Observer.Expect('c10', '2,x,y');
        Observer.Expect('c11', 'a,b');
        Observer.Expect('c12', '4,x');
        Observer.Expect('c13', '0,x');
        Observer.Expect('c14', ',x');
        Observer.Expect('plain', 'Ctl Plain');
        Observer.Verify();
    end;

    [Test]
    procedure Table_Log_A()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('log');
        Tbl(Observer, 'f01', Rec.FieldCaption(F01));
        Tbl(Observer, 'f02', Rec.FieldCaption(F02));
        Tbl(Observer, 'f03', Rec.FieldCaption(F03));
        Tbl(Observer, 'f04', Rec.FieldCaption(F04));
        Tbl(Observer, 'f05', Rec.FieldCaption(F05));
        Tbl(Observer, 'f06', Rec.FieldCaption(F06));
        Tbl(Observer, 'f07', Rec.FieldCaption(F07));
        CapLog.SetMode('');
        Observer.Expect('f01', '1,1,x');
        Observer.Expect('f01_calls', '');
        Observer.Expect('f02', '1,2,x');
        Observer.Expect('f02_calls', '');
        Observer.Expect('f03', 'x');
        Observer.Expect('f03_calls', '');
        Observer.Expect('f04', '2,x');
        Observer.Expect('f04_calls', '');
        Observer.Expect('f05', '1,1,');
        Observer.Expect('f05_calls', '');
        Observer.Expect('f06', 'Tbl Caption 06');
        Observer.Expect('f06_calls', '');
        Observer.Expect('f07', '1,1');
        Observer.Expect('f07_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_Log_A()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('log');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c01', Page.C01.Caption());
        Tbl(Observer, 'c02', Page.C02.Caption());
        Tbl(Observer, 'c03', Page.C03.Caption());
        Tbl(Observer, 'c04', Page.C04.Caption());
        Tbl(Observer, 'c05', Page.C05.Caption());
        Tbl(Observer, 'c06', Page.C06.Caption());
        Tbl(Observer, 'c07', Page.C07.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c01', '1,1,x');
        Observer.Expect('c01_calls', '');
        Observer.Expect('c02', '1,2,x');
        Observer.Expect('c02_calls', '');
        Observer.Expect('c03', 'x');
        Observer.Expect('c03_calls', '');
        Observer.Expect('c04', '2,x');
        Observer.Expect('c04_calls', '');
        Observer.Expect('c05', '1,1,');
        Observer.Expect('c05_calls', '');
        Observer.Expect('c06', 'Ctl Plain');
        Observer.Expect('c06_calls', '');
        Observer.Expect('c07', '1,1');
        Observer.Expect('c07_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_Log_B()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('log');
        Tbl(Observer, 'f08', Rec.FieldCaption(F08));
        Tbl(Observer, 'f09', Rec.FieldCaption(F09));
        Tbl(Observer, 'f10', Rec.FieldCaption(F10));
        Tbl(Observer, 'f11', Rec.FieldCaption(F11));
        Tbl(Observer, 'f12', Rec.FieldCaption(F12));
        Tbl(Observer, 'f13', Rec.FieldCaption(F13));
        Tbl(Observer, 'f14', Rec.FieldCaption(F14));
        CapLog.SetMode('');
        Observer.Expect('f08', '1,3,x');
        Observer.Expect('f08_calls', '');
        Observer.Expect('f09', '1,9,x');
        Observer.Expect('f09_calls', '');
        Observer.Expect('f10', '2,x,y');
        Observer.Expect('f10_calls', '');
        Observer.Expect('f11', 'a,b');
        Observer.Expect('f11_calls', '');
        Observer.Expect('f12', '4,x');
        Observer.Expect('f12_calls', '');
        Observer.Expect('f13', '0,x');
        Observer.Expect('f13_calls', '');
        Observer.Expect('f14', ',x');
        Observer.Expect('f14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_Log_B()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('log');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c08', Page.C08.Caption());
        Tbl(Observer, 'c09', Page.C09.Caption());
        Tbl(Observer, 'c10', Page.C10.Caption());
        Tbl(Observer, 'c11', Page.C11.Caption());
        Tbl(Observer, 'c12', Page.C12.Caption());
        Tbl(Observer, 'c13', Page.C13.Caption());
        Tbl(Observer, 'c14', Page.C14.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c08', '1,3,x');
        Observer.Expect('c08_calls', '');
        Observer.Expect('c09', '1,9,x');
        Observer.Expect('c09_calls', '');
        Observer.Expect('c10', '2,x,y');
        Observer.Expect('c10_calls', '');
        Observer.Expect('c11', 'a,b');
        Observer.Expect('c11_calls', '');
        Observer.Expect('c12', '4,x');
        Observer.Expect('c12_calls', '');
        Observer.Expect('c13', '0,x');
        Observer.Expect('c13_calls', '');
        Observer.Expect('c14', ',x');
        Observer.Expect('c14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_Resolve_A()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('resolve');
        Tbl(Observer, 'f01', Rec.FieldCaption(F01));
        Tbl(Observer, 'f02', Rec.FieldCaption(F02));
        Tbl(Observer, 'f03', Rec.FieldCaption(F03));
        Tbl(Observer, 'f04', Rec.FieldCaption(F04));
        Tbl(Observer, 'f05', Rec.FieldCaption(F05));
        Tbl(Observer, 'f06', Rec.FieldCaption(F06));
        Tbl(Observer, 'f07', Rec.FieldCaption(F07));
        CapLog.SetMode('');
        Observer.Expect('f01', '1,1,x');
        Observer.Expect('f01_calls', '');
        Observer.Expect('f02', '1,2,x');
        Observer.Expect('f02_calls', '');
        Observer.Expect('f03', 'x');
        Observer.Expect('f03_calls', '');
        Observer.Expect('f04', '2,x');
        Observer.Expect('f04_calls', '');
        Observer.Expect('f05', '1,1,');
        Observer.Expect('f05_calls', '');
        Observer.Expect('f06', 'Tbl Caption 06');
        Observer.Expect('f06_calls', '');
        Observer.Expect('f07', '1,1');
        Observer.Expect('f07_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_Resolve_A()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('resolve');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c01', Page.C01.Caption());
        Tbl(Observer, 'c02', Page.C02.Caption());
        Tbl(Observer, 'c03', Page.C03.Caption());
        Tbl(Observer, 'c04', Page.C04.Caption());
        Tbl(Observer, 'c05', Page.C05.Caption());
        Tbl(Observer, 'c06', Page.C06.Caption());
        Tbl(Observer, 'c07', Page.C07.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c01', '1,1,x');
        Observer.Expect('c01_calls', '');
        Observer.Expect('c02', '1,2,x');
        Observer.Expect('c02_calls', '');
        Observer.Expect('c03', 'x');
        Observer.Expect('c03_calls', '');
        Observer.Expect('c04', '2,x');
        Observer.Expect('c04_calls', '');
        Observer.Expect('c05', '1,1,');
        Observer.Expect('c05_calls', '');
        Observer.Expect('c06', 'Ctl Plain');
        Observer.Expect('c06_calls', '');
        Observer.Expect('c07', '1,1');
        Observer.Expect('c07_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_Resolve_B()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('resolve');
        Tbl(Observer, 'f08', Rec.FieldCaption(F08));
        Tbl(Observer, 'f09', Rec.FieldCaption(F09));
        Tbl(Observer, 'f10', Rec.FieldCaption(F10));
        Tbl(Observer, 'f11', Rec.FieldCaption(F11));
        Tbl(Observer, 'f12', Rec.FieldCaption(F12));
        Tbl(Observer, 'f13', Rec.FieldCaption(F13));
        Tbl(Observer, 'f14', Rec.FieldCaption(F14));
        CapLog.SetMode('');
        Observer.Expect('f08', '1,3,x');
        Observer.Expect('f08_calls', '');
        Observer.Expect('f09', '1,9,x');
        Observer.Expect('f09_calls', '');
        Observer.Expect('f10', '2,x,y');
        Observer.Expect('f10_calls', '');
        Observer.Expect('f11', 'a,b');
        Observer.Expect('f11_calls', '');
        Observer.Expect('f12', '4,x');
        Observer.Expect('f12_calls', '');
        Observer.Expect('f13', '0,x');
        Observer.Expect('f13_calls', '');
        Observer.Expect('f14', ',x');
        Observer.Expect('f14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_Resolve_B()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('resolve');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c08', Page.C08.Caption());
        Tbl(Observer, 'c09', Page.C09.Caption());
        Tbl(Observer, 'c10', Page.C10.Caption());
        Tbl(Observer, 'c11', Page.C11.Caption());
        Tbl(Observer, 'c12', Page.C12.Caption());
        Tbl(Observer, 'c13', Page.C13.Caption());
        Tbl(Observer, 'c14', Page.C14.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c08', '1,3,x');
        Observer.Expect('c08_calls', '');
        Observer.Expect('c09', '1,9,x');
        Observer.Expect('c09_calls', '');
        Observer.Expect('c10', '2,x,y');
        Observer.Expect('c10_calls', '');
        Observer.Expect('c11', 'a,b');
        Observer.Expect('c11_calls', '');
        Observer.Expect('c12', '4,x');
        Observer.Expect('c12_calls', '');
        Observer.Expect('c13', '0,x');
        Observer.Expect('c13_calls', '');
        Observer.Expect('c14', ',x');
        Observer.Expect('c14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_CaptionOnly_Sel()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('caption-only');
        Tbl(Observer, 'f01', Rec.FieldCaption(F01));
        Tbl(Observer, 'f03', Rec.FieldCaption(F03));
        Tbl(Observer, 'f06', Rec.FieldCaption(F06));
        Tbl(Observer, 'f09', Rec.FieldCaption(F09));
        Tbl(Observer, 'f14', Rec.FieldCaption(F14));
        CapLog.SetMode('');
        Observer.Expect('f01', '1,1,x');
        Observer.Expect('f01_calls', '');
        Observer.Expect('f03', 'x');
        Observer.Expect('f03_calls', '');
        Observer.Expect('f06', 'Tbl Caption 06');
        Observer.Expect('f06_calls', '');
        Observer.Expect('f09', '1,9,x');
        Observer.Expect('f09_calls', '');
        Observer.Expect('f14', ',x');
        Observer.Expect('f14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_CaptionOnly_Sel()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('caption-only');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c01', Page.C01.Caption());
        Tbl(Observer, 'c03', Page.C03.Caption());
        Tbl(Observer, 'c06', Page.C06.Caption());
        Tbl(Observer, 'c09', Page.C09.Caption());
        Tbl(Observer, 'c14', Page.C14.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c01', '1,1,x');
        Observer.Expect('c01_calls', '');
        Observer.Expect('c03', 'x');
        Observer.Expect('c03_calls', '');
        Observer.Expect('c06', 'Ctl Plain');
        Observer.Expect('c06_calls', '');
        Observer.Expect('c09', '1,9,x');
        Observer.Expect('c09_calls', '');
        Observer.Expect('c14', ',x');
        Observer.Expect('c14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_ResolvedOnly_Sel()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('resolved-only');
        Tbl(Observer, 'f01', Rec.FieldCaption(F01));
        Tbl(Observer, 'f03', Rec.FieldCaption(F03));
        Tbl(Observer, 'f06', Rec.FieldCaption(F06));
        Tbl(Observer, 'f09', Rec.FieldCaption(F09));
        Tbl(Observer, 'f14', Rec.FieldCaption(F14));
        CapLog.SetMode('');
        Observer.Expect('f01', '1,1,x');
        Observer.Expect('f01_calls', '');
        Observer.Expect('f03', 'x');
        Observer.Expect('f03_calls', '');
        Observer.Expect('f06', 'Tbl Caption 06');
        Observer.Expect('f06_calls', '');
        Observer.Expect('f09', '1,9,x');
        Observer.Expect('f09_calls', '');
        Observer.Expect('f14', ',x');
        Observer.Expect('f14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Page_ResolvedOnly_Sel()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P84 Cap Card";
    begin
        CapLog.SetMode('resolved-only');
        Page.OpenNew();
        Observer.Observe('open_calls', CapLog.Take());
        Tbl(Observer, 'c01', Page.C01.Caption());
        Tbl(Observer, 'c03', Page.C03.Caption());
        Tbl(Observer, 'c06', Page.C06.Caption());
        Tbl(Observer, 'c09', Page.C09.Caption());
        Tbl(Observer, 'c14', Page.C14.Caption());
        CapLog.SetMode('');
        Page.Close();
        Observer.Expect('open_calls', '');
        Observer.Expect('c01', '1,1,x');
        Observer.Expect('c01_calls', '');
        Observer.Expect('c03', 'x');
        Observer.Expect('c03_calls', '');
        Observer.Expect('c06', 'Ctl Plain');
        Observer.Expect('c06_calls', '');
        Observer.Expect('c09', '1,9,x');
        Observer.Expect('c09_calls', '');
        Observer.Expect('c14', ',x');
        Observer.Expect('c14_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Captions()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FRef: FieldRef;
        Index: Integer;
    begin
        CapLog.SetMode('');
        RecRef.Open(Database::"LT P84 Cap Rec");
        for Index := 11 to 24 do begin
            FRef := RecRef.Field(Index);
            Observer.Observe('nolog_' + Format(Index), FRef.Caption());
        end;
        RecRef.Close();
        Observer.Expect('nolog_11', '1,1,x');
        Observer.Expect('nolog_12', '1,2,x');
        Observer.Expect('nolog_13', 'x');
        Observer.Expect('nolog_14', '2,x');
        Observer.Expect('nolog_15', '1,1,');
        Observer.Expect('nolog_16', 'Tbl Caption 06');
        Observer.Expect('nolog_17', '1,1');
        Observer.Expect('nolog_18', '1,3,x');
        Observer.Expect('nolog_19', '1,9,x');
        Observer.Expect('nolog_20', '2,x,y');
        Observer.Expect('nolog_21', 'a,b');
        Observer.Expect('nolog_22', '4,x');
        Observer.Expect('nolog_23', '0,x');
        Observer.Expect('nolog_24', ',x');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Resolved()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FRef: FieldRef;
        Index: Integer;
    begin
        CapLog.SetMode('resolve');
        RecRef.Open(Database::"LT P84 Cap Rec");
        for Index := 11 to 17 do begin
            FRef := RecRef.Field(Index);
            Observer.Observe('res_' + Format(Index), FRef.Caption());
            Observer.Observe('res_' + Format(Index) + '_calls', CapLog.Take());
        end;
        CapLog.SetMode('');
        RecRef.Close();
        Observer.Expect('res_11', '1,1,x');
        Observer.Expect('res_11_calls', '');
        Observer.Expect('res_12', '1,2,x');
        Observer.Expect('res_12_calls', '');
        Observer.Expect('res_13', 'x');
        Observer.Expect('res_13_calls', '');
        Observer.Expect('res_14', '2,x');
        Observer.Expect('res_14_calls', '');
        Observer.Expect('res_15', '1,1,');
        Observer.Expect('res_15_calls', '');
        Observer.Expect('res_16', 'Tbl Caption 06');
        Observer.Expect('res_16_calls', '');
        Observer.Expect('res_17', '1,1');
        Observer.Expect('res_17_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Table_ReadTwice_CallCount()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P84 Cap Rec";
    begin
        CapLog.SetMode('resolve');
        Observer.Observe('first', Rec.FieldCaption(F03));
        Observer.Observe('first_calls', CapLog.Take());
        Observer.Observe('second', Rec.FieldCaption(F03));
        Observer.Observe('second_calls', CapLog.Take());
        Observer.Observe('other_record', Rec.FieldCaption(F04));
        Observer.Observe('other_calls', CapLog.Take());
        CapLog.SetMode('');
        Observer.Expect('first', 'x');
        Observer.Expect('first_calls', '');
        Observer.Expect('second', 'x');
        Observer.Expect('second_calls', '');
        Observer.Expect('other_record', '2,x');
        Observer.Expect('other_calls', '');
        Observer.Verify();
    end;
}
