// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in Y82Objects.al
// Probe (runner issues 6796 and 6797): Insert of values that are not valid for an Integer, BigInteger or Variant Code field (primary key and secondary key).
// BC versions: 27.5, 28.5, 29.0 (values observed on the Linux CI containers; Windows pending)
codeunit 94311 "LT Y82 Insert Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        H: Codeunit "LT Y82 Helper";

    [Test]
    procedure PkInt_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, 'ABC'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''ABC''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''007''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''0''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''-5''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''1.5''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''12A''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '12');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''3000000000''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[StringLengthExceeded]: The length of the string is 19, but it must be less than or equal to 10 characters. Value: 9223372036854775808');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkInt table contains a value that is not valid in an integer Code field:\\K=''1E3''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure PkInt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, 'ABC'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''ABC''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''007''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''0''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''-5''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''1.5''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''12A''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '12');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '3000000000');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[StringLengthExceeded]: The length of the string is 19, but it must be less than or equal to 10 characters. Value: 9223372036854775808');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 PkBig table contains a value that is not valid in an integer Code field:\\K=''1E3''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '5');
        Observer.Verify();
    end;

    [Test]
    procedure PkBig_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, 'ABC'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '7');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '-5');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1.5');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '12A');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '12');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '3000000000');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ERR[StringLengthExceeded]: The length of the string is 19, but it must be less than or equal to 10 characters. Value: 9223372036854775808');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1E3');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '+5');
        Observer.Verify();
    end;

    [Test]
    procedure PkVnt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '007'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '0'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '-5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '1.5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '12A'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, ' 12'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '3000000000'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[StringLengthExceeded]: The length of the string is 19, but it must be less than or equal to 10 characters. Value: 9223372036854775808');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '1E3'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '+5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFInt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, ''));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '007'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '0'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadCSideCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '-5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '1.5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '12A'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, ' 12'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '3000000000'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[StringLengthExceeded]: The length of the string is 19, but it must be less than or equal to 10 characters. Value: 9223372036854775808');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '1E3'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ERR[NDBCS:BadSqlIntCodeData]: The LT Y82 Sec table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('rows', '(none)');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '+5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecFBig_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, ''));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Expect('insert', 'ok');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;


}
