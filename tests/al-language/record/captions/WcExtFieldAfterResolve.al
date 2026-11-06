// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96200, 96206 and 96217, table extensions 96201, 96207 and 96218, card pages 96202, 96208 and 96219, log 96203 (used only by test codeunit 96205),
//   subscriber codeunit 96204, test codeunit 96205.
// Probe: writer rwcap (al-runner issue 6924, waldo): the caption of a TABLE EXTENSION field whose CaptionClass is in an area no
//   OnResolveCaptionClass subscriber claims ('LTWC,27,1'), when a static subscriber of Caption Class.OnAfterCaptionClassResolve sets the
//   caption. Read through FieldCaption, FieldRef.Caption, a TestPage control, CaptionClassTranslate; a base table field of the same kind; an
//   area 3 field; a second read of the same field; an expression with only one comma. Results (BC 27.5, 28.5, 29.0, all equal): the first read of an expression raises OnAfterCaptionClassResolve once with the
//   expression and the caption as given (area 3 and a one-comma expression too), the subscriber's caption is the result, a second read raises
//   nothing. Reads after a TestPage of the table was opened raised nothing (v1). The last test isolates that case on a second table. The log shows which OnAfterCaptionClassResolve calls
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

table 96206 "LT WC Cap Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 96207 "LT WC Cap Two Ext" extends "LT WC Cap Two"
{
    fields
    {
        field(96207; "WC Two Shown"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Two Shown Cap';
            CaptionClass = 'LTWC,27,7';
        }
        field(96208; "WC Two Hidden"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Two Hidden Cap';
            CaptionClass = 'LTWC,27,8';
        }
    }
}

page 96208 "LT WC Cap Two Card"
{
    PageType = Card;
    SourceTable = "LT WC Cap Two";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(ShownCtl; Rec."WC Two Shown") { ApplicationArea = All; }
        }
    }
}

table 96217 "LT WC Cap Three"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 96218 "LT WC Cap Three Ext" extends "LT WC Cap Three"
{
    fields
    {
        field(96209; "WC No Comma"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC No Comma Cap';
            CaptionClass = 'WCNOCOMMA';
        }
        field(96210; "WC Empty Area"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Empty Area Cap';
            CaptionClass = ',WC empty area';
        }
        field(96211; "WC Three Alone"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'WC Three Alone Cap';
            CaptionClass = '3,';
        }
    }
}

page 96219 "LT WC Cap Three Card"
{
    PageType = Card;
    SourceTable = "LT WC Cap Three";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CtlThree; Rec.Id)
            {
                ApplicationArea = All;
                CaptionClass = '3,WC ctl three';
            }
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
        Log.Add(StrSubstNo('after expr=%1 in=%2 lang_is_session=%3', CaptionExpression, Caption, Language = GlobalLanguage()));
        CsvValues := CaptionExpression.Split(',');
        if CsvValues.Get(1) <> 'LTWC' then
            exit;
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
        Observer.Expect('fieldcaption', 'WC plain three');
        Observer.Expect('log', 'after expr=3,WC plain three in=WC plain three lang_is_session=Yes');
        Observer.Verify();
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
        Observer.Expect('first', 'WC table 27 field 5');
        Observer.Expect('log-first', 'after expr=LTWC,27,5 in=LTWC,27,5 lang_is_session=Yes');
        Observer.Expect('second', 'WC table 27 field 5');
        Observer.Expect('log-second', '');
        Observer.Verify();
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
        Observer.Expect('fieldcaption', 'WC table 1 field base');
        Observer.Expect('log', 'after expr=LTWC,1,base in=LTWC,1,base lang_is_session=Yes');
        Observer.Verify();
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
        Observer.Expect('fieldcaption', 'WC short x');
        Observer.Expect('log', 'after expr=LTWC,x in=LTWC,x lang_is_session=Yes');
        Observer.Verify();
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
        Observer.Expect('fieldcaption', 'WC table 27 field 1');
        Observer.Expect('log', 'after expr=LTWC,27,1 in=LTWC,27,1 lang_is_session=Yes');
        Observer.Expect('fieldname', 'WC Ext FC');
        Observer.Expect('log-after-fieldname', '');
        Observer.Verify();
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
        Observer.Expect('fieldref-caption', 'WC table 27 field 2');
        Observer.Expect('log', 'after expr=LTWC,27,2 in=LTWC,27,2 lang_is_session=Yes');
        Observer.Verify();
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
        Observer.Expect('translate', 'WC table 27 field 9');
        Observer.Expect('log', 'after expr=LTWC,27,9 in=LTWC,27,9 lang_is_session=Yes');
        Observer.Verify();
    end;
    [Test]
    procedure WcPageOpen_UndisplayedFieldOfTheSameTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Two";
        Card: TestPage "LT WC Cap Two Card";
    begin
        T.DeleteAll();
        T.Init();
        T.Id := 1;
        T.Insert();
        Log.Start();
        Card.OpenView();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('control-caption', Card.ShownCtl.Caption());
        Observer.Observe('log-after-control', Log.Take());
        Observer.Observe('hidden-fieldcaption', T.FieldCaption("WC Two Hidden"));
        Observer.Observe('log-hidden', Log.Take());
        Card.Close();
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_NoComma_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Three";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC No Comma"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_EmptyArea_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Three";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Empty Area"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcExtField_ThreeAlone_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Three";
    begin
        Log.Start();
        Observer.Observe('fieldcaption', T.FieldCaption("WC Three Alone"));
        Observer.Observe('log', Log.Take());
        Log.Stop();
        Observer.Finish();
    end;

    [Test]
    procedure WcControl_OwnArea3_TestPageCaption()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT WC Cap Log";
        T: Record "LT WC Cap Three";
        Card: TestPage "LT WC Cap Three Card";
    begin
        T.DeleteAll();
        T.Init();
        T.Id := 1;
        T.Insert();
        Log.Start();
        Card.OpenView();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('control-caption', Card.CtlThree.Caption());
        Observer.Observe('log-after-control', Log.Take());
        Card.Close();
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
        Observer.Expect('control-caption', 'WC table 27 field 3');
        Observer.Verify();
    end;
}
