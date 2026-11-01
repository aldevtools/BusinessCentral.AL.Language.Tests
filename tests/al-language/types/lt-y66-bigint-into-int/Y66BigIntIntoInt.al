// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93401, codeunits 93405 and 93406
// Probe (al-runner issue 6660, writer Y66): the type a value has after a BigInteger expression is stored in an Integer (a var parameter, a
// local, a global, a record field, an array element, a by-value parameter, an exit value of a procedure returning Integer, +=), seen through a
// Variant (IsInteger, IsBigInteger, IsDecimal, IsDuration) and through Format(V, 0, 9); the neighbours: Decimal and Duration targets, a
// BigInteger target of an Integer expression, and expressions assigned to a Variant directly (BigInteger div Integer, Duration div Integer,
// Integer div Integer, BigInteger literal).
// Values (not the type) of BigInteger into Integer, with overflow: types/lt-y31-conversion-matrix/Y31ConvCv.al BigInteger_To_Integer.
// The reporter's Library Assert is not a dependency of this app; its type check reads the same IsInteger/IsBigInteger kinds.
// BC versions: 27, 28, 29

table 93401 "LT Y66 BI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Days; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93406 "LT Y66 BI Grace Period"
{
    procedure GetDaysLeft(var DaysLeft: Integer)
    var
        MsPerDay: Integer;
    begin
        MsPerDay := 86400000;
        DaysLeft := MyRemainingMs() div MsPerDay;
    end;

    procedure GetDaysLeftMinus(var DaysLeft: Integer)
    var
        MsPerDay: Integer;
    begin
        MsPerDay := 86400000;
        DaysLeft := 3;
        DaysLeft := (MyRemainingMs() div MsPerDay) - DaysLeft;
    end;

    procedure DaysAsInteger(): Integer
    begin
        exit(MyRemainingMs() div 86400000);
    end;

    procedure MyRemainingMs(): BigInteger
    begin
        exit(86400000L);
    end;
}

codeunit 93405 "LT Y66 BigInt Into Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        GlobalInt: Integer;

    [Test]
    procedure Y66_BigIntIntoInt_ReporterShape()
    var
        MyGracePeriod: Codeunit "LT Y66 BI Grace Period";
        DaysLeft: Integer;
    begin
        MyGracePeriod.GetDaysLeft(DaysLeft);
        Observer.Observe('var param', Kind(DaysLeft));
        MyGracePeriod.GetDaysLeftMinus(DaysLeft);
        Observer.Observe('var param minus', Kind(DaysLeft));
        Observer.Observe('exit Integer', Kind(MyGracePeriod.DaysAsInteger()));
        Observer.Expect('var param', 'Integer 1');
        Observer.Expect('var param minus', 'Integer -2');
        Observer.Expect('exit Integer', 'Integer 1');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_BigIntIntoInt_Targets()
    var
        MyGracePeriod: Codeunit "LT Y66 BI Grace Period";
        Row: Record "LT Y66 BI Row";
        LocalInt: Integer;
        Ints: array[2] of Integer;
        Big: BigInteger;
        MsPerDay: Integer;
        Dur: Duration;
    begin
        MsPerDay := 86400000;
        LocalInt := MyGracePeriod.MyRemainingMs() div MsPerDay;
        Observer.Observe('local', Kind(LocalInt));
        GlobalInt := MyGracePeriod.MyRemainingMs() div MsPerDay;
        Observer.Observe('global', Kind(GlobalInt));
        Row.Days := MyGracePeriod.MyRemainingMs() div MsPerDay;
        Observer.Observe('field', Kind(Row.Days));
        Ints[2] := MyGracePeriod.MyRemainingMs() div MsPerDay;
        Observer.Observe('array element', Kind(Ints[2]));
        Big := 5;
        LocalInt := Big;
        Observer.Observe('BigInteger variable', Kind(LocalInt));
        LocalInt := 7L;
        Observer.Observe('BigInteger literal', Kind(LocalInt));
        LocalInt := 1;
        LocalInt += MyGracePeriod.MyRemainingMs() div MsPerDay;
        Observer.Observe('compound add', Kind(LocalInt));
        LocalInt := Big * 2;
        Observer.Observe('BigInteger times Integer', Kind(LocalInt));
        Observer.Observe('by-value Integer parameter', ByValue(MyGracePeriod.MyRemainingMs() div MsPerDay));
        Dur := 60000;
        LocalInt := Dur div 1000;
        Observer.Observe('Duration div Integer into Integer', Kind(LocalInt));
        Observer.Expect('local', 'Integer 1');
        Observer.Expect('global', 'Integer 1');
        Observer.Expect('field', 'Integer 1');
        Observer.Expect('array element', 'Integer 1');
        Observer.Expect('BigInteger variable', 'Integer 5');
        Observer.Expect('BigInteger literal', 'Integer 7');
        Observer.Expect('compound add', 'Integer 2');
        Observer.Expect('BigInteger times Integer', 'Integer 10');
        Observer.Expect('by-value Integer parameter', 'Integer 1');
        Observer.Expect('Duration div Integer into Integer', 'Integer 60');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_BigIntIntoInt_Neighbours()
    var
        MyGracePeriod: Codeunit "LT Y66 BI Grace Period";
        Dec: Decimal;
        Big: BigInteger;
        Dur: Duration;
        IntA: Integer;
        IntB: Integer;
        V: Variant;
    begin
        Dec := MyGracePeriod.MyRemainingMs() div 86400000;
        Observer.Observe('into Decimal', Kind(Dec));
        IntA := 10;
        IntB := 3;
        Big := IntA div IntB;
        Observer.Observe('Integer expression into BigInteger', Kind(Big));
        Dur := MyGracePeriod.MyRemainingMs() div 1000;
        Observer.Observe('into Duration', Kind(Dur));
        V := MyGracePeriod.MyRemainingMs() div IntB;
        Observer.Observe('Variant := BigInteger div Integer', Kind(V));
        V := IntA div IntB;
        Observer.Observe('Variant := Integer div Integer', Kind(V));
        Dur := 60000;
        V := Dur div IntB;
        Observer.Observe('Variant := Duration div Integer', Kind(V));
        V := Dur + IntA;
        Observer.Observe('Variant := Duration + Integer', Kind(V));
        V := 5L;
        Observer.Observe('Variant := 5L', Kind(V));
        V := IntA + Big;
        Observer.Observe('Variant := Integer + BigInteger', Kind(V));
        V := IntA * 1.0;
        Observer.Observe('Variant := Integer * Decimal', Kind(V));
        Observer.Expect('into Decimal', 'Decimal 1');
        Observer.Expect('Integer expression into BigInteger', 'BigInteger 3');
        Observer.Expect('into Duration', 'Duration P0DT0H1M26.4S');
        Observer.Expect('Variant := BigInteger div Integer', 'BigInteger 28800000');
        Observer.Expect('Variant := Integer div Integer', 'Integer 3');
        Observer.Expect('Variant := Duration div Integer', 'Decimal 20000');
        Observer.Expect('Variant := Duration + Integer', 'BigInteger 60010');
        Observer.Expect('Variant := 5L', 'BigInteger 5');
        Observer.Expect('Variant := Integer + BigInteger', 'BigInteger 13');
        Observer.Expect('Variant := Integer * Decimal', 'Decimal 10');
        Observer.Verify();
    end;

    local procedure ByValue(Value: Integer): Text
    begin
        exit(Kind(Value));
    end;

    local procedure Kind(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsInteger then
            R += 'Integer ';
        if V.IsBigInteger then
            R += 'BigInteger ';
        if V.IsDecimal then
            R += 'Decimal ';
        if V.IsDuration then
            R += 'Duration ';
        exit(R + Format(V, 0, 9));
    end;
}
