// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (P93); the lead measures the facts on a local BC 29 and turns them into assertions.
// Facts: Guid.ToText with and without delimiters, CreateGuid shape
// BC versions: 29 (27 and 28 by CI)

codeunit 70322 "LT P93 Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(T: Text): Text
    var
        R: Text;
        i: Integer;
    begin
        R := 'len=' + Format(StrLen(T));
        R += ' first=' + CopyStr(T, 1, 1);
        R += ' last=' + CopyStr(T, StrLen(T), 1);
        for i := 1 to StrLen(T) do
            if not (T[i] in ['0' .. '9', 'a' .. 'f', 'A' .. 'F']) then
                R += ' [' + Format(i) + ']=' + CopyStr(T, i, 1);
        exit(R);
    end;

    [Test]
    procedure ToText_FixedGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Evaluate(G, '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Observe('tt', G.ToText());
        Observer.Observe('tt-true', G.ToText(true));
        Observer.Observe('tt-false', G.ToText(false));
        Observer.Observe('format', Format(G));
        Observer.Observe('format-0', Format(G, 0, 0));
        Observer.Observe('format-1', Format(G, 0, 1));
        Observer.Observe('format-2', Format(G, 0, 2));
        Observer.Observe('format-3', Format(G, 0, 3));
        Observer.Observe('format-9', Format(G, 0, 9));
        Observer.Observe('format-4', Format(G, 0, 4));
        Observer.Observe('lowercase-in', Format(Lowercase(G.ToText())));
        Observer.Expect('tt', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('tt-true', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('tt-false', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format-0', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format-1', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format-2', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format-3', 'E6C0BDA35B0A4A7E9A5E0123456789AB');
        Observer.Expect('format-9', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('format-4', 'E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB');
        Observer.Expect('lowercase-in', '{e6c0bda3-5b0a-4a7e-9a5e-0123456789ab}');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Observer.Observe('tt', G.ToText());
        Observer.Observe('tt-true', G.ToText(true));
        Observer.Observe('tt-false', G.ToText(false));
        Observer.Observe('format', Format(G));
        Observer.Observe('format-9', Format(G, 0, 9));
        Observer.Observe('isnull', Format(IsNullGuid(G)));
        Observer.Expect('tt', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('tt-true', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('tt-false', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('format', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('format-9', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_ParseForms()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
    begin
        Evaluate(G, 'e6c0bda3-5b0a-4a7e-9a5e-0123456789ab');
        Observer.Observe('lower-no-braces', G.ToText());
        Evaluate(G2, '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Observe('equal', Format(G = G2));
        Observer.Observe('tt-equal', Format(G.ToText() = G2.ToText()));
        Observer.Observe('tt-false-eq-true', Format(G.ToText(false) = G.ToText(true)));
        Observer.Observe('tt-false-eq-tt', Format(G.ToText(false) = G.ToText()));
        Observer.Observe('tt-true-eq-tt', Format(G.ToText(true) = G.ToText()));
        Observer.Observe('rt', Format(Evaluate(G2, G.ToText(false))));
        Observer.Observe('rt-eq', Format(G2 = G));
        Observer.Observe('rt-true', Format(Evaluate(G2, G.ToText(true))));
        Observer.Expect('lower-no-braces', '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Expect('equal', 'Yes');
        Observer.Expect('tt-equal', 'Yes');
        Observer.Expect('tt-false-eq-true', 'Yes');
        Observer.Expect('tt-false-eq-tt', 'Yes');
        Observer.Expect('tt-true-eq-tt', 'Yes');
        Observer.Expect('rt', 'Yes');
        Observer.Expect('rt-eq', 'Yes');
        Observer.Expect('rt-true', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CreateGuid_Shape()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        H: Guid;
    begin
        G := CreateGuid();
        H := CreateGuid();
        Observer.Observe('notnull', Format(not IsNullGuid(G)));
        Observer.Observe('distinct', Format(G <> H));
        Observer.Observe('tt-shape', Shape(G.ToText()));
        Observer.Observe('tt-true-shape', Shape(G.ToText(true)));
        Observer.Observe('tt-false-shape', Shape(G.ToText(false)));
        Observer.Observe('format-shape', Shape(Format(G)));
        Observer.Observe('format-9-shape', Shape(Format(G, 0, 9)));
        Observer.Observe('format-eq-tt', Format(Format(G) = G.ToText()));
        Observer.Observe('format-9-eq-tt-true', Format(Format(G, 0, 9) = G.ToText(true)));
        Observer.Observe('tt-two-differ', Format(G.ToText() <> H.ToText()));
        Observer.Expect('notnull', 'Yes');
        Observer.Expect('distinct', 'Yes');
        Observer.Expect('tt-shape', 'len=38 first={ last=} [1]={ [10]=- [15]=- [20]=- [25]=- [38]=}');
        Observer.Expect('tt-true-shape', 'len=38 first={ last=} [1]={ [10]=- [15]=- [20]=- [25]=- [38]=}');
        Observer.Expect('tt-false-shape', 'len=38 first={ last=} [1]={ [10]=- [15]=- [20]=- [25]=- [38]=}');
        Observer.Expect('format-shape', 'len=38 first={ last=} [1]={ [10]=- [15]=- [20]=- [25]=- [38]=}');
        Observer.Expect('format-9-shape', 'len=38 first={ last=} [1]={ [10]=- [15]=- [20]=- [25]=- [38]=}');
        Observer.Expect('format-eq-tt', 'Yes');
        Observer.Expect('format-9-eq-tt-true', 'Yes');
        Observer.Expect('tt-two-differ', 'Yes');
        Observer.Verify();
    end;
}
