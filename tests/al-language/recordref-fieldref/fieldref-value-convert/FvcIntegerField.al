// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value assigned to a variable of another type (runner issue 8662: an Integer field value assigned to a DateTime).
//   Each cell is run twice: directly (R := FR.Value) and through a Variant (V := FR.Value; R := V).
//   Source fields of the type named in the codeunit; targets DateTime, Date, Time, Duration, Decimal, Boolean, Code, Text, Integer, BigInteger.
//   A cell that BC refuses records the error text and code.
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75981 "FVC Integer Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IntField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDateTime(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDateTime(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDateTime(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDateTime(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDateTime(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDateTime(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDateTime(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDateTime(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDateTime(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDateTime(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDateTime(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDateTime(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_DateTime_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_DateTime_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_DateTime_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Date()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Date;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDate(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDate(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDate(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDate(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDate(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDate(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDate(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDate(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDate(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDate(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDate(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDate(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Date_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Date_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Date_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Time()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Time;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToTime(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaTime(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToTime(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaTime(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToTime(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaTime(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToTime(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaTime(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToTime(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaTime(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToTime(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaTime(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Time_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Time_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Time_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure IntField_To_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Duration;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDuration(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDuration(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDuration(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDuration(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDuration(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDuration(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDuration(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDuration(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDuration(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDuration(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDuration(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDuration(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDecimal(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDecimal(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDecimal(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDecimal(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDecimal(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDecimal(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDecimal(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDecimal(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDecimal(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDecimal(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDecimal(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDecimal(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Boolean;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToBoolean(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaBoolean(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToBoolean(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaBoolean(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToBoolean(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaBoolean(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToBoolean(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaBoolean(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToBoolean(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaBoolean(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToBoolean(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaBoolean(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Code20()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Code[20];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToCode20(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaCode20(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToCode20(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaCode20(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToCode20(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaCode20(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToCode20(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaCode20(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToCode20(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaCode20(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToCode20(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaCode20(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToText50(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaText50(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToText50(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaText50(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToText50(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaText50(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToText50(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaText50(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToText50(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaText50(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToText50(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaText50(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure IntField_To_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: BigInteger;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToBigInteger(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaBigInteger(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToBigInteger(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaBigInteger(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToBigInteger(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaBigInteger(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToBigInteger(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaBigInteger(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToBigInteger(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaBigInteger(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToBigInteger(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaBigInteger(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Finish();
    end;

    [Test]
    procedure PrimaryKeyViaFieldIndex_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        RR.GetTable(Rec);
        FR := RR.FieldIndex(1);
        Observer.Observe('type', Format(FR.Type));
        if ToDateTime(FR, R) then Observer.Observe('pk', Format(R, 0, 9)) else Observer.ObserveError('pk');
        RR.Close();
        RR.Open(Database::"FVC Source");
        RR.FindFirst();
        FR := RR.FieldIndex(1);
        if ToDateTime(FR, R) then Observer.Observe('pk reread', Format(R, 0, 9)) else Observer.ObserveError('pk reread');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure ToDateTime(var FR: FieldRef; var R: DateTime)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDateTime(var FR: FieldRef; var R: DateTime)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDate(var FR: FieldRef; var R: Date)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDate(var FR: FieldRef; var R: Date)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToTime(var FR: FieldRef; var R: Time)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaTime(var FR: FieldRef; var R: Time)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDuration(var FR: FieldRef; var R: Duration)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDuration(var FR: FieldRef; var R: Duration)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDecimal(var FR: FieldRef; var R: Decimal)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDecimal(var FR: FieldRef; var R: Decimal)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToBoolean(var FR: FieldRef; var R: Boolean)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaBoolean(var FR: FieldRef; var R: Boolean)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToCode20(var FR: FieldRef; var R: Code[20])
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaCode20(var FR: FieldRef; var R: Code[20])
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToText50(var FR: FieldRef; var R: Text[50])
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaText50(var FR: FieldRef; var R: Text[50])
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToInteger(var FR: FieldRef; var R: Integer)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaInteger(var FR: FieldRef; var R: Integer)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToBigInteger(var FR: FieldRef; var R: BigInteger)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaBigInteger(var FR: FieldRef; var R: BigInteger)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
}
