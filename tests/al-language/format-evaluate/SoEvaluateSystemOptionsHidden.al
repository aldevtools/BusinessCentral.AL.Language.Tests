// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/library
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe (gap probe 3, next to SoEvaluateSystemOptions.al): what corpus PR 1219 left open. (1) WebServiceActionResultCode: Evaluate and Format of the numbers
//   of its members (200, 201, 204 and the numbers between and around them), with format numbers 0, 2 and 9, and Format of every member in the formats 0, 1, 2 and 9.
//   (2) The NAMES of members AL code cannot name (ObjectType Form and Enum, ReportFormat None, Jpeg, Xps, Meta, ExcelDataset, Custom and Zip, ExecutionContext
//   Uninstall, FieldClass KeyFieldReference on BC 27): exact, in other case, as a prefix, with blanks around it, and Format of the value read. (3) A text with blanks
//   or TABs around it that Evaluate rejects, in the statement form (error text and code), for the 14 types of SoEvaluateSystemOptions.al.
// Each test starts with the variable set to a member, so a failed Evaluate shows as the member kept.
// BC versions: 27, 28, 29
codeunit 99614 "LT SO Eval Hidden Members"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tab(): Text
    var
        T: Text[1];
    begin
        T[1] := 9;
        exit(T);
    end;

    [TryFunction]
    local procedure TryObjectType(var V: ObjectType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowObjectType(V: ObjectType): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsObjectType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ObjectType;
        Ok: Boolean;
    begin
        V := ObjectType::Page;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowObjectType(V));
    end;

    local procedure ObsObjectTypeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ObjectType;
        Ok: Boolean;
    begin
        V := ObjectType::Page;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowObjectType(V));
    end;

    local procedure ErrObjectType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ObjectType;
        Passed: Boolean;
    begin
        V := ObjectType::Page;
        Passed := TryObjectType(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure ObjectType_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrObjectType(Observer, 'lead', ' zzz');
        ErrObjectType(Observer, 'trail', 'zzz ');
        ErrObjectType(Observer, 'both', ' zzz ');
        ErrObjectType(Observer, 'tab_lead', Tab() + 'zzz');
        ErrObjectType(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure ObjectType_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrObjectType(Observer, 'num_both', ' 99 ');
        ErrObjectType(Observer, 'num_lead', ' 99');
        ErrObjectType(Observer, 'num_trail', '99 ');
        ErrObjectType(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [Test]
    procedure ObjectType_UnnamableNames1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsObjectType(Observer, 'name Form', 'Form');
        ObsObjectType(Observer, 'lower Form', 'form');
        ObsObjectType(Observer, 'upper Form', 'FORM');
        ObsObjectType(Observer, 'blanks Form', '  Form  ');
        ObsObjectType(Observer, 'prefix Form', 'Fo');
        ObsObjectTypeFormat(Observer, 'f9 Form', 'Form', 9);
        ErrObjectType(Observer, 'stmt Form', 'Form');
        Observer.Finish();
    end;

    [Test]
    procedure ObjectType_UnnamableNames2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsObjectType(Observer, 'name Enum', 'Enum');
        ObsObjectType(Observer, 'lower Enum', 'enum');
        ObsObjectType(Observer, 'upper Enum', 'ENUM');
        ObsObjectType(Observer, 'blanks Enum', '  Enum  ');
        ObsObjectType(Observer, 'prefix Enum', 'En');
        ObsObjectTypeFormat(Observer, 'f9 Enum', 'Enum', 9);
        ErrObjectType(Observer, 'stmt Enum', 'Enum');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryVerbosity(var V: Verbosity; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowVerbosity(V: Verbosity): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsVerbosity(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: Verbosity;
        Ok: Boolean;
    begin
        V := Verbosity::Verbose;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowVerbosity(V));
    end;

    local procedure ObsVerbosityFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: Verbosity;
        Ok: Boolean;
    begin
        V := Verbosity::Verbose;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowVerbosity(V));
    end;

    local procedure ErrVerbosity(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: Verbosity;
        Passed: Boolean;
    begin
        V := Verbosity::Verbose;
        Passed := TryVerbosity(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure Verbosity_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrVerbosity(Observer, 'lead', ' zzz');
        ErrVerbosity(Observer, 'trail', 'zzz ');
        ErrVerbosity(Observer, 'both', ' zzz ');
        ErrVerbosity(Observer, 'tab_lead', Tab() + 'zzz');
        ErrVerbosity(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Verbosity_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrVerbosity(Observer, 'num_both', ' 99 ');
        ErrVerbosity(Observer, 'num_lead', ' 99');
        ErrVerbosity(Observer, 'num_trail', '99 ');
        ErrVerbosity(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTelemetryScope(var V: TelemetryScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowTelemetryScope(V: TelemetryScope): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsTelemetryScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TelemetryScope;
        Ok: Boolean;
    begin
        V := TelemetryScope::All;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTelemetryScope(V));
    end;

    local procedure ObsTelemetryScopeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TelemetryScope;
        Ok: Boolean;
    begin
        V := TelemetryScope::All;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTelemetryScope(V));
    end;

    local procedure ErrTelemetryScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TelemetryScope;
        Passed: Boolean;
    begin
        V := TelemetryScope::All;
        Passed := TryTelemetryScope(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure TelemetryScope_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTelemetryScope(Observer, 'lead', ' zzz');
        ErrTelemetryScope(Observer, 'trail', 'zzz ');
        ErrTelemetryScope(Observer, 'both', ' zzz ');
        ErrTelemetryScope(Observer, 'tab_lead', Tab() + 'zzz');
        ErrTelemetryScope(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure TelemetryScope_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTelemetryScope(Observer, 'num_both', ' 99 ');
        ErrTelemetryScope(Observer, 'num_lead', ' 99');
        ErrTelemetryScope(Observer, 'num_trail', '99 ');
        ErrTelemetryScope(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDataClassification(var V: DataClassification; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowDataClassification(V: DataClassification): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsDataClassification(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataClassification;
        Ok: Boolean;
    begin
        V := DataClassification::SystemMetadata;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDataClassification(V));
    end;

    local procedure ObsDataClassificationFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DataClassification;
        Ok: Boolean;
    begin
        V := DataClassification::SystemMetadata;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDataClassification(V));
    end;

    local procedure ErrDataClassification(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataClassification;
        Passed: Boolean;
    begin
        V := DataClassification::SystemMetadata;
        Passed := TryDataClassification(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure DataClassification_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDataClassification(Observer, 'lead', ' zzz');
        ErrDataClassification(Observer, 'trail', 'zzz ');
        ErrDataClassification(Observer, 'both', ' zzz ');
        ErrDataClassification(Observer, 'tab_lead', Tab() + 'zzz');
        ErrDataClassification(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure DataClassification_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDataClassification(Observer, 'num_both', ' 99 ');
        ErrDataClassification(Observer, 'num_lead', ' 99');
        ErrDataClassification(Observer, 'num_trail', '99 ');
        ErrDataClassification(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTransactionType(var V: TransactionType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowTransactionType(V: TransactionType): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsTransactionType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TransactionType;
        Ok: Boolean;
    begin
        V := TransactionType::Report;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTransactionType(V));
    end;

    local procedure ObsTransactionTypeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TransactionType;
        Ok: Boolean;
    begin
        V := TransactionType::Report;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTransactionType(V));
    end;

    local procedure ErrTransactionType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TransactionType;
        Passed: Boolean;
    begin
        V := TransactionType::Report;
        Passed := TryTransactionType(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure TransactionType_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTransactionType(Observer, 'lead', ' zzz');
        ErrTransactionType(Observer, 'trail', 'zzz ');
        ErrTransactionType(Observer, 'both', ' zzz ');
        ErrTransactionType(Observer, 'tab_lead', Tab() + 'zzz');
        ErrTransactionType(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure TransactionType_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTransactionType(Observer, 'num_both', ' 99 ');
        ErrTransactionType(Observer, 'num_lead', ' 99');
        ErrTransactionType(Observer, 'num_trail', '99 ');
        ErrTransactionType(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryReportFormat(var V: ReportFormat; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowReportFormat(V: ReportFormat): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsReportFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ReportFormat;
        Ok: Boolean;
    begin
        V := ReportFormat::Html;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowReportFormat(V));
    end;

    local procedure ObsReportFormatFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ReportFormat;
        Ok: Boolean;
    begin
        V := ReportFormat::Html;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowReportFormat(V));
    end;

    local procedure ErrReportFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ReportFormat;
        Passed: Boolean;
    begin
        V := ReportFormat::Html;
        Passed := TryReportFormat(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure ReportFormat_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrReportFormat(Observer, 'lead', ' zzz');
        ErrReportFormat(Observer, 'trail', 'zzz ');
        ErrReportFormat(Observer, 'both', ' zzz ');
        ErrReportFormat(Observer, 'tab_lead', Tab() + 'zzz');
        ErrReportFormat(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrReportFormat(Observer, 'num_both', ' 99 ');
        ErrReportFormat(Observer, 'num_lead', ' 99');
        ErrReportFormat(Observer, 'num_trail', '99 ');
        ErrReportFormat(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name None', 'None');
        ObsReportFormat(Observer, 'lower None', 'none');
        ObsReportFormat(Observer, 'upper None', 'NONE');
        ObsReportFormat(Observer, 'blanks None', '  None  ');
        ObsReportFormat(Observer, 'prefix None', 'No');
        ObsReportFormatFormat(Observer, 'f9 None', 'None', 9);
        ErrReportFormat(Observer, 'stmt None', 'None');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name Jpeg', 'Jpeg');
        ObsReportFormat(Observer, 'lower Jpeg', 'jpeg');
        ObsReportFormat(Observer, 'upper Jpeg', 'JPEG');
        ObsReportFormat(Observer, 'blanks Jpeg', '  Jpeg  ');
        ObsReportFormat(Observer, 'prefix Jpeg', 'Jp');
        ObsReportFormatFormat(Observer, 'f9 Jpeg', 'Jpeg', 9);
        ErrReportFormat(Observer, 'stmt Jpeg', 'Jpeg');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name Xps', 'Xps');
        ObsReportFormat(Observer, 'lower Xps', 'xps');
        ObsReportFormat(Observer, 'upper Xps', 'XPS');
        ObsReportFormat(Observer, 'blanks Xps', '  Xps  ');
        ObsReportFormat(Observer, 'prefix Xps', 'X');
        ObsReportFormatFormat(Observer, 'f9 Xps', 'Xps', 9);
        ErrReportFormat(Observer, 'stmt Xps', 'Xps');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name Meta', 'Meta');
        ObsReportFormat(Observer, 'lower Meta', 'meta');
        ObsReportFormat(Observer, 'upper Meta', 'META');
        ObsReportFormat(Observer, 'blanks Meta', '  Meta  ');
        ObsReportFormat(Observer, 'prefix Meta', 'Me');
        ObsReportFormatFormat(Observer, 'f9 Meta', 'Meta', 9);
        ErrReportFormat(Observer, 'stmt Meta', 'Meta');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name ExcelDataset', 'ExcelDataset');
        ObsReportFormat(Observer, 'lower ExcelDataset', 'exceldataset');
        ObsReportFormat(Observer, 'upper ExcelDataset', 'EXCELDATASET');
        ObsReportFormat(Observer, 'blanks ExcelDataset', '  ExcelDataset  ');
        ObsReportFormat(Observer, 'prefix ExcelDataset', 'ExcelDatas');
        ObsReportFormatFormat(Observer, 'f9 ExcelDataset', 'ExcelDataset', 9);
        ErrReportFormat(Observer, 'stmt ExcelDataset', 'ExcelDataset');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name Custom', 'Custom');
        ObsReportFormat(Observer, 'lower Custom', 'custom');
        ObsReportFormat(Observer, 'upper Custom', 'CUSTOM');
        ObsReportFormat(Observer, 'blanks Custom', '  Custom  ');
        ObsReportFormat(Observer, 'prefix Custom', 'Cust');
        ObsReportFormatFormat(Observer, 'f9 Custom', 'Custom', 9);
        ErrReportFormat(Observer, 'stmt Custom', 'Custom');
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_UnnamableNames7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsReportFormat(Observer, 'name Zip', 'Zip');
        ObsReportFormat(Observer, 'lower Zip', 'zip');
        ObsReportFormat(Observer, 'upper Zip', 'ZIP');
        ObsReportFormat(Observer, 'blanks Zip', '  Zip  ');
        ObsReportFormat(Observer, 'prefix Zip', 'Z');
        ObsReportFormatFormat(Observer, 'f9 Zip', 'Zip', 9);
        ErrReportFormat(Observer, 'stmt Zip', 'Zip');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryErrorType(var V: ErrorType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowErrorType(V: ErrorType): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsErrorType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ErrorType;
        Ok: Boolean;
    begin
        V := ErrorType::Internal;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowErrorType(V));
    end;

    local procedure ObsErrorTypeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ErrorType;
        Ok: Boolean;
    begin
        V := ErrorType::Internal;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowErrorType(V));
    end;

    local procedure ErrErrorType(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ErrorType;
        Passed: Boolean;
    begin
        V := ErrorType::Internal;
        Passed := TryErrorType(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure ErrorType_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrErrorType(Observer, 'lead', ' zzz');
        ErrErrorType(Observer, 'trail', 'zzz ');
        ErrErrorType(Observer, 'both', ' zzz ');
        ErrErrorType(Observer, 'tab_lead', Tab() + 'zzz');
        ErrErrorType(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure ErrorType_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrErrorType(Observer, 'num_both', ' 99 ');
        ErrErrorType(Observer, 'num_lead', ' 99');
        ErrErrorType(Observer, 'num_trail', '99 ');
        ErrErrorType(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDefaultLayout(var V: DefaultLayout; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowDefaultLayout(V: DefaultLayout): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsDefaultLayout(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DefaultLayout;
        Ok: Boolean;
    begin
        V := DefaultLayout::Word;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDefaultLayout(V));
    end;

    local procedure ObsDefaultLayoutFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DefaultLayout;
        Ok: Boolean;
    begin
        V := DefaultLayout::Word;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDefaultLayout(V));
    end;

    local procedure ErrDefaultLayout(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DefaultLayout;
        Passed: Boolean;
    begin
        V := DefaultLayout::Word;
        Passed := TryDefaultLayout(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure DefaultLayout_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDefaultLayout(Observer, 'lead', ' zzz');
        ErrDefaultLayout(Observer, 'trail', 'zzz ');
        ErrDefaultLayout(Observer, 'both', ' zzz ');
        ErrDefaultLayout(Observer, 'tab_lead', Tab() + 'zzz');
        ErrDefaultLayout(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure DefaultLayout_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDefaultLayout(Observer, 'num_both', ' 99 ');
        ErrDefaultLayout(Observer, 'num_lead', ' 99');
        ErrDefaultLayout(Observer, 'num_trail', '99 ');
        ErrDefaultLayout(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTestPermissions(var V: TestPermissions; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowTestPermissions(V: TestPermissions): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsTestPermissions(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TestPermissions;
        Ok: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTestPermissions(V));
    end;

    local procedure ObsTestPermissionsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TestPermissions;
        Ok: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowTestPermissions(V));
    end;

    local procedure ErrTestPermissions(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TestPermissions;
        Passed: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Passed := TryTestPermissions(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure TestPermissions_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTestPermissions(Observer, 'lead', ' zzz');
        ErrTestPermissions(Observer, 'trail', 'zzz ');
        ErrTestPermissions(Observer, 'both', ' zzz ');
        ErrTestPermissions(Observer, 'tab_lead', Tab() + 'zzz');
        ErrTestPermissions(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure TestPermissions_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrTestPermissions(Observer, 'num_both', ' 99 ');
        ErrTestPermissions(Observer, 'num_lead', ' 99');
        ErrTestPermissions(Observer, 'num_trail', '99 ');
        ErrTestPermissions(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryDataScope(var V: DataScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowDataScope(V: DataScope): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsDataScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataScope;
        Ok: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDataScope(V));
    end;

    local procedure ObsDataScopeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DataScope;
        Ok: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowDataScope(V));
    end;

    local procedure ErrDataScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataScope;
        Passed: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Passed := TryDataScope(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure DataScope_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDataScope(Observer, 'lead', ' zzz');
        ErrDataScope(Observer, 'trail', 'zzz ');
        ErrDataScope(Observer, 'both', ' zzz ');
        ErrDataScope(Observer, 'tab_lead', Tab() + 'zzz');
        ErrDataScope(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure DataScope_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrDataScope(Observer, 'num_both', ' 99 ');
        ErrDataScope(Observer, 'num_lead', ' 99');
        ErrDataScope(Observer, 'num_trail', '99 ');
        ErrDataScope(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryExecutionContext(var V: ExecutionContext; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowExecutionContext(V: ExecutionContext): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsExecutionContext(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ExecutionContext;
        Ok: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowExecutionContext(V));
    end;

    local procedure ObsExecutionContextFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ExecutionContext;
        Ok: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowExecutionContext(V));
    end;

    local procedure ErrExecutionContext(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ExecutionContext;
        Passed: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Passed := TryExecutionContext(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure ExecutionContext_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrExecutionContext(Observer, 'lead', ' zzz');
        ErrExecutionContext(Observer, 'trail', 'zzz ');
        ErrExecutionContext(Observer, 'both', ' zzz ');
        ErrExecutionContext(Observer, 'tab_lead', Tab() + 'zzz');
        ErrExecutionContext(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure ExecutionContext_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrExecutionContext(Observer, 'num_both', ' 99 ');
        ErrExecutionContext(Observer, 'num_lead', ' 99');
        ErrExecutionContext(Observer, 'num_trail', '99 ');
        ErrExecutionContext(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [Test]
    procedure ExecutionContext_UnnamableNames1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsExecutionContext(Observer, 'name Uninstall', 'Uninstall');
        ObsExecutionContext(Observer, 'lower Uninstall', 'uninstall');
        ObsExecutionContext(Observer, 'upper Uninstall', 'UNINSTALL');
        ObsExecutionContext(Observer, 'blanks Uninstall', '  Uninstall  ');
        ObsExecutionContext(Observer, 'prefix Uninstall', 'Uninsta');
        ObsExecutionContextFormat(Observer, 'f9 Uninstall', 'Uninstall', 9);
        ErrExecutionContext(Observer, 'stmt Uninstall', 'Uninstall');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryNotificationScope(var V: NotificationScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowNotificationScope(V: NotificationScope): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsNotificationScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: NotificationScope;
        Ok: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowNotificationScope(V));
    end;

    local procedure ObsNotificationScopeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: NotificationScope;
        Ok: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowNotificationScope(V));
    end;

    local procedure ErrNotificationScope(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: NotificationScope;
        Passed: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Passed := TryNotificationScope(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure NotificationScope_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrNotificationScope(Observer, 'lead', ' zzz');
        ErrNotificationScope(Observer, 'trail', 'zzz ');
        ErrNotificationScope(Observer, 'both', ' zzz ');
        ErrNotificationScope(Observer, 'tab_lead', Tab() + 'zzz');
        ErrNotificationScope(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure NotificationScope_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrNotificationScope(Observer, 'num_both', ' 99 ');
        ErrNotificationScope(Observer, 'num_lead', ' 99');
        ErrNotificationScope(Observer, 'num_trail', '99 ');
        ErrNotificationScope(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryWebServiceActionResultCode(var V: WebServiceActionResultCode; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowWebServiceActionResultCode(V: WebServiceActionResultCode): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsWebServiceActionResultCode(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: WebServiceActionResultCode;
        Ok: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowWebServiceActionResultCode(V));
    end;

    local procedure ObsWebServiceActionResultCodeFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: WebServiceActionResultCode;
        Ok: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowWebServiceActionResultCode(V));
    end;

    local procedure ErrWebServiceActionResultCode(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: WebServiceActionResultCode;
        Passed: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Passed := TryWebServiceActionResultCode(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure WebServiceActionResultCode_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrWebServiceActionResultCode(Observer, 'lead', ' zzz');
        ErrWebServiceActionResultCode(Observer, 'trail', 'zzz ');
        ErrWebServiceActionResultCode(Observer, 'both', ' zzz ');
        ErrWebServiceActionResultCode(Observer, 'tab_lead', Tab() + 'zzz');
        ErrWebServiceActionResultCode(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure WebServiceActionResultCode_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrWebServiceActionResultCode(Observer, 'num_both', ' 99 ');
        ErrWebServiceActionResultCode(Observer, 'num_lead', ' 99');
        ErrWebServiceActionResultCode(Observer, 'num_trail', '99 ');
        ErrWebServiceActionResultCode(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [Test]
    procedure WebServiceActionResultCode_HttpNumbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsWebServiceActionResultCode(Observer, 'num 0', '0');
        ObsWebServiceActionResultCode(Observer, 'num 1', '1');
        ObsWebServiceActionResultCode(Observer, 'num 199', '199');
        ObsWebServiceActionResultCode(Observer, 'num 200', '200');
        ObsWebServiceActionResultCode(Observer, 'num 201', '201');
        ObsWebServiceActionResultCode(Observer, 'num 202', '202');
        ObsWebServiceActionResultCode(Observer, 'num 203', '203');
        ObsWebServiceActionResultCode(Observer, 'num 204', '204');
        ObsWebServiceActionResultCode(Observer, 'num 205', '205');
        ObsWebServiceActionResultCode(Observer, 'num 206', '206');
        ObsWebServiceActionResultCode(Observer, 'num 300', '300');
        ObsWebServiceActionResultCode(Observer, 'num 400', '400');
        ObsWebServiceActionResultCode(Observer, 'num 404', '404');
        ObsWebServiceActionResultCode(Observer, 'num 500', '500');
        Observer.Finish();
    end;

    [Test]
    procedure WebServiceActionResultCode_HttpNumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsWebServiceActionResultCode(Observer, 'plus_200', '+200');
        ObsWebServiceActionResultCode(Observer, 'blank_200', ' 200 ');
        ObsWebServiceActionResultCode(Observer, 'zero_200', '0200');
        ObsWebServiceActionResultCode(Observer, 'tab_204', '204' + Tab());
        ObsWebServiceActionResultCode(Observer, 'decimal_200', '200.0');
        ObsWebServiceActionResultCode(Observer, 'neg_200', '-200');
        ObsWebServiceActionResultCodeFormat(Observer, 'f0 200', '200', 0);
        ObsWebServiceActionResultCodeFormat(Observer, 'f2 201', '201', 2);
        ObsWebServiceActionResultCodeFormat(Observer, 'f9 204', '204', 9);
        ObsWebServiceActionResultCodeFormat(Observer, 'f9 202', '202', 9);
        ErrWebServiceActionResultCode(Observer, 'stmt 200', '200');
        ErrWebServiceActionResultCode(Observer, 'stmt 202', '202');
        ErrWebServiceActionResultCode(Observer, 'stmt blank 202', ' 202 ');
        Observer.Finish();
    end;

    [Test]
    procedure WebServiceActionResultCode_FormatOfMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('None', ShowWebServiceActionResultCode(WebServiceActionResultCode::None));
        Observer.Observe('Get', ShowWebServiceActionResultCode(WebServiceActionResultCode::Get));
        Observer.Observe('Created', ShowWebServiceActionResultCode(WebServiceActionResultCode::Created));
        Observer.Observe('Updated', ShowWebServiceActionResultCode(WebServiceActionResultCode::Updated));
        Observer.Observe('Deleted', ShowWebServiceActionResultCode(WebServiceActionResultCode::Deleted));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryFieldClass(var V: FieldClass; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ShowFieldClass(V: FieldClass): Text
    begin
        exit(Format(V) + '/' + Format(V, 0, 1) + '/' + Format(V, 0, 2) + '/' + Format(V, 0, 9));
    end;

    local procedure ObsFieldClass(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: FieldClass;
        Ok: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowFieldClass(V));
    end;

    local procedure ObsFieldClassFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: FieldClass;
        Ok: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + ShowFieldClass(V));
    end;

    local procedure ErrFieldClass(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: FieldClass;
        Passed: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Passed := TryFieldClass(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    [Test]
    procedure FieldClass_StatementBlanksText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrFieldClass(Observer, 'lead', ' zzz');
        ErrFieldClass(Observer, 'trail', 'zzz ');
        ErrFieldClass(Observer, 'both', ' zzz ');
        ErrFieldClass(Observer, 'tab_lead', Tab() + 'zzz');
        ErrFieldClass(Observer, 'tab_trail', 'zzz' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure FieldClass_StatementBlanksNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ErrFieldClass(Observer, 'num_both', ' 99 ');
        ErrFieldClass(Observer, 'num_lead', ' 99');
        ErrFieldClass(Observer, 'num_trail', '99 ');
        ErrFieldClass(Observer, 'neg_both', ' -1 ');
        Observer.Finish();
    end;

    [Test]
    procedure FieldClass_UnnamableNames1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFieldClass(Observer, 'name KeyFieldReference', 'KeyFieldReference');
        ObsFieldClass(Observer, 'lower KeyFieldReference', 'keyfieldreference');
        ObsFieldClass(Observer, 'upper KeyFieldReference', 'KEYFIELDREFERENCE');
        ObsFieldClass(Observer, 'blanks KeyFieldReference', '  KeyFieldReference  ');
        ObsFieldClass(Observer, 'prefix KeyFieldReference', 'KeyFieldReferen');
        ObsFieldClassFormat(Observer, 'f9 KeyFieldReference', 'KeyFieldReference', 9);
        ErrFieldClass(Observer, 'stmt KeyFieldReference', 'KeyFieldReference');
        Observer.Finish();
    end;
}
