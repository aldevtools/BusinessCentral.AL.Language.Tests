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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Page');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Page');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Page');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Page');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Page');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Page');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Page');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Page');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Page');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ObsObjectType(Observer, 'prefix_Fo', 'Fo');
        ObsObjectTypeFormat(Observer, 'f9 Form', 'Form', 9);
        ErrObjectType(Observer, 'stmt Form', 'Form');
        Observer.Expect('name Form', 'Yes/Form/Form/2/2');
        Observer.Expect('lower Form', 'Yes/Form/Form/2/2');
        Observer.Expect('upper Form', 'Yes/Form/Form/2/2');
        Observer.Expect('blanks Form', 'Yes/Form/Form/2/2');
        Observer.Expect('prefix_Fo', 'Yes/Form/Form/2/2');
        Observer.Expect('f9 Form', 'Yes/Form/Form/2/2');
        Observer.Expect('stmt Form', 'Yes/Form');
        Observer.Expect('stmt Form|text', '');
        Observer.Expect('stmt Form|code', '');
        Observer.Verify();
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
        ObsObjectType(Observer, 'prefix_En', 'En');
        ObsObjectTypeFormat(Observer, 'f9 Enum', 'Enum', 9);
        ErrObjectType(Observer, 'stmt Enum', 'Enum');
        Observer.Expect('name Enum', 'Yes/Enum/Enum/10/10');
        Observer.Expect('lower Enum', 'Yes/Enum/Enum/10/10');
        Observer.Expect('upper Enum', 'Yes/Enum/Enum/10/10');
        Observer.Expect('blanks Enum', 'Yes/Enum/Enum/10/10');
        Observer.Expect('prefix_En', 'Yes/Enum/Enum/10/10');
        Observer.Expect('f9 Enum', 'Yes/Enum/Enum/10/10');
        Observer.Expect('stmt Enum', 'Yes/Enum');
        Observer.Expect('stmt Enum|text', '');
        Observer.Expect('stmt Enum|code', '');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Verbose');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Verbose');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Verbose');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Verbose');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Verbose');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Verbose');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Verbose');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Verbose');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Verbose');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/All');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/All');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/All');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/All');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/All');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/All');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/All');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/All');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/All');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/SystemMetadata');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/SystemMetadata');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/SystemMetadata');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/SystemMetadata');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/SystemMetadata');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/SystemMetadata');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/SystemMetadata');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/SystemMetadata');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/SystemMetadata');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Report');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Report');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Report');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Report');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Report');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Report');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Report');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Report');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Report');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Html');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Html');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Html');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Html');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Html');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Html');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Html');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Html');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Html');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_No', 'No');
        ObsReportFormatFormat(Observer, 'f9 None', 'None', 9);
        ErrReportFormat(Observer, 'stmt None', 'None');
        Observer.Expect('name None', 'Yes/None/None/0/0');
        Observer.Expect('lower None', 'Yes/None/None/0/0');
        Observer.Expect('upper None', 'Yes/None/None/0/0');
        Observer.Expect('blanks None', 'Yes/None/None/0/0');
        Observer.Expect('prefix_No', 'Yes/None/None/0/0');
        Observer.Expect('f9 None', 'Yes/None/None/0/0');
        Observer.Expect('stmt None', 'Yes/None');
        Observer.Expect('stmt None|text', '');
        Observer.Expect('stmt None|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_Jp', 'Jp');
        ObsReportFormatFormat(Observer, 'f9 Jpeg', 'Jpeg', 9);
        ErrReportFormat(Observer, 'stmt Jpeg', 'Jpeg');
        Observer.Expect('name Jpeg', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('lower Jpeg', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('upper Jpeg', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('blanks Jpeg', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('prefix_Jp', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('f9 Jpeg', 'Yes/Jpeg/Jpeg/6/6');
        Observer.Expect('stmt Jpeg', 'Yes/Jpeg');
        Observer.Expect('stmt Jpeg|text', '');
        Observer.Expect('stmt Jpeg|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_X', 'X');
        ObsReportFormatFormat(Observer, 'f9 Xps', 'Xps', 9);
        ErrReportFormat(Observer, 'stmt Xps', 'Xps');
        Observer.Expect('name Xps', 'Yes/Xps/Xps/7/7');
        Observer.Expect('lower Xps', 'Yes/Xps/Xps/7/7');
        Observer.Expect('upper Xps', 'Yes/Xps/Xps/7/7');
        Observer.Expect('blanks Xps', 'Yes/Xps/Xps/7/7');
        Observer.Expect('prefix_X', 'Yes/Xml/Xml/4/4');
        Observer.Expect('f9 Xps', 'Yes/Xps/Xps/7/7');
        Observer.Expect('stmt Xps', 'Yes/Xps');
        Observer.Expect('stmt Xps|text', '');
        Observer.Expect('stmt Xps|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_Me', 'Me');
        ObsReportFormatFormat(Observer, 'f9 Meta', 'Meta', 9);
        ErrReportFormat(Observer, 'stmt Meta', 'Meta');
        Observer.Expect('name Meta', 'Yes/Meta/Meta/8/8');
        Observer.Expect('lower Meta', 'Yes/Meta/Meta/8/8');
        Observer.Expect('upper Meta', 'Yes/Meta/Meta/8/8');
        Observer.Expect('blanks Meta', 'Yes/Meta/Meta/8/8');
        Observer.Expect('prefix_Me', 'Yes/Meta/Meta/8/8');
        Observer.Expect('f9 Meta', 'Yes/Meta/Meta/8/8');
        Observer.Expect('stmt Meta', 'Yes/Meta');
        Observer.Expect('stmt Meta|text', '');
        Observer.Expect('stmt Meta|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_ExcelDatas', 'ExcelDatas');
        ObsReportFormatFormat(Observer, 'f9 ExcelDataset', 'ExcelDataset', 9);
        ErrReportFormat(Observer, 'stmt ExcelDataset', 'ExcelDataset');
        Observer.Expect('name ExcelDataset', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('lower ExcelDataset', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('upper ExcelDataset', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('blanks ExcelDataset', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('prefix_ExcelDatas', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('f9 ExcelDataset', 'Yes/ExcelDataset/ExcelDataset/9/9');
        Observer.Expect('stmt ExcelDataset', 'Yes/ExcelDataset');
        Observer.Expect('stmt ExcelDataset|text', '');
        Observer.Expect('stmt ExcelDataset|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_Cust', 'Cust');
        ObsReportFormatFormat(Observer, 'f9 Custom', 'Custom', 9);
        ErrReportFormat(Observer, 'stmt Custom', 'Custom');
        Observer.Expect('name Custom', 'Yes/Custom/Custom/10/10');
        Observer.Expect('lower Custom', 'Yes/Custom/Custom/10/10');
        Observer.Expect('upper Custom', 'Yes/Custom/Custom/10/10');
        Observer.Expect('blanks Custom', 'Yes/Custom/Custom/10/10');
        Observer.Expect('prefix_Cust', 'Yes/Custom/Custom/10/10');
        Observer.Expect('f9 Custom', 'Yes/Custom/Custom/10/10');
        Observer.Expect('stmt Custom', 'Yes/Custom');
        Observer.Expect('stmt Custom|text', '');
        Observer.Expect('stmt Custom|code', '');
        Observer.Verify();
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
        ObsReportFormat(Observer, 'prefix_Z', 'Z');
        ObsReportFormatFormat(Observer, 'f9 Zip', 'Zip', 9);
        ErrReportFormat(Observer, 'stmt Zip', 'Zip');
        Observer.Expect('name Zip', 'Yes/Zip/Zip/11/11');
        Observer.Expect('lower Zip', 'Yes/Zip/Zip/11/11');
        Observer.Expect('upper Zip', 'Yes/Zip/Zip/11/11');
        Observer.Expect('blanks Zip', 'Yes/Zip/Zip/11/11');
        Observer.Expect('prefix_Z', 'Yes/Zip/Zip/11/11');
        Observer.Expect('f9 Zip', 'Yes/Zip/Zip/11/11');
        Observer.Expect('stmt Zip', 'Yes/Zip');
        Observer.Expect('stmt Zip|text', '');
        Observer.Expect('stmt Zip|code', '');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Internal');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Internal');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Internal');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Internal');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Internal');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Internal');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Internal');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Internal');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Internal');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Word');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Word');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Word');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Word');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Word');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Word');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Word');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Word');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Word');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/InheritFromTestCodeunit');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/InheritFromTestCodeunit');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/InheritFromTestCodeunit');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/InheritFromTestCodeunit');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/InheritFromTestCodeunit');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/InheritFromTestCodeunit');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/InheritFromTestCodeunit');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/InheritFromTestCodeunit');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/InheritFromTestCodeunit');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/CompanyAndUser');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/CompanyAndUser');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/CompanyAndUser');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/CompanyAndUser');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/CompanyAndUser');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/CompanyAndUser');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/CompanyAndUser');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/CompanyAndUser');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/CompanyAndUser');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Upgrade');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Upgrade');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Upgrade');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Upgrade');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Upgrade');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Upgrade');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Upgrade');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Upgrade');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Upgrade');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ObsExecutionContext(Observer, 'prefix_Uninsta', 'Uninsta');
        ObsExecutionContextFormat(Observer, 'f9 Uninstall', 'Uninstall', 9);
        ErrExecutionContext(Observer, 'stmt Uninstall', 'Uninstall');
        Observer.Expect('name Uninstall', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('lower Uninstall', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('upper Uninstall', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('blanks Uninstall', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('prefix_Uninsta', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('f9 Uninstall', 'Yes/Uninstall/Uninstall/2/2');
        Observer.Expect('stmt Uninstall', 'Yes/Uninstall');
        Observer.Expect('stmt Uninstall|text', '');
        Observer.Expect('stmt Uninstall|code', '');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/GlobalScope');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/GlobalScope');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/GlobalScope');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/GlobalScope');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/GlobalScope');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/GlobalScope');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/GlobalScope');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/GlobalScope');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/GlobalScope');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('lead', 'No/Deleted');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/Deleted');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/Deleted');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/Deleted');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/Deleted');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num_both', 'No/Deleted');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/Deleted');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/Deleted');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/Deleted');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/None/None/0/0');
        Observer.Expect('num 1', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 199', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 200', 'Yes/Get/Get/200/200');
        Observer.Expect('num 201', 'Yes/Created/Created/201/201');
        Observer.Expect('num 202', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 203', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 204', 'Yes/Deleted/Deleted/204/204');
        Observer.Expect('num 205', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 206', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 300', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 400', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 404', 'No/Deleted/Deleted/204/204');
        Observer.Expect('num 500', 'No/Deleted/Deleted/204/204');
        Observer.Verify();
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
        Observer.Expect('plus_200', 'Yes/Get/Get/200/200');
        Observer.Expect('blank_200', 'Yes/Get/Get/200/200');
        Observer.Expect('zero_200', 'Yes/Get/Get/200/200');
        Observer.Expect('tab_204', 'Yes/Deleted/Deleted/204/204');
        Observer.Expect('decimal_200', 'No/Deleted/Deleted/204/204');
        Observer.Expect('neg_200', 'No/Deleted/Deleted/204/204');
        Observer.Expect('f0 200', 'Yes/Get/Get/200/200');
        Observer.Expect('f2 201', 'Yes/Created/Created/201/201');
        Observer.Expect('f9 204', 'Yes/Deleted/Deleted/204/204');
        Observer.Expect('f9 202', 'No/Deleted/Deleted/204/204');
        Observer.Expect('stmt 200', 'Yes/Get');
        Observer.Expect('stmt 200|text', '');
        Observer.Expect('stmt 200|code', '');
        Observer.Expect('stmt 202', 'No/Deleted');
        Observer.Expect('stmt 202|text', '''202'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('stmt 202|code', 'InvalidOptionString');
        Observer.Expect('stmt blank 202', 'No/Deleted');
        Observer.Expect('stmt blank 202|text', '''202'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('stmt blank 202|code', 'InvalidOptionString');
        Observer.Verify();
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
        Observer.Expect('None', 'None/None/0/0');
        Observer.Expect('Get', 'Get/Get/200/200');
        Observer.Expect('Created', 'Created/Created/201/201');
        Observer.Expect('Updated', 'Get/Get/200/200');
        Observer.Expect('Deleted', 'Deleted/Deleted/204/204');
        Observer.Verify();
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
        ClearLastError();
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
#if BC28PLUS
        Observer.Expect('lead', 'No/FlowFilter');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/FlowFilter');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/FlowFilter');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/FlowFilter');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/FlowFilter');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
#else
        Observer.Expect('lead', 'No/FlowFilter');
        Observer.Expect('lead|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('lead|code', 'InvalidOptionString');
        Observer.Expect('trail', 'No/FlowFilter');
        Observer.Expect('trail|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('trail|code', 'InvalidOptionString');
        Observer.Expect('both', 'No/FlowFilter');
        Observer.Expect('both|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('both|code', 'InvalidOptionString');
        Observer.Expect('tab_lead', 'No/FlowFilter');
        Observer.Expect('tab_lead|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('tab_lead|code', 'InvalidOptionString');
        Observer.Expect('tab_trail', 'No/FlowFilter');
        Observer.Expect('tab_trail|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('tab_trail|code', 'InvalidOptionString');
#endif
        Observer.Verify();
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
#if BC28PLUS
        Observer.Expect('num_both', 'No/FlowFilter');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/FlowFilter');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/FlowFilter');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/FlowFilter');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
#else
        Observer.Expect('num_both', 'No/FlowFilter');
        Observer.Expect('num_both|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('num_both|code', 'InvalidOptionString');
        Observer.Expect('num_lead', 'No/FlowFilter');
        Observer.Expect('num_lead|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('num_lead|code', 'InvalidOptionString');
        Observer.Expect('num_trail', 'No/FlowFilter');
        Observer.Expect('num_trail|text', '''99'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('num_trail|code', 'InvalidOptionString');
        Observer.Expect('neg_both', 'No/FlowFilter');
        Observer.Expect('neg_both|text', '''-1'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('neg_both|code', 'InvalidOptionString');
#endif
        Observer.Verify();
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
        ObsFieldClass(Observer, 'prefix_KeyFieldReferen', 'KeyFieldReferen');
        ObsFieldClassFormat(Observer, 'f9 KeyFieldReference', 'KeyFieldReference', 9);
        ErrFieldClass(Observer, 'stmt KeyFieldReference', 'KeyFieldReference');
#if BC28PLUS
        Observer.Expect('name KeyFieldReference', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('lower KeyFieldReference', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('upper KeyFieldReference', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('blanks KeyFieldReference', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('prefix_KeyFieldReferen', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('f9 KeyFieldReference', 'Yes/KeyFieldReference/KeyFieldReference/KeyFieldReference/KeyFieldReference');
        Observer.Expect('stmt KeyFieldReference', 'Yes/KeyFieldReference');
        Observer.Expect('stmt KeyFieldReference|text', '');
        Observer.Expect('stmt KeyFieldReference|code', '');
#else
        Observer.Expect('name KeyFieldReference', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('lower KeyFieldReference', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('upper KeyFieldReference', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('blanks KeyFieldReference', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('prefix_KeyFieldReferen', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('f9 KeyFieldReference', 'No/FlowFilter/FlowFilter/FlowFilter/FlowFilter');
        Observer.Expect('stmt KeyFieldReference', 'No/FlowFilter');
        Observer.Expect('stmt KeyFieldReference|text', '''KeyFieldReference'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
        Observer.Expect('stmt KeyFieldReference|code', 'InvalidOptionString');
#endif
        Observer.Verify();
    end;
}
