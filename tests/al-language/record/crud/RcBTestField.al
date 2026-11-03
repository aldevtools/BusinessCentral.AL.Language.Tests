// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: self-contained table 72005, enum 72002, test codeunits 72003 and 72004
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField (Field), (Field, Value), (Field, ErrorInfo), (Field, Value, ErrorInfo) for each field type, and Record.FieldError (Field), (Field, Text), (Field, ErrorInfo):
// the error text and code, for blank, zero, mismatched and matching values, with and without a primary key set.
// BC versions: 29 (27 and 28 by CI)

enum 72002 "LT RcB TF Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
    value(2; Two) { }
}

table 72005 "LT RcB TF"
{
    DataClassification = SystemMetadata;
    Caption = 'RcB TF Caption';

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cod; Code[10]) { }
        field(4; Dec; Decimal) { }
        field(5; Int; Integer) { }
        field(6; Big; BigInteger) { }
        field(7; Bool; Boolean) { }
        field(8; Dt; Date) { }
        field(9; Tm; Time) { }
        field(10; DtTm; DateTime) { }
        field(11; Gd; Guid) { }
        field(12; Opt; Option) { OptionMembers = Zero,One,Two; }
        field(13; Knd; Enum "LT RcB TF Kind") { }
        field(14; Cap; Text[30]) { Caption = 'The Cap'; }
        field(15; Dur; Duration) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72006 "LT RcB TF2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Integer) { }
        field(2; B; Code[10]) { }
        field(3; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; A, B) { Clustered = true; }
    }
}

codeunit 72003 "LT RcB TestField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestField_Blank_Each_Type()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        asserterror Rec.TestField(Txt);
        Observer.ObserveError('text');
        asserterror Rec.TestField(Cod);
        Observer.ObserveError('code');
        asserterror Rec.TestField(Dec);
        Observer.ObserveError('decimal');
        asserterror Rec.TestField(Int);
        Observer.ObserveError('integer');
        asserterror Rec.TestField(Big);
        Observer.ObserveError('biginteger');
        asserterror Rec.TestField(Bool);
        Observer.ObserveError('boolean');
        asserterror Rec.TestField(Dt);
        Observer.ObserveError('date');
        asserterror Rec.TestField(Tm);
        Observer.ObserveError('time');
        asserterror Rec.TestField(DtTm);
        Observer.ObserveError('datetime');
        asserterror Rec.TestField(Gd);
        Observer.ObserveError('guid');
        asserterror Rec.TestField(Opt);
        Observer.ObserveError('option');
        asserterror Rec.TestField(Knd);
        Observer.ObserveError('enum');
        asserterror Rec.TestField(Dur);
        Observer.ObserveError('duration');
        asserterror Rec.TestField(Cap);
        Observer.ObserveError('captioned');
        Observer.Expect('text|text', 'Txt must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('text|code', 'TestField');
        Observer.Expect('code|text', 'Cod must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('code|code', 'TestField');
        Observer.Expect('decimal|text', 'Dec must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('decimal|code', 'TestField');
        Observer.Expect('integer|text', 'Int must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('integer|code', 'TestField');
        Observer.Expect('biginteger|text', 'Big must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('biginteger|code', 'TestField');
        Observer.Expect('boolean|text', 'Bool must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('boolean|code', 'TestField');
        Observer.Expect('date|text', 'Dt must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('date|code', 'TestField');
        Observer.Expect('time|text', 'Tm must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('time|code', 'TestField');
        Observer.Expect('datetime|text', 'DtTm must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('datetime|code', 'TestField');
        Observer.Expect('guid|text', 'Gd must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('guid|code', 'TestField');
        Observer.Expect('option|text', 'Opt must not be Zero in RcB TF Caption: Id=1');
        Observer.Expect('option|code', 'TestField');
        Observer.Expect('enum|text', 'Knd must not be None in RcB TF Caption: Id=1');
        Observer.Expect('enum|code', 'TestField');
        Observer.Expect('duration|text', 'Dur must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('duration|code', 'TestField');
        Observer.Expect('captioned|text', 'The Cap must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('captioned|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Filled_NoError()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Txt := 'x';
        Rec.Cod := 'X';
        Rec.Dec := 0.01;
        Rec.Int := -1;
        Rec.Big := 1;
        Rec.Bool := true;
        Rec.Dt := 20250101D;
        Rec.Tm := 120000T;
        Rec.DtTm := CreateDateTime(20250101D, 0T);
        Rec.Gd := CreateGuid();
        Rec.Opt := Rec.Opt::One;
        Rec.Knd := Rec.Knd::Two;
        Rec.Dur := 1;
        Rec.TestField(Txt);
        Rec.TestField(Cod);
        Rec.TestField(Dec);
        Rec.TestField(Int);
        Rec.TestField(Big);
        Rec.TestField(Bool);
        Rec.TestField(Dt);
        Rec.TestField(Tm);
        Rec.TestField(DtTm);
        Rec.TestField(Gd);
        Rec.TestField(Opt);
        Rec.TestField(Knd);
        Rec.TestField(Dur);
        Observer.Observe('all passed', 'yes');
        Observer.Expect('all passed', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Whitespace_Midnight()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Txt := ' ';
        Rec.TestField(Txt);
        Observer.Observe('space text', 'passes');
        Rec.Tm := 000000T;
        Rec.TestField(Tm);
        Observer.Observe('midnight time', 'no error');
        Rec.Dt := 0D;
        asserterror Rec.TestField(Dt);
        Observer.ObserveError('0D');
        Rec.Dec := 0.00001;
        Rec.TestField(Dec);
        Observer.Observe('tiny decimal', 'passes');
        Observer.Expect('space text', 'passes');
        Observer.Expect('midnight time', 'no error');
        Observer.Expect('0D|text', 'Dt must have a value in RcB TF Caption: Id=0. It cannot be zero or empty.');
        Observer.Expect('0D|code', 'TestField');
        Observer.Expect('tiny decimal', 'passes');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Value_Match_And_Mismatch()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 5;
        Rec.Txt := 'abc';
        Rec.Cod := 'COD';
        Rec.Dec := 1.5;
        Rec.Int := 3;
        Rec.Bool := true;
        Rec.Dt := 20250102D;
        Rec.Opt := Rec.Opt::One;
        Rec.Knd := Rec.Knd::Two;
        Rec.TestField(Txt, 'abc');
        Rec.TestField(Cod, 'COD');
        Rec.TestField(Dec, 1.5);
        Rec.TestField(Int, 3);
        Rec.TestField(Bool, true);
        Rec.TestField(Dt, 20250102D);
        Rec.TestField(Opt, Rec.Opt::One);
        Rec.TestField(Knd, Rec.Knd::Two);
        Observer.Observe('matches', 'ok');
        asserterror Rec.TestField(Txt, 'abd');
        Observer.ObserveError('text mismatch');
        asserterror Rec.TestField(Txt, 'ABC');
        Observer.ObserveError('text case mismatch');
        asserterror Rec.TestField(Cod, 'OTHER');
        Observer.ObserveError('code mismatch');
        asserterror Rec.TestField(Dec, 1.6);
        Observer.ObserveError('decimal mismatch');
        asserterror Rec.TestField(Int, 4);
        Observer.ObserveError('integer mismatch');
        asserterror Rec.TestField(Bool, false);
        Observer.ObserveError('boolean mismatch');
        asserterror Rec.TestField(Dt, 20250103D);
        Observer.ObserveError('date mismatch');
        asserterror Rec.TestField(Opt, Rec.Opt::Two);
        Observer.ObserveError('option mismatch');
        asserterror Rec.TestField(Knd, Rec.Knd::One);
        Observer.ObserveError('enum mismatch');
        Observer.Expect('matches', 'ok');
        Observer.Expect('text mismatch|text', 'Txt must be equal to ''abd''  in RcB TF Caption: Id=5. Current value is ''abc''.');
        Observer.Expect('text mismatch|code', 'TestField');
        Observer.Expect('text case mismatch|text', 'Txt must be equal to ''ABC''  in RcB TF Caption: Id=5. Current value is ''abc''.');
        Observer.Expect('text case mismatch|code', 'TestField');
        Observer.Expect('code mismatch|text', 'Cod must be equal to ''OTHER''  in RcB TF Caption: Id=5. Current value is ''COD''.');
        Observer.Expect('code mismatch|code', 'TestField');
        Observer.Expect('decimal mismatch|text', 'Dec must be equal to ''1.6''  in RcB TF Caption: Id=5. Current value is ''1.5''.');
        Observer.Expect('decimal mismatch|code', 'TestField');
        Observer.Expect('integer mismatch|text', 'Int must be equal to ''4''  in RcB TF Caption: Id=5. Current value is ''3''.');
        Observer.Expect('integer mismatch|code', 'TestField');
        Observer.Expect('boolean mismatch|text', 'Bool must be equal to ''No''  in RcB TF Caption: Id=5. Current value is ''Yes''.');
        Observer.Expect('boolean mismatch|code', 'TestField');
        Observer.Expect('date mismatch|text', 'Dt must be equal to ''01/03/25''  in RcB TF Caption: Id=5. Current value is ''01/02/25''.');
        Observer.Expect('date mismatch|code', 'TestField');
        Observer.Expect('option mismatch|text', 'Opt must be equal to ''Two''  in RcB TF Caption: Id=5. Current value is ''One''.');
        Observer.Expect('option mismatch|code', 'TestField');
        Observer.Expect('enum mismatch|text', 'Knd must be equal to ''One''  in RcB TF Caption: Id=5. Current value is ''Two''.');
        Observer.Expect('enum mismatch|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Value_Blank_Expected()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 2;
        Rec.TestField(Txt, '');
        Rec.TestField(Dec, 0);
        Rec.TestField(Int, 0);
        Rec.TestField(Bool, false);
        Rec.TestField(Dt, 0D);
        Observer.Observe('blank equals blank', 'ok');
        Rec.Txt := 'x';
        asserterror Rec.TestField(Txt, '');
        Observer.ObserveError('expect blank text');
        Rec.Int := 5;
        asserterror Rec.TestField(Int, 0);
        Observer.ObserveError('expect zero');
        Rec.Dt := 20250101D;
        asserterror Rec.TestField(Dt, 0D);
        Observer.ObserveError('expect 0D');
        Observer.Expect('blank equals blank', 'ok');
        Observer.Expect('expect blank text|text', 'Txt must be equal to ''''  in RcB TF Caption: Id=2. Current value is ''x''.');
        Observer.Expect('expect blank text|code', 'TestField');
        Observer.Expect('expect zero|text', 'Int must be equal to ''0''  in RcB TF Caption: Id=2. Current value is ''5''.');
        Observer.Expect('expect zero|code', 'TestField');
        Observer.Expect('expect 0D|text', 'Dt must be equal to ''''  in RcB TF Caption: Id=2. Current value is ''01/01/25''.');
        Observer.Expect('expect 0D|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Value_Conversions()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Dec := 5;
        Rec.TestField(Dec, 5);
        Rec.Int := 7;
        Rec.TestField(Int, 7.0);
        Observer.Observe('int vs decimal literal', 'ok');
        Rec.Txt := '5';
        Rec.TestField(Txt, '5');
        Observer.Observe('text', 'ok');
        Rec.Big := 9;
        Rec.TestField(Big, 9);
        Observer.Observe('big', 'ok');
        asserterror Rec.TestField(Big, 10);
        Observer.ObserveError('big mismatch');
        Observer.Expect('int vs decimal literal', 'ok');
        Observer.Expect('text', 'ok');
        Observer.Expect('big', 'ok');
        Observer.Expect('big mismatch|text', 'Big must be equal to ''10''  in RcB TF Caption: Id=0. Current value is ''9''.');
        Observer.Expect('big mismatch|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_PrimaryKey_Variants()
    var
        Rec: Record "LT RcB TF";
        Rec2: Record "LT RcB TF2";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 17;
        asserterror Rec.TestField(Txt);
        Observer.ObserveError('single pk');
        Rec.Id := 0;
        asserterror Rec.TestField(Txt);
        Observer.ObserveError('pk zero');
        Rec2.A := 3;
        Rec2.B := 'KEY';
        asserterror Rec2.TestField(Txt);
        Observer.ObserveError('composite pk');
        asserterror Rec2.TestField(Txt, 'q');
        Observer.ObserveError('composite pk value');
        Rec2.Init();
        asserterror Rec2.TestField(Txt);
        Observer.ObserveError('composite pk blank');
        Observer.Expect('single pk|text', 'Txt must have a value in RcB TF Caption: Id=17. It cannot be zero or empty.');
        Observer.Expect('single pk|code', 'TestField');
        Observer.Expect('pk zero|text', 'Txt must have a value in RcB TF Caption: Id=0. It cannot be zero or empty.');
        Observer.Expect('pk zero|code', 'TestField');
        Observer.Expect('composite pk|text', 'Txt must have a value in LT RcB TF2: A=3, B=KEY. It cannot be zero or empty.');
        Observer.Expect('composite pk|code', 'TestField');
        Observer.Expect('composite pk value|text', 'Txt must be equal to ''q''  in LT RcB TF2: A=3, B=KEY. Current value is ''''.');
        Observer.Expect('composite pk value|code', 'TestField');
        Observer.Expect('composite pk blank|text', 'Txt must have a value in LT RcB TF2: A=3, B=KEY. It cannot be zero or empty.');
        Observer.Expect('composite pk blank|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_ErrorInfo_Overloads()
    var
        Rec: Record "LT RcB TF";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Info := ErrorInfo.Create('custom text');
        asserterror Rec.TestField(Txt, Info);
        Observer.ObserveError('field errorinfo');
        Rec.Txt := 'a';
        asserterror Rec.TestField(Txt, 'b', Info);
        Observer.ObserveError('field value errorinfo');
        Rec.TestField(Txt, 'a', Info);
        Observer.Observe('passing', 'ok');
        Observer.Observe('info message', Info.Message());
        Observer.Observe('info fieldno', Format(Info.FieldNo()));
        Observer.Observe('info tableid', Format(Info.TableId()));
        Observer.Expect('field errorinfo|text', 'Txt must have a value in RcB TF Caption: Id=1. It cannot be zero or empty.');
        Observer.Expect('field errorinfo|code', 'TestField');
        Observer.Expect('field value errorinfo|text', 'Txt must be equal to ''b''  in RcB TF Caption: Id=1. Current value is ''a''.');
        Observer.Expect('field value errorinfo|code', 'TestField');
        Observer.Expect('passing', 'ok');
        Observer.Expect('info message', 'custom text');
        Observer.Expect('info fieldno', '0');
        Observer.Expect('info tableid', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_ErrorInfo_Collect()
    var
        Rec: Record "LT RcB TF";
        Info: ErrorInfo;
        Errors: List of [ErrorInfo];
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        asserterror CollectOne(Rec);
        Observer.ObserveError('af313');
        Errors := GetCollectedErrors();
        Observer.Observe('collected', Format(Errors.Count()));
        if Errors.Count() > 0 then begin
            Info := Errors.Get(1);
            Observer.Observe('message', Info.Message());
            Observer.Observe('fieldno', Format(Info.FieldNo()));
            Observer.Observe('tableid', Format(Info.TableId()));
            Observer.Observe('errortype', Format(Info.ErrorType()));
            Observer.Observe('collectible', Format(Info.Collectible()));
        end;
        ClearCollectedErrors();
        Observer.Expect('af313|text', 'Multiple errors occurred during the operation the first of which is: collect me. All errors can be found under ''Detailed Information''.');
        Observer.Expect('af313|code', 'Dialog');
        Observer.Expect('collected', '0');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectOne(var Rec: Record "LT RcB TF")
    var
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('collect me', true);
        Rec.TestField(Txt, Info);
        Rec.TestField(Txt, 'z', Info);
    end;

    [Test]
    procedure TestField_UsesFieldCaption()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('table caption', Rec.TableCaption());
        asserterror Rec.TestField(Cap);
        Observer.ObserveError('caption in error');
        Observer.Expect('table caption', 'RcB TF Caption');
        Observer.Expect('caption in error|text', 'The Cap must have a value in RcB TF Caption: Id=0. It cannot be zero or empty.');
        Observer.Expect('caption in error|code', 'TestField');
        Observer.Verify();
    end;

    // Corpus issue 670 item 16 (writer CT): what a failed TestField inside asserterror leaves in the record variable and in the
    // database, for a field assigned in memory only and for a field changed by Modify before the failing TestField.
    [Test]
    procedure TestField_Failed_RecordStateAfterwards()
    var
        Rec: Record "LT RcB TF";
        Stored: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        // Not committed: the failed TestField rolls back the Insert made before the asserterror, the variable keeps its values.
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 16;
        Rec.Txt := 'orig';
        Rec.Insert();
        Rec.Txt := 'in memory';
        asserterror Rec.TestField(Cod);
        Observer.ObserveError('memory only');
        Observer.Observe('memory only var', Rec.Txt);
        Observer.Observe('memory only stored', Format(Stored.Get(16)));
        // Committed row, then Modify and a failed TestField: the Modify is rolled back, the variable keeps the modified value.
        Rec.Txt := 'orig';
        Rec.Insert();
        Commit();
        Rec.Txt := 'modified';
        Rec.Modify();
        asserterror Rec.TestField(Cod);
        Observer.ObserveError('after modify');
        Observer.Observe('after modify var', Rec.Txt);
        Clear(Stored);
        Observer.Observe('after modify stored', Format(Stored.Get(16)) + ' ' + Stored.Txt);
        Rec.DeleteAll();
        Commit();
        Observer.Expect('memory only|text', 'Cod must have a value in RcB TF Caption: Id=16. It cannot be zero or empty.');
        Observer.Expect('memory only|code', 'TestField');
        Observer.Expect('memory only var', 'in memory');
        Observer.Expect('memory only stored', 'No');
        Observer.Expect('after modify|text', 'Cod must have a value in RcB TF Caption: Id=16. It cannot be zero or empty.');
        Observer.Expect('after modify|code', 'TestField');
        Observer.Expect('after modify var', 'modified');
        Observer.Expect('after modify stored', 'Yes orig');
        Observer.Verify();
    end;
}

codeunit 72004 "LT RcB FieldError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldError_NoText()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 4;
        Rec.Txt := 'abc';
        asserterror Rec.FieldError(Txt);
        Observer.ObserveError('text');
        asserterror Rec.FieldError(Int);
        Observer.ObserveError('integer');
        asserterror Rec.FieldError(Opt);
        Observer.ObserveError('option');
        asserterror Rec.FieldError(Knd);
        Observer.ObserveError('enum');
        asserterror Rec.FieldError(Cap);
        Observer.ObserveError('captioned');
        Observer.Expect('text|text', 'Txt must not be abc in RcB TF Caption Id=''4''.');
        Observer.Expect('text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('integer|text', 'Int must not be 0 in RcB TF Caption Id=''4''.');
        Observer.Expect('integer|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('option|text', 'Opt must not be Zero in RcB TF Caption Id=''4''.');
        Observer.Expect('option|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('enum|text', 'Knd must not be None in RcB TF Caption Id=''4''.');
        Observer.Expect('enum|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('captioned|text', 'You must specify The Cap in RcB TF Caption Id=''4''.');
        Observer.Expect('captioned|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_WithText()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 4;
        asserterror Rec.FieldError(Txt, 'is wrong');
        Observer.ObserveError('plain');
        asserterror Rec.FieldError(Txt, '');
        Observer.ObserveError('empty text');
        asserterror Rec.FieldError(Txt, 'with %1 placeholder');
        Observer.ObserveError('placeholder');
        asserterror Rec.FieldError(Txt, 'multi' + Format(CreateGuid()).Substring(1, 0) + 'part. Second sentence.');
        Observer.ObserveError('sentence');
        asserterror Rec.FieldError(Txt, 'unicode äöü ✓');
        Observer.ObserveError('unicode');
        Observer.Expect('plain|text', 'Txt is wrong in RcB TF Caption Id=''4''.');
        Observer.Expect('plain|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('empty text|text', 'You must specify Txt in RcB TF Caption Id=''4''.');
        Observer.Expect('empty text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('placeholder|text', 'Txt with %1 placeholder in RcB TF Caption Id=''4''.');
        Observer.Expect('placeholder|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('sentence|text', 'Txt multipart. Second sentence. in RcB TF Caption Id=''4''.');
        Observer.Expect('sentence|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('unicode|text', 'Txt unicode äöü ✓ in RcB TF Caption Id=''4''.');
        Observer.Expect('unicode|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Label()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 9;
        asserterror Rec.FieldError(Dec, LblText);
        Observer.ObserveError('label');
        asserterror Rec.FieldError(Dec, StrSubstNo(LblFmt, 'a', 2));
        Observer.ObserveError('substituted label');
        Observer.Expect('label|text', 'Dec label text in RcB TF Caption Id=''9''.');
        Observer.Expect('label|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('substituted label|text', 'Dec fmt a and 2 in RcB TF Caption Id=''9''.');
        Observer.Expect('substituted label|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_CompositeKey()
    var
        Rec2: Record "LT RcB TF2";
        Observer: Codeunit "Probe Observer";
    begin
        Rec2.A := 1;
        Rec2.B := 'K';
        asserterror Rec2.FieldError(Txt, 'bad');
        Observer.ObserveError('composite');
        asserterror Rec2.FieldError(Txt);
        Observer.ObserveError('composite no text');
        Observer.Expect('composite|text', 'Txt bad in LT RcB TF2 A=''1'',B=''K''.');
        Observer.Expect('composite|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('composite no text|text', 'You must specify Txt in LT RcB TF2 A=''1'',B=''K''.');
        Observer.Expect('composite no text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_ErrorInfo()
    var
        Rec: Record "LT RcB TF";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 3;
        Info := ErrorInfo.Create('info message');
        asserterror Rec.FieldError(Txt, Info);
        Observer.ObserveError('errorinfo');
        Info := ErrorInfo.Create('');
        asserterror Rec.FieldError(Txt, Info);
        Observer.ObserveError('errorinfo empty');
        Observer.Expect('errorinfo|text', 'Txt info message in RcB TF Caption Id=''3''.');
        Observer.Expect('errorinfo|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('errorinfo empty|text', 'You must specify Txt in RcB TF Caption Id=''3''.');
        Observer.Expect('errorinfo empty|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Collect()
    var
        Rec: Record "LT RcB TF";
        Errors: List of [ErrorInfo];
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 3;
        asserterror CollectFieldError(Rec);
        Observer.ObserveError('af453');
        Errors := GetCollectedErrors();
        Observer.Observe('collected', Format(Errors.Count()));
        if Errors.Count() > 0 then begin
            Info := Errors.Get(1);
            Observer.Observe('message', Info.Message());
            Observer.Observe('fieldno', Format(Info.FieldNo()));
            Observer.Observe('tableid', Format(Info.TableId()));
        end;
        ClearCollectedErrors();
        Observer.Expect('af453|text', 'Txt collected field error in RcB TF Caption Id=''3''.');
        Observer.Expect('af453|code', 'Dialog');
        Observer.Expect('collected', '0');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectFieldError(var Rec: Record "LT RcB TF")
    var
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('collected field error', true);
        Rec.FieldError(Txt, Info);
    end;

    // Corpus issue 670 item 21 (writer CT): FieldError with a text that already ends in a period, with a backslash, with only a
    // period, and on a field whose value ends in a period.
    [Test]
    procedure FieldError_PeriodAndBackslash()
    var
        Rec: Record "LT RcB TF";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 21;
        asserterror Rec.FieldError(Txt, 'is wrong.');
        Observer.ObserveError('ends in period');
        asserterror Rec.FieldError(Txt, 'is wrong..');
        Observer.ObserveError('two periods');
        asserterror Rec.FieldError(Txt, '.');
        Observer.ObserveError('only period');
        asserterror Rec.FieldError(Txt, 'first\second');
        Observer.ObserveError('backslash');
        asserterror Rec.FieldError(Txt, 'ends in backslash\');
        Observer.ObserveError('trailing backslash');
        Rec.Txt := 'value.';
        asserterror Rec.FieldError(Txt);
        Observer.ObserveError('value ends in period');
        Rec.Txt := '';
        asserterror Rec.FieldError(Txt);
        Observer.ObserveError('empty value');
        Observer.Expect('ends in period|text', 'Txt is wrong. in RcB TF Caption Id=''21''.');
        Observer.Expect('ends in period|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('two periods|text', 'Txt is wrong.. in RcB TF Caption Id=''21''.');
        Observer.Expect('two periods|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('only period|text', 'Txt . in RcB TF Caption Id=''21''.');
        Observer.Expect('only period|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('backslash|text', 'Txt first\second in RcB TF Caption Id=''21''.');
        Observer.Expect('backslash|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('trailing backslash|text', 'Txt ends in backslash\ in RcB TF Caption Id=''21''.');
        Observer.Expect('trailing backslash|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('value ends in period|text', 'Txt must not be value. in RcB TF Caption Id=''21''.');
        Observer.Expect('value ends in period|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('empty value|text', 'You must specify Txt in RcB TF Caption Id=''21''.');
        Observer.Expect('empty value|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    var
        LblText: Label 'label text';
        LblFmt: Label 'fmt %1 and %2';
}
