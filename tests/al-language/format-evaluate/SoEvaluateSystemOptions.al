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
// Observed on the corpus CI service tiers (BC 27.5, 28.5, 29.0); every literal asserted below is what they produced, with version guards where they differ.
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
        Observer.Expect('name TableData', 'Yes/TableData/0');
        Observer.Expect('name Table', 'Yes/Table/1');
        Observer.Expect('name Report', 'Yes/Report/3');
        Observer.Expect('name Codeunit', 'Yes/Codeunit/5');
        Observer.Expect('name XmlPort', 'Yes/XmlPort/6');
        Observer.Expect('name MenuSuite', 'Yes/MenuSuite/7');
        Observer.Expect('name Page', 'Yes/Page/8');
        Observer.Expect('name Query', 'Yes/Query/9');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/TableData/0');
        Observer.Expect('upper', 'Yes/TableData/0');
        Observer.Expect('mixedcase', 'Yes/TableData/0');
        Observer.Expect('leading_blank', 'Yes/TableData/0');
        Observer.Expect('trailing_blank', 'Yes/TableData/0');
        Observer.Expect('both_blanks', 'Yes/TableData/0');
        Observer.Expect('prefix', 'Yes/TableData/0');
        Observer.Expect('extra_char', 'No/Page/8');
        Observer.Expect('two_names', 'No/Page/8');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/TableData/0');
        Observer.Expect('num 1', 'Yes/Table/1');
        Observer.Expect('num 2', 'Yes/Form/2');
        Observer.Expect('num 3', 'Yes/Report/3');
        Observer.Expect('num 4', 'No/Page/8');
        Observer.Expect('num 5', 'Yes/Codeunit/5');
        Observer.Expect('num 6', 'Yes/XmlPort/6');
        Observer.Expect('num 7', 'Yes/MenuSuite/7');
        Observer.Expect('num 8', 'Yes/Page/8');
        Observer.Expect('num 9', 'Yes/Query/9');
        Observer.Expect('num 10', 'Yes/Enum/10');
        Observer.Expect('num 11', 'No/Page/8');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Table/1');
        Observer.Expect('minus_1', 'No/Page/8');
        Observer.Expect('blank_1', 'Yes/Table/1');
        Observer.Expect('zero_1', 'Yes/Table/1');
        Observer.Expect('decimal', 'No/Page/8');
        Observer.Expect('comma', 'No/Page/8');
        Observer.Expect('hundred', 'No/Page/8');
        Observer.Expect('int_max', 'No/Page/8');
        Observer.Expect('int_over', 'No/Page/8');
        Observer.Expect('big', 'No/Page/8');
        Observer.Expect('hex', 'No/Page/8');
        Observer.Expect('exp', 'No/Page/8');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/TableData/0');
        Observer.Expect('blank', 'Yes/TableData/0');
        Observer.Expect('blanks', 'Yes/TableData/0');
        Observer.Expect('garbage', 'No/Page/8');
        Observer.Expect('dash', 'No/Page/8');
        Observer.Expect('dot', 'No/Page/8');
        Observer.Expect('question', 'No/Page/8');
        Observer.Expect('tab only', 'Yes/TableData/0');
        Observer.Expect('name_tab', 'Yes/TableData/0');
        Observer.Expect('tab_name', 'Yes/TableData/0');
        Observer.Expect('number_tab', 'Yes/Table/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/TableData');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/TableData');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Page');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/TableData');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/TableData');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'Yes/Page');
        Observer.Expect('past_last|text', '');
        Observer.Expect('past_last|code', '');
        Observer.Expect('far_past', 'No/Page');
        Observer.Expect('far_past|text', '''28'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Page');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Page');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Page');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Page');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: TableData, Table, Form, Report, Codeunit, XmlPort, MenuSuite, Page, Query, Enum');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/TableData');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/TableData/0');
        Observer.Expect('f9 last', 'Yes/Query/9');
        Observer.Expect('f9 0', 'Yes/TableData/0');
        Observer.Expect('f9 past', 'Yes/Page/8');
        Observer.Expect('f9 garbage', 'No/Page/8');
        Observer.Expect('f9 empty', 'Yes/TableData/0');
        Observer.Expect('f0 first', 'Yes/TableData/0');
        Observer.Expect('f0 1', 'Yes/Table/1');
        Observer.Expect('f2 1', 'Yes/Table/1');
        Observer.Expect('f2 garbage', 'No/Page/8');
        Observer.Verify();
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
        Observer.Expect('name Critical', 'Yes/Critical/1');
        Observer.Expect('name Error', 'Yes/Error/2');
        Observer.Expect('name Warning', 'Yes/Warning/3');
        Observer.Expect('name Normal', 'Yes/Normal/4');
        Observer.Expect('name Verbose', 'Yes/Verbose/5');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Critical/1');
        Observer.Expect('upper', 'Yes/Critical/1');
        Observer.Expect('mixedcase', 'Yes/Critical/1');
        Observer.Expect('leading_blank', 'Yes/Critical/1');
        Observer.Expect('trailing_blank', 'Yes/Critical/1');
        Observer.Expect('both_blanks', 'Yes/Critical/1');
        Observer.Expect('prefix', 'Yes/Critical/1');
        Observer.Expect('extra_char', 'No/Verbose/5');
        Observer.Expect('two_names', 'No/Verbose/5');
        Observer.Verify();
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
        Observer.Expect('num 0', 'No/Verbose/5');
        Observer.Expect('num 1', 'Yes/Critical/1');
        Observer.Expect('num 2', 'Yes/Error/2');
        Observer.Expect('num 3', 'Yes/Warning/3');
        Observer.Expect('num 4', 'Yes/Normal/4');
        Observer.Expect('num 5', 'Yes/Verbose/5');
        Observer.Expect('num 6', 'No/Verbose/5');
        Observer.Expect('num 7', 'No/Verbose/5');
        Observer.Expect('num 8', 'No/Verbose/5');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Critical/1');
        Observer.Expect('minus_1', 'No/Verbose/5');
        Observer.Expect('blank_1', 'Yes/Critical/1');
        Observer.Expect('zero_1', 'Yes/Critical/1');
        Observer.Expect('decimal', 'No/Verbose/5');
        Observer.Expect('comma', 'No/Verbose/5');
        Observer.Expect('hundred', 'No/Verbose/5');
        Observer.Expect('int_max', 'No/Verbose/5');
        Observer.Expect('int_over', 'No/Verbose/5');
        Observer.Expect('big', 'No/Verbose/5');
        Observer.Expect('hex', 'No/Verbose/5');
        Observer.Expect('exp', 'No/Verbose/5');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/Critical/1');
        Observer.Expect('blank', 'Yes/Critical/1');
        Observer.Expect('blanks', 'Yes/Critical/1');
        Observer.Expect('garbage', 'No/Verbose/5');
        Observer.Expect('dash', 'No/Verbose/5');
        Observer.Expect('dot', 'No/Verbose/5');
        Observer.Expect('question', 'No/Verbose/5');
        Observer.Expect('tab only', 'Yes/Critical/1');
        Observer.Expect('name_tab', 'Yes/Critical/1');
        Observer.Expect('tab_name', 'Yes/Critical/1');
        Observer.Expect('number_tab', 'Yes/Critical/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Critical');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'No/Verbose');
        Observer.Expect('good_number|text', '''0'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('good_number|code', 'InvalidOptionString');
        Observer.Expect('garbage', 'No/Verbose');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/Critical');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/Critical');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'Yes/Verbose');
        Observer.Expect('past_last|text', '');
        Observer.Expect('past_last|code', '');
        Observer.Expect('far_past', 'No/Verbose');
        Observer.Expect('far_past|text', '''25'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Verbose');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Verbose');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Verbose');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Verbose');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Critical, Error, Warning, Normal, Verbose');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Critical');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Critical/1');
        Observer.Expect('f9 last', 'Yes/Verbose/5');
        Observer.Expect('f9 0', 'No/Verbose/5');
        Observer.Expect('f9 past', 'Yes/Verbose/5');
        Observer.Expect('f9 garbage', 'No/Verbose/5');
        Observer.Expect('f9 empty', 'Yes/Critical/1');
        Observer.Expect('f0 first', 'Yes/Critical/1');
        Observer.Expect('f0 1', 'Yes/Critical/1');
        Observer.Expect('f2 1', 'Yes/Critical/1');
        Observer.Expect('f2 garbage', 'No/Verbose/5');
        Observer.Verify();
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
        Observer.Expect('name ExtensionPublisher', 'Yes/ExtensionPublisher/1');
        Observer.Expect('name All', 'Yes/All/2');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/ExtensionPublisher/1');
        Observer.Expect('upper', 'Yes/ExtensionPublisher/1');
        Observer.Expect('mixedcase', 'Yes/ExtensionPublisher/1');
        Observer.Expect('leading_blank', 'Yes/ExtensionPublisher/1');
        Observer.Expect('trailing_blank', 'Yes/ExtensionPublisher/1');
        Observer.Expect('both_blanks', 'Yes/ExtensionPublisher/1');
        Observer.Expect('prefix', 'Yes/ExtensionPublisher/1');
        Observer.Expect('extra_char', 'No/All/2');
        Observer.Expect('two_names', 'No/All/2');
        Observer.Verify();
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
        Observer.Expect('num 0', 'No/All/2');
        Observer.Expect('num 1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('num 2', 'Yes/All/2');
        Observer.Expect('num 3', 'No/All/2');
        Observer.Expect('num 4', 'No/All/2');
        Observer.Expect('num 5', 'No/All/2');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('minus_1', 'No/All/2');
        Observer.Expect('blank_1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('zero_1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('decimal', 'No/All/2');
        Observer.Expect('comma', 'No/All/2');
        Observer.Expect('hundred', 'No/All/2');
        Observer.Expect('int_max', 'No/All/2');
        Observer.Expect('int_over', 'No/All/2');
        Observer.Expect('big', 'No/All/2');
        Observer.Expect('hex', 'No/All/2');
        Observer.Expect('exp', 'No/All/2');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/ExtensionPublisher/1');
        Observer.Expect('blank', 'Yes/ExtensionPublisher/1');
        Observer.Expect('blanks', 'Yes/ExtensionPublisher/1');
        Observer.Expect('garbage', 'No/All/2');
        Observer.Expect('dash', 'No/All/2');
        Observer.Expect('dot', 'No/All/2');
        Observer.Expect('question', 'No/All/2');
        Observer.Expect('tab only', 'Yes/ExtensionPublisher/1');
        Observer.Expect('name_tab', 'Yes/ExtensionPublisher/1');
        Observer.Expect('tab_name', 'Yes/ExtensionPublisher/1');
        Observer.Expect('number_tab', 'Yes/ExtensionPublisher/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/ExtensionPublisher');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'No/All');
        Observer.Expect('good_number|text', '''0'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('good_number|code', 'InvalidOptionString');
        Observer.Expect('garbage', 'No/All');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/ExtensionPublisher');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/ExtensionPublisher');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'Yes/All');
        Observer.Expect('past_last|text', '');
        Observer.Expect('past_last|code', '');
        Observer.Expect('far_past', 'No/All');
        Observer.Expect('far_past|text', '''22'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/All');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/All');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/All');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/All');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: ExtensionPublisher, All');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/ExtensionPublisher');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/ExtensionPublisher/1');
        Observer.Expect('f9 last', 'Yes/All/2');
        Observer.Expect('f9 0', 'No/All/2');
        Observer.Expect('f9 past', 'Yes/All/2');
        Observer.Expect('f9 garbage', 'No/All/2');
        Observer.Expect('f9 empty', 'Yes/ExtensionPublisher/1');
        Observer.Expect('f0 first', 'Yes/ExtensionPublisher/1');
        Observer.Expect('f0 1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('f2 1', 'Yes/ExtensionPublisher/1');
        Observer.Expect('f2 garbage', 'No/All/2');
        Observer.Verify();
    end;
}

codeunit 99603 "LT SO Eval DataClassifica"
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
        V := DataClassification::SystemMetadata;
        Ok := Evaluate(V, Txt);
        Observer.Observe(Nm, Format(Ok) + '/' + Format(V) + '/' + Format(V, 0, 2));
    end;

    local procedure Err(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text)
    var
        V: DataClassification;
        Passed: Boolean;
    begin
        V := DataClassification::SystemMetadata;
        Passed := TryEval(V, Txt);
        Observer.Observe(Nm, Format(Passed) + '/' + Format(V));
        Observer.ObserveError(Nm);
    end;

    local procedure ObsFormat(var Observer: Codeunit "Probe Observer"; Nm: Text; Txt: Text; Number: Integer)
    var
        V: DataClassification;
        Ok: Boolean;
    begin
        V := DataClassification::SystemMetadata;
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
        Observer.Expect('name CustomerContent', 'Yes/CustomerContent/0');
        Observer.Expect('name ToBeClassified', 'Yes/ToBeClassified/1');
        Observer.Expect('name EndUserIdentifiableInformation', 'Yes/EndUserIdentifiableInformation/2');
        Observer.Expect('name AccountData', 'Yes/AccountData/3');
        Observer.Expect('name EndUserPseudonymousIdentifiers', 'Yes/EndUserPseudonymousIdentifiers/4');
        Observer.Expect('name OrganizationIdentifiableInformation', 'Yes/OrganizationIdentifiableInformation/5');
        Observer.Expect('name SystemMetadata', 'Yes/SystemMetadata/6');
        Observer.Verify();
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
        Obs(Observer, 'two_names', 'CustomerContent,SystemMetadata');
        Observer.Expect('lower', 'Yes/CustomerContent/0');
        Observer.Expect('upper', 'Yes/CustomerContent/0');
        Observer.Expect('mixedcase', 'Yes/CustomerContent/0');
        Observer.Expect('leading_blank', 'Yes/CustomerContent/0');
        Observer.Expect('trailing_blank', 'Yes/CustomerContent/0');
        Observer.Expect('both_blanks', 'Yes/CustomerContent/0');
        Observer.Expect('prefix', 'Yes/CustomerContent/0');
        Observer.Expect('extra_char', 'No/SystemMetadata/6');
        Observer.Expect('two_names', 'No/SystemMetadata/6');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/CustomerContent/0');
        Observer.Expect('num 1', 'Yes/ToBeClassified/1');
        Observer.Expect('num 2', 'Yes/EndUserIdentifiableInformation/2');
        Observer.Expect('num 3', 'Yes/AccountData/3');
        Observer.Expect('num 4', 'Yes/EndUserPseudonymousIdentifiers/4');
        Observer.Expect('num 5', 'Yes/OrganizationIdentifiableInformation/5');
        Observer.Expect('num 6', 'Yes/SystemMetadata/6');
        Observer.Expect('num 7', 'No/SystemMetadata/6');
        Observer.Expect('num 8', 'No/SystemMetadata/6');
        Observer.Expect('num 9', 'No/SystemMetadata/6');
        Observer.Expect('num 10', 'No/SystemMetadata/6');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/ToBeClassified/1');
        Observer.Expect('minus_1', 'No/SystemMetadata/6');
        Observer.Expect('blank_1', 'Yes/ToBeClassified/1');
        Observer.Expect('zero_1', 'Yes/ToBeClassified/1');
        Observer.Expect('decimal', 'No/SystemMetadata/6');
        Observer.Expect('comma', 'No/SystemMetadata/6');
        Observer.Expect('hundred', 'No/SystemMetadata/6');
        Observer.Expect('int_max', 'No/SystemMetadata/6');
        Observer.Expect('int_over', 'No/SystemMetadata/6');
        Observer.Expect('big', 'No/SystemMetadata/6');
        Observer.Expect('hex', 'No/SystemMetadata/6');
        Observer.Expect('exp', 'No/SystemMetadata/6');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/CustomerContent/0');
        Observer.Expect('blank', 'Yes/CustomerContent/0');
        Observer.Expect('blanks', 'Yes/CustomerContent/0');
        Observer.Expect('garbage', 'No/SystemMetadata/6');
        Observer.Expect('dash', 'No/SystemMetadata/6');
        Observer.Expect('dot', 'No/SystemMetadata/6');
        Observer.Expect('question', 'No/SystemMetadata/6');
        Observer.Expect('tab only', 'Yes/CustomerContent/0');
        Observer.Expect('name_tab', 'Yes/CustomerContent/0');
        Observer.Expect('tab_name', 'Yes/CustomerContent/0');
        Observer.Expect('number_tab', 'Yes/ToBeClassified/1');
        Observer.Verify();
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
        Err(Observer, 'past_last', '7');
        Err(Observer, 'far_past', '27');
        Err(Observer, 'negative', '-1');
        Err(Observer, 'long_garbage', 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs');
        Err(Observer, 'quote', 'it''s');
        Observer.Expect('good_name', 'Yes/CustomerContent');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/CustomerContent');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/SystemMetadata');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/CustomerContent');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/CustomerContent');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/SystemMetadata');
        Observer.Expect('past_last|text', '''7'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/SystemMetadata');
        Observer.Expect('far_past|text', '''27'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/SystemMetadata');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/SystemMetadata');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/SystemMetadata');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure StatementErrorTabInside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'tab_garbage', 'a' + Tab() + 'b');
        Observer.Expect('tab_garbage', 'No/SystemMetadata');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: CustomerContent, ToBeClassified, EndUserIdentifiableInformation, AccountData, EndUserPseudonymousIdentifiers, OrganizationIdentifiableInformation, SystemMetadata');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure StatementErrorNameThenTab()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Err(Observer, 'name_tab', 'CustomerContent' + Tab());
        Observer.Expect('name_tab', 'Yes/CustomerContent');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObsFormat(Observer, 'f9 first', 'CustomerContent', 9);
        ObsFormat(Observer, 'f9 last', 'SystemMetadata', 9);
        ObsFormat(Observer, 'f9 0', '0', 9);
        ObsFormat(Observer, 'f9 past', '7', 9);
        ObsFormat(Observer, 'f9 garbage', 'zzz', 9);
        ObsFormat(Observer, 'f9 empty', '', 9);
        ObsFormat(Observer, 'f0 first', 'CustomerContent', 0);
        ObsFormat(Observer, 'f0 1', '1', 0);
        ObsFormat(Observer, 'f2 1', '1', 2);
        ObsFormat(Observer, 'f2 garbage', 'zzz', 2);
        Observer.Expect('f9 first', 'Yes/CustomerContent/0');
        Observer.Expect('f9 last', 'Yes/SystemMetadata/6');
        Observer.Expect('f9 0', 'Yes/CustomerContent/0');
        Observer.Expect('f9 past', 'No/SystemMetadata/6');
        Observer.Expect('f9 garbage', 'No/SystemMetadata/6');
        Observer.Expect('f9 empty', 'Yes/CustomerContent/0');
        Observer.Expect('f0 first', 'Yes/CustomerContent/0');
        Observer.Expect('f0 1', 'Yes/ToBeClassified/1');
        Observer.Expect('f2 1', 'Yes/ToBeClassified/1');
        Observer.Expect('f2 garbage', 'No/SystemMetadata/6');
        Observer.Verify();
    end;
}

codeunit 99604 "LT SO Eval TransactionTyp"
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
        Observer.Expect('name UpdateNoLocks', 'Yes/UpdateNoLocks/0');
        Observer.Expect('name Update', 'Yes/Update/1');
        Observer.Expect('name Snapshot', 'Yes/Snapshot/2');
        Observer.Expect('name Browse', 'Yes/Browse/3');
        Observer.Expect('name Report', 'Yes/Report/4');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/UpdateNoLocks/0');
        Observer.Expect('upper', 'Yes/UpdateNoLocks/0');
        Observer.Expect('mixedcase', 'Yes/UpdateNoLocks/0');
        Observer.Expect('leading_blank', 'Yes/UpdateNoLocks/0');
        Observer.Expect('trailing_blank', 'Yes/UpdateNoLocks/0');
        Observer.Expect('both_blanks', 'Yes/UpdateNoLocks/0');
        Observer.Expect('prefix', 'Yes/UpdateNoLocks/0');
        Observer.Expect('extra_char', 'No/Report/4');
        Observer.Expect('two_names', 'No/Report/4');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/UpdateNoLocks/0');
        Observer.Expect('num 1', 'Yes/Update/1');
        Observer.Expect('num 2', 'Yes/Snapshot/2');
        Observer.Expect('num 3', 'Yes/Browse/3');
        Observer.Expect('num 4', 'Yes/Report/4');
        Observer.Expect('num 5', 'No/Report/4');
        Observer.Expect('num 6', 'No/Report/4');
        Observer.Expect('num 7', 'No/Report/4');
        Observer.Expect('num 8', 'No/Report/4');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Update/1');
        Observer.Expect('minus_1', 'No/Report/4');
        Observer.Expect('blank_1', 'Yes/Update/1');
        Observer.Expect('zero_1', 'Yes/Update/1');
        Observer.Expect('decimal', 'No/Report/4');
        Observer.Expect('comma', 'No/Report/4');
        Observer.Expect('hundred', 'No/Report/4');
        Observer.Expect('int_max', 'No/Report/4');
        Observer.Expect('int_over', 'No/Report/4');
        Observer.Expect('big', 'No/Report/4');
        Observer.Expect('hex', 'No/Report/4');
        Observer.Expect('exp', 'No/Report/4');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/UpdateNoLocks/0');
        Observer.Expect('blank', 'Yes/UpdateNoLocks/0');
        Observer.Expect('blanks', 'Yes/UpdateNoLocks/0');
        Observer.Expect('garbage', 'No/Report/4');
        Observer.Expect('dash', 'No/Report/4');
        Observer.Expect('dot', 'No/Report/4');
        Observer.Expect('question', 'No/Report/4');
        Observer.Expect('tab only', 'Yes/UpdateNoLocks/0');
        Observer.Expect('name_tab', 'Yes/UpdateNoLocks/0');
        Observer.Expect('tab_name', 'Yes/UpdateNoLocks/0');
        Observer.Expect('number_tab', 'Yes/Update/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/UpdateNoLocks');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/UpdateNoLocks');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Report');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/UpdateNoLocks');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/UpdateNoLocks');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/Report');
        Observer.Expect('past_last|text', '''5'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/Report');
        Observer.Expect('far_past|text', '''25'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Report');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Report');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Report');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Report');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: UpdateNoLocks, Update, Snapshot, Browse, Report');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/UpdateNoLocks');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/UpdateNoLocks/0');
        Observer.Expect('f9 last', 'Yes/Report/4');
        Observer.Expect('f9 0', 'Yes/UpdateNoLocks/0');
        Observer.Expect('f9 past', 'No/Report/4');
        Observer.Expect('f9 garbage', 'No/Report/4');
        Observer.Expect('f9 empty', 'Yes/UpdateNoLocks/0');
        Observer.Expect('f0 first', 'Yes/UpdateNoLocks/0');
        Observer.Expect('f0 1', 'Yes/Update/1');
        Observer.Expect('f2 1', 'Yes/Update/1');
        Observer.Expect('f2 garbage', 'No/Report/4');
        Observer.Verify();
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
        Observer.Expect('name Excel', 'Yes/Excel/1');
        Observer.Expect('name Pdf', 'Yes/Pdf/2');
        Observer.Expect('name Word', 'Yes/Word/3');
        Observer.Expect('name Xml', 'Yes/Xml/4');
        Observer.Expect('name Html', 'Yes/Html/5');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Excel/1');
        Observer.Expect('upper', 'Yes/Excel/1');
        Observer.Expect('mixedcase', 'Yes/Excel/1');
        Observer.Expect('leading_blank', 'Yes/Excel/1');
        Observer.Expect('trailing_blank', 'Yes/Excel/1');
        Observer.Expect('both_blanks', 'Yes/Excel/1');
        Observer.Expect('prefix', 'Yes/Excel/1');
        Observer.Expect('extra_char', 'No/Html/5');
        Observer.Expect('two_names', 'No/Html/5');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/None/0');
        Observer.Expect('num 1', 'Yes/Excel/1');
        Observer.Expect('num 2', 'Yes/Pdf/2');
        Observer.Expect('num 3', 'Yes/Word/3');
        Observer.Expect('num 4', 'Yes/Xml/4');
        Observer.Expect('num 5', 'Yes/Html/5');
        Observer.Expect('num 6', 'Yes/Jpeg/6');
        Observer.Expect('num 7', 'Yes/Xps/7');
        Observer.Expect('num 8', 'Yes/Meta/8');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Excel/1');
        Observer.Expect('minus_1', 'No/Html/5');
        Observer.Expect('blank_1', 'Yes/Excel/1');
        Observer.Expect('zero_1', 'Yes/Excel/1');
        Observer.Expect('decimal', 'No/Html/5');
        Observer.Expect('comma', 'No/Html/5');
        Observer.Expect('hundred', 'No/Html/5');
        Observer.Expect('int_max', 'No/Html/5');
        Observer.Expect('int_over', 'No/Html/5');
        Observer.Expect('big', 'No/Html/5');
        Observer.Expect('hex', 'No/Html/5');
        Observer.Expect('exp', 'No/Html/5');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/None/0');
        Observer.Expect('blank', 'Yes/None/0');
        Observer.Expect('blanks', 'Yes/None/0');
        Observer.Expect('garbage', 'No/Html/5');
        Observer.Expect('dash', 'No/Html/5');
        Observer.Expect('dot', 'No/Html/5');
        Observer.Expect('question', 'No/Html/5');
        Observer.Expect('tab only', 'Yes/None/0');
        Observer.Expect('name_tab', 'Yes/Excel/1');
        Observer.Expect('tab_name', 'Yes/Excel/1');
        Observer.Expect('number_tab', 'Yes/Excel/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Excel');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/None');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Html');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/None');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/None');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'Yes/Html');
        Observer.Expect('past_last|text', '');
        Observer.Expect('past_last|code', '');
        Observer.Expect('far_past', 'No/Html');
        Observer.Expect('far_past|text', '''25'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Html');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Html');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Html');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Html');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: None, Excel, Pdf, Word, Xml, Html, Jpeg, Xps, Meta, ExcelDataset, Custom, Zip');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Excel');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Excel/1');
        Observer.Expect('f9 last', 'Yes/Html/5');
        Observer.Expect('f9 0', 'Yes/None/0');
        Observer.Expect('f9 past', 'Yes/Html/5');
        Observer.Expect('f9 garbage', 'No/Html/5');
        Observer.Expect('f9 empty', 'Yes/None/0');
        Observer.Expect('f0 first', 'Yes/Excel/1');
        Observer.Expect('f0 1', 'Yes/Excel/1');
        Observer.Expect('f2 1', 'Yes/Excel/1');
        Observer.Expect('f2 garbage', 'No/Html/5');
        Observer.Verify();
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
        Observer.Expect('name Client', 'Yes/Client/0');
        Observer.Expect('name Internal', 'Yes/Internal/1');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Client/0');
        Observer.Expect('upper', 'Yes/Client/0');
        Observer.Expect('mixedcase', 'Yes/Client/0');
        Observer.Expect('leading_blank', 'Yes/Client/0');
        Observer.Expect('trailing_blank', 'Yes/Client/0');
        Observer.Expect('both_blanks', 'Yes/Client/0');
        Observer.Expect('prefix', 'Yes/Client/0');
        Observer.Expect('extra_char', 'No/Internal/1');
        Observer.Expect('two_names', 'No/Internal/1');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/Client/0');
        Observer.Expect('num 1', 'Yes/Internal/1');
        Observer.Expect('num 2', 'No/Internal/1');
        Observer.Expect('num 3', 'No/Internal/1');
        Observer.Expect('num 4', 'No/Internal/1');
        Observer.Expect('num 5', 'No/Internal/1');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Internal/1');
        Observer.Expect('minus_1', 'No/Internal/1');
        Observer.Expect('blank_1', 'Yes/Internal/1');
        Observer.Expect('zero_1', 'Yes/Internal/1');
        Observer.Expect('decimal', 'No/Internal/1');
        Observer.Expect('comma', 'No/Internal/1');
        Observer.Expect('hundred', 'No/Internal/1');
        Observer.Expect('int_max', 'No/Internal/1');
        Observer.Expect('int_over', 'No/Internal/1');
        Observer.Expect('big', 'No/Internal/1');
        Observer.Expect('hex', 'No/Internal/1');
        Observer.Expect('exp', 'No/Internal/1');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/Client/0');
        Observer.Expect('blank', 'Yes/Client/0');
        Observer.Expect('blanks', 'Yes/Client/0');
        Observer.Expect('garbage', 'No/Internal/1');
        Observer.Expect('dash', 'No/Internal/1');
        Observer.Expect('dot', 'No/Internal/1');
        Observer.Expect('question', 'No/Internal/1');
        Observer.Expect('tab only', 'Yes/Client/0');
        Observer.Expect('name_tab', 'Yes/Client/0');
        Observer.Expect('tab_name', 'Yes/Client/0');
        Observer.Expect('number_tab', 'Yes/Internal/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Client');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/Client');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Internal');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/Client');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/Client');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/Internal');
        Observer.Expect('past_last|text', '''2'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/Internal');
        Observer.Expect('far_past|text', '''22'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Internal');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Internal');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Internal');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Internal');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Client, Internal');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Client');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Client/0');
        Observer.Expect('f9 last', 'Yes/Internal/1');
        Observer.Expect('f9 0', 'Yes/Client/0');
        Observer.Expect('f9 past', 'No/Internal/1');
        Observer.Expect('f9 garbage', 'No/Internal/1');
        Observer.Expect('f9 empty', 'Yes/Client/0');
        Observer.Expect('f0 first', 'Yes/Client/0');
        Observer.Expect('f0 1', 'Yes/Internal/1');
        Observer.Expect('f2 1', 'Yes/Internal/1');
        Observer.Expect('f2 garbage', 'No/Internal/1');
        Observer.Verify();
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
        Observer.Expect('name RDLC', 'Yes/RDLC/1');
        Observer.Expect('name Word', 'Yes/Word/2');
        Observer.Expect('name Excel', 'Yes/Excel/3');
        Observer.Expect('name Custom', 'No/Word/2');
        Observer.Expect('name None', 'Yes/None/0');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/RDLC/1');
        Observer.Expect('upper', 'Yes/RDLC/1');
        Observer.Expect('mixedcase', 'Yes/RDLC/1');
        Observer.Expect('leading_blank', 'Yes/RDLC/1');
        Observer.Expect('trailing_blank', 'Yes/RDLC/1');
        Observer.Expect('both_blanks', 'Yes/RDLC/1');
        Observer.Expect('prefix', 'Yes/RDLC/1');
        Observer.Expect('extra_char', 'No/Word/2');
        Observer.Expect('two_names', 'No/Word/2');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/None/0');
        Observer.Expect('num 1', 'Yes/RDLC/1');
        Observer.Expect('num 2', 'Yes/Word/2');
        Observer.Expect('num 3', 'Yes/Excel/3');
        Observer.Expect('num 4', 'No/Word/2');
        Observer.Expect('num 5', 'No/Word/2');
        Observer.Expect('num 6', 'No/Word/2');
        Observer.Expect('num 7', 'No/Word/2');
        Observer.Expect('num 8', 'No/Word/2');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/RDLC/1');
        Observer.Expect('minus_1', 'No/Word/2');
        Observer.Expect('blank_1', 'Yes/RDLC/1');
        Observer.Expect('zero_1', 'Yes/RDLC/1');
        Observer.Expect('decimal', 'No/Word/2');
        Observer.Expect('comma', 'No/Word/2');
        Observer.Expect('hundred', 'No/Word/2');
        Observer.Expect('int_max', 'No/Word/2');
        Observer.Expect('int_over', 'No/Word/2');
        Observer.Expect('big', 'No/Word/2');
        Observer.Expect('hex', 'No/Word/2');
        Observer.Expect('exp', 'No/Word/2');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/None/0');
        Observer.Expect('blank', 'Yes/None/0');
        Observer.Expect('blanks', 'Yes/None/0');
        Observer.Expect('garbage', 'No/Word/2');
        Observer.Expect('dash', 'No/Word/2');
        Observer.Expect('dot', 'No/Word/2');
        Observer.Expect('question', 'No/Word/2');
        Observer.Expect('tab only', 'Yes/None/0');
        Observer.Expect('name_tab', 'Yes/RDLC/1');
        Observer.Expect('tab_name', 'Yes/RDLC/1');
        Observer.Expect('number_tab', 'Yes/RDLC/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/RDLC');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/None');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Word');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/None');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/None');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/Word');
        Observer.Expect('past_last|text', '''5'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/Word');
        Observer.Expect('far_past|text', '''25'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Word');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Word');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Word');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Word');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: None, RDLC, Word, Excel');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/RDLC');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/RDLC/1');
        Observer.Expect('f9 last', 'Yes/None/0');
        Observer.Expect('f9 0', 'Yes/None/0');
        Observer.Expect('f9 past', 'No/Word/2');
        Observer.Expect('f9 garbage', 'No/Word/2');
        Observer.Expect('f9 empty', 'Yes/None/0');
        Observer.Expect('f0 first', 'Yes/RDLC/1');
        Observer.Expect('f0 1', 'Yes/RDLC/1');
        Observer.Expect('f2 1', 'Yes/RDLC/1');
        Observer.Expect('f2 garbage', 'No/Word/2');
        Observer.Verify();
    end;
}

codeunit 99608 "LT SO Eval TestPermission"
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
        Observer.Expect('name Disabled', 'Yes/Disabled/3');
        Observer.Expect('name Restrictive', 'Yes/Restrictive/1');
        Observer.Expect('name NonRestrictive', 'Yes/NonRestrictive/2');
        Observer.Expect('name InheritFromTestCodeunit', 'Yes/InheritFromTestCodeunit/0');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Disabled/3');
        Observer.Expect('upper', 'Yes/Disabled/3');
        Observer.Expect('mixedcase', 'Yes/Disabled/3');
        Observer.Expect('leading_blank', 'Yes/Disabled/3');
        Observer.Expect('trailing_blank', 'Yes/Disabled/3');
        Observer.Expect('both_blanks', 'Yes/Disabled/3');
        Observer.Expect('prefix', 'Yes/Disabled/3');
        Observer.Expect('extra_char', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('two_names', 'No/InheritFromTestCodeunit/0');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('num 1', 'Yes/Restrictive/1');
        Observer.Expect('num 2', 'Yes/NonRestrictive/2');
        Observer.Expect('num 3', 'Yes/Disabled/3');
        Observer.Expect('num 4', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('num 5', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('num 6', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('num 7', 'No/InheritFromTestCodeunit/0');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Restrictive/1');
        Observer.Expect('minus_1', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('blank_1', 'Yes/Restrictive/1');
        Observer.Expect('zero_1', 'Yes/Restrictive/1');
        Observer.Expect('decimal', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('comma', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('hundred', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('int_max', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('int_over', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('big', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('hex', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('exp', 'No/InheritFromTestCodeunit/0');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('blank', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('blanks', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('garbage', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('dash', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('dot', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('question', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('tab only', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('name_tab', 'Yes/Disabled/3');
        Observer.Expect('tab_name', 'Yes/Disabled/3');
        Observer.Expect('number_tab', 'Yes/Restrictive/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Disabled');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/InheritFromTestCodeunit');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/InheritFromTestCodeunit');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/InheritFromTestCodeunit');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/InheritFromTestCodeunit');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/InheritFromTestCodeunit');
        Observer.Expect('past_last|text', '''4'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/InheritFromTestCodeunit');
        Observer.Expect('far_past|text', '''24'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/InheritFromTestCodeunit');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/InheritFromTestCodeunit');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/InheritFromTestCodeunit');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/InheritFromTestCodeunit');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: InheritFromTestCodeunit, Restrictive, NonRestrictive, Disabled');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Disabled');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Disabled/3');
        Observer.Expect('f9 last', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('f9 0', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('f9 past', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('f9 garbage', 'No/InheritFromTestCodeunit/0');
        Observer.Expect('f9 empty', 'Yes/InheritFromTestCodeunit/0');
        Observer.Expect('f0 first', 'Yes/Disabled/3');
        Observer.Expect('f0 1', 'Yes/Restrictive/1');
        Observer.Expect('f2 1', 'Yes/Restrictive/1');
        Observer.Expect('f2 garbage', 'No/InheritFromTestCodeunit/0');
        Observer.Verify();
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
        Observer.Expect('name Module', 'Yes/Module/0');
        Observer.Expect('name Company', 'Yes/Company/1');
        Observer.Expect('name User', 'Yes/User/2');
        Observer.Expect('name CompanyAndUser', 'Yes/CompanyAndUser/3');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Module/0');
        Observer.Expect('upper', 'Yes/Module/0');
        Observer.Expect('mixedcase', 'Yes/Module/0');
        Observer.Expect('leading_blank', 'Yes/Module/0');
        Observer.Expect('trailing_blank', 'Yes/Module/0');
        Observer.Expect('both_blanks', 'Yes/Module/0');
        Observer.Expect('prefix', 'Yes/Module/0');
        Observer.Expect('extra_char', 'No/CompanyAndUser/3');
        Observer.Expect('two_names', 'No/CompanyAndUser/3');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/Module/0');
        Observer.Expect('num 1', 'Yes/Company/1');
        Observer.Expect('num 2', 'Yes/User/2');
        Observer.Expect('num 3', 'Yes/CompanyAndUser/3');
        Observer.Expect('num 4', 'No/CompanyAndUser/3');
        Observer.Expect('num 5', 'No/CompanyAndUser/3');
        Observer.Expect('num 6', 'No/CompanyAndUser/3');
        Observer.Expect('num 7', 'No/CompanyAndUser/3');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Company/1');
        Observer.Expect('minus_1', 'No/CompanyAndUser/3');
        Observer.Expect('blank_1', 'Yes/Company/1');
        Observer.Expect('zero_1', 'Yes/Company/1');
        Observer.Expect('decimal', 'No/CompanyAndUser/3');
        Observer.Expect('comma', 'No/CompanyAndUser/3');
        Observer.Expect('hundred', 'No/CompanyAndUser/3');
        Observer.Expect('int_max', 'No/CompanyAndUser/3');
        Observer.Expect('int_over', 'No/CompanyAndUser/3');
        Observer.Expect('big', 'No/CompanyAndUser/3');
        Observer.Expect('hex', 'No/CompanyAndUser/3');
        Observer.Expect('exp', 'No/CompanyAndUser/3');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/Module/0');
        Observer.Expect('blank', 'Yes/Module/0');
        Observer.Expect('blanks', 'Yes/Module/0');
        Observer.Expect('garbage', 'No/CompanyAndUser/3');
        Observer.Expect('dash', 'No/CompanyAndUser/3');
        Observer.Expect('dot', 'No/CompanyAndUser/3');
        Observer.Expect('question', 'No/CompanyAndUser/3');
        Observer.Expect('tab only', 'Yes/Module/0');
        Observer.Expect('name_tab', 'Yes/Module/0');
        Observer.Expect('tab_name', 'Yes/Module/0');
        Observer.Expect('number_tab', 'Yes/Company/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Module');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/Module');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/CompanyAndUser');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/Module');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/Module');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/CompanyAndUser');
        Observer.Expect('past_last|text', '''4'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/CompanyAndUser');
        Observer.Expect('far_past|text', '''24'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/CompanyAndUser');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/CompanyAndUser');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/CompanyAndUser');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/CompanyAndUser');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Module, Company, User, CompanyAndUser');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Module');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Module/0');
        Observer.Expect('f9 last', 'Yes/CompanyAndUser/3');
        Observer.Expect('f9 0', 'Yes/Module/0');
        Observer.Expect('f9 past', 'No/CompanyAndUser/3');
        Observer.Expect('f9 garbage', 'No/CompanyAndUser/3');
        Observer.Expect('f9 empty', 'Yes/Module/0');
        Observer.Expect('f0 first', 'Yes/Module/0');
        Observer.Expect('f0 1', 'Yes/Company/1');
        Observer.Expect('f2 1', 'Yes/Company/1');
        Observer.Expect('f2 garbage', 'No/CompanyAndUser/3');
        Observer.Verify();
    end;
}

codeunit 99610 "LT SO Eval ExecutionConte"
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
        Observer.Expect('name Normal', 'Yes/Normal/0');
        Observer.Expect('name Install', 'Yes/Install/1');
        Observer.Expect('name Upgrade', 'Yes/Upgrade/3');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Normal/0');
        Observer.Expect('upper', 'Yes/Normal/0');
        Observer.Expect('mixedcase', 'Yes/Normal/0');
        Observer.Expect('leading_blank', 'Yes/Normal/0');
        Observer.Expect('trailing_blank', 'Yes/Normal/0');
        Observer.Expect('both_blanks', 'Yes/Normal/0');
        Observer.Expect('prefix', 'Yes/Normal/0');
        Observer.Expect('extra_char', 'No/Upgrade/3');
        Observer.Expect('two_names', 'No/Upgrade/3');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/Normal/0');
        Observer.Expect('num 1', 'Yes/Install/1');
        Observer.Expect('num 2', 'Yes/Uninstall/2');
        Observer.Expect('num 3', 'Yes/Upgrade/3');
        Observer.Expect('num 4', 'No/Upgrade/3');
        Observer.Expect('num 5', 'No/Upgrade/3');
        Observer.Expect('num 6', 'No/Upgrade/3');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/Install/1');
        Observer.Expect('minus_1', 'No/Upgrade/3');
        Observer.Expect('blank_1', 'Yes/Install/1');
        Observer.Expect('zero_1', 'Yes/Install/1');
        Observer.Expect('decimal', 'No/Upgrade/3');
        Observer.Expect('comma', 'No/Upgrade/3');
        Observer.Expect('hundred', 'No/Upgrade/3');
        Observer.Expect('int_max', 'No/Upgrade/3');
        Observer.Expect('int_over', 'No/Upgrade/3');
        Observer.Expect('big', 'No/Upgrade/3');
        Observer.Expect('hex', 'No/Upgrade/3');
        Observer.Expect('exp', 'No/Upgrade/3');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/Normal/0');
        Observer.Expect('blank', 'Yes/Normal/0');
        Observer.Expect('blanks', 'Yes/Normal/0');
        Observer.Expect('garbage', 'No/Upgrade/3');
        Observer.Expect('dash', 'No/Upgrade/3');
        Observer.Expect('dot', 'No/Upgrade/3');
        Observer.Expect('question', 'No/Upgrade/3');
        Observer.Expect('tab only', 'Yes/Normal/0');
        Observer.Expect('name_tab', 'Yes/Normal/0');
        Observer.Expect('tab_name', 'Yes/Normal/0');
        Observer.Expect('number_tab', 'Yes/Install/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Normal');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/Normal');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Upgrade');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/Normal');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/Normal');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'Yes/Upgrade');
        Observer.Expect('past_last|text', '');
        Observer.Expect('past_last|code', '');
        Observer.Expect('far_past', 'No/Upgrade');
        Observer.Expect('far_past|text', '''23'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Upgrade');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Upgrade');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Upgrade');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Upgrade');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Normal, Install, Uninstall, Upgrade');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Normal');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Normal/0');
        Observer.Expect('f9 last', 'Yes/Upgrade/3');
        Observer.Expect('f9 0', 'Yes/Normal/0');
        Observer.Expect('f9 past', 'Yes/Upgrade/3');
        Observer.Expect('f9 garbage', 'No/Upgrade/3');
        Observer.Expect('f9 empty', 'Yes/Normal/0');
        Observer.Expect('f0 first', 'Yes/Normal/0');
        Observer.Expect('f0 1', 'Yes/Install/1');
        Observer.Expect('f2 1', 'Yes/Install/1');
        Observer.Expect('f2 garbage', 'No/Upgrade/3');
        Observer.Verify();
    end;
}

codeunit 99611 "LT SO Eval NotificationSc"
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
        Observer.Expect('name LocalScope', 'Yes/LocalScope/0');
        Observer.Expect('name GlobalScope', 'Yes/GlobalScope/1');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/LocalScope/0');
        Observer.Expect('upper', 'Yes/LocalScope/0');
        Observer.Expect('mixedcase', 'Yes/LocalScope/0');
        Observer.Expect('leading_blank', 'Yes/LocalScope/0');
        Observer.Expect('trailing_blank', 'Yes/LocalScope/0');
        Observer.Expect('both_blanks', 'Yes/LocalScope/0');
        Observer.Expect('prefix', 'Yes/LocalScope/0');
        Observer.Expect('extra_char', 'No/GlobalScope/1');
        Observer.Expect('two_names', 'No/GlobalScope/1');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/LocalScope/0');
        Observer.Expect('num 1', 'Yes/GlobalScope/1');
        Observer.Expect('num 2', 'No/GlobalScope/1');
        Observer.Expect('num 3', 'No/GlobalScope/1');
        Observer.Expect('num 4', 'No/GlobalScope/1');
        Observer.Expect('num 5', 'No/GlobalScope/1');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/GlobalScope/1');
        Observer.Expect('minus_1', 'No/GlobalScope/1');
        Observer.Expect('blank_1', 'Yes/GlobalScope/1');
        Observer.Expect('zero_1', 'Yes/GlobalScope/1');
        Observer.Expect('decimal', 'No/GlobalScope/1');
        Observer.Expect('comma', 'No/GlobalScope/1');
        Observer.Expect('hundred', 'No/GlobalScope/1');
        Observer.Expect('int_max', 'No/GlobalScope/1');
        Observer.Expect('int_over', 'No/GlobalScope/1');
        Observer.Expect('big', 'No/GlobalScope/1');
        Observer.Expect('hex', 'No/GlobalScope/1');
        Observer.Expect('exp', 'No/GlobalScope/1');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/LocalScope/0');
        Observer.Expect('blank', 'Yes/LocalScope/0');
        Observer.Expect('blanks', 'Yes/LocalScope/0');
        Observer.Expect('garbage', 'No/GlobalScope/1');
        Observer.Expect('dash', 'No/GlobalScope/1');
        Observer.Expect('dot', 'No/GlobalScope/1');
        Observer.Expect('question', 'No/GlobalScope/1');
        Observer.Expect('tab only', 'Yes/LocalScope/0');
        Observer.Expect('name_tab', 'Yes/LocalScope/0');
        Observer.Expect('tab_name', 'Yes/LocalScope/0');
        Observer.Expect('number_tab', 'Yes/GlobalScope/1');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/LocalScope');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/LocalScope');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/GlobalScope');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/LocalScope');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/LocalScope');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/GlobalScope');
        Observer.Expect('past_last|text', '''2'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/GlobalScope');
        Observer.Expect('far_past|text', '''22'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/GlobalScope');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/GlobalScope');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/GlobalScope');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/GlobalScope');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: LocalScope, GlobalScope');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/LocalScope');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/LocalScope/0');
        Observer.Expect('f9 last', 'Yes/GlobalScope/1');
        Observer.Expect('f9 0', 'Yes/LocalScope/0');
        Observer.Expect('f9 past', 'No/GlobalScope/1');
        Observer.Expect('f9 garbage', 'No/GlobalScope/1');
        Observer.Expect('f9 empty', 'Yes/LocalScope/0');
        Observer.Expect('f0 first', 'Yes/LocalScope/0');
        Observer.Expect('f0 1', 'Yes/GlobalScope/1');
        Observer.Expect('f2 1', 'Yes/GlobalScope/1');
        Observer.Expect('f2 garbage', 'No/GlobalScope/1');
        Observer.Verify();
    end;
}

codeunit 99612 "LT SO Eval WebServiceActi"
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
        Observer.Expect('name None', 'Yes/None/0');
        Observer.Expect('name Get', 'Yes/Get/200');
        Observer.Expect('name Created', 'Yes/Created/201');
        Observer.Expect('name Updated', 'Yes/Get/200');
        Observer.Expect('name Deleted', 'Yes/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/None/0');
        Observer.Expect('upper', 'Yes/None/0');
        Observer.Expect('mixedcase', 'Yes/None/0');
        Observer.Expect('leading_blank', 'Yes/None/0');
        Observer.Expect('trailing_blank', 'Yes/None/0');
        Observer.Expect('both_blanks', 'Yes/None/0');
        Observer.Expect('prefix', 'Yes/None/0');
        Observer.Expect('extra_char', 'No/Deleted/204');
        Observer.Expect('two_names', 'No/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/None/0');
        Observer.Expect('num 1', 'No/Deleted/204');
        Observer.Expect('num 2', 'No/Deleted/204');
        Observer.Expect('num 3', 'No/Deleted/204');
        Observer.Expect('num 4', 'No/Deleted/204');
        Observer.Expect('num 5', 'No/Deleted/204');
        Observer.Expect('num 6', 'No/Deleted/204');
        Observer.Expect('num 7', 'No/Deleted/204');
        Observer.Expect('num 8', 'No/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'No/Deleted/204');
        Observer.Expect('minus_1', 'No/Deleted/204');
        Observer.Expect('blank_1', 'No/Deleted/204');
        Observer.Expect('zero_1', 'No/Deleted/204');
        Observer.Expect('decimal', 'No/Deleted/204');
        Observer.Expect('comma', 'No/Deleted/204');
        Observer.Expect('hundred', 'No/Deleted/204');
        Observer.Expect('int_max', 'No/Deleted/204');
        Observer.Expect('int_over', 'No/Deleted/204');
        Observer.Expect('big', 'No/Deleted/204');
        Observer.Expect('hex', 'No/Deleted/204');
        Observer.Expect('exp', 'No/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/None/0');
        Observer.Expect('blank', 'Yes/None/0');
        Observer.Expect('blanks', 'Yes/None/0');
        Observer.Expect('garbage', 'No/Deleted/204');
        Observer.Expect('dash', 'No/Deleted/204');
        Observer.Expect('dot', 'No/Deleted/204');
        Observer.Expect('question', 'No/Deleted/204');
        Observer.Expect('tab only', 'Yes/None/0');
        Observer.Expect('name_tab', 'Yes/None/0');
        Observer.Expect('tab_name', 'Yes/None/0');
        Observer.Expect('number_tab', 'No/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/None');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/None');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/Deleted');
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/None');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/None');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('past_last', 'No/Deleted');
        Observer.Expect('past_last|text', '''5'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('past_last|code', 'InvalidOptionString');
        Observer.Expect('far_past', 'No/Deleted');
        Observer.Expect('far_past|text', '''25'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/Deleted');
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/Deleted');
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/Deleted');
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/Deleted');
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: None, Get, Created, Updated, Deleted');
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/None');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/None/0');
        Observer.Expect('f9 last', 'Yes/Deleted/204');
        Observer.Expect('f9 0', 'Yes/None/0');
        Observer.Expect('f9 past', 'No/Deleted/204');
        Observer.Expect('f9 garbage', 'No/Deleted/204');
        Observer.Expect('f9 empty', 'Yes/None/0');
        Observer.Expect('f0 first', 'Yes/None/0');
        Observer.Expect('f0 1', 'No/Deleted/204');
        Observer.Expect('f2 1', 'No/Deleted/204');
        Observer.Expect('f2 garbage', 'No/Deleted/204');
        Observer.Verify();
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
        Observer.Expect('name Normal', 'Yes/Normal/Normal');
        Observer.Expect('name FlowField', 'Yes/FlowField/FlowField');
        Observer.Expect('name FlowFilter', 'Yes/FlowFilter/FlowFilter');
        Observer.Verify();
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
        Observer.Expect('lower', 'Yes/Normal/Normal');
        Observer.Expect('upper', 'Yes/Normal/Normal');
        Observer.Expect('mixedcase', 'Yes/Normal/Normal');
        Observer.Expect('leading_blank', 'Yes/Normal/Normal');
        Observer.Expect('trailing_blank', 'Yes/Normal/Normal');
        Observer.Expect('both_blanks', 'Yes/Normal/Normal');
        Observer.Expect('prefix', 'Yes/Normal/Normal');
        Observer.Expect('extra_char', 'No/FlowFilter/FlowFilter');
        Observer.Expect('two_names', 'No/FlowFilter/FlowFilter');
        Observer.Verify();
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
        Observer.Expect('num 0', 'Yes/Normal/Normal');
        Observer.Expect('num 1', 'Yes/FlowField/FlowField');
        Observer.Expect('num 2', 'Yes/FlowFilter/FlowFilter');
#if BC28PLUS
        Observer.Expect('num 3', 'Yes/KeyFieldReference/KeyFieldReference');
#else
        Observer.Expect('num 3', 'No/FlowFilter/FlowFilter');
#endif
        Observer.Expect('num 4', 'No/FlowFilter/FlowFilter');
        Observer.Expect('num 5', 'No/FlowFilter/FlowFilter');
        Observer.Expect('num 6', 'No/FlowFilter/FlowFilter');
        Observer.Verify();
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
        Observer.Expect('plus_1', 'Yes/FlowField/FlowField');
        Observer.Expect('minus_1', 'No/FlowFilter/FlowFilter');
        Observer.Expect('blank_1', 'Yes/FlowField/FlowField');
        Observer.Expect('zero_1', 'Yes/FlowField/FlowField');
        Observer.Expect('decimal', 'No/FlowFilter/FlowFilter');
        Observer.Expect('comma', 'No/FlowFilter/FlowFilter');
        Observer.Expect('hundred', 'No/FlowFilter/FlowFilter');
        Observer.Expect('int_max', 'No/FlowFilter/FlowFilter');
        Observer.Expect('int_over', 'No/FlowFilter/FlowFilter');
        Observer.Expect('big', 'No/FlowFilter/FlowFilter');
        Observer.Expect('hex', 'No/FlowFilter/FlowFilter');
        Observer.Expect('exp', 'No/FlowFilter/FlowFilter');
        Observer.Verify();
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
        Observer.Expect('empty', 'Yes/Normal/Normal');
        Observer.Expect('blank', 'Yes/Normal/Normal');
        Observer.Expect('blanks', 'Yes/Normal/Normal');
        Observer.Expect('garbage', 'No/FlowFilter/FlowFilter');
        Observer.Expect('dash', 'No/FlowFilter/FlowFilter');
        Observer.Expect('dot', 'No/FlowFilter/FlowFilter');
        Observer.Expect('question', 'No/FlowFilter/FlowFilter');
        Observer.Expect('tab only', 'Yes/Normal/Normal');
        Observer.Expect('name_tab', 'Yes/Normal/Normal');
        Observer.Expect('tab_name', 'Yes/Normal/Normal');
        Observer.Expect('number_tab', 'Yes/FlowField/FlowField');
        Observer.Verify();
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
        Observer.Expect('good_name', 'Yes/Normal');
        Observer.Expect('good_name|text', '');
        Observer.Expect('good_name|code', '');
        Observer.Expect('good_number', 'Yes/Normal');
        Observer.Expect('good_number|text', '');
        Observer.Expect('good_number|code', '');
        Observer.Expect('garbage', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('garbage|text', '''zzz'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('garbage|code', 'InvalidOptionString');
        Observer.Expect('empty', 'Yes/Normal');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('blank', 'Yes/Normal');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
#if BC28PLUS
        Observer.Expect('past_last', 'Yes/KeyFieldReference');
#else
        Observer.Expect('past_last', 'No/FlowFilter');
#endif
#if BC28PLUS
        Observer.Expect('past_last|text', '');
#else
        Observer.Expect('past_last|text', '''3'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
#if BC28PLUS
        Observer.Expect('past_last|code', '');
#else
        Observer.Expect('past_last|code', 'InvalidOptionString');
#endif
        Observer.Expect('far_past', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('far_past|text', '''23'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('far_past|text', '''23'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('far_past|code', 'InvalidOptionString');
        Observer.Expect('negative', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('negative|text', '''-1'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('negative|code', 'InvalidOptionString');
        Observer.Expect('long_garbage', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('long_garbage|text', '''AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSs'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('long_garbage|code', 'InvalidOptionString');
        Observer.Expect('quote', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('quote|text', '''it''s'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('quote|code', 'InvalidOptionString');
        Observer.Expect('tab_garbage', 'No/FlowFilter');
#if BC28PLUS
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Normal, FlowField, FlowFilter, KeyFieldReference');
#else
        Observer.Expect('tab_garbage|text', '''a\tb'' is not an option. The existing options are: Normal, FlowField, FlowFilter');
#endif
        Observer.Expect('tab_garbage|code', 'InvalidOptionString');
        Observer.Expect('name_tab', 'Yes/Normal');
        Observer.Expect('name_tab|text', '');
        Observer.Expect('name_tab|code', '');
        Observer.Verify();
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
        Observer.Expect('f9 first', 'Yes/Normal/Normal');
        Observer.Expect('f9 last', 'Yes/FlowFilter/FlowFilter');
        Observer.Expect('f9 0', 'Yes/Normal/Normal');
#if BC28PLUS
        Observer.Expect('f9 past', 'Yes/KeyFieldReference/KeyFieldReference');
#else
        Observer.Expect('f9 past', 'No/FlowFilter/FlowFilter');
#endif
        Observer.Expect('f9 garbage', 'No/FlowFilter/FlowFilter');
        Observer.Expect('f9 empty', 'Yes/Normal/Normal');
        Observer.Expect('f0 first', 'Yes/Normal/Normal');
        Observer.Expect('f0 1', 'Yes/FlowField/FlowField');
        Observer.Expect('f2 1', 'Yes/FlowField/FlowField');
        Observer.Expect('f2 garbage', 'No/FlowFilter/FlowFilter');
        Observer.Verify();
    end;

    // Gap probe 2: Format of a FieldClass value and of the Class column of the Field table.
    local procedure ShowFormats(V: FieldClass): Text
    begin
        exit(Format(V) + '|' + Format(V, 0, 0) + '|' + Format(V, 0, 1) + '|' + Format(V, 0, 2) + '|' + Format(V, 0, 9));
    end;

    local procedure ShowClass(var FieldRec: Record Field): Text
    begin
        exit(Format(FieldRec.Class) + '|' + Format(FieldRec.Class, 0, 0) + '|' + Format(FieldRec.Class, 0, 1) + '|' + Format(FieldRec.Class, 0, 2) + '|' + Format(FieldRec.Class, 0, 9));
    end;

    [Test]
    procedure FormatOfVariable_Members()
    var
        Observer: Codeunit "Probe Observer";
        V: FieldClass;
    begin
        V := FieldClass::Normal;
        Observer.Observe('Normal', ShowFormats(V));
        V := FieldClass::FlowField;
        Observer.Observe('FlowField', ShowFormats(V));
        V := FieldClass::FlowFilter;
        Observer.Observe('FlowFilter', ShowFormats(V));
        Observer.Finish();
    end;

    [Test]
    procedure FormatOfVariable_Default()
    var
        Observer: Codeunit "Probe Observer";
        V: FieldClass;
    begin
        Observer.Observe('default', ShowFormats(V));
        Observer.Observe('default text', Format(V, 0, '<Text>'));
        Observer.Observe('default length 3', Format(V, 3));
        Observer.Finish();
    end;

#if BC28PLUS // FieldClass::KeyFieldReference exists from BC 28 (Evaluate of 3, see Numbers)
    [Test]
    procedure FormatOfVariable_KeyFieldReference()
    var
        Observer: Codeunit "Probe Observer";
        V: FieldClass;
    begin
        V := FieldClass::KeyFieldReference;
        Observer.Observe('KeyFieldReference', ShowFormats(V));
        Observer.Finish();
    end;
#endif

    [Test]
    procedure FormatOfVariable_FromEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: FieldClass;
        Ok: Boolean;
    begin
        Ok := Evaluate(V, '3');
        Observer.Observe('evaluate 3', Format(Ok) + '/' + ShowFormats(V));
        Ok := Evaluate(V, '2');
        Observer.Observe('evaluate 2', Format(Ok) + '/' + ShowFormats(V));
        Observer.Finish();
    end;

    [Test]
    procedure FormatOfFieldTableClassColumn()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
    begin
        // The Field rows come from table 67307 "W6 FK Types" (metadata/W6FieldKeyRows.al): field 2 FText Normal, 17 FNormalSum FlowField, 18 FFilter FlowFilter
        FieldRec.Get(67307, 2);
        Observer.Observe('Normal', ShowClass(FieldRec));
        FieldRec.Get(67307, 17);
        Observer.Observe('FlowField', ShowClass(FieldRec));
        FieldRec.Get(67307, 18);
        Observer.Observe('FlowFilter', ShowClass(FieldRec));
        Observer.Finish();
    end;

    [Test]
    procedure FieldTableClassColumn_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        Ok: Boolean;
    begin
        FieldRec.Get(67307, 2);
        Ok := Evaluate(FieldRec.Class, 'KeyFieldReference');
        Observer.Observe('evaluate name', Format(Ok) + '/' + ShowClass(FieldRec));
        Ok := Evaluate(FieldRec.Class, '3');
        Observer.Observe('evaluate 3', Format(Ok) + '/' + ShowClass(FieldRec));
        Ok := Evaluate(FieldRec.Class, 'FlowField');
        Observer.Observe('evaluate FlowField', Format(Ok) + '/' + ShowClass(FieldRec));
        Ok := Evaluate(FieldRec.Class, '2', 9);
        Observer.Observe('evaluate 2 f9', Format(Ok) + '/' + ShowClass(FieldRec));
        FieldRec.Get(67307, 2);
        asserterror Evaluate(FieldRec.Class, 'zzz');
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        ClearLastError();
        Observer.Finish();
    end;
}
