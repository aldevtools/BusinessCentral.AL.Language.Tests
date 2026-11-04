// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-for-statement
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73742 and codeunit 73743
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a for loop whose variable is an Option field of a record or an Option variable: passes, the member held in each round (Format and Format(,0,2) ordinal),
//   the value after the loop, downto, an empty range, a start in the middle, a body that changes the loop variable
// BC versions: 29 (27 and 28 by CI)

table 73742 "LT ForOpt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,C,D; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73743 "LT ForOpt Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure For_OptionField_AtoC()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
        Seen: Text;
        Ords: Text;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::A to R.Opt::C do begin
            Passes += 1;
            Seen += Format(R.Opt) + ',';
            Ords += Format(R.Opt, 0, 2) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('ordinals', Ords);
        Observer.Observe('after', Format(R.Opt));
        Observer.Observe('afterOrdinal', Format(R.Opt, 0, 2));
        Observer.Expect('passes', '3');
        Observer.Expect('seen', 'A,B,C,');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('after', 'C');
        Observer.Expect('afterOrdinal', '2');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_FullRange()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
        Seen: Text;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::A to R.Opt::D do begin
            Passes += 1;
            Seen += Format(R.Opt) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(R.Opt));
        Observer.Expect('passes', '4');
        Observer.Expect('seen', 'A,B,C,D,');
        Observer.Expect('after', 'D');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_Downto()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
        Seen: Text;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::D downto R.Opt::B do begin
            Passes += 1;
            Seen += Format(R.Opt) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(R.Opt));
        Observer.Expect('passes', '3');
        Observer.Expect('seen', 'D,C,B,');
        Observer.Expect('after', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_EmptyRange()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
    begin
        R.DeleteAll();
        R.Opt := R.Opt::D;
        for R.Opt := R.Opt::C to R.Opt::A do
            Passes += 1;
        Observer.Observe('passesUp', Format(Passes));
        Observer.Observe('afterUp', Format(R.Opt));
        Passes := 0;
        R.Opt := R.Opt::D;
        for R.Opt := R.Opt::A downto R.Opt::C do
            Passes += 1;
        Observer.Observe('passesDown', Format(Passes));
        Observer.Observe('afterDown', Format(R.Opt));
        Observer.Expect('passesUp', '0');
        Observer.Expect('afterUp', 'C');
        Observer.Expect('passesDown', '0');
        Observer.Expect('afterDown', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_SingleMember()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::B to R.Opt::B do
            Passes += 1;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('after', Format(R.Opt));
        Observer.Expect('passes', '1');
        Observer.Expect('after', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_BodyChangesVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
        Seen: Text;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::A to R.Opt::D do begin
            Passes += 1;
            Seen += Format(R.Opt) + ',';
            if R.Opt = R.Opt::A then
                R.Opt := R.Opt::B;
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(R.Opt));
        Observer.Expect('passes', '3');
        Observer.Expect('seen', 'A,C,D,');
        Observer.Expect('after', 'D');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionField_BodyJumpsToLast()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT ForOpt Row";
        Passes: Integer;
        Seen: Text;
    begin
        R.DeleteAll();
        for R.Opt := R.Opt::A to R.Opt::D do begin
            Passes += 1;
            Seen += Format(R.Opt) + ',';
            if R.Opt = R.Opt::B then
                R.Opt := R.Opt::D;
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(R.Opt));
        Observer.Expect('passes', '2');
        Observer.Expect('seen', 'A,B,');
        Observer.Expect('after', 'D');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_AtoC()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        Passes: Integer;
        Seen: Text;
        Ords: Text;
    begin
        for Opt := Opt::A to Opt::C do begin
            Passes += 1;
            Seen += Format(Opt) + ',';
            Ords += Format(Opt, 0, 2) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('ordinals', Ords);
        Observer.Observe('after', Format(Opt));
        Observer.Observe('afterOrdinal', Format(Opt, 0, 2));
        Observer.Expect('passes', '3');
        Observer.Expect('seen', 'A,B,C,');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('after', 'C');
        Observer.Expect('afterOrdinal', '2');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_Downto()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        Passes: Integer;
        Seen: Text;
    begin
        for Opt := Opt::D downto Opt::A do begin
            Passes += 1;
            Seen += Format(Opt) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(Opt));
        Observer.Expect('passes', '4');
        Observer.Expect('seen', 'D,C,B,A,');
        Observer.Expect('after', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_StartInMiddle()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        Passes: Integer;
        Seen: Text;
    begin
        for Opt := Opt::B to Opt::C do begin
            Passes += 1;
            Seen += Format(Opt) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(Opt));
        Observer.Expect('passes', '2');
        Observer.Expect('seen', 'B,C,');
        Observer.Expect('after', 'C');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_BodyChangesVariable()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        Passes: Integer;
        Seen: Text;
    begin
        for Opt := Opt::A to Opt::D do begin
            Passes += 1;
            Seen += Format(Opt) + ',';
            if Opt = Opt::A then
                Opt := Opt::C;
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(Opt));
        Observer.Expect('passes', '2');
        Observer.Expect('seen', 'A,D,');
        Observer.Expect('after', 'D');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_BoundsFromVariables()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        FromOpt: Option A,B,C,D;
        ToOpt: Option A,B,C,D;
        Passes: Integer;
        Seen: Text;
    begin
        FromOpt := FromOpt::B;
        ToOpt := ToOpt::D;
        for Opt := FromOpt to ToOpt do begin
            Passes += 1;
            Seen += Format(Opt) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('seen', Seen);
        Observer.Observe('after', Format(Opt));
        Observer.Expect('passes', '3');
        Observer.Expect('seen', 'B,C,D,');
        Observer.Expect('after', 'D');
        Observer.Verify();
    end;

    [Test]
    procedure For_OptionVariable_IntegerLoopWithOptionBound()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option A,B,C,D;
        I: Integer;
        Passes: Integer;
    begin
        Opt := Opt::C;
        for I := 0 to Opt do
            Passes += 1;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('afterI', Format(I));
        Observer.Expect('passes', '3');
        Observer.Expect('afterI', '2');
        Observer.Verify();
    end;
}
