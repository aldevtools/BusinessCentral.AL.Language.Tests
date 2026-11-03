// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-selecttokens-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 78800, 78801
// Probe: JsonObject.SelectTokens and JsonArray.SelectTokens with a List of [JsonToken]; the methods need app runtime 17 (BC 28 and 29; on BC 27 the app runs on 16.1 and the compiler refuses them: must-not-compile cases 0364 and 0640).
// Facts: result, list content, list pre-filled, no match (true, empty list), several matches, invalid path (false, last error InvalidOperation, no exception)
// BC versions: 28, 29

#if BC28PLUS
codeunit 78800 "LT S Array SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var A: JsonArray)
    begin
        A.ReadFrom('[{"a":1,"n":{"a":"deep"}},{"a":2},{"b":3},[{"a":4}]]');
    end;

    local procedure Render(L: List of [JsonToken]): Text
    var
        T: JsonToken;
        R: Text;
        Part: Text;
    begin
        foreach T in L do begin
            T.WriteTo(Part);
            R += Part + '|';
        end;
        exit(Format(L.Count()) + ':' + R);
    end;

    [Test]
    procedure SelectTokens_Array()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        L: List of [JsonToken];
        B: Boolean;
    begin
        Doc(A);
        B := A.SelectTokens('$[0].a', L);
        Observer.Observe('single_result', Format(B));
        Observer.Observe('single_list', Render(L));
        B := A.SelectTokens('$[9]', L);
        Observer.Observe('nomatch_result', Format(B));
        Observer.Observe('nomatch_list', Render(L));
        B := A.SelectTokens('$[*].a', L);
        Observer.Observe('wild_result', Format(B));
        Observer.Observe('wild_list', Render(L));
        B := A.SelectTokens('$..a', L);
        Observer.Observe('recursive_result', Format(B));
        Observer.Observe('recursive_list', Render(L));
        B := A.SelectTokens('$', L);
        Observer.Observe('root_result', Format(B));
        Observer.Observe('root_list', Render(L));
        B := A.SelectTokens('$[1:3]', L);
        Observer.Observe('slice_result', Format(B));
        Observer.Observe('slice_list', Render(L));
        Observer.Expect('single_result', 'Yes');
        Observer.Expect('single_list', '1:1|');
        Observer.Expect('nomatch_result', 'Yes');
        Observer.Expect('nomatch_list', '0:');
        Observer.Expect('wild_result', 'Yes');
        Observer.Expect('wild_list', '2:1|2|');
        Observer.Expect('recursive_result', 'Yes');
        Observer.Expect('recursive_list', '4:1|"deep"|2|4|');
        Observer.Expect('root_result', 'Yes');
        Observer.Expect('root_list', '1:[{"a":1,"n":{"a":"deep"}},{"a":2},{"b":3},[{"a":4}]]|');
        Observer.Expect('slice_result', 'Yes');
        Observer.Expect('slice_list', '2:{"a":2}|{"b":3}|');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_PrefilledList()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        L: List of [JsonToken];
        Filler: JsonToken;
        B: Boolean;
    begin
        Doc(A);
        Filler.ReadFrom('"old"');
        L.Add(Filler);
        B := A.SelectTokens('$[1].a', L);
        Observer.Observe('prefilled_match_result', Format(B));
        Observer.Observe('prefilled_match_list', Render(L));
        B := A.SelectTokens('$[9]', L);
        Observer.Observe('prefilled_nomatch_result', Format(B));
        Observer.Observe('prefilled_nomatch_list', Render(L));
        Observer.Expect('prefilled_match_result', 'Yes');
        Observer.Expect('prefilled_match_list', '1:2|');
        Observer.Expect('prefilled_nomatch_result', 'Yes');
        Observer.Expect('prefilled_nomatch_list', '0:');
        Observer.Verify();
    end;

    var
        Subject: JsonArray;

    [TryFunction]
    local procedure TrySelect(Path: Text; var L: List of [JsonToken]; var Selected: Boolean)
    begin
        Selected := Subject.SelectTokens(Path, L);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text)
    var
        L: List of [JsonToken];
        Selected: Boolean;
    begin
        ClearLastError();
        Observer.Observe(Name + '_noexception', Format(TrySelect(Path, L, Selected)));
        Observer.Observe(Name + '_result', Format(Selected));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '_count', Format(L.Count()));
    end;

    [Test]
    procedure SelectTokens_Array_Bad1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad1', '$[');
        Observer.Expect('bad1_noexception', 'Yes');
        Observer.Expect('bad1_result', 'No');
        Observer.Expect('bad1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad1|code', 'InvalidOperation');
        Observer.Expect('bad1_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Bad2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad2', '$.a[?(@.x');
        Observer.Expect('bad2_noexception', 'Yes');
        Observer.Expect('bad2_result', 'No');
        Observer.Expect('bad2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad2|code', 'InvalidOperation');
        Observer.Expect('bad2_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Bad3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad3', '');
        Observer.Expect('bad3_noexception', 'Yes');
        Observer.Expect('bad3_result', 'Yes');
        Observer.Expect('bad3|text', '');
        Observer.Expect('bad3|code', '');
        Observer.Expect('bad3_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Bad4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad4', 'a..[');
        Observer.Expect('bad4_noexception', 'Yes');
        Observer.Expect('bad4_result', 'No');
        Observer.Expect('bad4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad4|code', 'InvalidOperation');
        Observer.Expect('bad4_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Bad5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad5', '$.a.[');
        Observer.Expect('bad5_noexception', 'Yes');
        Observer.Expect('bad5_result', 'No');
        Observer.Expect('bad5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad5|code', 'InvalidOperation');
        Observer.Expect('bad5_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Bad6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad6', '$[?(');
        Observer.Expect('bad6_noexception', 'Yes');
        Observer.Expect('bad6_result', 'No');
        Observer.Expect('bad6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad6|code', 'InvalidOperation');
        Observer.Expect('bad6_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Array_Empty()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonToken];
        EmptyDoc: JsonArray;
    begin
        Observer.Observe('empty', Format(EmptyDoc.SelectTokens('$[*]', L)));
        Observer.Observe('empty_list', Render(L));
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty_list', '0:');
        Observer.Verify();
    end;
}

codeunit 78801 "LT S Object SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var O: JsonObject)
    begin
        O.ReadFrom('{"a":1,"list":[{"id":10},{"id":20},{"x":30}],"n":{"a":"deep","list":[{"id":40}]}}');
    end;

    local procedure Render(L: List of [JsonToken]): Text
    var
        T: JsonToken;
        R: Text;
        Part: Text;
    begin
        foreach T in L do begin
            T.WriteTo(Part);
            R += Part + '|';
        end;
        exit(Format(L.Count()) + ':' + R);
    end;

    [Test]
    procedure SelectTokens_Object()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        B: Boolean;
    begin
        Doc(O);
        B := O.SelectTokens('$.a', L);
        Observer.Observe('single_result', Format(B));
        Observer.Observe('single_list', Render(L));
        B := O.SelectTokens('$.nope', L);
        Observer.Observe('nomatch_result', Format(B));
        Observer.Observe('nomatch_list', Render(L));
        B := O.SelectTokens('$.list[*].id', L);
        Observer.Observe('wild_result', Format(B));
        Observer.Observe('wild_list', Render(L));
        B := O.SelectTokens('$..id', L);
        Observer.Observe('recursive_result', Format(B));
        Observer.Observe('recursive_list', Render(L));
        B := O.SelectTokens('$..a', L);
        Observer.Observe('recursive_a_result', Format(B));
        Observer.Observe('recursive_a_list', Render(L));
        B := O.SelectTokens('$.list[?(@.id > 10)]', L);
        Observer.Observe('filter_result', Format(B));
        Observer.Observe('filter_list', Render(L));
        B := O.SelectTokens('$.*', L);
        Observer.Observe('allprops_result', Format(B));
        Observer.Observe('allprops_count', Format(L.Count()));
        Observer.Expect('single_result', 'Yes');
        Observer.Expect('single_list', '1:1|');
        Observer.Expect('nomatch_result', 'Yes');
        Observer.Expect('nomatch_list', '0:');
        Observer.Expect('wild_result', 'Yes');
        Observer.Expect('wild_list', '2:10|20|');
        Observer.Expect('recursive_result', 'Yes');
        Observer.Expect('recursive_list', '3:10|20|40|');
        Observer.Expect('recursive_a_result', 'Yes');
        Observer.Expect('recursive_a_list', '2:1|"deep"|');
        Observer.Expect('filter_result', 'Yes');
        Observer.Expect('filter_list', '1:{"id":20}|');
        Observer.Expect('allprops_result', 'Yes');
        Observer.Expect('allprops_count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_PrefilledList()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        Filler: JsonToken;
        B: Boolean;
    begin
        Doc(O);
        Filler.ReadFrom('"old"');
        L.Add(Filler);
        B := O.SelectTokens('$.a', L);
        Observer.Observe('prefilled_match_result', Format(B));
        Observer.Observe('prefilled_match_list', Render(L));
        B := O.SelectTokens('$.nope', L);
        Observer.Observe('prefilled_nomatch_result', Format(B));
        Observer.Observe('prefilled_nomatch_list', Render(L));
        Observer.Expect('prefilled_match_result', 'Yes');
        Observer.Expect('prefilled_match_list', '1:1|');
        Observer.Expect('prefilled_nomatch_result', 'Yes');
        Observer.Expect('prefilled_nomatch_list', '0:');
        Observer.Verify();
    end;

    var
        Subject: JsonObject;

    [TryFunction]
    local procedure TrySelect(Path: Text; var L: List of [JsonToken]; var Selected: Boolean)
    begin
        Selected := Subject.SelectTokens(Path, L);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text)
    var
        L: List of [JsonToken];
        Selected: Boolean;
    begin
        ClearLastError();
        Observer.Observe(Name + '_noexception', Format(TrySelect(Path, L, Selected)));
        Observer.Observe(Name + '_result', Format(Selected));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '_count', Format(L.Count()));
    end;

    [Test]
    procedure SelectTokens_Object_Bad1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad1', '$[');
        Observer.Expect('bad1_noexception', 'Yes');
        Observer.Expect('bad1_result', 'No');
        Observer.Expect('bad1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad1|code', 'InvalidOperation');
        Observer.Expect('bad1_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Bad2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad2', '$.a[?(@.x');
        Observer.Expect('bad2_noexception', 'Yes');
        Observer.Expect('bad2_result', 'No');
        Observer.Expect('bad2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad2|code', 'InvalidOperation');
        Observer.Expect('bad2_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Bad3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad3', '');
        Observer.Expect('bad3_noexception', 'Yes');
        Observer.Expect('bad3_result', 'Yes');
        Observer.Expect('bad3|text', '');
        Observer.Expect('bad3|code', '');
        Observer.Expect('bad3_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Bad4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad4', 'a..[');
        Observer.Expect('bad4_noexception', 'Yes');
        Observer.Expect('bad4_result', 'No');
        Observer.Expect('bad4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad4|code', 'InvalidOperation');
        Observer.Expect('bad4_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Bad5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad5', '$.a.[');
        Observer.Expect('bad5_noexception', 'Yes');
        Observer.Expect('bad5_result', 'No');
        Observer.Expect('bad5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad5|code', 'InvalidOperation');
        Observer.Expect('bad5_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Bad6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc(Subject);
        Probe(Observer, 'bad6', '$[?(');
        Observer.Expect('bad6_noexception', 'Yes');
        Observer.Expect('bad6_result', 'No');
        Observer.Expect('bad6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('bad6|code', 'InvalidOperation');
        Observer.Expect('bad6_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokens_Object_Empty()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [JsonToken];
        EmptyDoc: JsonObject;
    begin
        Observer.Observe('empty', Format(EmptyDoc.SelectTokens('$.*', L)));
        Observer.Observe('empty_list', Render(L));
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty_list', '0:');
        Observer.Verify();
    end;
}
#endif
