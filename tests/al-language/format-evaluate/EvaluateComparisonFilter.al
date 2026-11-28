// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-joker-string-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73476, helper codeunit 73476, test codeunit 73477
// Probe (AL Runner issue 8219, item 3): Evaluate of a filter expression, or of a text of spaces, into a number: a Decimal variable (the
//   issue's cell), an Integer and a BigInteger variable, and a Decimal field of a record (Evaluate(Row.Dec, T)).
//   Comparison texts: '<300', '>300', '<=300', '>=300', '<>300', '=300', '<' and '<-1.5'.
//   Other texts: '300..400', '..300', '300..', '300|400', '*', '300*', ' 300', '300 ' and a text of 25 spaces.
//   Every target holds 7 before each Evaluate. Two forms per text:
//     <text> bool: Ok := Evaluate(X, T); records "<Ok> <Format(X, 0, 9)>".
//     <text> stmt: the statement Evaluate(X, T) in a TryFunction; records "ok <Format(X, 0, 9)>" or "E: <GetLastErrorText> | <GetLastErrorCode>".
//   A test is <Target>_<Group>. The texts are written in brackets in the names ([<300] bool) so the spaces can be seen.
//   Not repeated: Evaluate(D, ''), '1,000', 'abc' and '(100)' (EvaluateDecimal.al and EvalDecimalEn.al).
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects; the values are that run's readings,
//   turned into Expect and Verify by convert.py verbatim. This pull request's CI checks them on 27.5, 28.5 and 29.0.
//   Facts (BC 29.0), the same for all four targets: every comparison text, every range, '300|400', '*', '300*' and the text of
//   25 spaces fail: the Boolean form returns No and leaves the target at 7; the statement raises 'The value "<text>" can't be
//   evaluated into type <Decimal|Integer|BigInteger>.' with GetLastErrorCode 'Evaluate'. ' 300' and '300 ' evaluate to 300 in both
//   forms.
//   Review additions (measured on a local BC 29.0.54011.57673 on 2026-11-28; on BC 27.5 by this pull request's CI observe run
//   46135846648, both 27.5 legs alike; one block where 27.5 equals BC 29, #if BC28PLUS / #else where it differs):
//   AllTargets_OneSpace: a text of one space fails like the 25-space text: No and the target unchanged, and 'The value " " can't
//   be evaluated into type <Decimal|Integer|BigInteger>.' (Evaluate).
// BC versions: 27, 28, 29 by CI
table 73476 "LT ECF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dec; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73476 "LT ECF Probe"
{
    procedure Spaces25(): Text
    begin
        exit(PadStr('', 25, ' '));
    end;

    [TryFunction]
    local procedure TryDec(var X: Decimal; T: Text)
    begin
        Evaluate(X, T);
    end;

    [TryFunction]
    local procedure TryInt(var X: Integer; T: Text)
    begin
        Evaluate(X, T);
    end;

    [TryFunction]
    local procedure TryBig(var X: BigInteger; T: Text)
    begin
        Evaluate(X, T);
    end;

    [TryFunction]
    local procedure TryField(var Row: Record "LT ECF Row"; T: Text)
    begin
        Evaluate(Row.Dec, T);
    end;

    local procedure Stmt(var Observer: Codeunit "Probe Observer"; T: Text; Ok: Boolean; Value: Text)
    begin
        if Ok then
            Observer.Observe('[' + T + '] stmt', 'ok ' + Value)
        else
            Observer.Observe('[' + T + '] stmt', 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        ClearLastError();
    end;

    procedure CellDec(var Observer: Codeunit "Probe Observer"; T: Text)
    var
        X: Decimal;
        Ok: Boolean;
    begin
        X := 7;
        Ok := Evaluate(X, T);
        Observer.Observe('[' + T + '] bool', Format(Ok) + ' ' + Format(X, 0, 9));
        X := 7;
        Ok := TryDec(X, T);
        Stmt(Observer, T, Ok, Format(X, 0, 9));
    end;

    procedure CellInt(var Observer: Codeunit "Probe Observer"; T: Text)
    var
        X: Integer;
        Ok: Boolean;
    begin
        X := 7;
        Ok := Evaluate(X, T);
        Observer.Observe('[' + T + '] bool', Format(Ok) + ' ' + Format(X, 0, 9));
        X := 7;
        Ok := TryInt(X, T);
        Stmt(Observer, T, Ok, Format(X, 0, 9));
    end;

    procedure CellBig(var Observer: Codeunit "Probe Observer"; T: Text)
    var
        X: BigInteger;
        Ok: Boolean;
    begin
        X := 7;
        Ok := Evaluate(X, T);
        Observer.Observe('[' + T + '] bool', Format(Ok) + ' ' + Format(X, 0, 9));
        X := 7;
        Ok := TryBig(X, T);
        Stmt(Observer, T, Ok, Format(X, 0, 9));
    end;

    procedure CellField(var Observer: Codeunit "Probe Observer"; T: Text)
    var
        Row: Record "LT ECF Row";
        Ok: Boolean;
    begin
        Row.Dec := 7;
        Ok := Evaluate(Row.Dec, T);
        Observer.Observe('[' + T + '] bool', Format(Ok) + ' ' + Format(Row.Dec, 0, 9));
        Row.Dec := 7;
        Ok := TryField(Row, T);
        Stmt(Observer, T, Ok, Format(Row.Dec, 0, 9));
    end;

    procedure Texts(Group: Text) Result: List of [Text]
    begin
        if Group = 'Comparison' then begin
            Result.Add('<300');
            Result.Add('>300');
            Result.Add('<=300');
            Result.Add('>=300');
            Result.Add('<>300');
            Result.Add('=300');
            Result.Add('<');
            Result.Add('<-1.5');
            exit;
        end;
        Result.Add('300..400');
        Result.Add('..300');
        Result.Add('300..');
        Result.Add('300|400');
        Result.Add('*');
        Result.Add('300*');
        Result.Add(' 300');
        Result.Add('300 ');
        Result.Add(Spaces25());
    end;
}

codeunit 73477 "LT ECF Evaluate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Decimal_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Comparison') do
            Probe.CellDec(Observer, T);
        Observer.Expect('[<300] bool', 'No 7');
        Observer.Expect('[<300] stmt', 'E: The value "<300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[>300] bool', 'No 7');
        Observer.Expect('[>300] stmt', 'E: The value ">300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<=300] bool', 'No 7');
        Observer.Expect('[<=300] stmt', 'E: The value "<=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[>=300] bool', 'No 7');
        Observer.Expect('[>=300] stmt', 'E: The value ">=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<>300] bool', 'No 7');
        Observer.Expect('[<>300] stmt', 'E: The value "<>300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[=300] bool', 'No 7');
        Observer.Expect('[=300] stmt', 'E: The value "=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<] bool', 'No 7');
        Observer.Expect('[<] stmt', 'E: The value "<" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<-1.5] bool', 'No 7');
        Observer.Expect('[<-1.5] stmt', 'E: The value "<-1.5" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Other()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Other') do
            Probe.CellDec(Observer, T);
        Observer.Expect('[300..400] bool', 'No 7');
        Observer.Expect('[300..400] stmt', 'E: The value "300..400" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[..300] bool', 'No 7');
        Observer.Expect('[..300] stmt', 'E: The value "..300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300..] bool', 'No 7');
        Observer.Expect('[300..] stmt', 'E: The value "300.." can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300|400] bool', 'No 7');
        Observer.Expect('[300|400] stmt', 'E: The value "300|400" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[*] bool', 'No 7');
        Observer.Expect('[*] stmt', 'E: The value "*" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300*] bool', 'No 7');
        Observer.Expect('[300*] stmt', 'E: The value "300*" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[ 300] bool', 'Yes 300');
        Observer.Expect('[ 300] stmt', 'ok 300');
        Observer.Expect('[300 ] bool', 'Yes 300');
        Observer.Expect('[300 ] stmt', 'ok 300');
        Observer.Expect('[                         ] bool', 'No 7');
        Observer.Expect('[                         ] stmt', 'E: The value "                         " can''t be evaluated into type Decimal. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Comparison') do
            Probe.CellInt(Observer, T);
        Observer.Expect('[<300] bool', 'No 7');
        Observer.Expect('[<300] stmt', 'E: The value "<300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[>300] bool', 'No 7');
        Observer.Expect('[>300] stmt', 'E: The value ">300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[<=300] bool', 'No 7');
        Observer.Expect('[<=300] stmt', 'E: The value "<=300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[>=300] bool', 'No 7');
        Observer.Expect('[>=300] stmt', 'E: The value ">=300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[<>300] bool', 'No 7');
        Observer.Expect('[<>300] stmt', 'E: The value "<>300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[=300] bool', 'No 7');
        Observer.Expect('[=300] stmt', 'E: The value "=300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[<] bool', 'No 7');
        Observer.Expect('[<] stmt', 'E: The value "<" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[<-1.5] bool', 'No 7');
        Observer.Expect('[<-1.5] stmt', 'E: The value "<-1.5" can''t be evaluated into type Integer. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Other()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Other') do
            Probe.CellInt(Observer, T);
        Observer.Expect('[300..400] bool', 'No 7');
        Observer.Expect('[300..400] stmt', 'E: The value "300..400" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[..300] bool', 'No 7');
        Observer.Expect('[..300] stmt', 'E: The value "..300" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[300..] bool', 'No 7');
        Observer.Expect('[300..] stmt', 'E: The value "300.." can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[300|400] bool', 'No 7');
        Observer.Expect('[300|400] stmt', 'E: The value "300|400" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[*] bool', 'No 7');
        Observer.Expect('[*] stmt', 'E: The value "*" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[300*] bool', 'No 7');
        Observer.Expect('[300*] stmt', 'E: The value "300*" can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[ 300] bool', 'Yes 300');
        Observer.Expect('[ 300] stmt', 'ok 300');
        Observer.Expect('[300 ] bool', 'Yes 300');
        Observer.Expect('[300 ] stmt', 'ok 300');
        Observer.Expect('[                         ] bool', 'No 7');
        Observer.Expect('[                         ] stmt', 'E: The value "                         " can''t be evaluated into type Integer. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Comparison') do
            Probe.CellBig(Observer, T);
        Observer.Expect('[<300] bool', 'No 7');
        Observer.Expect('[<300] stmt', 'E: The value "<300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[>300] bool', 'No 7');
        Observer.Expect('[>300] stmt', 'E: The value ">300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[<=300] bool', 'No 7');
        Observer.Expect('[<=300] stmt', 'E: The value "<=300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[>=300] bool', 'No 7');
        Observer.Expect('[>=300] stmt', 'E: The value ">=300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[<>300] bool', 'No 7');
        Observer.Expect('[<>300] stmt', 'E: The value "<>300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[=300] bool', 'No 7');
        Observer.Expect('[=300] stmt', 'E: The value "=300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[<] bool', 'No 7');
        Observer.Expect('[<] stmt', 'E: The value "<" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[<-1.5] bool', 'No 7');
        Observer.Expect('[<-1.5] stmt', 'E: The value "<-1.5" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Other()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Other') do
            Probe.CellBig(Observer, T);
        Observer.Expect('[300..400] bool', 'No 7');
        Observer.Expect('[300..400] stmt', 'E: The value "300..400" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[..300] bool', 'No 7');
        Observer.Expect('[..300] stmt', 'E: The value "..300" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[300..] bool', 'No 7');
        Observer.Expect('[300..] stmt', 'E: The value "300.." can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[300|400] bool', 'No 7');
        Observer.Expect('[300|400] stmt', 'E: The value "300|400" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[*] bool', 'No 7');
        Observer.Expect('[*] stmt', 'E: The value "*" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[300*] bool', 'No 7');
        Observer.Expect('[300*] stmt', 'E: The value "300*" can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[ 300] bool', 'Yes 300');
        Observer.Expect('[ 300] stmt', 'ok 300');
        Observer.Expect('[300 ] bool', 'Yes 300');
        Observer.Expect('[300 ] stmt', 'ok 300');
        Observer.Expect('[                         ] bool', 'No 7');
        Observer.Expect('[                         ] stmt', 'E: The value "                         " can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalField_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Comparison') do
            Probe.CellField(Observer, T);
        Observer.Expect('[<300] bool', 'No 7');
        Observer.Expect('[<300] stmt', 'E: The value "<300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[>300] bool', 'No 7');
        Observer.Expect('[>300] stmt', 'E: The value ">300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<=300] bool', 'No 7');
        Observer.Expect('[<=300] stmt', 'E: The value "<=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[>=300] bool', 'No 7');
        Observer.Expect('[>=300] stmt', 'E: The value ">=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<>300] bool', 'No 7');
        Observer.Expect('[<>300] stmt', 'E: The value "<>300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[=300] bool', 'No 7');
        Observer.Expect('[=300] stmt', 'E: The value "=300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<] bool', 'No 7');
        Observer.Expect('[<] stmt', 'E: The value "<" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[<-1.5] bool', 'No 7');
        Observer.Expect('[<-1.5] stmt', 'E: The value "<-1.5" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalField_Other()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
        T: Text;
    begin
        foreach T in Probe.Texts('Other') do
            Probe.CellField(Observer, T);
        Observer.Expect('[300..400] bool', 'No 7');
        Observer.Expect('[300..400] stmt', 'E: The value "300..400" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[..300] bool', 'No 7');
        Observer.Expect('[..300] stmt', 'E: The value "..300" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300..] bool', 'No 7');
        Observer.Expect('[300..] stmt', 'E: The value "300.." can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300|400] bool', 'No 7');
        Observer.Expect('[300|400] stmt', 'E: The value "300|400" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[*] bool', 'No 7');
        Observer.Expect('[*] stmt', 'E: The value "*" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[300*] bool', 'No 7');
        Observer.Expect('[300*] stmt', 'E: The value "300*" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[ 300] bool', 'Yes 300');
        Observer.Expect('[ 300] stmt', 'ok 300');
        Observer.Expect('[300 ] bool', 'Yes 300');
        Observer.Expect('[300 ] stmt', 'ok 300');
        Observer.Expect('[                         ] bool', 'No 7');
        Observer.Expect('[                         ] stmt', 'E: The value "                         " can''t be evaluated into type Decimal. | Evaluate');
        Observer.Verify();
    end;

    // A text of one space, into each target.
    [Test]
    procedure AllTargets_OneSpace()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT ECF Probe";
    begin
        Probe.CellDec(Observer, ' ');
        Probe.CellInt(Observer, ' ');
        Probe.CellBig(Observer, ' ');
        Probe.CellField(Observer, ' ');
        Observer.Expect('[ ] bool', 'No 7');
        Observer.Expect('[ ] stmt', 'E: The value " " can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('[ ] bool', 'No 7');
        Observer.Expect('[ ] stmt', 'E: The value " " can''t be evaluated into type Integer. | Evaluate');
        Observer.Expect('[ ] bool', 'No 7');
        Observer.Expect('[ ] stmt', 'E: The value " " can''t be evaluated into type BigInteger. | Evaluate');
        Observer.Expect('[ ] bool', 'No 7');
        Observer.Expect('[ ] stmt', 'E: The value " " can''t be evaluated into type Decimal. | Evaluate');
        Observer.Verify();
    end;
}
