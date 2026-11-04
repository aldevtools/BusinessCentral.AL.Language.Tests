// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 and table 70190 (P67Defs.al), self-contained test codeunit 70202
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Get with an enum of another type or an integer as key; GetLastErrorText
// BC versions: 29 (27 and 28 by CI)

codeunit 70202 "LT P67 Enum Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P67 Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Info := 'uno';
        Row.Insert();
        Row.Kind := Row.Kind::Tres;
        Row.Info := 'tres';
        Row.Insert();
        Row.Code := 'B';
        Row.Kind := Row.Kind::None;
        Row.Info := 'none';
        Row.Insert();
    end;

    [Test]
    procedure GetWithOtherEnum()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Seed();
        S := S::One;
        Observer.Observe('one_found', Format(Row.Get('A', S)) + '|' + Row.Info);
        S := S::Three;
        Observer.Observe('three_found', Format(Row.Get('A', S)) + '|' + Row.Info);
        S := S::None;
        Observer.Observe('none_wrong_code', Format(Row.Get('A', S)));
        Observer.Observe('none_b', Format(Row.Get('B', S)) + '|' + Row.Info);
        Observer.Expect('one_found', 'Yes|uno');
        Observer.Expect('three_found', 'Yes|tres');
        Observer.Expect('none_wrong_code', 'No');
        Observer.Expect('none_b', 'Yes|none');
        Observer.Verify();
    end;

    [Test]
    procedure GetWithOtherEnum_NotFound()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Seed();
        S := S::Seven;
        asserterror Row.Get('A', S);
        Observer.ObserveError('seven_a');
        Observer.Observe('seven_a_text', GetLastErrorText());
        Observer.Observe('seven_a_code', GetLastErrorCode());
        S := S::None;
        asserterror Row.Get('A', S);
        Observer.ObserveError('none_a');
        Observer.Observe('none_a_text', GetLastErrorText());
        S := S::One;
        asserterror Row.Get('B', S);
        Observer.ObserveError('one_b');
        Observer.Observe('one_b_text', GetLastErrorText());
        Observer.Expect('seven_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''Seven''');
        Observer.Expect('seven_a|code', 'DB:RecordNotFound');
        Observer.Expect('seven_a_text', '');
        Observer.Expect('seven_a_code', '');
        Observer.Expect('none_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''None''');
        Observer.Expect('none_a|code', 'DB:RecordNotFound');
        Observer.Expect('none_a_text', '');
        Observer.Expect('one_b|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''B'',Kind=''One''');
        Observer.Expect('one_b|code', 'DB:RecordNotFound');
        Observer.Expect('one_b_text', '');
        Observer.Verify();
    end;

    [Test]
    procedure GetWithInteger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        I: Integer;
    begin
        Seed();
        I := 1;
        Observer.Observe('int1', Format(Row.Get('A', I)) + '|' + Row.Info);
        I := 3;
        Observer.Observe('int3', Format(Row.Get('A', I)) + '|' + Row.Info);
        Observer.Observe('literal0_b', Format(Row.Get('B', 0)) + '|' + Row.Info);
        Observer.Expect('int1', 'Yes|uno');
        Observer.Expect('int3', 'Yes|tres');
        Observer.Expect('literal0_b', 'Yes|none');
        Observer.Verify();
    end;

    [Test]
    procedure GetWithInteger_NotFound()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        I: Integer;
    begin
        Seed();
        I := 2;
        asserterror Row.Get('A', I);
        Observer.ObserveError('int2_a');
        Observer.Observe('int2_a_text', GetLastErrorText());
        I := 7;
        asserterror Row.Get('A', I);
        Observer.ObserveError('int7_a');
        Observer.Observe('int7_a_text', GetLastErrorText());
        I := -1;
        asserterror Row.Get('A', I);
        Observer.ObserveError('minus1_a');
        Observer.Observe('minus1_a_text', GetLastErrorText());
        asserterror Row.Get('A', 9);
        Observer.ObserveError('literal9_a');
        Observer.Expect('int2_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''Dos''');
        Observer.Expect('int2_a|code', 'DB:RecordNotFound');
        Observer.Expect('int2_a_text', '');
        Observer.Expect('int7_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''7''');
        Observer.Expect('int7_a|code', 'DB:RecordNotFound');
        Observer.Expect('int7_a_text', '');
        Observer.Expect('minus1_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''-1''');
        Observer.Expect('minus1_a|code', 'DB:RecordNotFound');
        Observer.Expect('minus1_a_text', '');
        Observer.Expect('literal9_a|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''9''');
        Observer.Expect('literal9_a|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure GetWithOtherEnum_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Row.DeleteAll();
        S := S::Three;
        asserterror Row.Get('A', S);
        Observer.ObserveError('empty_three');
        Observer.Observe('empty_three_text', GetLastErrorText());
        Observer.Expect('empty_three|text', 'The LT P67 Row does not exist. Identification fields and values: Code=''A'',Kind=''Three''');
        Observer.Expect('empty_three|code', 'DB:RecordNotFound');
        Observer.Expect('empty_three_text', '');
        Observer.Verify();
    end;
}
