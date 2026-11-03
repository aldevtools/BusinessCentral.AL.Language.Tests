// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74872-74876, enum 74872, codeunits 74891
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Evaluate(RecordId, Format(RecordId)) for composite keys (Code+Code, Enum+Code, Integer+Code+Code, Date+Code), a key value that holds a comma and a quote,
//   a text with too few and too many key values, and a bare table name. Evaluate into a RecordId that is already set, when the text is valid, invalid or empty:
//   is the old value kept or cleared (return value used and result left unused inside a Codeunit.Run wrapper). Settles the assumption evaluate-recordid-composite-key.
// BC versions: all (CI)

enum 74872 "LT EVR Kind"
{
    Extensible = true;

    value(0; Alpha) { }
    value(1; Beta) { }
}

table 74872 "LT EVR CodeCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Code[10]) { }
    }

    keys { key(PK; A, B) { Clustered = true; } }
}

table 74873 "LT EVR EnumCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Kind; Enum "LT EVR Kind") { }
        field(2; B; Code[10]) { }
    }

    keys { key(PK; Kind, B) { Clustered = true; } }
}

table 74874 "LT EVR IntCodeCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; N; Integer) { }
        field(2; A; Code[10]) { }
        field(3; B; Code[10]) { }
    }

    keys { key(PK; N, A, B) { Clustered = true; } }
}

table 74875 "LT EVR DateCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; D; Date) { }
        field(2; B; Code[10]) { }
    }

    keys { key(PK; D, B) { Clustered = true; } }
}

table 74876 "LT EVR Single"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[20]) { }
    }

    keys { key(PK; A) { Clustered = true; } }
}

codeunit 74890 "LT EVR Evaluator"
{
    var
        Text2: Text;
        Rid: RecordId;
        Ok: Boolean;
        Mode: Integer;

    procedure Setup(NewMode: Integer; NewText: Text; Start: RecordId)
    begin
        Mode := NewMode;
        Text2 := NewText;
        Rid := Start;
    end;

    procedure Result(): RecordId
    begin
        exit(Rid);
    end;

    procedure Returned(): Boolean
    begin
        exit(Ok);
    end;

    trigger OnRun()
    begin
        if Mode = 1 then
            Ok := Evaluate(Rid, Text2)
        else begin
            Evaluate(Rid, Text2);
            Ok := true;
        end;
    end;
}

codeunit 74891 "LT EVR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RidOf(var RR: RecordRef): RecordId
    begin
        exit(RR.RecordId());
    end;

    local procedure RoundTrip(var Observer: Codeunit "Probe Observer"; Tag: Text; Source: RecordId)
    var
        Back: RecordId;
        Txt: Text;
        Ok: Boolean;
    begin
        Txt := Format(Source);
        Observer.Observe(Tag + 'Text', Txt);
        Ok := Evaluate(Back, Txt);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + 'Err')
        else begin
            Observer.Observe(Tag + 'Back', Format(Back));
            Observer.Observe(Tag + 'Equal', Format(Back = Source));
        end;
    end;

    local procedure Eval(var Observer: Codeunit "Probe Observer"; Tag: Text; Txt: Text)
    var
        Back: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Back, Txt);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + 'Err')
        else
            Observer.Observe(Tag + 'Back', Format(Back));
    end;

    [Test]
    procedure RoundTrip_CodeCode()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR CodeCode";
        RR: RecordRef;
    begin
        T.A := 'AA';
        T.B := 'BB';
        RR.GetTable(T);
        RoundTrip(Observer, 'cc', RidOf(RR));
        T.A := '';
        T.B := 'BB';
        RR.GetTable(T);
        RoundTrip(Observer, 'ccBlankA', RidOf(RR));
        T.A := 'AA';
        T.B := '';
        RR.GetTable(T);
        RoundTrip(Observer, 'ccBlankB', RidOf(RR));
        Observer.Expect('ccText', 'LT EVR CodeCode: AA,BB');
        Observer.Expect('ccOk', 'Yes');
        Observer.Expect('ccBack', 'LT EVR CodeCode: AA,BB');
        Observer.Expect('ccEqual', 'Yes');
        Observer.Expect('ccBlankAText', 'LT EVR CodeCode: "",BB');
        Observer.Expect('ccBlankAOk', 'Yes');
        Observer.Expect('ccBlankABack', 'LT EVR CodeCode: "",BB');
        Observer.Expect('ccBlankAEqual', 'Yes');
        Observer.Expect('ccBlankBText', 'LT EVR CodeCode: AA,""');
        Observer.Expect('ccBlankBOk', 'Yes');
        Observer.Expect('ccBlankBBack', 'LT EVR CodeCode: AA,""');
        Observer.Expect('ccBlankBEqual', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_EnumCode()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR EnumCode";
        RR: RecordRef;
    begin
        T.Kind := T.Kind::Beta;
        T.B := 'BB';
        RR.GetTable(T);
        RoundTrip(Observer, 'ec', RidOf(RR));
        T.Kind := T.Kind::Alpha;
        RR.GetTable(T);
        RoundTrip(Observer, 'ecAlpha', RidOf(RR));
        Observer.Expect('ecText', 'LT EVR EnumCode: Beta,BB');
        Observer.Expect('ecOk', 'Yes');
        Observer.Expect('ecBack', 'LT EVR EnumCode: Beta,BB');
        Observer.Expect('ecEqual', 'Yes');
        Observer.Expect('ecAlphaText', 'LT EVR EnumCode: Alpha,BB');
        Observer.Expect('ecAlphaOk', 'Yes');
        Observer.Expect('ecAlphaBack', 'LT EVR EnumCode: Alpha,BB');
        Observer.Expect('ecAlphaEqual', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_IntCodeCode()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR IntCodeCode";
        RR: RecordRef;
    begin
        T.N := 42;
        T.A := 'AA';
        T.B := 'BB';
        RR.GetTable(T);
        RoundTrip(Observer, 'icc', RidOf(RR));
        T.N := -7;
        RR.GetTable(T);
        RoundTrip(Observer, 'iccNegative', RidOf(RR));
        Observer.Expect('iccText', 'LT EVR IntCodeCode: 42,AA,BB');
        Observer.Expect('iccOk', 'Yes');
        Observer.Expect('iccBack', 'LT EVR IntCodeCode: 42,AA,BB');
        Observer.Expect('iccEqual', 'Yes');
        Observer.Expect('iccNegativeText', 'LT EVR IntCodeCode: -7,AA,BB');
        Observer.Expect('iccNegativeOk', 'Yes');
        Observer.Expect('iccNegativeBack', 'LT EVR IntCodeCode: -7,AA,BB');
        Observer.Expect('iccNegativeEqual', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_DateCode()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR DateCode";
        RR: RecordRef;
    begin
        T.D := DMY2Date(5, 3, 2024);
        T.B := 'BB';
        RR.GetTable(T);
        RoundTrip(Observer, 'dc', RidOf(RR));
        T.D := 0D;
        RR.GetTable(T);
        RoundTrip(Observer, 'dcBlank', RidOf(RR));
        Observer.Expect('dcText', 'LT EVR DateCode: 03/05/24,BB');
        Observer.Expect('dcOk', 'Yes');
        Observer.Expect('dcBack', 'LT EVR DateCode: 03/05/24,BB');
        Observer.Expect('dcEqual', 'Yes');
        Observer.Expect('dcBlankText', 'LT EVR DateCode: "",BB');
        Observer.Expect('dcBlankOk', 'Yes');
        Observer.Expect('dcBlankBack', 'LT EVR DateCode: "",BB');
        Observer.Expect('dcBlankEqual', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RoundTrip_KeyValueWithComma()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR CodeCode";
        S: Record "LT EVR Single";
        RR: RecordRef;
    begin
        T.A := 'X,Y';
        T.B := 'Z';
        RR.GetTable(T);
        RoundTrip(Observer, 'comma', RidOf(RR));
        T.A := 'X';
        T.B := 'Y,Z';
        RR.GetTable(T);
        RoundTrip(Observer, 'commaSecond', RidOf(RR));
        S.A := 'a,b,c';
        RR.GetTable(S);
        RoundTrip(Observer, 'commaSingle', RidOf(RR));
        S.A := 'it''s';
        RR.GetTable(S);
        RoundTrip(Observer, 'quote', RidOf(RR));
        S.A := '"q"';
        RR.GetTable(S);
        RoundTrip(Observer, 'dquote', RidOf(RR));
        Observer.Expect('commaText', 'LT EVR CodeCode: "X,Y",Z');
        Observer.Expect('commaOk', 'Yes');
        Observer.Expect('commaBack', 'LT EVR CodeCode: "X,Y",Z');
        Observer.Expect('commaEqual', 'Yes');
        Observer.Expect('commaSecondText', 'LT EVR CodeCode: X,"Y,Z"');
        Observer.Expect('commaSecondOk', 'Yes');
        Observer.Expect('commaSecondBack', 'LT EVR CodeCode: X,"Y,Z"');
        Observer.Expect('commaSecondEqual', 'Yes');
        Observer.Expect('commaSingleText', 'LT EVR Single: "A,B,C"');
        Observer.Expect('commaSingleOk', 'Yes');
        Observer.Expect('commaSingleBack', 'LT EVR Single: "A,B,C"');
        Observer.Expect('commaSingleEqual', 'Yes');
        Observer.Expect('quoteText', 'LT EVR Single: IT''S');
        Observer.Expect('quoteOk', 'Yes');
        Observer.Expect('quoteBack', 'LT EVR Single: IT''S');
        Observer.Expect('quoteEqual', 'Yes');
        Observer.Expect('dquoteText', 'LT EVR Single: """Q"""');
        Observer.Expect('dquoteOk', 'Yes');
        Observer.Expect('dquoteBack', 'LT EVR Single: """Q"""');
        Observer.Expect('dquoteEqual', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_WrongNumberOfValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Eval(Observer, 'exact', 'LT EVR CodeCode: A,B');
        Eval(Observer, 'tooFew', 'LT EVR CodeCode: A');
        Eval(Observer, 'tooMany', 'LT EVR CodeCode: A,B,C');
        Eval(Observer, 'noValues', 'LT EVR CodeCode: ');
        Eval(Observer, 'noColon', 'LT EVR CodeCode');
        Eval(Observer, 'tooFew3', 'LT EVR IntCodeCode: 1,A');
        Eval(Observer, 'tooMany1', 'LT EVR Single: A,B');
        Eval(Observer, 'badInteger', 'LT EVR IntCodeCode: x,A,B');
        Eval(Observer, 'badEnum', 'LT EVR EnumCode: Gamma,B');
        Eval(Observer, 'badDate', 'LT EVR DateCode: notadate,B');
        Eval(Observer, 'codeTooLong', 'LT EVR CodeCode: AAAAAAAAAAAA,B');
        Eval(Observer, 'idNumber', 'LT EVR EnumCode: 1,B');
        Observer.Expect('exactOk', 'Yes');
        Observer.Expect('exactBack', 'LT EVR CodeCode: A,B');
        Observer.Expect('tooFewOk', 'Yes');
        Observer.Expect('tooFewBack', 'LT EVR CodeCode: A');
        Observer.Expect('tooManyOk', 'No');
        Observer.Expect('tooManyErr|text', 'The value "LT EVR CodeCode: A,B,C" can''t be evaluated into type RecordID.');
        Observer.Expect('tooManyErr|code', 'Evaluate');
        Observer.Expect('noValuesOk', 'Yes');
        Observer.Expect('noValuesBack', 'LT EVR CodeCode');
        Observer.Expect('noColonOk', 'Yes');
        Observer.Expect('noColonBack', 'LT EVR CodeCode');
        Observer.Expect('tooFew3Ok', 'Yes');
        Observer.Expect('tooFew3Back', 'LT EVR IntCodeCode: 1,A');
        Observer.Expect('tooMany1Ok', 'No');
        Observer.Expect('tooMany1Err|text', 'The value "LT EVR Single: A,B" can''t be evaluated into type RecordID.');
        Observer.Expect('tooMany1Err|code', 'Evaluate');
        Observer.Expect('badIntegerOk', 'No');
        Observer.Expect('badIntegerErr|text', 'The value "x" can''t be evaluated into type Integer.');
        Observer.Expect('badIntegerErr|code', 'Evaluate');
        Observer.Expect('badEnumOk', 'No');
        Observer.Expect('badEnumErr|text', '''Gamma'' is not an option. The existing options are: Alpha,Beta');
        Observer.Expect('badEnumErr|code', 'InvalidOptionString');
        Observer.Expect('badDateOk', 'No');
        Observer.Expect('badDateErr|text', 'The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('badDateErr|code', 'Evaluate');
        Observer.Expect('codeTooLongOk', 'No');
        Observer.Expect('codeTooLongErr|text', 'The length of the string is 12, but it must be less than or equal to 10 characters. Value: AAAAAAAAAAAA');
        Observer.Expect('codeTooLongErr|code', 'StringLengthExceeded');
        Observer.Expect('idNumberOk', 'Yes');
        Observer.Expect('idNumberBack', 'LT EVR EnumCode: Beta,B');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_IntoSetRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Ev: Codeunit "LT EVR Evaluator";
        T: Record "LT EVR CodeCode";
        S: Record "LT EVR Single";
        RR: RecordRef;
        Start: RecordId;
        Ran: Boolean;
    begin
        T.A := 'OLD';
        T.B := 'KEY';
        RR.GetTable(T);
        Start := RR.RecordId();
        Observer.Observe('start', Format(Start));

        // valid text of the same table
        Ev.Setup(1, 'LT EVR CodeCode: NEW,KEY', Start);
        Ran := Ev.Run();
        Observer.Observe('validRan', Format(Ran));
        Observer.Observe('validReturned', Format(Ev.Returned()));
        Observer.Observe('validResult', Format(Ev.Result()));

        // valid text of another table
        Ev.Setup(1, 'LT EVR Single: ONE', Start);
        Ran := Ev.Run();
        Observer.Observe('otherTableRan', Format(Ran));
        Observer.Observe('otherTableResult', Format(Ev.Result()));

        // invalid text, return value used
        Ev.Setup(1, 'garbage', Start);
        Ran := Ev.Run();
        Observer.Observe('garbageRan', Format(Ran));
        Observer.Observe('garbageReturned', Format(Ev.Returned()));
        Observer.Observe('garbageResult', Format(Ev.Result()));

        // invalid text, return value unused
        Ev.Setup(2, 'garbage', Start);
        Ran := Ev.Run();
        Observer.Observe('garbageUnusedRan', Format(Ran));
        if not Ran then
            Observer.ObserveError('garbageUnusedErr');
        Observer.Observe('garbageUnusedResult', Format(Ev.Result()));

        // wrong number of values, return value used
        Ev.Setup(1, 'LT EVR CodeCode: ONLY', Start);
        Ran := Ev.Run();
        Observer.Observe('fewRan', Format(Ran));
        Observer.Observe('fewReturned', Format(Ev.Returned()));
        Observer.Observe('fewResult', Format(Ev.Result()));

        // empty text
        Ev.Setup(1, '', Start);
        Ran := Ev.Run();
        Observer.Observe('emptyRan', Format(Ran));
        Observer.Observe('emptyReturned', Format(Ev.Returned()));
        Observer.Observe('emptyResult', Format(Ev.Result()));

        Ev.Setup(2, '', Start);
        Ran := Ev.Run();
        Observer.Observe('emptyUnusedRan', Format(Ran));
        if not Ran then
            Observer.ObserveError('emptyUnusedErr');
        Observer.Observe('emptyUnusedResult', Format(Ev.Result()));
        Observer.Expect('start', 'LT EVR CodeCode: OLD,KEY');
        Observer.Expect('validRan', 'Yes');
        Observer.Expect('validReturned', 'Yes');
        Observer.Expect('validResult', 'LT EVR CodeCode: NEW,KEY');
        Observer.Expect('otherTableRan', 'Yes');
        Observer.Expect('otherTableResult', 'LT EVR Single: ONE');
        Observer.Expect('garbageRan', 'Yes');
        Observer.Expect('garbageReturned', 'No');
        Observer.Expect('garbageResult', 'LT EVR CodeCode: OLD,KEY');
        Observer.Expect('garbageUnusedRan', 'No');
        Observer.Expect('garbageUnusedErr|text', 'The value "garbage" can''t be evaluated into type RecordID.');
        Observer.Expect('garbageUnusedErr|code', 'Evaluate');
        Observer.Expect('garbageUnusedResult', 'LT EVR CodeCode: OLD,KEY');
        Observer.Expect('fewRan', 'Yes');
        Observer.Expect('fewReturned', 'Yes');
        Observer.Expect('fewResult', 'LT EVR CodeCode: ONLY');
        Observer.Expect('emptyRan', 'Yes');
        Observer.Expect('emptyReturned', 'Yes');
        Observer.Expect('emptyResult', '');
        Observer.Expect('emptyUnusedRan', 'Yes');
        Observer.Expect('emptyUnusedResult', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvaluateUnused(var FR: FieldRef; Txt: Text)
    begin
        Evaluate(FR, Txt);
    end;

    [Test]
    procedure Evaluate_IntoFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT EVR IntCodeCode";
        RR: RecordRef;
        FR: FieldRef;
        Ok: Boolean;
    begin
        T.N := 5;
        RR.GetTable(T);
        FR := RR.Field(T.FieldNo(N));
        Ok := Evaluate(FR, '12');
        Observer.Observe('validUsed', Format(Ok) + ' ' + Format(FR.Value));
        Ok := Evaluate(FR, 'x');
        Observer.Observe('invalidUsed', Format(Ok) + ' ' + Format(FR.Value));
        if not Ok then
            Observer.ObserveError('invalidUsedErr');
        Ok := TryEvaluateUnused(FR, '34');
        Observer.Observe('validUnused', Format(Ok) + ' ' + Format(FR.Value));
        Ok := TryEvaluateUnused(FR, 'x');
        Observer.Observe('invalidUnused', Format(Ok) + ' ' + Format(FR.Value));
        if not Ok then
            Observer.ObserveError('invalidUnusedErr');
        FR := RR.Field(T.FieldNo(A));
        Ok := Evaluate(FR, 'abc');
        Observer.Observe('codeField', Format(Ok) + ' ' + Format(FR.Value));
        Observer.Expect('validUsed', 'Yes 12');
        Observer.Expect('invalidUsed', 'No 12');
        Observer.Expect('invalidUsedErr|text', '');
        Observer.Expect('invalidUsedErr|code', '');
        Observer.Expect('validUnused', 'Yes 34');
        Observer.Expect('invalidUnused', 'No 34');
        Observer.Expect('invalidUnusedErr|text', 'The value "x" can''t be evaluated into type Integer.');
        Observer.Expect('invalidUnusedErr|code', 'Evaluate');
        Observer.Expect('codeField', 'Yes ABC');
        Observer.Verify();
    end;
}
