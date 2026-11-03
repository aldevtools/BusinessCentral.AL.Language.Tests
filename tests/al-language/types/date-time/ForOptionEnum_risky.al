// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-for-statement
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73744, table 73745 and codeunit 73746
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a for loop whose variable is an Enum variable or Enum field; Enum bounds; an Integer loop with an Enum bound. The enum has a gap in its ordinals (0, 1, 5).
// Facts: passes, the member held in each round, the value after the loop, downto, a body that changes the variable
// BC versions: 29 (27 and 28 by CI)

enum 73744 "LT ForOpt Kind"
{
    Extensible = true;

    value(0; Red) { }
    value(1; Green) { }
    value(5; Blue) { }
}

table 73745 "LT ForOpt Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT ForOpt Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73746 "LT ForOpt Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure For_EnumVariable_RedToBlue()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT ForOpt Kind";
        Passes: Integer;
        Seen: Text;
    begin
        for K := K::Red to K::Blue do begin
            Passes += 1;
            Seen += Format(K) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(K));
        Observer.Expect('passes', '6');
        Observer.Expect('seen', 'Red,Green,2,3,4,Blue,');
        Observer.Expect('after', 'Blue');
        Observer.Verify();
    end;

    [Test]
    procedure For_EnumField_RedToGreen()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Enum Row";
        Passes: Integer;
        Seen: Text;
    begin
        R.DeleteAll();
        for R.Kind := R.Kind::Red to R.Kind::Green do begin
            Passes += 1;
            Seen += Format(R.Kind) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(R.Kind));
        Observer.Expect('passes', '2');
        Observer.Expect('seen', 'Red,Green,');
        Observer.Expect('after', 'Green');
        Observer.Verify();
    end;

    [Test]
    procedure For_EnumVariable_Downto()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT ForOpt Kind";
        Passes: Integer;
        Seen: Text;
    begin
        for K := K::Blue downto K::Red do begin
            Passes += 1;
            Seen += Format(K) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(K));
        Observer.Expect('passes', '6');
        Observer.Expect('seen', 'Blue,4,3,2,Green,Red,');
        Observer.Expect('after', 'Red');
        Observer.Verify();
    end;

    [Test]
    procedure For_IntegerVariable_EnumBound()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT ForOpt Kind";
        I: Integer;
        Passes: Integer;
    begin
        K := K::Blue;
        for I := 0 to K.AsInteger() do
            Passes += 1;
        Observer.Observe('passesAsInteger', Format(Passes));
        Passes := 0;
        for I := 0 to K do
            Passes += 1;
        Observer.Observe('passesDirect', Format(Passes));
        Observer.Expect('passesAsInteger', '6');
        Observer.Expect('passesDirect', '6');
        Observer.Verify();
    end;
}
