// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 87572, test codeunit 87573
// Probe (writer QX, Microsoft's DemoTool through Base App table 85 "Acc. Schedule Line", field Totaling OnValidate:
//   Description := Description = '' ? GLAcc.Name : Description;): a conditional expression whose branches are Text or Code of different
//   lengths, assigned to a shorter Text or Code variable or field, with a value that fits and one that is longer than the target. Which
//   branch is converted, and whether a long value is an error (which text) or cut. The ternary matrix of corpus issue 685 is in
//   types/TestTernaryContracts.al (writer QW); this file covers only the sized Text/Code target.
// BC versions: 27-29

table 87572 "LT QX Tern Sized Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[80]) { }
        field(3; Name; Text[100]) { }
        field(4; ShortCode; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 87573 "LT QX Tern Sized"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Chars(Count: Integer): Text
    begin
        exit(PadStr('', Count, 'x'));
    end;

    [TryFunction]
    local procedure TryT80FromT100First(Cond: Boolean; Len: Integer; var Result: Text)
    var
        T80: Text[80];
        T100: Text[100];
    begin
        T80 := 'short80';
        T100 := Chars(Len);
        T80 := Cond ? T100 : T80;
        Result := Format(StrLen(T80)) + '|' + CopyStr(T80, 1, 10);
    end;

    [TryFunction]
    local procedure TryT80FromT100Second(Cond: Boolean; Len: Integer; var Result: Text)
    var
        T80: Text[80];
        T100: Text[100];
    begin
        T80 := 'short80';
        T100 := Chars(Len);
        T80 := Cond ? T80 : T100;
        Result := Format(StrLen(T80)) + '|' + CopyStr(T80, 1, 10);
    end;

    [TryFunction]
    local procedure TryFieldFromField(Cond: Boolean; Len: Integer; var Result: Text)
    var
        Row: Record "LT QX Tern Sized Row";
    begin
        Row.Description := '';
        Row.Name := Chars(Len);
        Row.Description := Cond ? Row.Name : Row.Description;
        Result := Format(StrLen(Row.Description));
    end;

    [TryFunction]
    local procedure TryFieldDemoShape(Len: Integer; var Result: Text)
    var
        Row: Record "LT QX Tern Sized Row";
    begin
        Row.Description := '';
        Row.Name := Chars(Len);
        Row.Description := Row.Description = '' ? Row.Name : Row.Description;
        Result := Format(StrLen(Row.Description));
    end;

    [TryFunction]
    local procedure TryCode10FromText(Cond: Boolean; Value: Text; var Result: Text)
    var
        Row: Record "LT QX Tern Sized Row";
        T30: Text[30];
    begin
        Row.ShortCode := 'KEEP';
        T30 := CopyStr(Value, 1, 30);
        Row.ShortCode := Cond ? T30 : Row.ShortCode;
        Result := Row.ShortCode;
    end;

    [TryFunction]
    local procedure TryText10FromCode20(Cond: Boolean; Value: Code[20]; var Result: Text)
    var
        T10: Text[10];
        C20: Code[20];
    begin
        T10 := 'keep';
        C20 := Value;
        T10 := Cond ? C20 : T10;
        Result := T10;
    end;

    [TryFunction]
    local procedure TryCode20FromCode30(Cond: Boolean; Len: Integer; var Result: Text)
    var
        C20: Code[20];
        C30: Code[30];
    begin
        C20 := 'KEEP';
        C30 := Chars(Len);
        C20 := Cond ? C20 : C30;
        Result := Format(StrLen(C20));
    end;

    local procedure Run(Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, 'ok|' + Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure QX_Ternary_SizedTextTarget()
    var
        R: Text;
    begin
        Run('T80 := true ? T100(79) : T80', TryT80FromT100First(true, 79, R), R);
        Run('T80 := true ? T100(80) : T80', TryT80FromT100First(true, 80, R), R);
        Run('T80 := true ? T100(81) : T80', TryT80FromT100First(true, 81, R), R);
        Run('T80 := true ? T100(100) : T80', TryT80FromT100First(true, 100, R), R);
        Run('T80 := false ? T100(100) : T80', TryT80FromT100First(false, 100, R), R);
        Run('T80 := false ? T80 : T100(90)', TryT80FromT100Second(false, 90, R), R);
        Run('T80 := true ? T80 : T100(90)', TryT80FromT100Second(true, 90, R), R);
        Run('T80 := false ? T80 : T100(50)', TryT80FromT100Second(false, 50, R), R);
        Observer.Expect('T80 := true ? T100(79) : T80', 'ok|79|xxxxxxxxxx');
        Observer.Expect('T80 := true ? T100(80) : T80', 'ok|80|xxxxxxxxxx');
        Observer.Expect('T80 := true ? T100(81) : T80|text', 'The length of the string is 81, but it must be less than or equal to 80 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Expect('T80 := true ? T100(81) : T80|code', 'StringLengthExceeded');
        Observer.Expect('T80 := true ? T100(100) : T80|text', 'The length of the string is 100, but it must be less than or equal to 80 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Expect('T80 := true ? T100(100) : T80|code', 'StringLengthExceeded');
        Observer.Expect('T80 := false ? T100(100) : T80', 'ok|7|short80');
        Observer.Expect('T80 := false ? T80 : T100(90)|text', 'The length of the string is 90, but it must be less than or equal to 80 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Expect('T80 := false ? T80 : T100(90)|code', 'StringLengthExceeded');
        Observer.Expect('T80 := true ? T80 : T100(90)', 'ok|7|short80');
        Observer.Expect('T80 := false ? T80 : T100(50)', 'ok|50|xxxxxxxxxx');
        Observer.Verify();
    end;

    [Test]
    procedure QX_Ternary_SizedFieldTarget()
    var
        R: Text;
    begin
        Run('field true Name(90)', TryFieldFromField(true, 90, R), R);
        Run('field true Name(80)', TryFieldFromField(true, 80, R), R);
        Run('field false Name(90)', TryFieldFromField(false, 90, R), R);
        Run('demo shape Name(30)', TryFieldDemoShape(30, R), R);
        Run('demo shape Name(95)', TryFieldDemoShape(95, R), R);
        Observer.Expect('field true Name(90)|text', 'The length of the string is 90, but it must be less than or equal to 80 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Expect('field true Name(90)|code', 'StringLengthExceeded');
        Observer.Expect('field true Name(80)', 'ok|80');
        Observer.Expect('field false Name(90)', 'ok|0');
        Observer.Expect('demo shape Name(30)', 'ok|30');
        Observer.Expect('demo shape Name(95)|text', 'The length of the string is 95, but it must be less than or equal to 80 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Expect('demo shape Name(95)|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure QX_Ternary_CodeAndTextMixes()
    var
        R: Text;
    begin
        Run('Code10 := true ? Text30(abc) : Code10', TryCode10FromText(true, 'abc', R), R);
        Run('Code10 := true ? Text30( lower case 15) : Code10', TryCode10FromText(true, ' lower case 15x', R), R);
        Run('Code10 := false ? Text30(long) : Code10', TryCode10FromText(false, 'abcdefghijklmnop', R), R);
        Run('Text10 := true ? Code20(ABC) : Text10', TryText10FromCode20(true, 'ABC', R), R);
        Run('Text10 := true ? Code20(15 chars) : Text10', TryText10FromCode20(true, 'ABCDEFGHIJKLMNO', R), R);
        Run('Code20 := false ? Code20 : Code30(25)', TryCode20FromCode30(false, 25, R), R);
        Run('Code20 := true ? Code20 : Code30(25)', TryCode20FromCode30(true, 25, R), R);
        Observer.Expect('Code10 := true ? Text30(abc) : Code10', 'ok|ABC');
        Observer.Expect('Code10 := true ? Text30( lower case 15) : Code10|text', 'The length of the string is 14, but it must be less than or equal to 10 characters. Value: lower case 15x');
        Observer.Expect('Code10 := true ? Text30( lower case 15) : Code10|code', 'StringLengthExceeded');
        Observer.Expect('Code10 := false ? Text30(long) : Code10', 'ok|KEEP');
        Observer.Expect('Text10 := true ? Code20(ABC) : Text10', 'ok|ABC');
        Observer.Expect('Text10 := true ? Code20(15 chars) : Text10|text', 'The length of the string is 15, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJKLMNO');
        Observer.Expect('Text10 := true ? Code20(15 chars) : Text10|code', 'StringLengthExceeded');
        Observer.Expect('Code20 := false ? Code20 : Code30(25)|text', 'The length of the string is 25, but it must be less than or equal to 20 characters. Value: XXXXXXXXXXXXXXXXXXXXXXXXX');
        Observer.Expect('Code20 := false ? Code20 : Code30(25)|code', 'StringLengthExceeded');
        Observer.Expect('Code20 := true ? Code20 : Code30(25)', 'ok|4');
        Observer.Verify();
    end;
}
