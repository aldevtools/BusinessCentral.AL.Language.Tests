// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in Y82Objects.al
// Probe (runner issues 6796 and 6797): Insert of values that are not valid for an Integer, BigInteger or Variant Code field (primary key and secondary key).
// BC versions: 27.5, 28.5, 29.0
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
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkInt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94301, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94301, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, 'ABC'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkBig_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94302, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94302, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, 'ABC'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '007'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '0'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '-5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '1.5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '12A'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, ' 12'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '3000000000'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '1E3'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, '+5'));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure PkVnt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94303, 1, 0, ''));
        Observer.Observe('rows', H.Dump(94303, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '007'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '0'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '-5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '1.5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '12A'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, ' 12'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '3000000000'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '1E3'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, '+5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFInt_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 3, 1, ''));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Abc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, 'ABC'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_LeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '007'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '0'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '-5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '1.5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Digit_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '12A'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Leading_Space()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, ' 12'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Over_Int32()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '3000000000'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Over_Int64()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '9223372036854775808'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Exponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '1E3'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Plus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, '+5'));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure SecFBig_Insert_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        H.Wipe();
        Observer.Observe('insert', H.Ins(94305, 4, 1, ''));
        Observer.Observe('rows', H.Dump(94305, 1, 1, true));
        Observer.Finish();
    end;


}
