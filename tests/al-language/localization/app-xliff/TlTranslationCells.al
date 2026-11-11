// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixture C's objects in tests/al-language-xapp-c/XlXcTranslations.al and its
//   translation files (nl-BE, nl-NL, fr-FR, en-GB, en-US); translation units of this file's objects in
//   Translations/AL Language Coverage Tests.nl-NL.xlf; own objects 96700-96708.
// local object: the labels, captions and translation units are the thing under test.
// Probe (al-runner area "translations"; an outside suite of a BE localization reads Labels and captions of apps that ship translation
//   files under GlobalLanguage 2067, 2060 and 1025): the cells of the area table the corpus did not pin yet.
// Area:
//   1. Which file of a dependency app gives a Label, an enum value caption, a table caption and a field caption: the file of the exact culture,
//      a unit only in the file of another culture of the same language (unit-level or file-level fallback), a language with only a file of
//      another culture (fr-FR read under fr-BE, fr-CA and fr-CH; en-GB under en-AU), a language without a file (de-DE), en-US and en-GB files
//      read under 1033, and a unit with a dependency label's id in the main app's file (each app is translated only by its own files).
//   2. The XLIFF id shapes of Labels declared outside a top-level procedure of a codeunit: a codeunit OnRun trigger, an event subscriber, a
//      table field OnValidate trigger, a table OnInsert trigger, a table and a page and a report global Label and procedure Label, a page
//      control OnValidate trigger, a page action OnAction trigger and a report data item OnAfterGetRecord trigger.
//   3. Unit forms: state needs-translation, needs-review-translation, new, final, translated and signed-off; an empty <target>, no
//      <target>, translate="no"; a target longer than the Label's MaxLength; a Label with a Comment.
//   4. An enum extension in the same app as its enum and one of a dependency app's enum; the page caption of a TestPage.
//   5. Error(Label) under 1043, read with GetLastErrorText after GlobalLanguage(1033); Labels read while a report runs with
//      CurrReport.Language set (the report's own Label and a dependency app's Label).
//   6. CaptionML and OptionCaptionML of a field in an app that ships a file, under 1043 (NLD entry) and 2067 (no NLB entry); TextConst
//      with NLD, NLB, FRB, FRA and DAN entries under 1043, 2067, 2060, 1036 and 1030.
// BC versions: 27.0+

codeunit 96700 "LT TL Trigger Labels"
{
    var
        LastText: Text;

    trigger OnRun()
    var
        RunLbl: Label 'OnRun label';
    begin
        LastText := RunLbl;
    end;

    procedure GetLast(): Text
    begin
        exit(LastText);
    end;

    procedure WithLocal(): Text
    var
        LocalLbl: Label 'Procedure label';
    begin
        exit(LocalLbl);
    end;

    procedure RaiseProbe(): Text
    var
        Result: Text;
    begin
        OnProbe(Result);
        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    procedure OnProbe(var Result: Text)
    begin
    end;
}

codeunit 96701 "LT TL Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT TL Trigger Labels", 'OnProbe', '', false, false)]
    local procedure HandleProbe(var Result: Text)
    var
        SubLbl: Label 'Subscriber label';
    begin
        Result := SubLbl;
    end;
}

table 96702 "LT TL Row"
{
    Caption = 'TL row';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'TL number';
        }
        field(2; Amount; Integer)
        {
            Caption = 'TL amount';

            trigger OnValidate()
            var
                FieldLbl: Label 'Field trigger label';
            begin
                FieldNote := FieldLbl;
            end;
        }
        field(3; Note; Text[100])
        {
            Caption = 'TL note';
        }
        field(4; FieldNote; Text[100])
        {
            Caption = 'TL field note';
        }
        field(5; InsertNote; Text[100])
        {
            Caption = 'TL insert note';
        }
        field(6; Mixed; Text[30])
        {
            CaptionML = ENU = 'Mixed ENU', NLD = 'Mixed NLD';
        }
        field(7; Opt; Option)
        {
            Caption = 'TL option';
            OptionMembers = A,B;
            OptionCaptionML = ENU = 'Opt A,Opt B', NLD = 'Optie A,Optie B';
        }
    }
    keys
    {
        key(PK; "No.") { }
    }

    var
        TableGlobalLbl: Label 'Table global label';

    trigger OnInsert()
    var
        InsertLbl: Label 'Insert trigger label';
    begin
        InsertNote := InsertLbl;
    end;

    procedure TableGlobal(): Text
    begin
        exit(TableGlobalLbl);
    end;

    procedure TableLocal(): Text
    var
        TableLocalLbl: Label 'Table procedure label';
    begin
        exit(TableLocalLbl);
    end;
}

page 96703 "LT TL Card"
{
    PageType = Card;
    SourceTable = "LT TL Row";
    Caption = 'TL card';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(AmountCtl; Rec.Amount)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    CtlLbl: Label 'Control trigger label';
                begin
                    Rec.Note := CtlLbl;
                end;
            }
            field(NoteCtl; Rec.Note) { ApplicationArea = All; }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ProbeAction)
            {
                ApplicationArea = All;
                Caption = 'Probe';

                trigger OnAction()
                var
                    ActLbl: Label 'Action trigger label';
                begin
                    Rec.Note := ActLbl;
                end;
            }
            action(GlobalAction)
            {
                ApplicationArea = All;
                Caption = 'Global';

                trigger OnAction()
                begin
                    Rec.Note := PageGlobalLbl;
                end;
            }
        }
    }

    var
        PageGlobalLbl: Label 'Page global label';

    procedure PageGlobal(): Text
    begin
        exit(PageGlobalLbl);
    end;

    procedure PageLocal(): Text
    var
        PageLocalLbl: Label 'Page procedure label';
    begin
        exit(PageLocalLbl);
    end;
}

report 96704 "LT TL Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(TlNumber; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                XL: Codeunit "LT XL Labels";
                DataLbl: Label 'Data item label';
            begin
                LastText := DataLbl;
                DepText := XL.Both();
                GlobalText := Format(GlobalLanguage());
                ReportLanguageText := Format(CurrReport.Language());
            end;
        }
    }

    trigger OnPreReport()
    begin
        if ReportLanguage <> 0 then
            CurrReport.Language := ReportLanguage;
    end;

    var
        LastText: Text;
        DepText: Text;
        GlobalText: Text;
        ReportLanguageText: Text;
        ReportLanguage: Integer;
        ReportGlobalLbl: Label 'Report global label';

    procedure SetReportLanguage(Language: Integer)
    begin
        ReportLanguage := Language;
    end;

    procedure GetRunTexts(): Text
    begin
        exit(LastText + '|' + DepText + '|' + GlobalText + '|' + ReportLanguageText);
    end;

    procedure GetLast(): Text
    begin
        exit(LastText);
    end;

    procedure ReportGlobal(): Text
    begin
        exit(ReportGlobalLbl);
    end;

    procedure ReportLocal(): Text
    var
        ReportLocalLbl: Label 'Report procedure label';
    begin
        exit(ReportLocalLbl);
    end;
}

enum 96705 "LT TLC Kind"
{
    Extensible = true;

    value(0; First)
    {
        Caption = 'First kind';
    }
    value(1; Second)
    {
        Caption = 'Second kind';
    }
}

enumextension 96706 "LT TLC Kind Ext" extends "LT TLC Kind"
{
    value(96706; Third)
    {
        Caption = 'Third kind';
    }
}

enumextension 96707 "LT TL XKind Ext" extends "LT XL Kind"
{
    value(96707; Extra)
    {
        Caption = 'Extra kind';
    }
}

codeunit 96708 "LT TL Translation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        StateNeedsLbl: Label 'State needs-translation';
        StateReviewLbl: Label 'State needs-review-translation';
        StateNewLbl: Label 'State new';
        StateFinalLbl: Label 'State final';
        StateTranslatedLbl: Label 'State translated';
        StateSignedOffLbl: Label 'State signed-off';
        EmptyTargetLbl: Label 'Empty target';
        NoTargetLbl: Label 'No target';
        TranslateNoLbl: Label 'Translate no';
        MaxLbl: Label 'Short', MaxLength = 5;
        CommentLbl: Label 'With comment', Comment = 'A note for the translator';
        ErrLbl: Label 'Error label';
        TcAll: TextConst ENU = 'TC English', NLD = 'TC Nederlands', NLB = 'TC Vlaams', FRB = 'TC Belge', FRA = 'TC Francais', DAN = 'TC Dansk';
        TcEnuNld: TextConst ENU = 'TC2 English', NLD = 'TC2 Nederlands';
        TcNldOnly: TextConst NLD = 'TC3 Nederlands';

    local procedure ObserveDependencyLabels(var Observer: Codeunit "Probe Observer"; Language: Integer; Tag: Text)
    var
        XL: Codeunit "LT XL Labels";
    begin
        GlobalLanguage(Language);
        Observer.Observe(Tag + '_both', XL.Both());
        Observer.Observe(Tag + '_nl_only', XL.NlOnly());
        Observer.Observe(Tag + '_be_only', XL.BeOnly());
        Observer.Observe(Tag + '_fr_only', XL.FrOnly());
        Observer.Observe(Tag + '_gb_only', XL.GbOnly());
        Observer.Observe(Tag + '_us_only', XL.UsOnly());
        GlobalLanguage(1033);
    end;

    local procedure ObserveDependencyCaptions(var Observer: Codeunit "Probe Observer"; Language: Integer; Tag: Text)
    var
        Row: Record "LT XL Row" temporary;
        Kind: Enum "LT XL Kind";
    begin
        GlobalLanguage(Language);
        Observer.Observe(Tag + '_table_caption', Row.TableCaption());
        Observer.Observe(Tag + '_field_caption', Row.FieldCaption("Code"));
        Kind := Kind::Alpha;
        Observer.Observe(Tag + '_alpha', Format(Kind));
        Kind := Kind::Beta;
        Observer.Observe(Tag + '_beta', Format(Kind));
        GlobalLanguage(1033);
    end;

    [Test]
    procedure TL_DependencyLabels_DutchCultures()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDependencyLabels(Observer, 2067, 'nlbe');
        ObserveDependencyLabels(Observer, 1043, 'nlnl');
        Observer.Verify();
    end;

    [Test]
    procedure TL_DependencyLabels_FrenchCultures()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDependencyLabels(Observer, 1036, 'frfr');
        ObserveDependencyLabels(Observer, 2060, 'frbe');
        ObserveDependencyLabels(Observer, 3084, 'frca');
        ObserveDependencyLabels(Observer, 4108, 'frch');
        Observer.Verify();
    end;

    [Test]
    procedure TL_DependencyLabels_EnglishAndGerman()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDependencyLabels(Observer, 1033, 'enus');
        ObserveDependencyLabels(Observer, 2057, 'engb');
        ObserveDependencyLabels(Observer, 3081, 'enau');
        ObserveDependencyLabels(Observer, 1031, 'dede');
        Observer.Verify();
    end;

    [Test]
    procedure TL_DependencyCaptions_Cultures()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveDependencyCaptions(Observer, 2067, 'nlbe');
        ObserveDependencyCaptions(Observer, 1043, 'nlnl');
        ObserveDependencyCaptions(Observer, 2060, 'frbe');
        ObserveDependencyCaptions(Observer, 1031, 'dede');
        Observer.Verify();
    end;

    [Test]
    procedure TL_DependencyLabel_UnitInMainAppFile()
    var
        Observer: Codeunit "Probe Observer";
        XL: Codeunit "LT XL Labels";
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_cross', XL.Cross());
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_EnumExtensions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Own: Enum "LT TLC Kind";
        Dep: Enum "LT XL Kind";
    begin
        GlobalLanguage(1043);
        Own := Own::First;
        Observer.Observe('nlnl_own_first', Format(Own));
        Own := Own::Second;
        Observer.Observe('nlnl_own_second_no_unit', Format(Own));
        Own := Own::Third;
        Observer.Observe('nlnl_own_ext_third', Format(Own));
        Dep := Dep::Alpha;
        Observer.Observe('nlnl_dep_alpha', Format(Dep));
        Dep := Dep::Extra;
        Observer.Observe('nlnl_dep_ext_extra', Format(Dep));
        GlobalLanguage(2067);
        Dep := Dep::Extra;
        Observer.Observe('nlbe_dep_ext_extra', Format(Dep));
        Dep := Dep::Alpha;
        Observer.Observe('nlbe_dep_alpha', Format(Dep));
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_LabelShapes_CodeunitAndEvent_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        TL: Codeunit "LT TL Trigger Labels";
    begin
        GlobalLanguage(1043);
        TL.Run();
        Observer.Observe('nlnl_onrun', TL.GetLast());
        Observer.Observe('nlnl_procedure_local', TL.WithLocal());
        Observer.Observe('nlnl_subscriber', TL.RaiseProbe());
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_LabelShapes_Table_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TL Row" temporary;
    begin
        GlobalLanguage(1043);
        Row."No." := 'A';
        Row.Insert(true);
        Observer.Observe('nlnl_table_oninsert', Row.InsertNote);
        Row.Validate(Amount, 1);
        Observer.Observe('nlnl_table_field_onvalidate', Row.FieldNote);
        Observer.Observe('nlnl_table_global', Row.TableGlobal());
        Observer.Observe('nlnl_table_procedure_local', Row.TableLocal());
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_LabelShapes_Page_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT TL Card";
        Pg: Page "LT TL Card";
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_page_global', Pg.PageGlobal());
        Observer.Observe('nlnl_page_procedure_local', Pg.PageLocal());
        Card.OpenNew();
        Observer.Observe('nlnl_page_caption', Card.Caption());
        Card.NoCtl.SetValue('A');
        Card.AmountCtl.SetValue(5);
        Observer.Observe('nlnl_page_control_onvalidate', Card.NoteCtl.Value());
        Card.ProbeAction.Invoke();
        Observer.Observe('nlnl_page_action_onaction', Card.NoteCtl.Value());
        Card.GlobalAction.Invoke();
        Observer.Observe('nlnl_page_action_global', Card.NoteCtl.Value());
        Card.Close();
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_LabelShapes_Report_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TL Report";
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_report_global', Rep.ReportGlobal());
        Observer.Observe('nlnl_report_procedure_local', Rep.ReportLocal());
        Rep.UseRequestPage(false);
        Rep.RunModal();
        Observer.Observe('nlnl_report_dataitem_onaftergetrecord', Rep.GetLast());
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_ReportLanguage_LabelsWhileReportRuns()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TL Report";
        Rep2: Report "LT TL Report";
    begin
        // GlobalLanguage 1033, CurrReport.Language 1043 (set in OnPreReport): the report's own Label and a dependency app's Label read in
        // OnAfterGetRecord, then GlobalLanguage and CurrReport.Language there (Label|dependency Label|GlobalLanguage|CurrReport.Language).
        GlobalLanguage(1033);
        Rep.SetReportLanguage(1043);
        Rep.UseRequestPage(false);
        Rep.RunModal();
        Observer.Observe('enus_global_nlnl_report', Rep.GetRunTexts());
        // GlobalLanguage 2067, report language not set.
        GlobalLanguage(2067);
        Rep2.UseRequestPage(false);
        Rep2.RunModal();
        Observer.Observe('nlbe_global_report_language_unset', Rep2.GetRunTexts());
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_UnitForms_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Text: Text;
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_state_needs_translation', StateNeedsLbl);
        Observer.Observe('nlnl_state_needs_review_translation', StateReviewLbl);
        Observer.Observe('nlnl_state_new', StateNewLbl);
        Observer.Observe('nlnl_state_final', StateFinalLbl);
        Observer.Observe('nlnl_state_translated', StateTranslatedLbl);
        Observer.Observe('nlnl_state_signed_off', StateSignedOffLbl);
        Observer.Observe('nlnl_empty_target', EmptyTargetLbl);
        Observer.Observe('nlnl_no_target', NoTargetLbl);
        Observer.Observe('nlnl_translate_no', TranslateNoLbl);
        Text := MaxLbl;
        Observer.Observe('nlnl_maxlength_text', Text);
        Observer.Observe('nlnl_maxlength_strlen', Format(StrLen(Text)));
        Observer.Observe('nlnl_comment', CommentLbl);
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_ErrorLabel_DutchThenEnglish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalLanguage(1043);
        asserterror Error(ErrLbl);
        GlobalLanguage(1033);
        Observer.Observe('error_text_after_1033', GetLastErrorText());
        Observer.Verify();
    end;

    [Test]
    procedure TL_CaptionML_InAppWithFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TL Row" temporary;
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_captionml', Row.FieldCaption(Mixed));
        Row.Opt := Row.Opt::B;
        Observer.Observe('nlnl_optioncaptionml', Format(Row.Opt));
        GlobalLanguage(2067);
        Observer.Observe('nlbe_captionml', Row.FieldCaption(Mixed));
        Observer.Observe('nlbe_optioncaptionml', Format(Row.Opt));
        GlobalLanguage(1033);
        Observer.Verify();
    end;

    [Test]
    procedure TL_TextConst_Languages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalLanguage(1043);
        Observer.Observe('nlnl_all', TcAll);
        Observer.Observe('nlnl_enu_nld', TcEnuNld);
        GlobalLanguage(2067);
        Observer.Observe('nlbe_all', TcAll);
        Observer.Observe('nlbe_enu_nld', TcEnuNld);
        Observer.Observe('nlbe_nld_only', TcNldOnly);
        GlobalLanguage(2060);
        Observer.Observe('frbe_all', TcAll);
        GlobalLanguage(1036);
        Observer.Observe('frfr_all', TcAll);
        GlobalLanguage(1030);
        Observer.Observe('dadk_all', TcAll);
        Observer.Observe('dadk_enu_nld', TcEnuNld);
        GlobalLanguage(1033);
        Observer.Observe('enus_nld_only', TcNldOnly);
        Observer.Verify();
    end;
}
