// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: page field properties Importance, QuickEntry, StyleExpr, Style, ExtendedDatatype, NotBlank, ShowCaption, BlankZero: what a TestPage exposes for such fields
// (Visible, Editable, Enabled, Caption, Value, IsMandatory, SetValue errors). Importance, QuickEntry, Style, StyleExpr and ExtendedDatatype have no TestPage member:
// they are declared and their effect on Value is observed.
// Added by writer BV (2026-10-19, Windows check 3 item AP): a page field with ExtendedDatatype = Ratio on a plain Decimal reads '0%' through TestPage Value()
// for every value (0.5, 1, 12.5, 0.25, -0.5, 0.333), on the Linux tiers and on Windows BC 27.5 and 29.0; a plain control on the same field reads the value.
// Self-contained table 83750 and page 83751; test P119_RatioNonZeroValues.

table 83750 "LT BV Ratio Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(5; Rt; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 83751 "LT BV Ratio Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT BV Ratio Row";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(RtF; Rec.Rt)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Ratio;
                }
                field(RtPlain; Rec.Rt) { ApplicationArea = All; }
            }
        }
    }
}

page 71629 "LT P119 Fields Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name Cap';
                    Importance = Promoted;
                    QuickEntry = false;
                    StyleExpr = StyleTxt;
                }
                field(NoteF; Rec.Note)
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    NotBlank = true;
                    Style = Unfavorable;
                }
                field(PhoneF; Rec.Phone)
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    QuickEntry = true;
                    ExtendedDatatype = PhoneNo;
                }
                field(MailF; Rec.Mail)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = EMail;
                }
                field(LinkF; Rec.Link)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                }
                field(RatioF; Rec.RatioVal)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Ratio;
                }
                field(SecretF; Rec.Secret)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(DecF; Rec.Dec)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
                field(BlankF; Rec.BlankNegN)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
                field(LevelF; Rec.Level)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Style = Favorable;
                }
            }
        }
    }

    var
        StyleTxt: Text;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := 'Strong';
    end;
}

codeunit 71630 "LT P119 Fields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_FieldState()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.Observe('name-editable', Format(TP.NameF.Editable()));
        Observer.Observe('name-enabled', Format(TP.NameF.Enabled()));
        Observer.Observe('name-caption', TP.NameF.Caption());
        Observer.Observe('name-value', TP.NameF.Value());
        Observer.Observe('note-visible', Format(TP.NoteF.Visible()));
        Observer.Observe('note-editable', Format(TP.NoteF.Editable()));
        Observer.Observe('note-value', TP.NoteF.Value());
        Observer.Observe('phone-visible', Format(TP.PhoneF.Visible()));
        Observer.Observe('phone-value', TP.PhoneF.Value());
        Observer.Observe('mail-value', TP.MailF.Value());
        Observer.Observe('link-value', TP.LinkF.Value());
        Observer.Observe('ratio-value', TP.RatioF.Value());
        Observer.Observe('secret-value', TP.SecretF.Value());
        Observer.Observe('level-visible', Format(TP.LevelF.Visible()));
        Observer.Observe('level-value', TP.LevelF.Value());
        TP.Close();
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-editable', 'Yes');
        Observer.Expect('name-enabled', 'Yes');
        Observer.Expect('name-caption', 'Name Cap');
        Observer.Expect('name-value', 'First');
        Observer.Expect('note-visible', 'Yes');
        Observer.Expect('note-editable', 'Yes');
        Observer.Expect('note-value', 'N1');
        Observer.Expect('phone-visible', 'Yes');
        Observer.Expect('phone-value', '');
        Observer.Expect('mail-value', '');
        Observer.Expect('link-value', '');
        Observer.Expect('ratio-value', '0%');
        Observer.Expect('secret-value', '');
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('level-value', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ShowCaptionField()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('dec-visible', Format(TP.DecF.Visible()));
        Observer.Observe('dec-caption', TP.DecF.Caption());
        Observer.Observe('dec-value', TP.DecF.Value());
        Observer.Observe('dec-editable', Format(TP.DecF.Editable()));
        Observer.Observe('name-caption', TP.NameF.Caption());
        TP.Close();
        Observer.Expect('dec-visible', 'Yes');
        Observer.Expect('dec-caption', 'Dec');
        Observer.Expect('dec-value', '0.000');
        Observer.Expect('dec-editable', 'Yes');
        Observer.Expect('name-caption', 'Name Cap');
        Observer.Verify();
    end;

    [Test]
    procedure P119_BlankZeroField()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('blank-zero-value', TP.BlankF.Value());
        TP.BlankF.SetValue(5);
        Observer.Observe('blank-five-value', TP.BlankF.Value());
        TP.BlankF.SetValue(-5);
        Observer.Observe('blank-minus-value', TP.BlankF.Value());
        TP.BlankF.SetValue(0);
        Observer.Observe('blank-reset-value', TP.BlankF.Value());
        TP.DecF.SetValue(1.23456);
        Observer.Observe('dec-after-set', TP.DecF.Value());
        TP.Close();
        Observer.Expect('blank-zero-value', '');
        Observer.Expect('blank-five-value', '5.00');
        Observer.Expect('blank-minus-value', '');
        Observer.Expect('blank-reset-value', '');
        Observer.Expect('dec-after-set', '1.235');
        Observer.Verify();
    end;

    [Test]
    procedure P119_NotBlankPageField()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.NoteF.SetValue('filled');
        Observer.Observe('note-filled', TP.NoteF.Value());
        asserterror TP.NoteF.SetValue('');
        Observer.ObserveError('note-blank');
        Observer.Observe('note-after', TP.NoteF.Value());
        TP.Close();
        Observer.Expect('note-filled', 'filled');
        Observer.Expect('note-blank|text', 'Validation error for Field: NoteF,  Message = ''Note must be filled in. Enter a value. (Select Refresh to discard errors)''');
        Observer.Expect('note-blank|code', 'TestValidation');
        Observer.Expect('note-after', 'filled');
        Observer.Verify();
    end;

    [Test]
    procedure P119_NotBlankMandatory()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.Close();
        Observer.Verify();
    end;

    [Test]
    procedure P119_SetValues()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
        Row: Record "LT P119 Row";
    begin
        Seed();
        TP.OpenEdit();
        TP.PhoneF.SetValue('+49 30 123456');
        Observer.Observe('phone', TP.PhoneF.Value());
        TP.LinkF.SetValue('https://example.invalid/a b');
        Observer.Observe('link', TP.LinkF.Value());
        Observer.Observe('ratio', TP.RatioF.Value());
        TP.SecretF.SetValue('hidden text');
        Observer.Observe('secret', TP.SecretF.Value());
        TP.NameF.SetValue('Renamed');
        Observer.Observe('name', TP.NameF.Value());
        TP.Close();
        Row.Get(1);
        Observer.Observe('row-phone', Row.Phone);
        Observer.Observe('row-secret', Row.Secret);
        Observer.Observe('row-name', Row.Name);
        Observer.Expect('phone', '+49 30 123456');
        Observer.Expect('link', 'https://example.invalid/a b');
        Observer.Expect('ratio', '0%');
        Observer.Expect('secret', '••••••••••');
        Observer.Expect('name', 'Renamed');
        Observer.Expect('row-phone', '+49 30 123456');
        Observer.Expect('row-secret', 'hidden text');
        Observer.Expect('row-name', 'Renamed');
        Observer.Verify();
    end;

    [Test]
    procedure P119_MailBadValue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.MailF.SetValue('a@b.example');
        Observer.Observe('mail-good', TP.MailF.Value());
        TP.MailF.SetValue('not an email');
        Observer.Observe('mail-bad', 'no error');
        Observer.Observe('mail-after', TP.MailF.Value());
        TP.Close();
        Observer.Expect('mail-good', 'a@b.example');
        Observer.Expect('mail-bad', 'no error');
        Observer.Expect('mail-after', 'not an email');
        Observer.Verify();
    end;

    local procedure BvRatioRow(NewCode: Code[20]; V: Decimal)
    var
        Row: Record "LT BV Ratio Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Rt := V;
        Row.Insert();
    end;

    // Windows check 3 (BC 27.5 and 29.0, run 39219539271 / 39219542141) gave exactly these values.
    [Test]
    procedure P119_RatioNonZeroValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BV Ratio Row";
        TP: TestPage "LT BV Ratio Card";
    begin
        Row.DeleteAll();
        BvRatioRow('R1', 0.5);
        BvRatioRow('R2', 1);
        BvRatioRow('R3', 12.5);
        BvRatioRow('R4', 0.25);
        BvRatioRow('R5', -0.5);
        BvRatioRow('R6', 0.333);
        TP.OpenView();
        TP.GoToKey('R1');
        Observer.Observe('0.5', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.GoToKey('R2');
        Observer.Observe('1', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.GoToKey('R3');
        Observer.Observe('12.5', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.GoToKey('R4');
        Observer.Observe('0.25', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.GoToKey('R5');
        Observer.Observe('-0.5', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.GoToKey('R6');
        Observer.Observe('0.333', TP."Code".Value() + '|' + TP.RtF.Value() + '|' + TP.RtPlain.Value());
        TP.Close();
        Row.DeleteAll();
        Observer.Expect('0.5', 'R1|0%|0.50');
        Observer.Expect('1', 'R2|0%|1.00');
        Observer.Expect('12.5', 'R3|0%|12.50');
        Observer.Expect('0.25', 'R4|0%|0.25');
        Observer.Expect('-0.5', 'R5|0%|-0.50');
        Observer.Expect('0.333', 'R6|0%|0.33');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Note := 'N1';
        Row.Level := 2;
        Row.Insert();
    end;
}
