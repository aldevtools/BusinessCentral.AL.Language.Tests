// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73896
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A Guid assigned to a Text or Code" (Tests-SCM round 2)
// Facts: T := G for Text, Text[40], Text[10], Code[40], Code[10], Dictionary of [Text, Text].Add('k', G), Evaluate(T, G), Format(G), List of [Text].Add(G), Text concatenation with a Guid
// BC versions: 29 (27 and 28 by CI)

codeunit 73896 "LT PnF Guid To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryToText40(G: Guid; var R: Text)
    var
        T: Text[40];
    begin
        T := G;
        R := T;
    end;

    [TryFunction]
    local procedure TryToText38(G: Guid; var R: Text)
    var
        T: Text[38];
    begin
        T := G;
        R := T;
    end;

    [TryFunction]
    local procedure TryToCode40(G: Guid; var R: Text)
    var
        C: Code[40];
    begin
        C := G;
        R := C;
    end;

    [TryFunction]
    local procedure TryToUnboundedText(G: Guid; var R: Text)
    var
        T: Text;
    begin
        T := G;
        R := T;
    end;

    [TryFunction]
    local procedure TryEvaluate(G: Guid; var R: Text)
    var
        T: Text[50];
    begin
        Evaluate(T, G);
        R := T;
    end;

    [TryFunction]
    local procedure TryDictionary(G: Guid; var R: Text)
    var
        Dict: Dictionary of [Text, Text];
    begin
        Dict.Add('k', G);
        R := Dict.Get('k');
    end;

    [TryFunction]
    local procedure TryList(G: Guid; var R: Text)
    var
        L: List of [Text];
    begin
        L.Add(G);
        R := L.Get(1);
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GuidToText_Assignments()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        R: Text;
        Ok: Boolean;
    begin
        Evaluate(G, '{12345678-abcd-4ef0-9a1b-0123456789ab}');
        Ok := TryToUnboundedText(G, R);
        Observer.Observe('text', Res(Ok, R));
        Ok := TryToText40(G, R);
        Observer.Observe('text40', Res(Ok, R));
        Ok := TryToText38(G, R);
        Observer.Observe('text38', Res(Ok, R));
        Ok := TryToCode40(G, R);
        Observer.Observe('code40', Res(Ok, R));
        Observer.Observe('format', Format(G));
        Observer.Expect('text', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('text40', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('text38', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('code40', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('format', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Verify();
    end;

    [Test]
    procedure GuidToText_Collections_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        R: Text;
        Ok: Boolean;
    begin
        Evaluate(G, '{12345678-abcd-4ef0-9a1b-0123456789ab}');
        Ok := TryDictionary(G, R);
        Observer.Observe('dictionary', Res(Ok, R));
        Ok := TryList(G, R);
        Observer.Observe('list', Res(Ok, R));
        Ok := TryEvaluate(G, R);
        Observer.Observe('evaluate', Res(Ok, R));
        Observer.Observe('concat', 'id=' + Format(G));
        Observer.Expect('dictionary', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('list', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('evaluate', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('concat', 'id={12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Verify();
    end;

    [Test]
    procedure GuidToText_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryToUnboundedText(G, R);
        Observer.Observe('text', Res(Ok, R));
        Ok := TryToText40(G, R);
        Observer.Observe('text40', Res(Ok, R));
        Ok := TryToCode40(G, R);
        Observer.Observe('code40', Res(Ok, R));
        Ok := TryDictionary(G, R);
        Observer.Observe('dictionary', Res(Ok, R));
        Observer.Expect('text', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('text40', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('code40', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('dictionary', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
