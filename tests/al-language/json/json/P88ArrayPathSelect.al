// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74407
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonArray Path and SelectTokens
// BC versions: 29

codeunit 74407 "LT P88 Array Path Select"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Doc(var A: JsonArray)
    begin
        A.ReadFrom('[{"a":[1,2,{"b":5}],"c":"x"},7,[8,9],{"a":"top"}]');
    end;

    [Test]
    procedure Path_OfElements()
    var
        A: JsonArray;
        T: JsonToken;
        Inner: JsonToken;
    begin
        Doc(A);
        Observer.Observe('path_array_itself', A.AsToken().Path());
        A.Get(0, T);
        Observer.Observe('path_0', T.Path());
        A.Get(1, T);
        Observer.Observe('path_1', T.Path());
        A.Get(2, T);
        Observer.Observe('path_2', T.Path());
        T.AsArray().Get(1, Inner);
        Observer.Observe('path_2_1', Inner.Path());
        A.Get(0, T);
        T.AsObject().Get('a', Inner);
        Observer.Observe('path_0_a', Inner.Path());
        Inner.AsArray().Get(2, T);
        Observer.Observe('path_0_a_2', T.Path());
        T.AsObject().Get('b', Inner);
        Observer.Observe('path_0_a_2_b', Inner.Path());
        Observer.Expect('path_array_itself', '');
        Observer.Expect('path_0', '[0]');
        Observer.Expect('path_1', '[1]');
        Observer.Expect('path_2', '[2]');
        Observer.Expect('path_2_1', '[2][1]');
        Observer.Expect('path_0_a', '[0].a');
        Observer.Expect('path_0_a_2', '[0].a[2]');
        Observer.Expect('path_0_a_2_b', '[0].a[2].b');
        Observer.Verify();
    end;

    [Test]
    procedure Path_Detached()
    var
        A: JsonArray;
        Fresh: JsonArray;
        T: JsonToken;
    begin
        Observer.Observe('path_empty_array', Fresh.AsToken().Path());
        A.Add(1);
        A.Get(0, T);
        Fresh.Add(T);
        Fresh.Get(0, T);
        Observer.Observe('path_copied_into_other', T.Path());
        Observer.Observe('path_source_unchanged', Fresh.AsToken().Path());
        Observer.Expect('path_empty_array', '');
        Observer.Expect('path_copied_into_other', '[0]');
        Observer.Expect('path_source_unchanged', '');
        Observer.Verify();
    end;

}
