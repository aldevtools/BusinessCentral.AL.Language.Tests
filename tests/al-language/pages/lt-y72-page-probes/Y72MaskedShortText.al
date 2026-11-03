// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-extendeddatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93857; codeunit 93853,93854; page 93858,93859
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what TestPage.Value() returns for a Masked control that shows a text of 1 to 50 characters: a table field with
//   ExtendedDatatype = Masked on the table and on the page control, a page variable bound to a Masked control (the SMTP account password
//   shape: a 3 character text), a Code field, blanks and non-ASCII characters, SetValue with a short text, a Masked property only on the
//   table field and only on the page control. The bullet is U+2022.
// Neighbours: pages/lt-page-presentation-properties/P119PageFields.al (11 characters show ten bullets, the empty text shows empty).
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): a Masked control shows ten bullets for a text of any length from 1 to 50 (field, Code
//   field, page variable, text of blanks only, non-ASCII, page-only and table-only property); an empty text shows empty. SetValue of a
//   short or long text keeps the ten bullets and stores the clear text. AssertEquals on a masked control compares with the ten bullets,
//   so the clear text and three bullets fail with TestAssertEquals. A page variable without the Masked property shows its clear text.
// BC versions: all (CI)

table 93857 "LT Y72 Mask Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Secret; Text[50]) { ExtendedDatatype = Masked; }
        field(3; SecretCode; Code[20]) { ExtendedDatatype = Masked; }
        field(4; Plain; Text[50]) { }
        field(5; TableOnly; Text[50]) { ExtendedDatatype = Masked; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93853 "LT Y72 Mask Value"
{
    SingleInstance = true;

    var
        Stored: Text;

    procedure Set(Value: Text)
    begin
        Stored := Value;
    end;

    procedure Get(): Text
    begin
        exit(Stored);
    end;
}

page 93858 "LT Y72 Mask Card"
{
    PageType = Card;
    SourceTable = "LT Y72 Mask Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(SecretF; Rec.Secret)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(VarF; PwVar)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(CodeF; Rec.SecretCode)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(PlainF; Rec.Plain)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    var
        PwVar: Text;

    trigger OnAfterGetRecord()
    var
        Holder: Codeunit "LT Y72 Mask Value";
    begin
        PwVar := Holder.Get();
    end;
}

page 93859 "LT Y72 Mask Card Two"
{
    PageType = Card;
    SourceTable = "LT Y72 Mask Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TableOnlyF; Rec.TableOnly) { ApplicationArea = All; }
                field(SecretF; Rec.Secret) { ApplicationArea = All; }
                field(VarF; PwVar) { ApplicationArea = All; }
            }
        }
    }

    var
        PwVar: Text;

    trigger OnAfterGetRecord()
    var
        Holder: Codeunit "LT Y72 Mask Value";
    begin
        PwVar := Holder.Get();
    end;
}

codeunit 93854 "LT Y72 Masked Short Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y72 Mask Row";
    begin
        ClearLastError();
        Observer.Discard();
        Row.DeleteAll();
    end;

    local procedure Rep(Ch: Text; Count: Integer): Text
    var
        Result: Text;
        i: Integer;
    begin
        for i := 1 to Count do
            Result += Ch;
        exit(Result);
    end;

    local procedure StoreSecret(Id: Integer; Value: Text)
    var
        Row: Record "LT Y72 Mask Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Secret := CopyStr(Value, 1, MaxStrLen(Row.Secret));
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryAssertEquals(var P: TestPage "LT Y72 Mask Card"; Expected: Text)
    begin
        P.SecretF.AssertEquals(Expected);
    end;

    [Test]
    procedure Masked_LengthSweep_Field()
    var
        Row: Record "LT Y72 Mask Row";
        P: TestPage "LT Y72 Mask Card";
        Lengths: List of [Integer];
        Len: Integer;
    begin
        Seed();
        Lengths.AddRange(1, 2, 3, 5, 9, 10, 11, 20, 50);
        foreach Len in Lengths do
            StoreSecret(Len, Rep('a', Len));
        foreach Len in Lengths do begin
            Row.Get(Len);
            P.Trap();
            Page.Run(Page::"LT Y72 Mask Card", Row);
            Observer.Observe('len ' + Format(Len) + ' value', P.SecretF.Value());
            Observer.Observe('len ' + Format(Len) + ' strlen', Format(StrLen(P.SecretF.Value())));
            P.Close();
        end;
        Observer.Expect('len 1 value', '••••••••••');
        Observer.Expect('len 1 strlen', '10');
        Observer.Expect('len 2 value', '••••••••••');
        Observer.Expect('len 2 strlen', '10');
        Observer.Expect('len 3 value', '••••••••••');
        Observer.Expect('len 3 strlen', '10');
        Observer.Expect('len 5 value', '••••••••••');
        Observer.Expect('len 5 strlen', '10');
        Observer.Expect('len 9 value', '••••••••••');
        Observer.Expect('len 9 strlen', '10');
        Observer.Expect('len 10 value', '••••••••••');
        Observer.Expect('len 10 strlen', '10');
        Observer.Expect('len 11 value', '••••••••••');
        Observer.Expect('len 11 strlen', '10');
        Observer.Expect('len 20 value', '••••••••••');
        Observer.Expect('len 20 strlen', '10');
        Observer.Expect('len 50 value', '••••••••••');
        Observer.Expect('len 50 strlen', '10');
        Observer.Verify();
    end;




    [Test]
    procedure Masked_PageVariable_Short()
    var
        Row: Record "LT Y72 Mask Row";
        Holder: Codeunit "LT Y72 Mask Value";
        P: TestPage "LT Y72 Mask Card";
        Values: List of [Text];
        Value: Text;
    begin
        Seed();
        StoreSecret(1, 'row');
        Row.Get(1);
        Values.Add('***');
        Values.Add('');
        Values.Add('x');
        Values.Add('123456789');
        Values.Add('1234567890');
        Values.Add('TestPassword123');
        foreach Value in Values do begin
            Holder.Set(Value);
            P.Trap();
            Page.Run(Page::"LT Y72 Mask Card", Row);
            Observer.Observe('var <' + Value + '> value', P.VarF.Value());
            Observer.Observe('var <' + Value + '> strlen', Format(StrLen(P.VarF.Value())));
            P.Close();
        end;
        Observer.Expect('var <***> value', '••••••••••');
        Observer.Expect('var <***> strlen', '10');
        Observer.Expect('var <> value', '');
        Observer.Expect('var <> strlen', '0');
        Observer.Expect('var <x> value', '••••••••••');
        Observer.Expect('var <x> strlen', '10');
        Observer.Expect('var <123456789> value', '••••••••••');
        Observer.Expect('var <123456789> strlen', '10');
        Observer.Expect('var <1234567890> value', '••••••••••');
        Observer.Expect('var <1234567890> strlen', '10');
        Observer.Expect('var <TestPassword123> value', '••••••••••');
        Observer.Expect('var <TestPassword123> strlen', '10');
        Observer.Verify();
    end;




    [Test]
    procedure Masked_SetValueShort()
    var
        Row: Record "LT Y72 Mask Row";
        P: TestPage "LT Y72 Mask Card";
    begin
        Seed();
        StoreSecret(1, 'start');
        P.OpenEdit();
        Observer.Observe('open value', P.SecretF.Value());
        P.SecretF.SetValue('abc');
        Observer.Observe('set abc value', P.SecretF.Value());
        P.SecretF.SetValue('abcdefghijkl');
        Observer.Observe('set 12 value', P.SecretF.Value());
        P.SecretF.SetValue('');
        Observer.Observe('set empty value', P.SecretF.Value());
        P.SecretF.SetValue('xy');
        P.Close();
        Row.Get(1);
        Observer.Observe('stored', Row.Secret);
        Observer.Expect('open value', '••••••••••');
        Observer.Expect('set abc value', '••••••••••');
        Observer.Expect('set 12 value', '••••••••••');
        Observer.Expect('set empty value', '');
        Observer.Expect('stored', 'xy');
        Observer.Verify();
    end;




    [Test]
    procedure Masked_AssertEquals()
    var
        P: TestPage "LT Y72 Mask Card";
        Ok: Boolean;
    begin
        Seed();
        StoreSecret(1, 'abc');
        P.OpenEdit();
        Ok := TryAssertEquals(P, 'abc');
        Observer.Observe('clear text ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('clear text');
        Ok := TryAssertEquals(P, '•••');
        Observer.Observe('three bullets ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('three bullets');
        Ok := TryAssertEquals(P, '••••••••••');
        Observer.Observe('ten bullets ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('ten bullets');
        P.Close();
        Observer.Expect('clear text ok', 'No');
        Observer.Expect('clear text|text', 'AssertEquals for Field: SecretF Expected = ''abc'', Actual = ''••••••••••''');
        Observer.Expect('clear text|code', 'TestAssertEquals');
        Observer.Expect('three bullets ok', 'No');
        Observer.Expect('three bullets|text', 'AssertEquals for Field: SecretF Expected = ''•••'', Actual = ''••••••••••''');
        Observer.Expect('three bullets|code', 'TestAssertEquals');
        Observer.Expect('ten bullets ok', 'Yes');
        Observer.Verify();
    end;




    [Test]
    procedure Masked_Code_And_Blanks()
    var
        Row: Record "LT Y72 Mask Row";
        P: TestPage "LT Y72 Mask Card";
    begin
        Seed();
        Row.Init();
        Row.Id := 1;
        Row.SecretCode := 'AB';
        Row.Secret := ' a ';
        Row.Plain := 'äö';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Secret := 'äö';
        Row.SecretCode := 'ABCDEFGHIJKLMNO';
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.Secret := '   ';
        Row.Insert();
        Row.Get(1);
        P.Trap();
        Page.Run(Page::"LT Y72 Mask Card", Row);
        Observer.Observe('1 code', P.CodeF.Value());
        Observer.Observe('1 blanks around', P.SecretF.Value());
        Observer.Observe('1 plain with page property', P.PlainF.Value());
        P.Close();
        Row.Get(2);
        P.Trap();
        Page.Run(Page::"LT Y72 Mask Card", Row);
        Observer.Observe('2 non-ascii', P.SecretF.Value());
        Observer.Observe('2 code 15', P.CodeF.Value());
        Observer.Observe('2 code strlen', Format(StrLen(P.CodeF.Value())));
        P.Close();
        Row.Get(3);
        P.Trap();
        Page.Run(Page::"LT Y72 Mask Card", Row);
        Observer.Observe('3 only blanks', P.SecretF.Value());
        Observer.Observe('3 only blanks strlen', Format(StrLen(P.SecretF.Value())));
        P.Close();
        Observer.Expect('1 code', '••••••••••');
        Observer.Expect('1 blanks around', '••••••••••');
        Observer.Expect('1 plain with page property', '••••••••••');
        Observer.Expect('2 non-ascii', '••••••••••');
        Observer.Expect('2 code 15', '••••••••••');
        Observer.Expect('2 code strlen', '10');
        Observer.Expect('3 only blanks', '••••••••••');
        Observer.Expect('3 only blanks strlen', '10');
        Observer.Verify();
    end;




    [Test]
    procedure Masked_TableOnly_And_PageVariableWithoutProperty()
    var
        Row: Record "LT Y72 Mask Row";
        Holder: Codeunit "LT Y72 Mask Value";
        P: TestPage "LT Y72 Mask Card Two";
    begin
        Seed();
        Row.Init();
        Row.Id := 1;
        Row.TableOnly := 'abc';
        Row.Secret := 'abcdefghijklmnop';
        Row.Insert();
        Holder.Set('***');
        P.OpenView();
        Observer.Observe('table only 3', P.TableOnlyF.Value());
        Observer.Observe('table only strlen', Format(StrLen(P.TableOnlyF.Value())));
        Observer.Observe('table masked field on page without property', P.SecretF.Value());
        Observer.Observe('page variable without property', P.VarF.Value());
        P.Close();
        Observer.Expect('table only 3', '••••••••••');
        Observer.Expect('table only strlen', '10');
        Observer.Expect('table masked field on page without property', '••••••••••');
        Observer.Expect('page variable without property', '***');
        Observer.Verify();
    end;



}
