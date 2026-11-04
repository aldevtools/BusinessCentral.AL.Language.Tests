// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-selecttoken-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: leads of corpus issue 671 (part F, items 36, 37, 43): JsonObject.SelectToken with a filter that compares with double or single quotes,
// a union of keys ('$.[A,B]', '$[A,B]', "$['A','B']"), and the last array element through '[(@.length-1)]' and '[-1:]'.
// Each path is observed as: the Boolean SelectToken returns, the token written as text, and the last error text and code (an invalid path
// answers false and leaves a last error without raising, see json/lt-json-selecttokens/SelectTokensList.al); a path that raises is observed
// as 'raised' with its error.
// Facts: see the Expect lines of each test.
// BC versions: 27, 28, 29

codeunit 85723 "LT DB JPath Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySel(O: JsonObject; Path: Text; var T: JsonToken; var Ret: Boolean)
    begin
        Ret := O.SelectToken(Path, T);
    end;

    local procedure Sel(var Observer: Codeunit "Probe Observer"; Name: Text; O: JsonObject; Path: Text)
    var
        T: JsonToken;
        Ret: Boolean;
        Written: Text;
    begin
        ClearLastError();
        if not TrySel(O, Path, T, Ret) then begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
            exit;
        end;
        if Ret then
            T.WriteTo(Written);
        Observer.Observe(Name, Format(Ret) + ' [' + Written + ']');
        Observer.ObserveError(Name);
    end;

    local procedure Employees() O: JsonObject
    begin
        O.ReadFrom('{"company":{"employees":[{"id":"John","salary":100},{"id":"Jane","salary":200}]}}');
    end;

    local procedure Messages(Json: Text) O: JsonObject
    begin
        O.ReadFrom(Json);
    end;

    [Test]
    procedure Filter_DoubleAndSingleQuotes()
    // Issue 671 item 36 (microsoft/AL#5006).
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'double', Employees(), '$.company.employees[?(@.id=="John")].salary');
        Sel(Observer, 'single', Employees(), '$.company.employees[?(@.id==''John'')].salary');
        Sel(Observer, 'single_nomatch', Employees(), '$.company.employees[?(@.id==''Nobody'')].salary');
        Sel(Observer, 'double_nomatch', Employees(), '$.company.employees[?(@.id=="Nobody")].salary');
        Sel(Observer, 'number', Employees(), '$.company.employees[?(@.salary==200)].id');
        Sel(Observer, 'single_two', Employees(), '$.company.employees[?(@.salary>50)].id');
        Observer.Expect('double', 'No []');
        Observer.Expect('double|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('double|code', 'InvalidOperation');
        Observer.Expect('single', 'Yes [100]');
        Observer.Expect('single|text', '');
        Observer.Expect('single|code', '');
        Observer.Expect('single_nomatch', 'No []');
        Observer.Expect('single_nomatch|text', '');
        Observer.Expect('single_nomatch|code', '');
        Observer.Expect('double_nomatch', 'No []');
        Observer.Expect('double_nomatch|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('double_nomatch|code', 'InvalidOperation');
        Observer.Expect('number', 'Yes ["Jane"]');
        Observer.Expect('number|text', '');
        Observer.Expect('number|code', '');
        Observer.Expect('single_two', 'No []');
        Observer.Expect('single_two|text', '');
        Observer.Expect('single_two|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Union_OfKeys()
    // Issue 671 item 37 (microsoft/AL#4957).
    var
        Observer: Codeunit "Probe Observer";
        OnlyApi: JsonObject;
        OnlyMsg: JsonObject;
        Both: JsonObject;
        Neither: JsonObject;
    begin
        OnlyApi := Messages('{"ApiMessage":"api"}');
        OnlyMsg := Messages('{"Message":"msg"}');
        Both := Messages('{"ApiMessage":"api","Message":"msg"}');
        Neither := Messages('{"Other":"x"}');
        Sel(Observer, 'dot_api', OnlyApi, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_msg', OnlyMsg, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_both', Both, '$.[ApiMessage,Message]');
        Sel(Observer, 'dot_neither', Neither, '$.[ApiMessage,Message]');
        Sel(Observer, 'nodot_api', OnlyApi, '$[ApiMessage,Message]');
        Sel(Observer, 'nodot_msg', OnlyMsg, '$[ApiMessage,Message]');
        Sel(Observer, 'nodot_both', Both, '$[ApiMessage,Message]');
        Sel(Observer, 'quoted_api', OnlyApi, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_msg', OnlyMsg, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_both', Both, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'quoted_neither', Neither, '$[''ApiMessage'',''Message'']');
        Sel(Observer, 'plain_api', OnlyApi, '$.ApiMessage');
        Sel(Observer, 'plain_on_msg', OnlyMsg, '$.ApiMessage');
        Observer.Expect('dot_api', 'No []');
        Observer.Expect('dot_api|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_api|code', 'InvalidOperation');
        Observer.Expect('dot_msg', 'No []');
        Observer.Expect('dot_msg|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_msg|code', 'InvalidOperation');
        Observer.Expect('dot_both', 'No []');
        Observer.Expect('dot_both|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_both|code', 'InvalidOperation');
        Observer.Expect('dot_neither', 'No []');
        Observer.Expect('dot_neither|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dot_neither|code', 'InvalidOperation');
        Observer.Expect('nodot_api', 'No []');
        Observer.Expect('nodot_api|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_api|code', 'InvalidOperation');
        Observer.Expect('nodot_msg', 'No []');
        Observer.Expect('nodot_msg|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_msg|code', 'InvalidOperation');
        Observer.Expect('nodot_both', 'No []');
        Observer.Expect('nodot_both|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('nodot_both|code', 'InvalidOperation');
        Observer.Expect('quoted_api', 'Yes ["api"]');
        Observer.Expect('quoted_api|text', '');
        Observer.Expect('quoted_api|code', '');
        Observer.Expect('quoted_msg', 'Yes ["msg"]');
        Observer.Expect('quoted_msg|text', '');
        Observer.Expect('quoted_msg|code', '');
        Observer.Expect('quoted_both', 'No []');
        Observer.Expect('quoted_both|text', '');
        Observer.Expect('quoted_both|code', '');
        Observer.Expect('quoted_neither', 'No []');
        Observer.Expect('quoted_neither|text', '');
        Observer.Expect('quoted_neither|code', '');
        Observer.Expect('plain_api', 'Yes ["api"]');
        Observer.Expect('plain_api|text', '');
        Observer.Expect('plain_api|code', '');
        Observer.Expect('plain_on_msg', 'No []');
        Observer.Expect('plain_on_msg|text', '');
        Observer.Expect('plain_on_msg|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastArrayElement()
    // Issue 671 item 43 (microsoft/AL#6323).
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
    begin
        O.ReadFrom('{"items":[{"x":1},{"x":2},{"x":3}]}');
        Sel(Observer, 'length_minus_1', O, '$.items[(@.length-1)].x');
        Sel(Observer, 'slice_minus_1', O, '$.items[-1:].x');
        Sel(Observer, 'index_minus_1', O, '$.items[-1].x');
        Sel(Observer, 'slice_minus_2', O, '$.items[-2:].x');
        Sel(Observer, 'index_2', O, '$.items[2].x');
        Observer.Expect('length_minus_1', 'No []');
        Observer.Expect('length_minus_1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('length_minus_1|code', 'InvalidOperation');
        Observer.Expect('slice_minus_1', 'Yes [3]');
        Observer.Expect('slice_minus_1|text', '');
        Observer.Expect('slice_minus_1|code', '');
        Observer.Expect('index_minus_1', 'No []');
        Observer.Expect('index_minus_1|text', 'An invalid argument was passed to a ''Json'' data type method.');
        Observer.Expect('index_minus_1|code', 'ArgumentOutOfRange');
        Observer.Expect('slice_minus_2', 'No []');
        Observer.Expect('slice_minus_2|text', '');
        Observer.Expect('slice_minus_2|code', '');
        Observer.Expect('index_2', 'Yes [3]');
        Observer.Expect('index_2|text', '');
        Observer.Expect('index_2|code', '');
        Observer.Verify();
    end;

    // Writer Y47 (al-runner issue 6588): a filter expression on a JsonArray root ('$.[?(@.id==2)]' and '$[?(@.id==2)]'), on a JsonToken
    // holding the array, and the close neighbours (string compare, no match, several matches, other operators). Observed like Sel above.
    [TryFunction]
    local procedure Y47_TrySelArr(A: JsonArray; Path: Text; var T: JsonToken; var Ret: Boolean)
    begin
        Ret := A.SelectToken(Path, T);
    end;

    local procedure Y47_SelArr(var Observer: Codeunit "Probe Observer"; Name: Text; A: JsonArray; Path: Text)
    var
        T: JsonToken;
        Ret: Boolean;
        Written: Text;
    begin
        ClearLastError();
        if not Y47_TrySelArr(A, Path, T, Ret) then begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
            exit;
        end;
        if Ret then
            T.WriteTo(Written);
        Observer.Observe(Name, Format(Ret) + ' [' + Written + ']');
        Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure Y47_TrySelTok(Tok: JsonToken; Path: Text; var T: JsonToken; var Ret: Boolean)
    begin
        Ret := Tok.SelectToken(Path, T);
    end;

    local procedure Y47_SelTok(var Observer: Codeunit "Probe Observer"; Name: Text; Tok: JsonToken; Path: Text)
    var
        T: JsonToken;
        Ret: Boolean;
        Written: Text;
    begin
        ClearLastError();
        if not Y47_TrySelTok(Tok, Path, T, Ret) then begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
            exit;
        end;
        if Ret then
            T.WriteTo(Written);
        Observer.Observe(Name, Format(Ret) + ' [' + Written + ']');
        Observer.ObserveError(Name);
    end;

    local procedure Y47_Records() A: JsonArray
    begin
        A.ReadFrom('[{"id":1,"name":"first"},{"id":2,"name":"second"}]');
    end;

    local procedure Y47_TwoMatches() A: JsonArray
    begin
        A.ReadFrom('[{"id":1,"name":"first"},{"id":2,"name":"second"},{"id":2,"name":"third"}]');
    end;

    [Test]
    procedure Y47_ArrayFilter_ReporterShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y47_SelArr(Observer, 'dot', Y47_Records(), '$.[?(@.id==2)]');
        Y47_SelArr(Observer, 'nodot', Y47_Records(), '$[?(@.id==2)]');
        Y47_SelArr(Observer, 'noroot', Y47_Records(), '[?(@.id==2)]');
        Y47_SelArr(Observer, 'deep', Y47_Records(), '$..[?(@.id==2)]');
        Y47_SelArr(Observer, 'dot_name', Y47_Records(), '$.[?(@.id==2)].name');
        Y47_SelArr(Observer, 'nodot_name', Y47_Records(), '$[?(@.id==2)].name');
        Y47_SelArr(Observer, 'spaces', Y47_Records(), '$[?(@.id == 2)]');
        Observer.Expect('dot', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('dot|text', '');
        Observer.Expect('dot|code', '');
        Observer.Expect('nodot', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('nodot|text', '');
        Observer.Expect('nodot|code', '');
        Observer.Expect('noroot', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('noroot|text', '');
        Observer.Expect('noroot|code', '');
        Observer.Expect('deep', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('deep|text', '');
        Observer.Expect('deep|code', '');
        Observer.Expect('dot_name', 'Yes ["second"]');
        Observer.Expect('dot_name|text', '');
        Observer.Expect('dot_name|code', '');
        Observer.Expect('nodot_name', 'Yes ["second"]');
        Observer.Expect('nodot_name|text', '');
        Observer.Expect('nodot_name|code', '');
        Observer.Expect('spaces', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('spaces|text', '');
        Observer.Expect('spaces|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_ArrayFilter_Neighbours()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y47_SelArr(Observer, 'str_single', Y47_Records(), '$[?(@.name==''second'')]');
        Y47_SelArr(Observer, 'str_double', Y47_Records(), '$[?(@.name=="second")]');
        Y47_SelArr(Observer, 'str_vs_number', Y47_Records(), '$[?(@.id==''2'')]');
        Y47_SelArr(Observer, 'nomatch', Y47_Records(), '$[?(@.id==9)]');
        Y47_SelArr(Observer, 'nomatch_dot', Y47_Records(), '$.[?(@.id==9)]');
        Y47_SelArr(Observer, 'missing_prop', Y47_Records(), '$[?(@.x==2)]');
        Y47_SelArr(Observer, 'two_matches', Y47_TwoMatches(), '$[?(@.id==2)]');
        Y47_SelArr(Observer, 'two_matches_dot', Y47_TwoMatches(), '$.[?(@.id==2)]');
        Y47_SelArr(Observer, 'two_matches_name', Y47_TwoMatches(), '$[?(@.name==''third'')]');
        Y47_SelArr(Observer, 'gt_one', Y47_Records(), '$[?(@.id>1)]');
        Y47_SelArr(Observer, 'ne', Y47_Records(), '$[?(@.id!=1)]');
        Y47_SelArr(Observer, 'le', Y47_Records(), '$[?(@.id<=1)]');
        Y47_SelArr(Observer, 'and', Y47_Records(), '$[?(@.id==2 && @.name==''second'')]');
        Y47_SelArr(Observer, 'exists', Y47_Records(), '$[?(@.name)]');
        Observer.Expect('str_single', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('str_single|text', '');
        Observer.Expect('str_single|code', '');
        Observer.Expect('str_double', 'No []');
        Observer.Expect('str_double|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('str_double|code', 'InvalidOperation');
        Observer.Expect('str_vs_number', 'No []');
        Observer.Expect('str_vs_number|text', '');
        Observer.Expect('str_vs_number|code', '');
        Observer.Expect('nomatch', 'No []');
        Observer.Expect('nomatch|text', '');
        Observer.Expect('nomatch|code', '');
        Observer.Expect('nomatch_dot', 'No []');
        Observer.Expect('nomatch_dot|text', '');
        Observer.Expect('nomatch_dot|code', '');
        Observer.Expect('missing_prop', 'No []');
        Observer.Expect('missing_prop|text', '');
        Observer.Expect('missing_prop|code', '');
        Observer.Expect('two_matches', 'No []');
        Observer.Expect('two_matches|text', '');
        Observer.Expect('two_matches|code', '');
        Observer.Expect('two_matches_dot', 'No []');
        Observer.Expect('two_matches_dot|text', '');
        Observer.Expect('two_matches_dot|code', '');
        Observer.Expect('two_matches_name', 'Yes [{"id":2,"name":"third"}]');
        Observer.Expect('two_matches_name|text', '');
        Observer.Expect('two_matches_name|code', '');
        Observer.Expect('gt_one', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('gt_one|text', '');
        Observer.Expect('gt_one|code', '');
        Observer.Expect('ne', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('ne|text', '');
        Observer.Expect('ne|code', '');
        Observer.Expect('le', 'Yes [{"id":1,"name":"first"}]');
        Observer.Expect('le|text', '');
        Observer.Expect('le|code', '');
        Observer.Expect('and', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('and|text', '');
        Observer.Expect('and|code', '');
        Observer.Expect('exists', 'No []');
        Observer.Expect('exists|text', '');
        Observer.Expect('exists|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_TokenFilter()
    var
        Observer: Codeunit "Probe Observer";
        Tok: JsonToken;
        ObjTok: JsonToken;
    begin
        Tok.ReadFrom('[{"id":1,"name":"first"},{"id":2,"name":"second"}]');
        ObjTok.ReadFrom('{"list":[{"id":1,"name":"first"},{"id":2,"name":"second"}]}');
        Y47_SelTok(Observer, 'tok_dot', Tok, '$.[?(@.id==2)]');
        Y47_SelTok(Observer, 'tok_nodot', Tok, '$[?(@.id==2)]');
        Y47_SelTok(Observer, 'tok_nomatch', Tok, '$[?(@.id==9)]');
        Y47_SelTok(Observer, 'obj_list', ObjTok, '$.list[?(@.id==2)]');
        Y47_SelTok(Observer, 'obj_list_name', ObjTok, '$.list[?(@.id==2)].name');
        Y47_SelTok(Observer, 'obj_list_nomatch', ObjTok, '$.list[?(@.id==9)]');
        Observer.Expect('tok_dot', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('tok_dot|text', '');
        Observer.Expect('tok_dot|code', '');
        Observer.Expect('tok_nodot', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('tok_nodot|text', '');
        Observer.Expect('tok_nodot|code', '');
        Observer.Expect('tok_nomatch', 'No []');
        Observer.Expect('tok_nomatch|text', '');
        Observer.Expect('tok_nomatch|code', '');
        Observer.Expect('obj_list', 'Yes [{"id":2,"name":"second"}]');
        Observer.Expect('obj_list|text', '');
        Observer.Expect('obj_list|code', '');
        Observer.Expect('obj_list_name', 'Yes ["second"]');
        Observer.Expect('obj_list_name|text', '');
        Observer.Expect('obj_list_name|code', '');
        Observer.Expect('obj_list_nomatch', 'No []');
        Observer.Expect('obj_list_nomatch|text', '');
        Observer.Expect('obj_list_nomatch|code', '');
        Observer.Verify();
    end;
#if BC28PLUS

    [Test]
    procedure Y47_SelectTokens_ArrayFilter()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonToken];
        T: JsonToken;
        B: Boolean;
        Written: Text;
        All: Text;
    begin
        ClearLastError();
        B := Y47_TwoMatches().SelectTokens('$[?(@.id==2)]', L);
        foreach T in L do begin
            T.WriteTo(Written);
            All += Written + ';';
        end;
        Observer.Observe('nodot', Format(B) + ' ' + Format(L.Count()) + ' ' + All);
        Observer.ObserveError('nodot');
        Clear(L);
        All := '';
        B := Y47_TwoMatches().SelectTokens('$.[?(@.id==2)]', L);
        foreach T in L do begin
            T.WriteTo(Written);
            All += Written + ';';
        end;
        Observer.Observe('dot', Format(B) + ' ' + Format(L.Count()) + ' ' + All);
        Observer.ObserveError('dot');
        Clear(L);
        B := Y47_TwoMatches().SelectTokens('$[?(@.id==9)]', L);
        Observer.Observe('nomatch', Format(B) + ' ' + Format(L.Count()));
        Observer.ObserveError('nomatch');
        Observer.Expect('nodot', 'Yes 2 {"id":2,"name":"second"};{"id":2,"name":"third"};');
        Observer.Expect('nodot|text', '');
        Observer.Expect('nodot|code', '');
        Observer.Expect('dot', 'Yes 2 {"id":2,"name":"second"};{"id":2,"name":"third"};');
        Observer.Expect('dot|text', '');
        Observer.Expect('dot|code', '');
        Observer.Expect('nomatch', 'Yes 0');
        Observer.Expect('nomatch|text', '');
        Observer.Expect('nomatch|code', '');
        Observer.Verify();
    end;
#endif

    // Al-runner issue 6924 item 2.5: the path forms of SelectToken that no test above or in JsonObjectBasics.al pins: wildcard names,
    // empty names (a trailing or a doubled dot), `..` with zero or several matches, quoted names with blanks, dots, quotes or nothing,
    // slices with an open end or a step, odd indexers, names on arrays and values, and the same paths as a statement (result unused).
    // Observed like Sel above; the statement form as P6924_SelStmt below ('raised', or 'done [<token>]', and the last error).
    [TryFunction]
    local procedure P6924_TrySelStmt(O: JsonObject; Path: Text; var T: JsonToken)
    begin
        O.SelectToken(Path, T);
    end;

    [TryFunction]
    local procedure P6924_TryWrite(T: JsonToken; var Written: Text)
    begin
        T.WriteTo(Written);
    end;

    local procedure P6924_SelStmt(var Observer: Codeunit "Probe Observer"; Name: Text; O: JsonObject; Path: Text)
    var
        T: JsonToken;
        Written: Text;
    begin
        ClearLastError();
        if not P6924_TrySelStmt(O, Path, T) then begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
            exit;
        end;
        if not P6924_TryWrite(T, Written) then
            Written := '<no token>';
        ClearLastError();
        Observer.Observe(Name, 'done [' + Written + ']');
        Observer.ObserveError(Name);
    end;

    local procedure P6924_Doc() O: JsonObject
    begin
        O.ReadFrom('{"a":{"b":1,"c":[10,20,30],"d e":2,"x.y":3,"it''s":4,"":5,"n":null},"arr":[{"k":1},{"k":2}],"one":[{"k":7}],"empty":[],"s":"txt"}');
    end;

    [Test]
    procedure P6924_SelectToken_WildcardAndEmptyNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'name_star', P6924_Doc(), 'a.*');
        Sel(Observer, 'root_star', P6924_Doc(), '$.*');
        Sel(Observer, 'bare_star', P6924_Doc(), '*');
        Sel(Observer, 'one_star', P6924_Doc(), 'one.*');
        Sel(Observer, 'trailing_dot', P6924_Doc(), 'a.');
        Sel(Observer, 'root_dot', P6924_Doc(), '$.');
        Sel(Observer, 'leading_dot', P6924_Doc(), '.a.b');
        Sel(Observer, 'at_sign', P6924_Doc(), '@.a');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_RecursiveDescent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'inner_descent', P6924_Doc(), 'a..b');
        Sel(Observer, 'descent_many', P6924_Doc(), '$..k');
        Sel(Observer, 'descent_none', P6924_Doc(), '$..zzz');
        Sel(Observer, 'descent_one', P6924_Doc(), '$..b');
        Sel(Observer, 'descent_index', P6924_Doc(), '$..[0]');
        Sel(Observer, 'descent_then_index', P6924_Doc(), '$..c[1]');
        Sel(Observer, 'descent_star', P6924_Doc(), '$..*');
        Sel(Observer, 'descent_one_then_key', P6924_Doc(), '$..one[0].k');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_QuotedNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'quoted_blank', P6924_Doc(), 'a[''d e'']');
        Sel(Observer, 'dotted_blank', P6924_Doc(), 'a.d e');
        Sel(Observer, 'quoted_dot', P6924_Doc(), 'a[''x.y'']');
        Sel(Observer, 'dotted_dot', P6924_Doc(), 'a.x.y');
        Sel(Observer, 'quoted_escaped_quote', P6924_Doc(), 'a[''it\''s'']');
        Sel(Observer, 'quoted_empty', P6924_Doc(), 'a['''']');
        Sel(Observer, 'root_quoted_chain', P6924_Doc(), '$[''a''][''b'']');
        Sel(Observer, 'quoted_null', P6924_Doc(), '$.a[''n'']');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_Slices()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'slice_open_start', P6924_Doc(), 'a.c[:1]');
        Sel(Observer, 'slice_open_end', P6924_Doc(), 'a.c[2:]');
        Sel(Observer, 'slice_step', P6924_Doc(), 'a.c[0:3:2]');
        Sel(Observer, 'slice_step_only', P6924_Doc(), 'a.c[::3]');
        Sel(Observer, 'slice_one', P6924_Doc(), 'a.c[1:2]');
        Sel(Observer, 'slice_two', P6924_Doc(), 'a.c[0:2]');
        Sel(Observer, 'slice_none', P6924_Doc(), 'a.c[5:9]');
        Sel(Observer, 'slice_then_key', P6924_Doc(), 'arr[1:2].k');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_WildcardIndexers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'wild_single', P6924_Doc(), 'one[*]');
        Sel(Observer, 'wild_single_key', P6924_Doc(), 'one[*].k');
        Sel(Observer, 'wild_empty', P6924_Doc(), 'empty[*]');
        Sel(Observer, 'wild_many_key', P6924_Doc(), 'arr[*].k');
        Sel(Observer, 'wild_on_object', P6924_Doc(), 'a[*]');
        Sel(Observer, 'quoted_star', P6924_Doc(), '$[''*'']');
        Sel(Observer, 'wild_then_index', P6924_Doc(), '$.a.c[*]');
        Sel(Observer, 'root_wild', P6924_Doc(), '$[*]');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_IndexerForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'index_blanks', P6924_Doc(), 'a.c[ 1 ]');
        Sel(Observer, 'index_plus', P6924_Doc(), 'a.c[+1]');
        Sel(Observer, 'index_leading_zero', P6924_Doc(), 'a.c[01]');
        Sel(Observer, 'index_decimal', P6924_Doc(), 'a.c[1.0]');
        Sel(Observer, 'index_letters_used', P6924_Doc(), 'a.c[x]');
        Sel(Observer, 'index_quoted_number', P6924_Doc(), 'a.c[''1'']');
        Sel(Observer, 'index_on_object', P6924_Doc(), 'a[0]');
        Sel(Observer, 'index_chain', P6924_Doc(), 'arr[0][0]');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_NamesOnArraysAndValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sel(Observer, 'name_on_array', P6924_Doc(), 'arr.k');
        Sel(Observer, 'name_on_text', P6924_Doc(), 's.x');
        Sel(Observer, 'name_on_null', P6924_Doc(), 'a.n.x');
        Sel(Observer, 'null_value', P6924_Doc(), 'a.n');
        Sel(Observer, 'name_on_number', P6924_Doc(), 'a.b.c');
        Sel(Observer, 'case_differs', P6924_Doc(), 'A.B');
        Sel(Observer, 'blank_around_dot', P6924_Doc(), 'a. b');
        Sel(Observer, 'dollar_inside', P6924_Doc(), 'a.$');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_Statement_NoOrManyMatches()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_SelStmt(Observer, 'stmt_missing', P6924_Doc(), 'nope');
        P6924_SelStmt(Observer, 'stmt_missing_inner', P6924_Doc(), 'a.zzz');
        P6924_SelStmt(Observer, 'stmt_index_past_end', P6924_Doc(), 'a.c[9]');
        P6924_SelStmt(Observer, 'stmt_wild_empty', P6924_Doc(), 'empty[*]');
        P6924_SelStmt(Observer, 'stmt_wild_single', P6924_Doc(), 'one[*]');
        P6924_SelStmt(Observer, 'stmt_descent_none', P6924_Doc(), '$..zzz');
        P6924_SelStmt(Observer, 'stmt_descent_many', P6924_Doc(), '$..k');
        P6924_SelStmt(Observer, 'stmt_descent_one', P6924_Doc(), '$..b');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_Statement_OtherForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_SelStmt(Observer, 'stmt_slice_two', P6924_Doc(), 'a.c[0:2]');
        P6924_SelStmt(Observer, 'stmt_slice_one', P6924_Doc(), 'a.c[1:2]');
        P6924_SelStmt(Observer, 'stmt_name_star', P6924_Doc(), 'a.*');
        P6924_SelStmt(Observer, 'stmt_trailing_dot', P6924_Doc(), 'a.');
        P6924_SelStmt(Observer, 'stmt_quoted_blank', P6924_Doc(), 'a[''d e'']');
        P6924_SelStmt(Observer, 'stmt_double_quoted', P6924_Doc(), 'a["b"]');
        P6924_SelStmt(Observer, 'stmt_name_on_array', P6924_Doc(), 'arr.k');
        P6924_SelStmt(Observer, 'stmt_wild_many_key', P6924_Doc(), 'arr[*].k');
        Observer.Finish();
    end;

    [Test]
    procedure P6924_SelectToken_OtherReceivers()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        V: JsonValue;
        Tok: JsonToken;
        T: JsonToken;
        Ret: Boolean;
        Written: Text;
    begin
        A.ReadFrom('[{"k":1},[2,3],"x"]');
        Y47_SelArr(Observer, 'array_index_key', A, '[0].k');
        Y47_SelArr(Observer, 'array_dollar_index', A, '$[1][0]');
        Y47_SelArr(Observer, 'array_name', A, 'k');
        Y47_SelArr(Observer, 'array_descent', A, '$..k');
        V.SetValue(5);
        Tok := V.AsToken();
        Y47_SelTok(Observer, 'value_token_root', Tok, '$');
        Y47_SelTok(Observer, 'value_token_name', Tok, 'x');
        ClearLastError();
        Ret := V.SelectToken('', T);
        if Ret then
            T.WriteTo(Written);
        Observer.Observe('value_empty_path', Format(Ret) + ' [' + Written + ']');
        Observer.ObserveError('value_empty_path');
        Observer.Finish();
    end;
}
