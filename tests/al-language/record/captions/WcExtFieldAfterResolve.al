// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 96200, table extension 96201, card page 96202, log 96203 (used only by test codeunit 96205),
//   subscriber codeunit 96204, test codeunit 96205.
// Probe: writer rwcap (al-runner issue 6924, waldo): the caption of a TABLE EXTENSION field whose CaptionClass is in an area no
//   OnResolveCaptionClass subscriber claims ('LTWC,27,1'), when a static subscriber of Caption Class.OnAfterCaptionClassResolve sets the
//   caption. Read through FieldCaption, FieldRef.Caption, a TestPage control, CaptionClassTranslate; a base table field of the same kind; an
//   area 3 field; a second read of the same field; an expression with only one comma. v2: the tests run in an order where the area 3, second-read, base and one-comma reads come first (v1 showed no
//   OnAfterCaptionClassResolve for them after a TestPage read), and a never-read field after the TestPage test. The log shows which OnAfterCaptionClassResolve calls
//   the read raised (the expression and the caption the subscriber got).
// BC versions: 27, 28, 29

table 96200 "LT WC Cap Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "WC Base"; Text[30])
        {
            Caption = 'WC Base Cap';
            CaptionClass = 'LTWC,1,base';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 96201 "LT WC Cap Ext" extends "LT WC Cap Base"
{
    fields
    {
        field(96200; "WC Ext FC"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext FC Cap';
            CaptionClass = 'LTWC,27,1';
        }
        field(96201; "WC Ext FR"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext FR Cap';
            CaptionClass = 'LTWC,27,2';
        }
        field(96202; "WC Ext Page"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext Page Cap';
            CaptionClass = 'LTWC,27,3';
        }
        field(96203; "WC Ext Area3"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext Area3 Cap';
            CaptionClass = '3,WC plain three';
        }
        field(96204; "WC Ext Short"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext Short Cap';
            CaptionClass = 'LTWC,x';
        }
        field(96206; "WC Ext Late"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext Late Cap';
            CaptionClass = 'LTWC,27,6';
        }
        field(96205; "WC Ext Twice"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Ext Twice Cap';
            CaptionClass = 'LTWC,27,5';
        }
    }
}

page 96202 "LT WC Cap Card"
{
    PageType = Card;
    SourceTable = "LT WC Cap Base";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(PageCtl; Rec."WC Ext Page") { ApplicationArea = All; }
        }
    }
}

codeunit 96203 "LT WC Cap Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        On: Boolean;

    procedure Start()
    begin
        Lines := '';
        On := true;
    end;

    procedure Stop()
    begin
        On := false;
    end;

    procedure Add(Line: Text)
    begin
        if not On then
            exit;
        if Lines <> '' then
            Lines += ' | ';
        Lines += Line;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

codeunit 96204 "LT WC Cap Subs"
{
    // The shape of al-runner issue 6924: a static subscriber that resolves its own area in OnAfterCaptionClassResolve.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnAfterCaptionClassResolve', '', false, false)]
    local procedure OnCaptionClassTranslate(CaptionExpression: Text; Language: Integer; var Caption: Text[1024])
    var
        Log: Codeunit "LT WC Cap Log";
        CsvValues: List of [Text];
    begin
        CsvValues := CaptionExpression.Split(',');
        if CsvValues.Get(1) <> 'LTWC' then begin
            if CaptionExpression = '3,WC plain three' then
                Log.Add(StrSubstNo('after expr=%1 in=%2 lang_is_session=%3', CaptionExpression, Caption, Language = GlobalLanguage()));
            exit;
        end;
        Log.Add(StrSubstNo('after expr=%1 in=%2 lang_is_session=%3', CaptionExpression, Caption, Language = GlobalLanguage()));
        if CsvValues.Count() < 3 then
            Caption := 'WC short ' + CsvValues.Get(2)
        else
            Caption := 'WC table ' + CsvValues.Get(2) + ' field ' + CsvValues.Get(3);
    end;
}

codeunit 96205 "LT WC Ext Caption Resolve"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WcExtField_Area3_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Ext Area3"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_ReadTwice()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('first', T.FieldCaption("WC Ext Twice"));
        Observer.Observe('log-first', Log.Take());
        Observer.Observe('second', T.FieldCaption("WC Ext Twice"));
        Observer.Observe('log-second', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcBaseField_FieldCaption_AfterResolveSets()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Base"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_OneComma_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Ext Short"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_FieldCaption_AfterResolveSets()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Ext FC"));
        Observer.Observe('log', Log.Take());
        Observer.Observe('fieldname', T.FieldName("WC Ext FC"));
        Observer.Observe('log-after-fieldname', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_FieldRefCaption_AfterResolveSets()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        RecRef: RecordRef;
    begin
        Log.Start();
        RecRef.Open(Database::"LT WC Cap Base");
        Observer.Observe('fieldref-caption', RecRef.Field(96201).Caption());
        Observer.Observe('log', Log.Take());
        RecRef.Close();
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcCaptionClassTranslate_AfterResolveSets()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
    begin
        Log.Start();
        Observer.Observe('translate', CaptionClassTranslate('LTWC,27,9'));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;
    [Test]
    procedure WcExtField_TestPageCaption_AfterResolveSets()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT WC Cap Base";
        Card: TestPage "LT WC Cap Card";
    begin
        T.DeleteAll();
        T.Init();
        T.Id := 1;
        T.Insert();
        Card.OpenView();
        Observer.Observe('control-caption', Card.PageCtl.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_AfterTestPage_NeverReadField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Base";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Ext Late"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

}
