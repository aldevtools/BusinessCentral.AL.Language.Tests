// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope
// Fixtures used: self-contained enum 72000, tables 72002 to 72004, test codeunit 72002
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.Init resets every field to its type default or InitValue, whether it touches the primary key, filters and a pre-set record; AutoIncrement; field defaults
// of Option, Enum, Boolean, Date, Time, DateTime, Guid, Code, Text, BigInteger, Decimal, Duration, BLOB; MinValue/MaxValue/NotBlank/BlankZero/InitValue properties.
// BC versions: 29 (27 and 28 by CI)

enum 72000 "LT RcB Color"
{
    Extensible = true;

    value(0; Red) { }
    value(1; Green) { }
    value(5; Blue) { }
}

enum 72001 "LT RcB Level"
{
    Extensible = false;

    value(0; Low) { }
    value(1; High) { }
}

table 72002 "LT RcB Defaults"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Cod; Code[10]) { }
        field(4; Dec; Decimal) { }
        field(5; Int; Integer) { }
        field(6; Big; BigInteger) { }
        field(7; Bool; Boolean) { }
        field(8; Dt; Date) { }
        field(9; Tm; Time) { }
        field(10; DtTm; DateTime) { }
        field(11; Gd; Guid) { }
        field(12; Opt; Option) { OptionMembers = First,Second,Third; }
        field(13; Col; Enum "LT RcB Color") { }
        field(14; Dur; Duration) { }
        field(15; Blb; Blob) { }
        field(16; InitInt; Integer) { InitValue = 7; }
        field(17; InitTxt; Text[20]) { InitValue = 'abc'; }
        field(18; InitBool; Boolean) { InitValue = true; }
        field(19; InitDec; Decimal) { InitValue = 1.5; }
        field(20; InitOpt; Option) { OptionMembers = A,B,C; InitValue = B; }
        field(21; InitCol; Enum "LT RcB Color") { InitValue = Blue; }
        field(22; InitDate; Date) { InitValue = 20250102D; }
        field(23; InitCode; Code[10]) { InitValue = 'xyz'; }
        field(24; Lvl; Enum "LT RcB Level") { }
        field(25; InitNeg; Integer) { InitValue = -3; }
        field(26; Rid; RecordId) { }
        field(27; TxtLong; Text[250]) { }
        field(29; Dec5; Decimal) { DecimalPlaces = 2 : 5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72003 "LT RcB Auto"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { AutoIncrement = true; }
        field(2; Name; Text[20]) { }
        field(3; Big; BigInteger) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

table 72004 "LT RcB Props"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ranged; Integer) { MinValue = 5; MaxValue = 10; }
        field(3; Req; Code[10]) { NotBlank = true; }
        field(4; Blanked; Integer) { BlankZero = true; }
        field(5; Opt; Option) { OptionMembers = ,One,Two; }
        field(6; DecRange; Decimal) { MinValue = -1.5; MaxValue = 1.5; }
        field(7; Upper; Code[5]) { }
        field(8; Cap; Text[10]) { CaptionML = ENU = 'Cap Caption'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72002 "LT RcB Init"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Init_TypeDefaults()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Observer.Observe('Id', Format(Rec.Id));
        Observer.Observe('Txt', '[' + Rec.Txt + ']');
        Observer.Observe('Cod', '[' + Rec.Cod + ']');
        Observer.Observe('Dec', Format(Rec.Dec));
        Observer.Observe('Int', Format(Rec.Int));
        Observer.Observe('Big', Format(Rec.Big));
        Observer.Observe('Bool', Format(Rec.Bool));
        Observer.Observe('Dt', Format(Rec.Dt));
        Observer.Observe('Dt eq 0D', Format(Rec.Dt = 0D));
        Observer.Observe('Tm', Format(Rec.Tm));
        Observer.Observe('Tm eq 0T', Format(Rec.Tm = 0T));
        Observer.Observe('DtTm', Format(Rec.DtTm));
        Observer.Observe('DtTm eq 0DT', Format(Rec.DtTm = 0DT));
        Observer.Observe('Gd', Format(Rec.Gd));
        Observer.Observe('Gd null', Format(IsNullGuid(Rec.Gd)));
        Observer.Observe('Opt', Format(Rec.Opt));
        Observer.Observe('Opt int', Format(Rec.Opt, 0, 2));
        Observer.Observe('Col', Format(Rec.Col));
        Observer.Observe('Col int', Format(Rec.Col.AsInteger()));
        Observer.Observe('Dur', Format(Rec.Dur));
        Observer.Observe('Blb', Format(Rec.Blb.HasValue()));
        Observer.Observe('Lvl', Format(Rec.Lvl));
        Observer.Observe('Dec5', Format(Rec.Dec5));
        Observer.Expect('Id', '0');
        Observer.Expect('Txt', '[]');
        Observer.Expect('Cod', '[]');
        Observer.Expect('Dec', '0');
        Observer.Expect('Int', '0');
        Observer.Expect('Big', '0');
        Observer.Expect('Bool', 'No');
        Observer.Expect('Dt', '');
        Observer.Expect('Dt eq 0D', 'Yes');
        Observer.Expect('Tm', '');
        Observer.Expect('Tm eq 0T', 'Yes');
        Observer.Expect('DtTm', '');
        Observer.Expect('DtTm eq 0DT', 'Yes');
        Observer.Expect('Gd', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('Gd null', 'Yes');
        Observer.Expect('Opt', 'First');
        Observer.Expect('Opt int', '0');
        Observer.Expect('Col', 'Red');
        Observer.Expect('Col int', '0');
        Observer.Expect('Dur', '');
        Observer.Expect('Blb', 'No');
        Observer.Expect('Lvl', 'Low');
        Observer.Expect('Dec5', '0.00');
        Observer.Verify();
    end;

    [Test]
    procedure Init_InitValues()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Observer.Observe('InitInt', Format(Rec.InitInt));
        Observer.Observe('InitTxt', Rec.InitTxt);
        Observer.Observe('InitBool', Format(Rec.InitBool));
        Observer.Observe('InitDec', Format(Rec.InitDec));
        Observer.Observe('InitOpt', Format(Rec.InitOpt));
        Observer.Observe('InitOpt int', Format(Rec.InitOpt, 0, 2));
        Observer.Observe('InitCol', Format(Rec.InitCol));
        Observer.Observe('InitCol int', Format(Rec.InitCol.AsInteger()));
        Observer.Observe('InitDate', Format(Rec.InitDate, 0, 9));
        Observer.Observe('InitCode', Rec.InitCode);
        Observer.Observe('InitNeg', Format(Rec.InitNeg));
        Observer.Expect('InitInt', '7');
        Observer.Expect('InitTxt', 'abc');
        Observer.Expect('InitBool', 'Yes');
        Observer.Expect('InitDec', '1.5');
        Observer.Expect('InitOpt', 'B');
        Observer.Expect('InitOpt int', '1');
        Observer.Expect('InitCol', 'Blue');
        Observer.Expect('InitCol int', '5');
        Observer.Expect('InitDate', '2025-01-02');
        Observer.Expect('InitCode', 'XYZ');
        Observer.Expect('InitNeg', '-3');
        Observer.Verify();
    end;

    [Test]
    procedure Init_ResetsAssignedFields()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 5;
        Rec.Txt := 'abc';
        Rec.Int := 9;
        Rec.InitInt := 100;
        Rec.InitTxt := 'changed';
        Rec.Opt := Rec.Opt::Third;
        Rec.Col := Rec.Col::Green;
        Rec.Bool := true;
        Rec.Init();
        Observer.Observe('Id', Format(Rec.Id));
        Observer.Observe('Txt', '[' + Rec.Txt + ']');
        Observer.Observe('Int', Format(Rec.Int));
        Observer.Observe('InitInt', Format(Rec.InitInt));
        Observer.Observe('InitTxt', Rec.InitTxt);
        Observer.Observe('Opt', Format(Rec.Opt));
        Observer.Observe('Col', Format(Rec.Col));
        Observer.Observe('Bool', Format(Rec.Bool));
        Observer.Expect('Id', '5');
        Observer.Expect('Txt', '[]');
        Observer.Expect('Int', '0');
        Observer.Expect('InitInt', '7');
        Observer.Expect('InitTxt', 'abc');
        Observer.Expect('Opt', 'First');
        Observer.Expect('Col', 'Red');
        Observer.Expect('Bool', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Init_IgnoresFilters()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.SetRange(Id, 42);
        Rec.SetRange(Txt, 'filtered');
        Rec.Init();
        Observer.Observe('Id', Format(Rec.Id));
        Observer.Observe('Txt', '[' + Rec.Txt + ']');
        Rec.SetFilter(Int, '5');
        Rec.Init();
        Observer.Observe('Int', Format(Rec.Int));
        Observer.Observe('has filter', Format(Rec.GetFilter(Id)));
        Observer.Expect('Id', '0');
        Observer.Expect('Txt', '[]');
        Observer.Expect('Int', '0');
        Observer.Expect('has filter', '42');
        Observer.Verify();
    end;

    [Test]
    procedure Init_InsertPersistsInitValues()
    var
        Rec: Record "LT RcB Defaults";
        Rec2: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 3;
        Rec.Insert();
        Rec2.Get(3);
        Observer.Observe('InitInt', Format(Rec2.InitInt));
        Observer.Observe('InitTxt', Rec2.InitTxt);
        Observer.Observe('InitCol', Format(Rec2.InitCol));
        Rec.Id := 4;
        Rec.InitInt := 0;
        Rec.Insert();
        Rec2.Get(4);
        Observer.Observe('InitInt zero kept', Format(Rec2.InitInt));
        Observer.Expect('InitInt', '7');
        Observer.Expect('InitTxt', 'abc');
        Observer.Expect('InitCol', 'Blue');
        Observer.Expect('InitInt zero kept', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NoInit_NewVariableDefaults()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('InitInt without Init', Format(Rec.InitInt));
        Observer.Observe('InitTxt without Init', '[' + Rec.InitTxt + ']');
        Observer.Observe('InitBool without Init', Format(Rec.InitBool));
        Observer.Observe('InitCol without Init', Format(Rec.InitCol));
        Rec.Init();
        Observer.Observe('InitInt with Init', Format(Rec.InitInt));
        Observer.Expect('InitInt without Init', '7');
        Observer.Expect('InitTxt without Init', '[abc]');
        Observer.Expect('InitBool without Init', 'Yes');
        Observer.Expect('InitCol without Init', 'Blue');
        Observer.Expect('InitInt with Init', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Init_Insert_WithoutInit_NoInitValue()
    var
        Rec: Record "LT RcB Defaults";
        Rec2: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 8;
        Rec.Insert();
        Rec2.Get(8);
        Observer.Observe('InitInt no Init', Format(Rec2.InitInt));
        Observer.Observe('InitTxt no Init', '[' + Rec2.InitTxt + ']');
        Observer.Expect('InitInt no Init', '7');
        Observer.Expect('InitTxt no Init', '[abc]');
        Observer.Verify();
    end;

    [Test]
    procedure Props_NotBlank()
    var
        Rec: Record "LT RcB Props";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Validate(Req, 'X');
        Observer.Observe('value', Rec.Req);
        Rec.Validate(Req, '');
        Observer.Observe('blank validate', 'no error');
        Rec.Req := '';
        Observer.Observe('blank assigned', '[' + Rec.Req + ']');
        Rec.Id := 1;
        Observer.Observe('insert blank', Format(Rec.Insert()));
        Rec.Validate(Req, 'low');
        Observer.Observe('code upper', Rec.Req);
        Observer.Expect('value', 'X');
        Observer.Expect('blank validate', 'no error');
        Observer.Expect('blank assigned', '[]');
        Observer.Expect('insert blank', 'Yes');
        Observer.Expect('code upper', 'LOW');
        Observer.Verify();
    end;

    [Test]
    procedure Props_BlankZero_Option_Caption()
    var
        Rec: Record "LT RcB Props";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blankzero 0', Format(Rec.Blanked));
        Rec.Blanked := 5;
        Observer.Observe('blankzero 5', Format(Rec.Blanked));
        Observer.Observe('opt blank member', '[' + Format(Rec.Opt) + ']');
        Rec.Opt := Rec.Opt::Two;
        Observer.Observe('opt two', Format(Rec.Opt));
        Observer.Observe('opt int', Format(Rec.Opt, 0, 2));
        Observer.Observe('field caption', Rec.FieldCaption(Cap));
        Observer.Observe('field name', Rec.FieldName(Cap));
        Observer.Expect('blankzero 0', '0');
        Observer.Expect('blankzero 5', '5');
        Observer.Expect('opt blank member', '[0]');
        Observer.Expect('opt two', 'Two');
        Observer.Expect('opt int', '2');
        Observer.Expect('field caption', 'Cap Caption');
        Observer.Expect('field name', 'Cap');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Option_Fields()
    var
        Rec: Record "LT RcB Defaults";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Opt := Rec.Opt::Second;
        Observer.Observe('opt format', Format(Rec.Opt));
        Rec.Opt := 2;
        Observer.Observe('opt by int', Format(Rec.Opt));
        Rec.Opt := 3;
        Observer.Observe('opt out of range', 'no error');
        Rec.Col := Rec.Col::Blue;
        Observer.Observe('enum blue', Format(Rec.Col) + '/' + Format(Rec.Col.AsInteger()));
        Observer.Observe('enum ordinal', Format(Rec.Col.Ordinals().Count()));
        Rec.Col := Enum::"LT RcB Color".FromInteger(1);
        Observer.Observe('enum from int', Format(Rec.Col));
        Rec.Validate(Col, Rec.Col::Red);
        Observer.Observe('enum validated', Format(Rec.Col));
        Rec.Lvl := Rec.Lvl::High;
        Observer.Observe('enum non extensible', Format(Rec.Lvl));
        Observer.Observe('opt text compare', Format(Rec.Opt = Rec.Opt::Third));
        Observer.Expect('opt format', 'Second');
        Observer.Expect('opt by int', 'Third');
        Observer.Expect('opt out of range', 'no error');
        Observer.Expect('enum blue', 'Blue/5');
        Observer.Expect('enum ordinal', '3');
        Observer.Expect('enum from int', 'Green');
        Observer.Expect('enum validated', 'Red');
        Observer.Expect('enum non extensible', 'High');
        Observer.Expect('opt text compare', 'No');
        Observer.Verify();
    end;

    // Corpus issue 668 item 68 (writer br): an Enum field with NotBlank = true compiles and publishes; Validate, Insert and Modify with
    // the ordinal 0 value, as a key field and as a normal field.
    [Test]
    procedure Props_NotBlank_EnumField()
    var
        Rec: Record "LT BR NotBlank Enum";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Observer.Observe('init value', Format(Rec.Color) + '|' + Format(Rec.KeyColor));
        Rec.Validate(Color, Rec.Color::Green);
        Observer.Observe('validate green', Format(Rec.Color));
        ClearLastError();
        asserterror begin
            Rec.Validate(Color, Rec.Color::Red);
            Error('no error');
        end;
        Observer.Observe('validate red (ordinal 0)', GetLastErrorText() + '|' + GetLastErrorCode());
        Rec.Color := Rec.Color::Red;
        Rec.KeyColor := Rec.KeyColor::Red;
        Observer.Observe('insert ordinal 0 key and field', Format(Rec.Insert()));
        Observer.Observe('count', Format(Rec.Count()));
        Rec.Color := Rec.Color::Blue;
        Observer.Observe('modify', Format(Rec.Modify()));
        Observer.Expect('init value', 'Red|Red');
        Observer.Expect('validate green', 'Green');
        Observer.Expect('validate red (ordinal 0)', 'no error|Dialog');
        Observer.Expect('insert ordinal 0 key and field', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('modify', 'Yes');
        Observer.Verify();
    end;

    // Writer QZ: a table procedure Init(A; B) next to the built-in Init() (fixture in QzInitOverload.al).
    [Test]
    procedure QZ_TableInitOverload_NextToBuiltin()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ Init Row";
    begin
        Row.Id := 1;
        Row.Name := 'set';
        Row.Num := 1;
        Row.Init();
        Observer.Observe('qualified Init()', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Row.Name := 'set';
        Row.Num := 1;
        Row.Init(3, 'x');
        Observer.Observe('qualified Init(3, x)', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Row.Name := 'set';
        Row.Num := 1;
        Row.CallBareInit();
        Observer.Observe('bare Init() in the table', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Row.Name := 'set';
        Row.Num := 1;
        Row.CallBareInitWithArguments();
        Observer.Observe('bare Init(5, inner) in the table', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Observer.Expect('qualified Init()', '1||7');
        Observer.Expect('qualified Init(3, x)', '1|own x|3');
        Observer.Expect('bare Init() in the table', '1||7');
        Observer.Expect('bare Init(5, inner) in the table', '1|own inner|5');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_TableInitSameSignature_HidesBuiltin()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ Init Hide";
    begin
        Row.Id := 1;
        Row.Name := 'set';
        Row.Num := 1;
        Row.Init();
        Observer.Observe('qualified Init()', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Row.Name := 'set';
        Row.Num := 1;
        Row.CallBareInit();
        Observer.Observe('bare Init() in the table', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Row.Name := 'set';
        Row.Num := 1;
        Row.CallRecInit();
        Observer.Observe('Rec.Init() in the table', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.Num));
        Observer.Expect('qualified Init()', '1|own Init()|1');
        Observer.Expect('bare Init() in the table', '1|own Init()|1');
        Observer.Expect('Rec.Init() in the table', '1|own Init()|1');
        Observer.Verify();
    end;
}

table 82965 "LT BR NotBlank Enum"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; KeyColor; Enum "LT RcB Color") { NotBlank = true; }
        field(2; Color; Enum "LT RcB Color") { NotBlank = true; }
    }

    keys { key(PK; KeyColor) { Clustered = true; } }
}
