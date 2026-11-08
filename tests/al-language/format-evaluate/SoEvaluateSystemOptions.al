// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/library
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Evaluate(Variable, Text) into system option types: by member name (exact, lower case, upper case, blanks, prefix), by number (0 to past the
//   last member, signs, blanks, leading zero, decimal point, int range), blank and garbage text, the value left after a failed Evaluate, format number 9,
//   and the error text and code of the statement form. Types: ObjectType, Verbosity, TelemetryScope, DataClassification, TransactionType, ReportFormat,
//   ErrorType, DefaultLayout, TestPermissions, DataScope, ExecutionContext, NotificationScope, WebServiceActionResultCode, FieldClass.
//   Not covered here (pinned elsewhere): AuditCategory (ACAuditCategory.al), FieldType, IsolationLevel, SecurityFilter (PnAPlatformOptions.al), ClientType,
//   ExecutionMode, TableConnectionType, SecurityOperationResult, ReportLayoutType. Not probed: PageStyle, HttpRequestType, PageBackgroundTaskErrorLevel
//   (Evaluate into them ends the test session on BC 28 and 29, see ACHttpRequestType.al).
// Each test starts with the variable set to a member, so a failed Evaluate shows as the member kept.
// BC versions: 27, 28, 29
codeunit 99600 "LT SO Eval ObjectType"
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
    local procedure TryEval(var V: ObjectType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ObjectType;
        Ok: Boolean;
    begin
        V := ObjectType::Page;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ObjectType;
        Passed: Boolean;
    begin
        V := ObjectType::Page;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ObjectType;
        Ok: Boolean;
    begin
        V := ObjectType::Page;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name TableData', 'TableData');
        Obs(Observer, 'name Table', 'Table');
        Obs(Observer, 'name Report', 'Report');
        Obs(Observer, 'name Codeunit', 'Codeunit');
        Obs(Observer, 'name XmlPort', 'XmlPort');
        Obs(Observer, 'name MenuSuite', 'MenuSuite');
        Obs(Observer, 'name Page', 'Page');
        Obs(Observer, 'name Query', 'Query');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'tabledata');
        Obs(Observer, 'upper', 'TABLEDATA');
        Obs(Observer, 'mixedcase', 'tABLEDATA');
        Obs(Observer, 'leading_blank', ' TableData');
        Obs(Observer, 'trailing_blank', 'TableData ');
        Obs(Observer, 'both_blanks', '  TableData  ');
        Obs(Observer, 'prefix', 'Tab');
        Obs(Observer, 'extra_char', 'TableDatax');
        Obs(Observer, 'two_names', 'TableData,Query');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Obs(Observer, 'num 9', '9');
        Obs(Observer, 'num 10', '10');
        Obs(Observer, 'num 11', '11');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'TableData' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'TableData');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'TableData');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '8');
        Err(Observer, 'far_past', '28');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'TableData' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'TableData', 9);
        ObsFormat(Observer, 'f9 last', 'Query', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '8', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'TableData', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99601 "LT SO Eval Verbosity"
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
    local procedure TryEval(var V: Verbosity; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: Verbosity;
        Ok: Boolean;
    begin
        V := Verbosity::Verbose;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: Verbosity;
        Passed: Boolean;
    begin
        V := Verbosity::Verbose;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: Verbosity;
        Ok: Boolean;
    begin
        V := Verbosity::Verbose;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Critical', 'Critical');
        Obs(Observer, 'name Error', 'Error');
        Obs(Observer, 'name Warning', 'Warning');
        Obs(Observer, 'name Normal', 'Normal');
        Obs(Observer, 'name Verbose', 'Verbose');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'critical');
        Obs(Observer, 'upper', 'CRITICAL');
        Obs(Observer, 'mixedcase', 'cRITICAL');
        Obs(Observer, 'leading_blank', ' Critical');
        Obs(Observer, 'trailing_blank', 'Critical ');
        Obs(Observer, 'both_blanks', '  Critical  ');
        Obs(Observer, 'prefix', 'Cri');
        Obs(Observer, 'extra_char', 'Criticalx');
        Obs(Observer, 'two_names', 'Critical,Verbose');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Critical' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Critical');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Critical');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '5');
        Err(Observer, 'far_past', '25');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Critical' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Critical', 9);
        ObsFormat(Observer, 'f9 last', 'Verbose', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '5', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Critical', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99602 "LT SO Eval TelemetryScope"
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
    local procedure TryEval(var V: TelemetryScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TelemetryScope;
        Ok: Boolean;
    begin
        V := TelemetryScope::All;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TelemetryScope;
        Passed: Boolean;
    begin
        V := TelemetryScope::All;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TelemetryScope;
        Ok: Boolean;
    begin
        V := TelemetryScope::All;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name ExtensionPublisher', 'ExtensionPublisher');
        Obs(Observer, 'name All', 'All');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'extensionpublisher');
        Obs(Observer, 'upper', 'EXTENSIONPUBLISHER');
        Obs(Observer, 'mixedcase', 'eXTENSIONPUBLISHER');
        Obs(Observer, 'leading_blank', ' ExtensionPublisher');
        Obs(Observer, 'trailing_blank', 'ExtensionPublisher ');
        Obs(Observer, 'both_blanks', '  ExtensionPublisher  ');
        Obs(Observer, 'prefix', 'Ext');
        Obs(Observer, 'extra_char', 'ExtensionPublisherx');
        Obs(Observer, 'two_names', 'ExtensionPublisher,All');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'ExtensionPublisher' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'ExtensionPublisher');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'ExtensionPublisher');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '2');
        Err(Observer, 'far_past', '22');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'ExtensionPublisher' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'ExtensionPublisher', 9);
        ObsFormat(Observer, 'f9 last', 'All', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '2', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'ExtensionPublisher', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99603 "LT SO Eval DataClassification"
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
    local procedure TryEval(var V: DataClassification; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataClassification;
        Ok: Boolean;
    begin
        V := DataClassification::AnonymousData;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataClassification;
        Passed: Boolean;
    begin
        V := DataClassification::AnonymousData;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DataClassification;
        Ok: Boolean;
    begin
        V := DataClassification::AnonymousData;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name CustomerContent', 'CustomerContent');
        Obs(Observer, 'name ToBeClassified', 'ToBeClassified');
        Obs(Observer, 'name EndUserIdentifiableInformation', 'EndUserIdentifiableInformation');
        Obs(Observer, 'name AccountData', 'AccountData');
        Obs(Observer, 'name EndUserPseudonymousIdentifiers', 'EndUserPseudonymousIdentifiers');
        Obs(Observer, 'name OrganizationIdentifiableInformation', 'OrganizationIdentifiableInformation');
        Obs(Observer, 'name SystemMetadata', 'SystemMetadata');
        Obs(Observer, 'name AnonymousData', 'AnonymousData');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'customercontent');
        Obs(Observer, 'upper', 'CUSTOMERCONTENT');
        Obs(Observer, 'mixedcase', 'cUSTOMERCONTENT');
        Obs(Observer, 'leading_blank', ' CustomerContent');
        Obs(Observer, 'trailing_blank', 'CustomerContent ');
        Obs(Observer, 'both_blanks', '  CustomerContent  ');
        Obs(Observer, 'prefix', 'Cus');
        Obs(Observer, 'extra_char', 'CustomerContentx');
        Obs(Observer, 'two_names', 'CustomerContent,AnonymousData');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Obs(Observer, 'num 9', '9');
        Obs(Observer, 'num 10', '10');
        Obs(Observer, 'num 11', '11');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'CustomerContent' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'CustomerContent');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'CustomerContent');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '8');
        Err(Observer, 'far_past', '28');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'CustomerContent' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'CustomerContent', 9);
        ObsFormat(Observer, 'f9 last', 'AnonymousData', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '8', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'CustomerContent', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99604 "LT SO Eval TransactionType"
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
    local procedure TryEval(var V: TransactionType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TransactionType;
        Ok: Boolean;
    begin
        V := TransactionType::Report;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TransactionType;
        Passed: Boolean;
    begin
        V := TransactionType::Report;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TransactionType;
        Ok: Boolean;
    begin
        V := TransactionType::Report;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name UpdateNoLocks', 'UpdateNoLocks');
        Obs(Observer, 'name Update', 'Update');
        Obs(Observer, 'name Snapshot', 'Snapshot');
        Obs(Observer, 'name Browse', 'Browse');
        Obs(Observer, 'name Report', 'Report');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'updatenolocks');
        Obs(Observer, 'upper', 'UPDATENOLOCKS');
        Obs(Observer, 'mixedcase', 'uPDATENOLOCKS');
        Obs(Observer, 'leading_blank', ' UpdateNoLocks');
        Obs(Observer, 'trailing_blank', 'UpdateNoLocks ');
        Obs(Observer, 'both_blanks', '  UpdateNoLocks  ');
        Obs(Observer, 'prefix', 'Upd');
        Obs(Observer, 'extra_char', 'UpdateNoLocksx');
        Obs(Observer, 'two_names', 'UpdateNoLocks,Report');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'UpdateNoLocks' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'UpdateNoLocks');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'UpdateNoLocks');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '5');
        Err(Observer, 'far_past', '25');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'UpdateNoLocks' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'UpdateNoLocks', 9);
        ObsFormat(Observer, 'f9 last', 'Report', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '5', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'UpdateNoLocks', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99605 "LT SO Eval ReportFormat"
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
    local procedure TryEval(var V: ReportFormat; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ReportFormat;
        Ok: Boolean;
    begin
        V := ReportFormat::Html;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ReportFormat;
        Passed: Boolean;
    begin
        V := ReportFormat::Html;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ReportFormat;
        Ok: Boolean;
    begin
        V := ReportFormat::Html;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Excel', 'Excel');
        Obs(Observer, 'name Pdf', 'Pdf');
        Obs(Observer, 'name Word', 'Word');
        Obs(Observer, 'name Xml', 'Xml');
        Obs(Observer, 'name Html', 'Html');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'excel');
        Obs(Observer, 'upper', 'EXCEL');
        Obs(Observer, 'mixedcase', 'eXCEL');
        Obs(Observer, 'leading_blank', ' Excel');
        Obs(Observer, 'trailing_blank', 'Excel ');
        Obs(Observer, 'both_blanks', '  Excel  ');
        Obs(Observer, 'prefix', 'Exc');
        Obs(Observer, 'extra_char', 'Excelx');
        Obs(Observer, 'two_names', 'Excel,Html');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Excel' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Excel');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Excel');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '5');
        Err(Observer, 'far_past', '25');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Excel' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Excel', 9);
        ObsFormat(Observer, 'f9 last', 'Html', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '5', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Excel', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99606 "LT SO Eval ErrorType"
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
    local procedure TryEval(var V: ErrorType; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ErrorType;
        Ok: Boolean;
    begin
        V := ErrorType::Internal;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ErrorType;
        Passed: Boolean;
    begin
        V := ErrorType::Internal;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ErrorType;
        Ok: Boolean;
    begin
        V := ErrorType::Internal;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Client', 'Client');
        Obs(Observer, 'name Internal', 'Internal');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'client');
        Obs(Observer, 'upper', 'CLIENT');
        Obs(Observer, 'mixedcase', 'cLIENT');
        Obs(Observer, 'leading_blank', ' Client');
        Obs(Observer, 'trailing_blank', 'Client ');
        Obs(Observer, 'both_blanks', '  Client  ');
        Obs(Observer, 'prefix', 'Cli');
        Obs(Observer, 'extra_char', 'Clientx');
        Obs(Observer, 'two_names', 'Client,Internal');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Client' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Client');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Client');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '2');
        Err(Observer, 'far_past', '22');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Client' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Client', 9);
        ObsFormat(Observer, 'f9 last', 'Internal', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '2', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Client', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99607 "LT SO Eval DefaultLayout"
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
    local procedure TryEval(var V: DefaultLayout; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DefaultLayout;
        Ok: Boolean;
    begin
        V := DefaultLayout::Word;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DefaultLayout;
        Passed: Boolean;
    begin
        V := DefaultLayout::Word;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DefaultLayout;
        Ok: Boolean;
    begin
        V := DefaultLayout::Word;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name RDLC', 'RDLC');
        Obs(Observer, 'name Word', 'Word');
        Obs(Observer, 'name Excel', 'Excel');
        Obs(Observer, 'name Custom', 'Custom');
        Obs(Observer, 'name None', 'None');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'rdlc');
        Obs(Observer, 'upper', 'RDLC');
        Obs(Observer, 'mixedcase', 'rDLC');
        Obs(Observer, 'leading_blank', ' RDLC');
        Obs(Observer, 'trailing_blank', 'RDLC ');
        Obs(Observer, 'both_blanks', '  RDLC  ');
        Obs(Observer, 'prefix', 'RDL');
        Obs(Observer, 'extra_char', 'RDLCx');
        Obs(Observer, 'two_names', 'RDLC,None');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'RDLC' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'RDLC');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'RDLC');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '5');
        Err(Observer, 'far_past', '25');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'RDLC' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'RDLC', 9);
        ObsFormat(Observer, 'f9 last', 'None', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '5', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'RDLC', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99608 "LT SO Eval TestPermissions"
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
    local procedure TryEval(var V: TestPermissions; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TestPermissions;
        Ok: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: TestPermissions;
        Passed: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: TestPermissions;
        Ok: Boolean;
    begin
        V := TestPermissions::InheritFromTestCodeunit;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Disabled', 'Disabled');
        Obs(Observer, 'name Restrictive', 'Restrictive');
        Obs(Observer, 'name NonRestrictive', 'NonRestrictive');
        Obs(Observer, 'name InheritFromTestCodeunit', 'InheritFromTestCodeunit');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'disabled');
        Obs(Observer, 'upper', 'DISABLED');
        Obs(Observer, 'mixedcase', 'dISABLED');
        Obs(Observer, 'leading_blank', ' Disabled');
        Obs(Observer, 'trailing_blank', 'Disabled ');
        Obs(Observer, 'both_blanks', '  Disabled  ');
        Obs(Observer, 'prefix', 'Dis');
        Obs(Observer, 'extra_char', 'Disabledx');
        Obs(Observer, 'two_names', 'Disabled,InheritFromTestCodeunit');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Disabled' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Disabled');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Disabled');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '4');
        Err(Observer, 'far_past', '24');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Disabled' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Disabled', 9);
        ObsFormat(Observer, 'f9 last', 'InheritFromTestCodeunit', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '4', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Disabled', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99609 "LT SO Eval DataScope"
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
    local procedure TryEval(var V: DataScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataScope;
        Ok: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataScope;
        Passed: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DataScope;
        Ok: Boolean;
    begin
        V := DataScope::CompanyAndUser;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Module', 'Module');
        Obs(Observer, 'name Company', 'Company');
        Obs(Observer, 'name User', 'User');
        Obs(Observer, 'name CompanyAndUser', 'CompanyAndUser');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'module');
        Obs(Observer, 'upper', 'MODULE');
        Obs(Observer, 'mixedcase', 'mODULE');
        Obs(Observer, 'leading_blank', ' Module');
        Obs(Observer, 'trailing_blank', 'Module ');
        Obs(Observer, 'both_blanks', '  Module  ');
        Obs(Observer, 'prefix', 'Mod');
        Obs(Observer, 'extra_char', 'Modulex');
        Obs(Observer, 'two_names', 'Module,CompanyAndUser');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Module' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Module');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Module');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '4');
        Err(Observer, 'far_past', '24');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Module' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Module', 9);
        ObsFormat(Observer, 'f9 last', 'CompanyAndUser', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '4', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Module', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99610 "LT SO Eval ExecutionContext"
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
    local procedure TryEval(var V: ExecutionContext; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ExecutionContext;
        Ok: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: ExecutionContext;
        Passed: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: ExecutionContext;
        Ok: Boolean;
    begin
        V := ExecutionContext::Upgrade;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Normal', 'Normal');
        Obs(Observer, 'name Install', 'Install');
        Obs(Observer, 'name Upgrade', 'Upgrade');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'normal');
        Obs(Observer, 'upper', 'NORMAL');
        Obs(Observer, 'mixedcase', 'nORMAL');
        Obs(Observer, 'leading_blank', ' Normal');
        Obs(Observer, 'trailing_blank', 'Normal ');
        Obs(Observer, 'both_blanks', '  Normal  ');
        Obs(Observer, 'prefix', 'Nor');
        Obs(Observer, 'extra_char', 'Normalx');
        Obs(Observer, 'two_names', 'Normal,Upgrade');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Normal' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Normal');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Normal');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '3');
        Err(Observer, 'far_past', '23');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Normal' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Normal', 9);
        ObsFormat(Observer, 'f9 last', 'Upgrade', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '3', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Normal', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99611 "LT SO Eval NotificationScope"
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
    local procedure TryEval(var V: NotificationScope; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: NotificationScope;
        Ok: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: NotificationScope;
        Passed: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: NotificationScope;
        Ok: Boolean;
    begin
        V := NotificationScope::GlobalScope;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name LocalScope', 'LocalScope');
        Obs(Observer, 'name GlobalScope', 'GlobalScope');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'localscope');
        Obs(Observer, 'upper', 'LOCALSCOPE');
        Obs(Observer, 'mixedcase', 'lOCALSCOPE');
        Obs(Observer, 'leading_blank', ' LocalScope');
        Obs(Observer, 'trailing_blank', 'LocalScope ');
        Obs(Observer, 'both_blanks', '  LocalScope  ');
        Obs(Observer, 'prefix', 'Loc');
        Obs(Observer, 'extra_char', 'LocalScopex');
        Obs(Observer, 'two_names', 'LocalScope,GlobalScope');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'LocalScope' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'LocalScope');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'LocalScope');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '2');
        Err(Observer, 'far_past', '22');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'LocalScope' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'LocalScope', 9);
        ObsFormat(Observer, 'f9 last', 'GlobalScope', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '2', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'LocalScope', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99612 "LT SO Eval WebServiceActionResultCode"
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
    local procedure TryEval(var V: WebServiceActionResultCode; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: WebServiceActionResultCode;
        Ok: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: WebServiceActionResultCode;
        Passed: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: WebServiceActionResultCode;
        Ok: Boolean;
    begin
        V := WebServiceActionResultCode::Deleted;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name None', 'None');
        Obs(Observer, 'name Get', 'Get');
        Obs(Observer, 'name Created', 'Created');
        Obs(Observer, 'name Updated', 'Updated');
        Obs(Observer, 'name Deleted', 'Deleted');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'none');
        Obs(Observer, 'upper', 'NONE');
        Obs(Observer, 'mixedcase', 'nONE');
        Obs(Observer, 'leading_blank', ' None');
        Obs(Observer, 'trailing_blank', 'None ');
        Obs(Observer, 'both_blanks', '  None  ');
        Obs(Observer, 'prefix', 'Non');
        Obs(Observer, 'extra_char', 'Nonex');
        Obs(Observer, 'two_names', 'None,Deleted');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Obs(Observer, 'num 7', '7');
        Obs(Observer, 'num 8', '8');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'None' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'None');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'None');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '5');
        Err(Observer, 'far_past', '25');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'None' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'None', 9);
        ObsFormat(Observer, 'f9 last', 'Deleted', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '5', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'None', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

codeunit 99613 "LT SO Eval FieldClass"
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
    local procedure TryEval(var V: FieldClass; Txt: Text)
    begin
        Evaluate(V, Txt);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: FieldClass;
        Ok: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: FieldClass;
        Passed: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: FieldClass;
        Ok: Boolean;
    begin
        V := FieldClass::FlowFilter;
        Ok := Evaluate(V, Txt, Number);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    [Test]
    procedure Names()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'name Normal', 'Normal');
        Obs(Observer, 'name FlowField', 'FlowField');
        Obs(Observer, 'name FlowFilter', 'FlowFilter');
        Observer.Finish();
    end;

    [Test]
    procedure NameForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'lower', 'normal');
        Obs(Observer, 'upper', 'NORMAL');
        Obs(Observer, 'mixedcase', 'nORMAL');
        Obs(Observer, 'leading_blank', ' Normal');
        Obs(Observer, 'trailing_blank', 'Normal ');
        Obs(Observer, 'both_blanks', '  Normal  ');
        Obs(Observer, 'prefix', 'Nor');
        Obs(Observer, 'extra_char', 'Normalx');
        Obs(Observer, 'two_names', 'Normal,FlowFilter');
        Observer.Finish();
    end;

    [Test]
    procedure Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'num 0', '0');
        Obs(Observer, 'num 1', '1');
        Obs(Observer, 'num 2', '2');
        Obs(Observer, 'num 3', '3');
        Obs(Observer, 'num 4', '4');
        Obs(Observer, 'num 5', '5');
        Obs(Observer, 'num 6', '6');
        Observer.Finish();
    end;

    [Test]
    procedure NumberForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'plus_1', '+1');
        Obs(Observer, 'minus_1', '-1');
        Obs(Observer, 'blank_1', ' 1 ');
        Obs(Observer, 'zero_1', '01');
        Obs(Observer, 'decimal', '1.0');
        Obs(Observer, 'comma', '1,0');
        Obs(Observer, 'hundred', '100');
        Obs(Observer, 'int_max', '2147483647');
        Obs(Observer, 'int_over', '2147483648');
        Obs(Observer, 'big', '99999999999');
        Obs(Observer, 'hex', '0x1');
        Obs(Observer, 'exp', '1e0');
        Observer.Finish();
    end;

    [Test]
    procedure BlankAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obs(Observer, 'empty', '');
        Obs(Observer, 'blank', ' ');
        Obs(Observer, 'blanks', '   ');
        Obs(Observer, 'garbage', 'zzz');
        Obs(Observer, 'dash', '-');
        Obs(Observer, 'dot', '.');
        Obs(Observer, 'question', '?');
        Obs(Observer, 'tab only', Tab());
        Obs(Observer, 'name_tab', 'Normal' + Tab());
        Obs(Observer, 'tab_name', Tab() + 'Normal');
        Obs(Observer, 'number_tab', '1' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure StatementErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'good_name', 'Normal');
        Err(Observer, 'good_number', '0');
        Err(Observer, 'garbage', 'zzz');
        Err(Observer, 'empty', '');
        Err(Observer, 'blank', ' ');
        Err(Observer, 'past_last', '3');
        Err(Observer, 'far_past', '23');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Err(Observer, 'name_tab', 'Normal' + Tab());
        Observer.Finish();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'Normal', 9);
        ObsFormat(Observer, 'f9 last', 'FlowFilter', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '3', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'Normal', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Finish();
    end;
}

