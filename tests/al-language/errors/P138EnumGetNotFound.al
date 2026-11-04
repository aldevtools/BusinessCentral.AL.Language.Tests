// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: self-contained enums 74506, 74507, table 74508, codeunit 74509
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: the text and code of the error of Get(Code, Key) with the result unused when the Key is an enum of another type (a declared ordinal and one the key lacks) or an
// Integer; which value the Identification fields text names: the caller's or the key's.

enum 74506 "LT P138 Src Enum"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { Caption = 'Src One'; }
    value(7; Seven) { Caption = 'Src Seven'; }
    value(9; Nine) { Caption = 'Src Nine'; }
}

enum 74507 "LT P138 Dst Enum"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; Uno) { Caption = 'Dst Uno'; }
    value(2; Dos) { Caption = 'Dst Dos'; }
    value(9; Nueve) { Caption = 'Dst Nueve'; }
}

table 74508 "LT P138 Enum Key Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "LT P138 Dst Enum") { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; Code, Kind) { Clustered = true; }
    }
}

codeunit 74509 "LT P138 Enum Get Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P138 Enum Key Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Dos;
        Row.Info := 'dos';
        Row.Insert();
    end;

    [Test]
    procedure P138_Get_OtherEnum_MissingRow_DeclaredOrdinal()
    var
        Found: Record "LT P138 Enum Key Row";
        Src: Enum "LT P138 Src Enum";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Src := Src::One;
        asserterror Found.Get('A', Src);
        Observer.ObserveError('src_one');
        Src := Src::Nine;
        asserterror Found.Get('A', Src);
        Observer.ObserveError('src_nine');
        Src := Src::None;
        asserterror Found.Get('A', Src);
        Observer.ObserveError('src_none');
        Observer.Expect('src_one|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Src One''');
        Observer.Expect('src_one|code', 'DB:RecordNotFound');
        Observer.Expect('src_nine|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Src Nine''');
        Observer.Expect('src_nine|code', 'DB:RecordNotFound');
        Observer.Expect('src_none|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''None''');
        Observer.Expect('src_none|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Get_OtherEnum_MissingRow_LackingOrdinal()
    var
        Found: Record "LT P138 Enum Key Row";
        Src: Enum "LT P138 Src Enum";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Src := Src::Seven;
        asserterror Found.Get('A', Src);
        Observer.ObserveError('src_seven');
        Observer.Observe('found_after', Format(Found.Code) + '/' + Format(Found.Info));
        Observer.Expect('src_seven|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Src Seven''');
        Observer.Expect('src_seven|code', 'DB:RecordNotFound');
        Observer.Expect('found_after', '/');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Get_Integer_MissingRow()
    var
        Found: Record "LT P138 Enum Key Row";
        Int: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Int := 1;
        asserterror Found.Get('A', Int);
        Observer.ObserveError('int_1');
        Int := 5;
        asserterror Found.Get('A', Int);
        Observer.ObserveError('int_5');
        Int := 0;
        asserterror Found.Get('A', Int);
        Observer.ObserveError('int_0');
        Observer.Expect('int_1|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Dst Uno''');
        Observer.Expect('int_1|code', 'DB:RecordNotFound');
        Observer.Expect('int_5|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''5''');
        Observer.Expect('int_5|code', 'DB:RecordNotFound');
        Observer.Expect('int_0|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''None''');
        Observer.Expect('int_0|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Get_IntegerLiteral_And_FromInteger_MissingRow()
    var
        Found: Record "LT P138 Enum Key Row";
        Dst: Enum "LT P138 Dst Enum";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Found.Get('A', 9);
        Observer.ObserveError('literal_9');
        asserterror Found.Get('A', 5);
        Observer.ObserveError('literal_5');
        Dst := Enum::"LT P138 Dst Enum".FromInteger(5);
        asserterror Found.Get('A', Dst);
        Observer.ObserveError('dst_lacking_5');
        Dst := Dst::Nueve;
        asserterror Found.Get('A', Dst);
        Observer.ObserveError('dst_same_type');
        Observer.Expect('literal_9|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Dst Nueve''');
        Observer.Expect('literal_9|code', 'DB:RecordNotFound');
        Observer.Expect('literal_5|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''5''');
        Observer.Expect('literal_5|code', 'DB:RecordNotFound');
        Observer.Expect('dst_lacking_5|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''5''');
        Observer.Expect('dst_lacking_5|code', 'DB:RecordNotFound');
        Observer.Expect('dst_same_type|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''A'',Kind=''Dst Nueve''');
        Observer.Expect('dst_same_type|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Get_OtherEnum_MissingFirstKeyPart()
    var
        Found: Record "LT P138 Enum Key Row";
        Src: Enum "LT P138 Src Enum";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Src := Src::Nine;
        asserterror Found.Get('Z', Src);
        Observer.ObserveError('missing_code_src_nine');
        Src := Src::Seven;
        asserterror Found.Get('Z', Src);
        Observer.ObserveError('missing_code_src_seven');
        Observer.Expect('missing_code_src_nine|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''Z'',Kind=''Src Nine''');
        Observer.Expect('missing_code_src_nine|code', 'DB:RecordNotFound');
        Observer.Expect('missing_code_src_seven|text', 'The LT P138 Enum Key Row does not exist. Identification fields and values: Code=''Z'',Kind=''Src Seven''');
        Observer.Expect('missing_code_src_seven|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
